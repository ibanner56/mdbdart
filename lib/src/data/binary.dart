// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/binary.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

/// Returns a copy of [buffer].
Uint8List readBinary(Uint8List buffer) => Uint8List.fromList(buffer);
