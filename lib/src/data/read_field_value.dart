// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/index.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../column.dart';
import '../database.dart';
import '../errors.dart';
import '../types.dart';
import 'bigint.dart';
import 'binary.dart';
import 'byte.dart';
import 'complex/complex.dart';
import 'currency.dart';
import 'datetime.dart';
import 'datetimextended.dart';
import 'double.dart';
import 'float.dart';
import 'integer.dart';
import 'long.dart';
import 'memo.dart';
import 'numeric.dart';
import 'ole.dart';
import 'repid.dart';
import 'text.dart';

Object? readFieldValue(
  Uint8List buffer,
  ColumnDefinition column,
  Database database,
) {
  switch (column.type) {
    case ColumnType.boolean:
      throw MdbFormatException('readFieldValue does not handle type boolean');
    case ColumnType.bigInt:
      return readBigInt(buffer);
    case ColumnType.binary:
      return readBinary(buffer);
    case ColumnType.byte:
      return readByte(buffer);
    case ColumnType.complex:
      return readComplex(buffer, column, database);
    case ColumnType.currency:
      return readCurrency(buffer);
    case ColumnType.dateTime:
      return readDateTime(buffer);
    case ColumnType.dateTimeExtended:
      return readDateTimeExtended(buffer);
    case ColumnType.double:
      return readDouble(buffer);
    case ColumnType.float:
      return readFloat(buffer);
    case ColumnType.integer:
      return readInteger(buffer);
    case ColumnType.long:
      return readLong(buffer);
    case ColumnType.text:
      return readText(buffer, database);
    case ColumnType.memo:
      return readMemo(buffer, database, database.format.textEncoding);
    case ColumnType.numeric:
      // Scale is always set for numeric columns
      return readNumeric(buffer, scale: column.scale ?? 0);
    case ColumnType.ole:
      return readOLE(buffer, database);
    case ColumnType.repId:
      return readRepID(buffer);
  }
}
