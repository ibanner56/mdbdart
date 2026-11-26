// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/complex/attachment.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../../bytes.dart';
import '../../errors.dart';
import '../../inflate.dart';

const _rawType = 0;
const _compressedType = 1;

/// Largest decoded attachment mdbdart inflates, to bound memory on hostile
/// files. Not upstream.
const maxAttachmentSize = 256 * 1024 * 1024;

/// Decodes attachment FileData as stored in Access (OLE wrapper with optional
/// deflate).
Uint8List decodeAttachmentFileData(Uint8List buffer) {
  // 0-3: type flag; 0=raw, 1=compressed
  // 4-7: length
  // 8-end: content
  if (buffer.length < 8) {
    throw MdbFormatException('Unknown encoded attachment data format');
  }
  final typeFlag = readInt32LE(buffer, 0);
  final dataLen = readInt32LE(buffer, 4);
  var content = slice(buffer, 8);

  switch (typeFlag) {
    case _compressedType:
      // Upstream inflates everything and then keeps at most dataLen bytes,
      // so stopping at dataLen gives the same result.
      content = zlibInflate(
        content,
        maxOutput: dataLen < maxAttachmentSize ? dataLen : maxAttachmentSize,
      );
    case _rawType:
      // do nothing
      break;
    default:
      throw MdbFormatException(
        'Unknown encoded attachment data type $typeFlag',
      );
  }

  if (content.length < 4) {
    throw MdbFormatException('Invalid attachment content header');
  }
  final headerLen = readInt32LE(content, 0);
  if (headerLen < 4 || headerLen > content.length) {
    throw MdbFormatException('Invalid attachment header length');
  }
  final payloadEnd = dataLen < content.length ? dataLen : content.length;
  if (headerLen >= payloadEnd) {
    throw MdbFormatException('Invalid attachment header length');
  }
  return Uint8List.fromList(slice(content, headerLen, payloadEnd));
}
