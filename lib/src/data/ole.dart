// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/ole.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../bytes.dart';
import '../errors.dart';
import 'memo.dart';

const _typeThisPage = 0x80;
const _typeOtherPage = 0x40;
const _typeOtherPages = 0x00;

/// Reads an OLE (long binary) value. Returns a new list that does not share
/// memory with the database buffer.
///
/// See mdbtools src/libmdb/data.c, mdb_ole_read_full, and Jackcess
/// LongValueColumnImpl.
Uint8List readOLE(Uint8List buffer, LongValueSource database) {
  final length = readUintLE(buffer, 0, 3);
  final type = readUint8(buffer, 3);

  switch (type) {
    case _typeThisPage:
      // 0-2: Length
      // 3: Type
      // 4-7: lval_dp
      // 8-11: unknown
      // 12: data

      // inline
      return Uint8List.fromList(slice(buffer, 12, 12 + length));
    case _typeOtherPage:
      // single page
      final pageRow = readUint32LE(buffer, 4);
      final rowBuffer = database.findPageRow(pageRow);
      return Uint8List.fromList(slice(rowBuffer, 0, length));
    case _typeOtherPages:
      // multi page
      var pageRow = readUint32LE(buffer, 4);
      final visited = <int>{};

      // `length` is at most 2^24 - 1, so this allocation is bounded.
      final result = Uint8List(length);

      var offset = 0;
      while (offset < length) {
        if (!visited.add(pageRow)) {
          throw MdbFormatException(
            'Cyclic OLE long-value chain at page-row $pageRow',
          );
        }
        final rowBuffer = database.findPageRow(pageRow);
        if (rowBuffer.length <= 4) {
          throw MdbFormatException('Invalid OLE long-value row: no payload');
        }

        pageRow = readUint32LE(rowBuffer, 0);

        final newChunk = slice(rowBuffer, 4);
        // Like Node's Buffer.copy, copy only what fits.
        final copyLength = newChunk.length < length - offset
            ? newChunk.length
            : length - offset;
        result.setRange(offset, offset + copyLength, newChunk);
        offset += newChunk.length;
        if (pageRow == 0) {
          break;
        }
      }

      return result;
    default:
      throw MdbFormatException('Unknown OLE type $type');
  }
}
