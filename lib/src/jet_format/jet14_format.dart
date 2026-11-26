// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/JetFormat/Jet14Format.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import '../sort_order.dart';
import 'jet12_format.dart';
import 'types.dart';

final JetFormat jet14Format = jet12Format.copyWith(
  defaultSortOrder: generalSortOrder,
);
