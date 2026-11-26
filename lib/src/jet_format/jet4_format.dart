// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/JetFormat/Jet4Format.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import '../sort_order.dart';
import 'types.dart';

const jet4Format = JetFormat(
  codecType: CodecType.jet,
  pageSize: 4096,
  textEncoding: TextEncoding.ucs2,
  defaultSortOrder: generalLegacySortOrder,
  databaseDefinitionPage: DatabaseDefinitionPageFormat(
    encryptedSize: 128,
    passwordSize: 40,
    creationDateOffset: 0x72, // 114
    defaultSortOrderOffset: 0x6e, // 110
    defaultSortOrderSize: 4,
  ),
  dataPage: DataPageFormat(
    recordCountOffset: 12,
    recordCountOffsetInRecord: 12,
    columnCountSize: 2,
    variableColumnCountSize: 2,
  ),
  tableDefinitionPage: TableDefinitionPageFormat(
    rowCountOffset: 16,
    variableColumnCountOffset: 43,
    columnCountOffset: 45,
    logicalIndexCountOffset: 47,
    realIndexCountOffset: 51,
    realIndexStartOffset: 63,
    realIndexEntrySize: 12,
    columnsDefinition: ColumnsDefinitionFormat(
      typeOffset: 0,
      indexOffset: 5,
      variableIndexOffset: 7,
      flagsOffset: 15,
      fixedIndexOffset: 21,
      sizeOffset: 23,
      entrySize: 25,
      complexTypeIdOffset: 9,
    ),
    nameLengthSize: 2,
    usageMapOffset: 55,
  ),
);
