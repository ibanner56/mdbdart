// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/complex/complexColumnsData.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import '../../database.dart';
import '../../errors.dart';
import '../../system_tables.dart';
import '../../table.dart';
import '../../util.dart';

const _msysComplexColumnsTable = 'MSysComplexColumns';

int _getMsysComplexColumnsPage(Database database) {
  final msysObjectsData = getMSysObjectsTable(
    database,
  ).getData(columns: ['Id', 'Name']);
  for (final row in msysObjectsData) {
    if (row['Name'] == _msysComplexColumnsTable) {
      final id = row['Id'];
      return maskTableId(id is int ? id : 0);
    }
  }
  throw MdbFormatException(
    'MSysComplexColumns table not found in MSysObjects table',
  );
}

/// Rows of MSysComplexColumns.
List<Map<String, Object?>> getComplexColumnsData(Database database) {
  final msysComplexColumnsPage = _getMsysComplexColumnsPage(database);
  final msysComplexColumns = Table(
    _msysComplexColumnsTable,
    database,
    msysComplexColumnsPage,
  );
  return msysComplexColumns.getData();
}
