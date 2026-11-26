// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/numeric.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../array.dart';
import '../errors.dart';
import 'util.dart';

const _maxPrecision = 40;

/// Reads a numeric (decimal) value: a sign byte and a 96-bit magnitude in
/// 32-bit little-endian words, most significant word first.
///
/// See mdbtools src/libmdb/money.c, mdb_numeric_to_string.
String readNumeric(Uint8List buffer, {required int scale}) {
  if (buffer.length < 17) {
    throw MdbFormatException(
      'Numeric value needs 17 bytes, got ${buffer.length}',
    );
  }

  var product = toArray(0, _maxPrecision);
  var multiplier = toArray(1, _maxPrecision);

  final bytes = Uint8List.sublistView(buffer, 1, 17);
  for (var i = 0; i < bytes.length; ++i) {
    final byte = bytes[12 - 4 * (i ~/ 4) + (i % 4)];
    product = addArray(
      product,
      multiplyArray(multiplier, toArray(byte, _maxPrecision)),
    );
    multiplier = multiplyArray(multiplier, toArray(256, _maxPrecision));
  }

  final negative = buffer[0] & 0x80 != 0;
  return buildValue(product, scale, negative);
}
