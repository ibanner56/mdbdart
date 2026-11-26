// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/SortOrder.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'types.dart';

const _generalSortOrderValue = 1033;

const general97SortOrder = SortOrder(
  value: _generalSortOrderValue,
  version: -1,
);
const generalLegacySortOrder = SortOrder(
  value: _generalSortOrderValue,
  version: 0,
);
const generalSortOrder = SortOrder(value: _generalSortOrderValue, version: 1);
