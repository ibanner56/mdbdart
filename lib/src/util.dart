// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/util.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import 'bytes.dart';
import 'errors.dart';

/// Reads a specific bit of a bitmap. Returns true for 1 and false for 0.
///
/// [pos] is 0-based. Bits past the end of the bitmap read as 0.
bool getBitmapValue(Uint8List bitmap, int pos) {
  final byteNumber = pos ~/ 8;
  final bitNumber = pos % 8;
  if (byteNumber < 0 || byteNumber >= bitmap.length) {
    return false;
  }
  return (bitmap[byteNumber] & (1 << bitNumber)) != 0;
}

/// Returns the number of bytes required to store a specific number of bits.
int roundToFullByte(int bits) => (bits + 7) ~/ 8;

/// XORs two byte arrays. The result has the length of the longer one; missing
/// bytes of the shorter one count as 0.
Uint8List xor(Uint8List a, Uint8List b) {
  final length = a.length > b.length ? a.length : b.length;
  final result = Uint8List(length);
  for (var i = 0; i < length; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    result[i] = x ^ y;
  }
  return result;
}

/// Returns true if the buffer only contains zeros.
bool isEmptyBuffer(Uint8List buffer) => buffer.every((v) => v == 0);

/// Encodes [n] as a 4-byte little-endian signed integer.
Uint8List intToBuffer(int n) {
  if (n < -0x80000000 || n > 0x7fffffff) {
    throw MdbFormatException('Value $n does not fit in a 32-bit integer');
  }
  final buffer = Uint8List(4);
  ByteData.sublistView(buffer).setInt32(0, n, Endian.little);
  return buffer;
}

/// Truncates or pads [buffer] to [length] bytes.
Uint8List fixBufferLength(Uint8List buffer, int length, [int padByte = 0]) {
  if (buffer.length > length) {
    return slice(buffer, 0, length);
  }
  if (buffer.length < length) {
    final result = Uint8List(length)..fillRange(buffer.length, length, padByte);
    result.setRange(0, buffer.length, buffer);
    return result;
  }
  return buffer;
}

bool isInRange(int from, int to, int value) => from <= value && value <= to;

int maskTableId(int id) => id & 0x00ffffff;
