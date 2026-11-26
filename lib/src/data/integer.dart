// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/integer.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../bytes.dart';

int readInteger(Uint8List buffer) => readInt16LE(buffer, 0);
