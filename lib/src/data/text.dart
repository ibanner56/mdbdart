// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/text.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../database.dart';
import '../unicode_compression.dart';

String readText(Uint8List buffer, Database database) {
  return uncompressText(buffer, database.format.textEncoding);
}
