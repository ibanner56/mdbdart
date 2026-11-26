// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/SysObject.ts at 4e08263; see THIRD_PARTY_NOTICES.md

/// See mdbtools include/mdbtools.h, MDB_FORM etc.
abstract final class SysObjectTypes {
  static const form = 0x00;
  static const table = 0x01;
  static const macro = 0x02;
  static const systemTable = 0x03;
  static const report = 0x04;
  static const query = 0x05;
  static const linkedTable = 0x06;
  static const module = 0x07;
  static const relationship = 0x08;
  static const databaseProperty = 0x0b;

  static const values = {
    form,
    table,
    macro,
    systemTable,
    report,
    query,
    linkedTable,
    module,
    relationship,
    databaseProperty,
  };
}

bool isSysObjectType(int typeValue) =>
    SysObjectTypes.values.contains(typeValue);

class SysObject {
  SysObject({
    required this.objectName,
    required this.objectType,
    required this.tablePage,
    required this.flags,
  });

  final String objectName;

  /// null = unknown
  final int? objectType;
  final int tablePage;
  final int flags;
}

const _systemObjectFlag = 0x80000000;
const _altSystemObjectFlag = 0x02;
const _systemObjectFlags = _systemObjectFlag | _altSystemObjectFlag;

/// See Jackcess DatabaseImpl, SYSTEM_OBJECT_FLAGS.
bool isSystemObject(int flags) => (flags & _systemObjectFlags) != 0;
