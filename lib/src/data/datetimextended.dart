// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/datetimextended.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:convert';
import 'dart:typed_data';

import '../bytes.dart';
import '../errors.dart';

const _daysStart = 0;
const _daysLength = 19;
const _secondsStart = _daysStart + _daysLength + 1;
const _secondsLength = 12;
const _nanosStart = _secondsStart + _secondsLength;
const _nanosLength = 7;

/// Reads an extended date/time value (ASCII digits) and formats it as
/// `yyyy.MM.dd HH:mm:ss.nnnnnnnnn`, in UTC.
String readDateTimeExtended(Uint8List buffer) {
  final days = _parseBigInt(
    slice(buffer, _daysStart, _daysStart + _daysLength),
  );
  final seconds = _parseBigInt(
    slice(buffer, _secondsStart, _secondsStart + _secondsLength),
  );
  final nanos =
      _parseBigInt(slice(buffer, _nanosStart, _nanosStart + _nanosLength)) *
      BigInt.from(100);

  return _format(days, seconds, nanos);
}

/// Like JavaScript's `BigInt(string)` on ASCII text: surrounding whitespace
/// is ignored and an empty string is 0.
BigInt _parseBigInt(Uint8List buffer) {
  final text = latin1.decode([for (final b in buffer) b & 0x7f]).trim();
  if (text.isEmpty) {
    return BigInt.zero;
  }
  final value = BigInt.tryParse(text);
  if (value == null) {
    throw MdbFormatException('Invalid extended date/time component "$text"');
  }
  return value;
}

/// Days from 0001-01-01 to 1970-01-01.
const _epochDays = 719162;

/// The largest magnitude, in milliseconds, a [DateTime] can hold.
const _maxMillis = 8640000000000000;

/// Largest day offset from 0001-01-01 a [DateTime] can hold, with margin.
const _maxDays = 100000000;

String _format(BigInt days, BigInt seconds, BigInt nanos) {
  // Upstream builds a JavaScript Date at 0001-01-01T00:00Z and adds the days
  // and seconds. Upstream reads the year with the local-time getFullYear()
  // and the other fields in UTC; this port reads every field in UTC so the
  // result does not depend on the time zone.
  if (days.abs() > BigInt.from(_maxDays) ||
      seconds.abs() > BigInt.from(_maxDays) * BigInt.from(86400)) {
    throw MdbFormatException('Extended date/time value is out of range');
  }
  final totalSeconds = (days.toInt() - _epochDays) * 86400 + seconds.toInt();
  if (totalSeconds.abs() > _maxMillis ~/ 1000) {
    throw MdbFormatException('Extended date/time value is out of range');
  }
  final date = DateTime.fromMillisecondsSinceEpoch(
    totalSeconds * 1000,
    isUtc: true,
  );

  String pad(int value, int width) => value.toString().padLeft(width, '0');

  final result = StringBuffer()
    ..write(pad(date.year, 4))
    ..write('.${pad(date.month, 2)}')
    ..write('.${pad(date.day, 2)}')
    ..write(' ${pad(date.hour, 2)}')
    ..write(':${pad(date.minute, 2)}')
    ..write(':${pad(date.second, 2)}')
    ..write('.${nanos.toString().padLeft(9, '0')}');

  return result.toString();
}
