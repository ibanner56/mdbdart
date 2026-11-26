// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/memo.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../bytes.dart';
import '../database.dart';
import '../errors.dart';
import '../jet_format/jet_format.dart';
import '../unicode_compression.dart';

const _typeThisPage = 0x80;
const _typeOtherPage = 0x40;
const _typeOtherPages = 0x00;

/// Abstraction over [Database] used by long-value reads, so that tests can
/// supply rows directly (upstream's tests stub the database object).
abstract interface class LongValueSource {
  Uint8List findPageRow(int pageRow);
}

/// See mdbtools src/libmdb/data.c, mdb_memo_to_string.
String readMemo(
  Uint8List buffer,
  LongValueSource database,
  TextEncoding textEncoding,
) {
  final memoLength = readUintLE(buffer, 0, 3);

  final type = readUint8(buffer, 3);
  switch (type) {
    case _typeThisPage:
      final compressedText = slice(buffer, 12, 12 + memoLength);
      return uncompressText(compressedText, textEncoding);

    case _typeOtherPage:
      final pageRow = readUint32LE(buffer, 4);
      final rowBuffer = database.findPageRow(pageRow);
      final compressedText = slice(rowBuffer, 0, memoLength);
      return uncompressText(compressedText, textEncoding);

    case _typeOtherPages:
      var pageRow = readUint32LE(buffer, 4);
      final visited = <int>{};
      final parts = <Uint8List>[];
      var memoDataLength = 0;
      while (memoDataLength < memoLength) {
        if (!visited.add(pageRow)) {
          throw MdbFormatException(
            'Cyclic Memo long-value chain at page-row $pageRow',
          );
        }
        final rowBuffer = database.findPageRow(pageRow);

        if (rowBuffer.length <= 4) {
          throw MdbFormatException('Invalid Memo long-value row: no payload');
        }

        if (memoDataLength + rowBuffer.length - 4 > memoLength) {
          break;
        }

        parts.add(slice(rowBuffer, 4));
        memoDataLength += rowBuffer.length - 4;

        pageRow = readUint32LE(rowBuffer, 0);
        if (pageRow == 0) {
          break;
        }
      }

      final memoDataBuffer = concatBytes(parts);
      final compressedText = slice(memoDataBuffer, 0, memoLength);
      return uncompressText(compressedText, textEncoding);

    default:
      throw MdbFormatException('Unknown memo type $type');
  }
}
