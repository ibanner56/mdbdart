// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/float.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../bytes.dart';

double readFloat(Uint8List buffer) => readFloat32LE(buffer, 0);
