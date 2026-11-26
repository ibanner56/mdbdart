// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/currency.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../array.dart';
import '../errors.dart';
import 'util.dart';

const _maxPrecision = 20;

/// Reads a currency value: a signed 64-bit integer scaled by 10^4, formatted
/// as a decimal string. Uses digit arrays instead of 64-bit arithmetic, so it
/// gives the same result on the web.
///
/// See mdbtools src/libmdb/money.c, mdb_money_to_string.
String readCurrency(Uint8List buffer) {
  const bytesCount = 8;
  const scale = 4;

  if (buffer.length < bytesCount) {
    throw MdbFormatException(
      'Currency value needs $bytesCount bytes, got ${buffer.length}',
    );
  }

  var product = toArray(0, _maxPrecision);
  var multiplier = toArray(1, _maxPrecision);
  // Negating the value must not mutate caller storage.
  final bytes = Uint8List.fromList(
    Uint8List.sublistView(buffer, 0, bytesCount),
  );

  var negative = false;
  if (bytes[bytesCount - 1] & 0x80 != 0) {
    negative = true;
    for (var i = 0; i < bytesCount; ++i) {
      bytes[i] = ~bytes[i] & 0xff;
    }
    for (var i = 0; i < bytesCount; ++i) {
      bytes[i] = (bytes[i] + 1) & 0xff;
      if (bytes[i] != 0) {
        break;
      }
    }
  }

  for (final byte in bytes) {
    product = addArray(
      product,
      multiplyArray(multiplier, toArray(byte, _maxPrecision)),
    );
    multiplier = multiplyArray(multiplier, toArray(256, _maxPrecision));
  }

  return buildValue(product, scale, negative);
}
