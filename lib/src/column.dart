// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/column.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'errors.dart';
import 'types.dart';

/// The definition of a column of a table.
class Column {
  Column({
    required this.name,
    required this.type,
    required this.size,
    required this.fixedLength,
    required this.nullable,
    required this.autoLong,
    required this.autoUUID,
    this.precision,
    this.scale,
  });

  /// Name of the column.
  final String name;

  /// Type of the column.
  final ColumnType type;
  final int size;

  final bool fixedLength;
  final bool nullable;
  final bool autoLong;
  final bool autoUUID;

  /// Only set if [type] is [ColumnType.numeric].
  final int? precision;

  /// Only set if [type] is [ColumnType.numeric].
  final int? scale;

  @override
  String toString() => 'Column($name, ${type.value})';
}

/// Includes internal fields that are not relevant for the user of the
/// library.
class ColumnDefinition extends Column {
  ColumnDefinition({
    required super.name,
    required super.type,
    required super.size,
    required super.fixedLength,
    required super.nullable,
    required super.autoLong,
    required super.autoUUID,
    super.precision,
    super.scale,
    required this.index,
    required this.variableIndex,
    required this.fixedIndex,
    this.complex,
  });

  final int index;
  final int variableIndex;
  final int fixedIndex;

  final ComplexColumnInfo? complex;

  /// Returns the public part of this definition.
  Column toColumn() => Column(
    name: name,
    type: type,
    size: size,
    fixedLength: fixedLength,
    nullable: nullable,
    autoLong: autoLong,
    autoUUID: autoUUID,
    precision: precision,
    scale: scale,
  );
}

class ComplexColumnInfo {
  ComplexColumnInfo({required this.typeId, required this.tableDefinitionPage});

  final int typeId;
  final int tableDefinitionPage;
}

const _columnTypeMap = <int, ColumnType>{
  0x01: ColumnType.boolean,
  0x02: ColumnType.byte,
  0x03: ColumnType.integer,
  0x04: ColumnType.long,
  0x05: ColumnType.currency,
  0x06: ColumnType.float,
  0x07: ColumnType.double,
  0x08: ColumnType.dateTime,
  0x09: ColumnType.binary,
  0x0a: ColumnType.text,
  0x0b: ColumnType.ole,
  0x0c: ColumnType.memo,
  0x0f: ColumnType.repId,
  0x10: ColumnType.numeric,
  0x12: ColumnType.complex,
  0x13: ColumnType.bigInt,
  0x14: ColumnType.dateTimeExtended,
};

/// See mdbtools include/mdbtools.h and HACKING, "Column types".
ColumnType getColumnType(int typeValue) {
  final type = _columnTypeMap[typeValue];

  if (type == null) {
    throw MdbUnsupportedException('Unsupported column type $typeValue');
  }

  return type;
}

/// See mdbtools HACKING, "Column flags".
({bool fixedLength, bool nullable, bool autoLong, bool autoUUID})
parseColumnFlags(int flags) {
  return (
    fixedLength: (flags & 0x01) != 0,
    nullable: (flags & 0x02) != 0,
    autoLong: (flags & 0x04) != 0,
    autoUUID: (flags & 0x40) != 0,
  );
}
