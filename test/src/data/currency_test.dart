// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/currency.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import 'package:mdbdart/src/data/currency.dart';
import 'package:test/test.dart';

/// Little-endian two's-complement bytes of [value], computed with BigInt so
/// the test also runs where ByteData.setInt64 is unavailable (the web).
Uint8List int64LE(BigInt value) {
  var v = value.toUnsigned(64);
  final bytes = Uint8List(8);
  for (var i = 0; i < 8; i++) {
    bytes[i] = (v & BigInt.from(0xff)).toInt();
    v >>= 8;
  }
  return bytes;
}

void main() {
  group('readCurrency', () {
    final cases = [
      (BigInt.zero, '0.0000'),
      (BigInt.from(420000), '42.0000'),
      (BigInt.from(-420000), '-42.0000'),
      (BigInt.from(-1), '-0.0001'),
      (BigInt.from(-256), '-0.0256'),
      (-(BigInt.one << 63), '-922337203685477.5808'),
      ((BigInt.one << 63) - BigInt.one, '922337203685477.5807'),
    ];

    for (final (scaledValue, expected) in cases) {
      test('reads $expected repeatedly without changing the input', () {
        final buffer = int64LE(scaledValue);
        final snapshot = Uint8List.fromList(buffer);

        expect(readCurrency(buffer), expected);
        expect(buffer, snapshot);
        expect(readCurrency(buffer), expected);
        expect(buffer, snapshot);
      });
    }

    test('preserves the entire parent buffer when reading a subarray', () {
      final parent = Uint8List(24)..fillRange(0, 24, 0xa5);
      parent.setRange(5, 13, int64LE(BigInt.from(-420000)));
      final buffer = Uint8List.sublistView(parent, 5, 13);
      final snapshot = Uint8List.fromList(parent);

      expect(readCurrency(buffer), '-42.0000');
      expect(parent, snapshot);
      expect(readCurrency(buffer), '-42.0000');
      expect(parent, snapshot);
    });
  });
}
