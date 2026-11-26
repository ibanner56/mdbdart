// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/systemTables.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'database.dart';
import 'table.dart';

Table getMSysObjectsTable(Database database) {
  return Table('MSysObjects', database, 2);
}
