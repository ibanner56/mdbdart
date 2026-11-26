// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/JetFormat/types.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import '../types.dart';

enum CodecType { jet, msisam, office }

enum TextEncoding { unknown, ucs2 }

class JetFormat {
  const JetFormat({
    required this.codecType,
    required this.pageSize,
    required this.textEncoding,
    required this.defaultSortOrder,
    required this.databaseDefinitionPage,
    required this.dataPage,
    required this.tableDefinitionPage,
  });

  final CodecType codecType;
  final int pageSize;
  final TextEncoding textEncoding;
  final SortOrder defaultSortOrder;
  final DatabaseDefinitionPageFormat databaseDefinitionPage;
  final DataPageFormat dataPage;
  final TableDefinitionPageFormat tableDefinitionPage;

  JetFormat copyWith({CodecType? codecType, SortOrder? defaultSortOrder}) {
    return JetFormat(
      codecType: codecType ?? this.codecType,
      pageSize: pageSize,
      textEncoding: textEncoding,
      defaultSortOrder: defaultSortOrder ?? this.defaultSortOrder,
      databaseDefinitionPage: databaseDefinitionPage,
      dataPage: dataPage,
      tableDefinitionPage: tableDefinitionPage,
    );
  }
}

class DatabaseDefinitionPageFormat {
  const DatabaseDefinitionPageFormat({
    required this.encryptedSize,
    required this.passwordSize,
    required this.creationDateOffset,
    required this.defaultSortOrderOffset,
    required this.defaultSortOrderSize,
  });

  final int encryptedSize;
  final int passwordSize;
  final int? creationDateOffset;
  final int defaultSortOrderOffset;
  final int defaultSortOrderSize;
}

class DataPageFormat {
  const DataPageFormat({
    required this.recordCountOffset,
    required this.recordCountOffsetInRecord,
    required this.columnCountSize,
    required this.variableColumnCountSize,
  });

  final int recordCountOffset;

  /// `dataPage.record.countOffset` upstream.
  final int recordCountOffsetInRecord;
  final int columnCountSize;

  /// 1 or 2.
  final int variableColumnCountSize;
}

class TableDefinitionPageFormat {
  const TableDefinitionPageFormat({
    required this.rowCountOffset,
    required this.columnCountOffset,
    required this.variableColumnCountOffset,
    required this.logicalIndexCountOffset,
    required this.realIndexCountOffset,
    required this.realIndexStartOffset,
    required this.realIndexEntrySize,
    required this.columnsDefinition,
    required this.nameLengthSize,
    required this.usageMapOffset,
  });

  final int rowCountOffset;
  final int columnCountOffset;
  final int variableColumnCountOffset;
  final int logicalIndexCountOffset;
  final int realIndexCountOffset;
  final int realIndexStartOffset;
  final int realIndexEntrySize;
  final ColumnsDefinitionFormat columnsDefinition;

  /// Number of bytes that store the length of the column name.
  final int nameLengthSize;
  final int usageMapOffset;
}

class ColumnsDefinitionFormat {
  const ColumnsDefinitionFormat({
    required this.typeOffset,
    required this.indexOffset,
    required this.variableIndexOffset,
    required this.flagsOffset,
    required this.fixedIndexOffset,
    required this.sizeOffset,
    required this.entrySize,
    this.complexTypeIdOffset,
  });

  final int typeOffset;
  final int indexOffset;
  final int variableIndexOffset;
  final int flagsOffset;
  final int fixedIndexOffset;
  final int sizeOffset;
  final int entrySize;

  /// Offset of the 4-byte complex type ID in the column definition. Null if
  /// not supported.
  final int? complexTypeIdOffset;
}
