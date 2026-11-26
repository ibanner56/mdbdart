// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/unicodeCompression.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import 'dependencies/windows1252.dart';
import 'jet_format/jet_format.dart';

/// Decodes little-endian UTF-16 code units. A trailing odd byte is ignored,
/// as Node's `Buffer.toString("ucs-2")` does.
String decodeUcs2(Uint8List buffer) {
  final length = buffer.length ~/ 2;
  final codeUnits = Uint16List(length);
  for (var i = 0; i < length; i++) {
    codeUnits[i] = buffer[i * 2] | (buffer[i * 2 + 1] << 8);
  }
  return String.fromCharCodes(codeUnits);
}

/// See mdbtools HACKING, "Text data type" (unicode compression).
String uncompressText(Uint8List buffer, TextEncoding textEncoding) {
  if (textEncoding == TextEncoding.unknown) {
    // Assume charset is windows 1252 / CP1252 (windows default)
    // In some cases this might not work
    return decodeWindows1252(buffer);
  }

  if (buffer.length <= 2 || buffer[0] != 0xff || buffer[1] != 0xfe) {
    return decodeUcs2(buffer);
  }

  var compressedMode = true;
  var curPos = 2;

  // maximum possible length
  final uncompressedBuffer = Uint8List((buffer.length - curPos) * 2);
  var uncompressedBufferPos = 0;
  while (curPos < buffer.length) {
    if (buffer[curPos] == 0) {
      compressedMode = !compressedMode;
      curPos++;
    } else if (compressedMode) {
      uncompressedBuffer[uncompressedBufferPos++] = buffer[curPos++];
      uncompressedBuffer[uncompressedBufferPos++] = 0;
    } else if (buffer.length - curPos >= 2) {
      uncompressedBuffer[uncompressedBufferPos++] = buffer[curPos++];
      uncompressedBuffer[uncompressedBufferPos++] = buffer[curPos++];
    } else {
      break;
    }
  }

  return decodeUcs2(
    Uint8List.sublistView(uncompressedBuffer, 0, uncompressedBufferPos),
  );
}
