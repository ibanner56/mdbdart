// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/util.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import 'package:mdbdart/src/util.dart';
import 'package:test/test.dart';

Uint8List b(List<int> bytes) => Uint8List.fromList(bytes);

void main() {
  test('getBitmapValue', () {
    final buffer = b([0xaa, 0x55]); // 10101010, 01010101

    expect(getBitmapValue(buffer, 0), isFalse);
    expect(getBitmapValue(buffer, 1), isTrue);
    expect(getBitmapValue(buffer, 7), isTrue);
    expect(getBitmapValue(buffer, 8), isTrue);
    expect(getBitmapValue(buffer, 9), isFalse);
    // Not upstream: out of range reads as 0.
    expect(getBitmapValue(buffer, 16), isFalse);
  });

  test('roundToFullByte', () {
    expect(roundToFullByte(0), 0);
    expect(roundToFullByte(1), 1);
    expect(roundToFullByte(2), 1);
    expect(roundToFullByte(3), 1);
    expect(roundToFullByte(8), 1);
    expect(roundToFullByte(9), 2);
  });

  test('xor', () {
    // https://github.com/crypto-browserify/buffer-xor/blob/master/test/fixtures.json
    expect(xor(b([0x00, 0x0f]), b([0xf0, 0xff])), b([0xf0, 0xf0]));
    expect(xor(b([0x00, 0x0f, 0x0f]), b([0xf0, 0xff])), b([0xf0, 0xf0, 0x0f]));
    expect(xor(b([0x00, 0x0f]), b([0xf0, 0xff, 0xff])), b([0xf0, 0xf0, 0xff]));
    expect(xor(b([0x00, 0x00, 0x00]), b([0x00, 0x00, 0x00])), b([0, 0, 0]));
  });

  test('isEmptyBuffer', () {
    expect(isEmptyBuffer(Uint8List(4)), isTrue);
    expect(isEmptyBuffer(Uint8List(0)), isTrue);
    expect(isEmptyBuffer(b([0, 0, 0, 0])), isTrue);
    expect(isEmptyBuffer(b([0, 0, 1, 0])), isFalse);
  });
}
