// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/byte.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../bytes.dart';

int readByte(Uint8List buffer) => readUint8(buffer, 0);
