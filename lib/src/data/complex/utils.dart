// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/complex/utils.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import '../../column.dart';
import '../../database.dart';
import '../../errors.dart';
import '../../system_tables.dart';
import '../../util.dart';
import 'complex_columns_data.dart';

typedef ResolvedFlatTable = ({String tableName, int firstPage});

/// Resolves (complexTypeId, tableDefinitionPage) to the flat table that
/// stores attachment rows for that complex column.
/// Throws if the system table is missing or no matching row is found.
ResolvedFlatTable resolveFlatTableForComplexColumn(
  Database database,
  ColumnDefinition column,
  ComplexColumnInfo complex,
) {
  final msysObjectsData = getMSysObjectsTable(
    database,
  ).getData(columns: ['Id', 'Name']);
  final complexColsData = getComplexColumnsData(database);
  final tableDefPageMasked = maskTableId(complex.tableDefinitionPage);

  for (final row in complexColsData) {
    final rowFlatTableId = row['FlatTableID'];
    // Upstream skips falsy values: null and 0.
    if (rowFlatTableId is! int || rowFlatTableId == 0) {
      continue;
    }

    final rowConceptualTableId = row['ConceptualTableID'];
    final tableMatch =
        rowConceptualTableId is int &&
        rowConceptualTableId == tableDefPageMasked;
    if (!tableMatch) {
      continue;
    }

    final complexTypeObjectId = row['ComplexTypeObjectID'];
    final complexId = row['ComplexID'];
    final columnName = row['ColumnName'];
    final complexTypeIdMatch =
        complexTypeObjectId is int && complexTypeObjectId == complex.typeId;
    final complexIdMatch = complexId is int && complexId == complex.typeId;
    final columnNameMatch =
        columnName is String &&
        columnName.toLowerCase() == column.name.toLowerCase();

    if (!complexTypeIdMatch && !complexIdMatch && !columnNameMatch) {
      continue;
    }

    final flatTableId = maskTableId(rowFlatTableId);
    for (final r in msysObjectsData) {
      final id = r['Id'];
      final name = r['Name'];
      if (id is int && maskTableId(id) == flatTableId) {
        if (name is! String) {
          break;
        }
        return (tableName: name, firstPage: flatTableId);
      }
    }
    throw MdbFormatException(
      'Flat table not found for complex column ${column.name}',
    );
  }

  throw MdbFormatException(
    'Flat table not found for complex column ${column.name}',
  );
}
