// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/double.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../bytes.dart';

double readDouble(Uint8List buffer) => readFloat64LE(buffer, 0);
