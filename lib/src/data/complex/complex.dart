// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/complex/index.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../../bytes.dart';
import '../../column.dart';
import '../../database.dart';
import '../../errors.dart';
import '../../table.dart';
import '../../types.dart';
import 'attachment.dart';
import 'utils.dart';

/// Known attachment type column names; the FK column is the Long that is not
/// one of these.
const _attachmentTypeColumnNames = {
  'FileName',
  'FileType',
  'FileData',
  'FileURL',
  'FileTimeStamp',
  'FileFlags',
};

/// Reads a complex (attachment) column: resolves the complex value FK to the
/// flat table, collects matching rows, and decodes each attachment's
/// FileData.
List<Attachment> readComplex(
  Uint8List buffer,
  ColumnDefinition column,
  Database database,
) {
  // Not upstream: an attachment table never has complex columns itself, so a
  // nested read means a hostile file whose tables refer to each other. Stop
  // before the recursion overflows the stack.
  if (database.complexReadDepth > 0) {
    throw MdbFormatException(
      'Failed to read complex column',
      cause: MdbFormatException('Nested complex column in ${column.name}'),
    );
  }
  database.complexReadDepth++;
  try {
    final complex = column.complex;
    if (complex == null) {
      throw MdbFormatException('Complex column is not valid');
    }

    final foreignKey = readInt32LE(buffer, 0);
    if (foreignKey <= 0) {
      throw MdbFormatException('Foreign key value is not valid');
    }

    final (tableName: flatTableName, firstPage: flatTableFirstPage) =
        resolveFlatTableForComplexColumn(database, column, complex);
    final flatTable = Table(flatTableName, database, flatTableFirstPage);
    String? foreignKeyColumnName;
    for (final c in flatTable.getColumns()) {
      if (c.type == ColumnType.long &&
          !c.autoLong &&
          !_attachmentTypeColumnNames.contains(c.name)) {
        foreignKeyColumnName = c.name;
        break;
      }
    }
    if (foreignKeyColumnName == null) {
      throw MdbFormatException('Foreign key column not found');
    }

    final flatData = flatTable.getData();
    final matchingRows = flatData.where(
      (row) => row[foreignKeyColumnName] == foreignKey,
    );

    return [
      for (final row in matchingRows)
        Attachment(
          name: _string(row['FileName'], 'FileName'),
          type: _string(row['FileType'], 'FileType'),
          data: decodeAttachmentFileData(_bytes(row['FileData'])),
          // Upstream only sets truthy values.
          url: switch (row['FileURL']) {
            final String url when url.isNotEmpty => url,
            _ => null,
          },
          timestamp: switch (row['FileTimeStamp']) {
            final DateTime timestamp => timestamp,
            _ => null,
          },
          flags: switch (row['FileFlags']) {
            final int flags when flags != 0 => flags,
            _ => null,
          },
        ),
    ];
  } on MdbException catch (error) {
    throw MdbFormatException('Failed to read complex column', cause: error);
  } finally {
    database.complexReadDepth--;
  }
}

String _string(Object? value, String column) {
  if (value is String) {
    return value;
  }
  throw MdbFormatException('Attachment column $column is not text');
}

Uint8List _bytes(Object? value) {
  if (value is Uint8List) {
    return value;
  }
  throw MdbFormatException('Attachment column FileData is not binary');
}
