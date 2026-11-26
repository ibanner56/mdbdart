// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/long.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../bytes.dart';

int readLong(Uint8List buffer) => readInt32LE(buffer, 0);
