// Test helpers for mdbdart. Not ported.

import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

/// Reads a fixture from test/data. Returns a fresh copy each call.
Uint8List readFixture(String path) {
  return File('test/data/$path').readAsBytesSync();
}

/// Matches a function that throws an exception of type [T] whose message
/// contains [message], if given.
Matcher throwsMdb<T>([String? message]) {
  var matcher = isA<T>();
  if (message != null) {
    matcher = matcher.having(
      (e) => e.toString(),
      'toString()',
      contains(message),
    );
  }
  return throwsA(matcher);
}

void writeUint32LE(Uint8List bytes, int offset, int value) {
  ByteData.sublistView(bytes).setUint32(offset, value, Endian.little);
}

void writeUint16LE(Uint8List bytes, int offset, int value) {
  ByteData.sublistView(bytes).setUint16(offset, value, Endian.little);
}

int readUint16(Uint8List bytes, int offset) {
  return ByteData.sublistView(bytes).getUint16(offset, Endian.little);
}
