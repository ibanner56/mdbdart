// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/PageType.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import 'errors.dart';

/// See mdbtools HACKING, "Pages".
abstract final class PageType {
  static const databaseDefinitionPage = 0x00;
  static const dataPage = 0x01;
  static const tableDefinition = 0x02;
  static const intermediateIndexPage = 0x03;
  static const leafIndexPages = 0x04;
  static const pageUsageBitmaps = 0x05;
}

void assertPageType(Uint8List buffer, int pageType) {
  final actual = buffer.isEmpty ? null : buffer[0];
  if (actual != pageType) {
    throw MdbFormatException(
      'Wrong page type. Expected $pageType but received $actual.',
    );
  }
}
