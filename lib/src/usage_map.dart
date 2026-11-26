// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/usage-map.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import 'bytes.dart';
import 'database.dart';
import 'errors.dart';
import 'page_type.dart';
import 'util.dart';

/// See mdbtools HACKING, "Page Usage Maps".
List<int> findMapPages(Uint8List buffer, Database database) {
  switch (buffer.isEmpty ? null : buffer[0]) {
    case 0x00:
      return _findMapPages0(buffer, database);
    case 0x01:
      return _findMapPages1(buffer, database);
    default:
      throw MdbFormatException('Unknown usage map type');
  }
}

/// See mdbtools src/libmdb/map.c, mdb_map_find_next0.
List<int> _findMapPages0(Uint8List buffer, Database database) {
  final pageStart = readUint32LE(buffer, 1);
  final bitmap = slice(buffer, 5);
  final pages = <int>[];
  _addPagesFromBitmap(pages, bitmap, pageStart, database.pageCount);
  return pages;
}

/// See mdbtools src/libmdb/map.c, mdb_map_find_next1.
List<int> _findMapPages1(Uint8List buffer, Database database) {
  final bitmapLength = (database.format.pageSize - 4) * 8;
  final mapCount = (buffer.length - 1) ~/ 4;

  final pages = <int>[];
  for (var mapIndex = 0; mapIndex < mapCount; ++mapIndex) {
    final page = readUint32LE(buffer, 1 + mapIndex * 4);
    if (page == 0) {
      continue;
    }

    final pageBuffer = database.getPage(page);
    assertPageType(pageBuffer, PageType.pageUsageBitmaps);

    final bitmap = slice(pageBuffer, 4);
    _addPagesFromBitmap(
      pages,
      bitmap,
      mapIndex * bitmapLength,
      database.pageCount,
    );
  }

  return pages;
}

/// Upstream's getPagesFromBitmap, which returns every set bit.
///
/// Not upstream: to bound memory on hostile files, scanning stops after the
/// first page at or beyond [pageCount]. That page is still added, so reading
/// data fails at the same point as upstream (every later bit in this bitmap
/// is a page that does not exist either).
void _addPagesFromBitmap(
  List<int> pages,
  Uint8List bitmap,
  int pageStart,
  int pageCount,
) {
  for (var i = 0; i < bitmap.length * 8; i++) {
    if (getBitmapValue(bitmap, i)) {
      final page = pageStart + i;
      pages.add(page);
      if (page >= pageCount) {
        return;
      }
    }
  }
}
