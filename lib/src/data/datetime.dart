// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/datetime.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../bytes.dart';
import '../errors.dart';

const _daysDiff = 25569; // days between 1899-12-30 and 1970-01-01

/// The largest magnitude, in milliseconds, a [DateTime] can hold.
const _maxMillis = 8640000000000000;

/// Reads an OLE Automation date as a UTC [DateTime].
DateTime readDateTime(Uint8List buffer) {
  final td = readFloat64LE(buffer, 0);
  final millis = _jsRound((td - _daysDiff) * 86400 * 1000);
  if (millis == null || millis.abs() > _maxMillis) {
    throw MdbFormatException('Date value $td is out of range');
  }
  return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
}

/// JavaScript's `Math.round`: rounds half up (towards positive infinity).
/// Returns null for NaN and infinities.
int? _jsRound(double x) {
  if (!x.isFinite || x.abs() > 1e17) {
    return null;
  }
  final floor = x.floorToDouble();
  return (x - floor >= 0.5 ? floor + 1 : floor).toInt();
}
