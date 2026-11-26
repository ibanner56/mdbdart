// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/JetFormat/MSISAMFormat.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'jet4_format.dart';
import 'types.dart';

final JetFormat msisamFormat = jet4Format.copyWith(codecType: CodecType.msisam);
