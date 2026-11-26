// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/JetFormat/Jet3Format.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import '../sort_order.dart';
import 'types.dart';

const jet3Format = JetFormat(
  codecType: CodecType.jet,
  pageSize: 2048,
  textEncoding: TextEncoding.unknown,
  defaultSortOrder: general97SortOrder,
  databaseDefinitionPage: DatabaseDefinitionPageFormat(
    encryptedSize: 126,
    passwordSize: 20,
    creationDateOffset: null,
    defaultSortOrderOffset: 0x3a, // 58
    defaultSortOrderSize: 2,
  ),
  dataPage: DataPageFormat(
    recordCountOffset: 8,
    recordCountOffsetInRecord: 8,
    columnCountSize: 1,
    variableColumnCountSize: 1,
  ),
  tableDefinitionPage: TableDefinitionPageFormat(
    rowCountOffset: 12,
    columnCountOffset: 25,
    variableColumnCountOffset: 23,
    logicalIndexCountOffset: 27,
    realIndexCountOffset: 31,
    realIndexStartOffset: 43,
    realIndexEntrySize: 8,
    columnsDefinition: ColumnsDefinitionFormat(
      typeOffset: 0,
      indexOffset: 1,
      variableIndexOffset: 3,
      flagsOffset: 13,
      fixedIndexOffset: 14,
      sizeOffset: 16,
      entrySize: 18,
    ),
    nameLengthSize: 1,
    usageMapOffset: 35,
  ),
);
