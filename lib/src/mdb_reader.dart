// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/MDBReader.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import 'database.dart';
import 'errors.dart';
import 'page_type.dart';
import 'sys_object.dart';
import 'system_tables.dart';
import 'table.dart';
import 'types.dart';
import 'util.dart';

/// Reads a Microsoft Access database from its bytes.
///
/// Supports Jet 3 (Access 97), Jet 4 (Access 2000-2003) and ACE 12-17
/// (Access 2007-2019) files. Encrypted databases throw
/// [MdbEncryptedException].
///
/// The reader never modifies [bytes]. It keeps a reference to them and reads
/// pages on demand, so do not modify them while the reader is in use.
class MdbReader {
  /// Opens the database in [bytes].
  ///
  /// Throws an [MdbException] if the file is malformed, encrypted or of an
  /// unsupported version.
  MdbReader(Uint8List bytes) {
    assertPageType(bytes, PageType.databaseDefinitionPage);

    _database = Database(bytes);

    final mSysObjectsTable = getMSysObjectsTable(
      _database,
    ).getData(columns: ['Id', 'Name', 'Type', 'Flags']);

    _sysObjects = [];
    for (final mSysObject in mSysObjectsTable) {
      final name = mSysObject['Name'];
      if (name is! String) {
        // Not upstream: upstream would list a null name. Objects without a
        // name cannot be looked up, so skip them.
        continue;
      }
      final objectType = _int(mSysObject['Type']) & 0x7f;
      _sysObjects.add(
        SysObject(
          objectName: name,
          objectType: isSysObjectType(objectType) ? objectType : null,
          tablePage: maskTableId(_int(mSysObject['Id'])),
          flags: _int(mSysObject['Flags']),
        ),
      );
    }
  }

  late final Database _database;
  late final List<SysObject> _sysObjects;

  /// Date when the database was created, in UTC. Null for Jet 3 databases,
  /// which do not store it.
  DateTime? getCreationDate() => _database.getCreationDate();

  /// Database password, or null if there is none.
  String? getPassword() => _database.getPassword();

  /// Default sort order.
  SortOrder getDefaultSortOrder() => _database.getDefaultSortOrder();

  /// Returns the table names.
  ///
  /// [normalTables] includes user tables, [systemTables] includes system
  /// tables and [linkedTables] includes linked tables.
  List<String> getTableNames({
    bool normalTables = true,
    bool systemTables = false,
    bool linkedTables = false,
  }) {
    final filteredSysObjects = <SysObject>[];
    for (final sysObject in _sysObjects) {
      if (sysObject.objectType == SysObjectTypes.table) {
        if (!isSystemObject(sysObject.flags)) {
          if (normalTables) {
            filteredSysObjects.add(sysObject);
          }
        } else if (systemTables) {
          filteredSysObjects.add(sysObject);
        }
      } else if (sysObject.objectType == SysObjectTypes.linkedTable &&
          linkedTables) {
        filteredSysObjects.add(sysObject);
      }
    }

    return [for (final o in filteredSysObjects) o.objectName];
  }

  /// Returns a table by its name.
  ///
  /// [name] is case sensitive. Throws [MdbNotFoundException] if there is no
  /// such table.
  Table getTable(String name) {
    for (final o in _sysObjects) {
      if (o.objectType == SysObjectTypes.table && o.objectName == name) {
        return Table(name, _database, o.tablePage);
      }
    }
    throw MdbNotFoundException('Could not find table with name $name');
  }
}

/// Upstream applies bitwise operators to these values, which turns null into
/// 0.
int _int(Object? value) {
  if (value == null) {
    return 0;
  }
  if (value is int) {
    return value;
  }
  throw MdbFormatException('Unexpected value $value in MSysObjects');
}
