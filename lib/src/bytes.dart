// Bounds-checked little-endian reads over Uint8List. Not ported: this replaces
// the Node.js Buffer API that mdb-reader relies on.
//
// Every read checks its offset and length against the buffer and throws
// MdbFormatException instead of a RangeError, because offsets come from
// untrusted files.

import 'dart:typed_data';

import 'errors.dart';

void _check(Uint8List bytes, int offset, int length) {
  if (offset < 0 || length < 0 || offset > bytes.length - length) {
    throw MdbFormatException(
      'Read of $length bytes at offset $offset is out of bounds '
      '(buffer length ${bytes.length})',
    );
  }
}

/// Returns a view of `bytes[start, end)`, like Node's `Buffer.slice`:
/// indices are clamped to `[0, bytes.length]` and an end before the start
/// gives an empty view. Unlike Node, negative indices clamp to 0 instead of
/// counting from the end.
Uint8List slice(Uint8List bytes, int start, [int? end]) {
  final length = bytes.length;
  var s = start < 0 ? 0 : (start > length ? length : start);
  var e = end ?? length;
  e = e < 0 ? 0 : (e > length ? length : e);
  if (e < s) {
    e = s;
  }
  return Uint8List.sublistView(bytes, s, e);
}

int readUint8(Uint8List bytes, int offset) {
  _check(bytes, offset, 1);
  return bytes[offset];
}

int readUint16LE(Uint8List bytes, int offset) {
  _check(bytes, offset, 2);
  return bytes[offset] | (bytes[offset + 1] << 8);
}

int readInt16LE(Uint8List bytes, int offset) {
  final value = readUint16LE(bytes, offset);
  return value >= 0x8000 ? value - 0x10000 : value;
}

int readUint32LE(Uint8List bytes, int offset) {
  _check(bytes, offset, 4);
  // Multiplication instead of `<< 24` keeps the result positive on the web,
  // where bitwise operators produce 32-bit values.
  return bytes[offset] +
      bytes[offset + 1] * 0x100 +
      bytes[offset + 2] * 0x10000 +
      bytes[offset + 3] * 0x1000000;
}

int readInt32LE(Uint8List bytes, int offset) {
  final value = readUint32LE(bytes, offset);
  return value >= 0x80000000 ? value - 0x100000000 : value;
}

/// Reads an unsigned little-endian integer of [byteLength] bytes (1 to 6).
int readUintLE(Uint8List bytes, int offset, int byteLength) {
  if (byteLength < 1 || byteLength > 6) {
    throw MdbFormatException('Unsupported integer width $byteLength');
  }
  _check(bytes, offset, byteLength);
  var value = 0;
  var multiplier = 1;
  for (var i = 0; i < byteLength; i++) {
    value += bytes[offset + i] * multiplier;
    multiplier *= 0x100;
  }
  return value;
}

double readFloat32LE(Uint8List bytes, int offset) {
  _check(bytes, offset, 4);
  return ByteData.sublistView(
    bytes,
    offset,
    offset + 4,
  ).getFloat32(0, Endian.little);
}

double readFloat64LE(Uint8List bytes, int offset) {
  _check(bytes, offset, 8);
  return ByteData.sublistView(
    bytes,
    offset,
    offset + 8,
  ).getFloat64(0, Endian.little);
}

/// Concatenates byte arrays into a new list.
Uint8List concatBytes(List<Uint8List> parts) {
  var total = 0;
  for (final part in parts) {
    total += part.length;
  }
  final result = Uint8List(total);
  var offset = 0;
  for (final part in parts) {
    result.setRange(offset, offset + part.length, part);
    offset += part.length;
  }
  return result;
}
