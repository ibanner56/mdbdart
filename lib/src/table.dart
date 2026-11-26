// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/Table.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import 'bytes.dart';
import 'column.dart';
import 'data/read_field_value.dart';
import 'database.dart';
import 'errors.dart';
import 'page_type.dart';
import 'types.dart';
import 'unicode_compression.dart';
import 'usage_map.dart';
import 'util.dart';

/// A table of a database.
class Table {
  /// [name]: table name. As this is stored in MSysObjects, it has to be
  /// passed in.
  ///
  /// [firstDefinitionPage]: the first page of the table definition referenced
  /// in the corresponding MSysObject.
  Table(this.name, this._database, this._firstDefinitionPage) {
    final tableFormat = _database.format.tableDefinitionPage;

    // Concat all table definition pages
    var nextDefinitionPage = _firstDefinitionPage;
    final parts = <Uint8List>[];
    final visitedDefinitionPages = <int>{};
    while (nextDefinitionPage > 0) {
      if (!visitedDefinitionPages.add(nextDefinitionPage)) {
        throw MdbFormatException(
          'Cyclic table definition for table "$name": '
          'repeated page $nextDefinitionPage',
        );
      }
      final curBuffer = _database.getPage(nextDefinitionPage);
      assertPageType(curBuffer, PageType.tableDefinition);

      parts.add(parts.isEmpty ? curBuffer : slice(curBuffer, 8));

      nextDefinitionPage = readUint32LE(curBuffer, 4);
    }
    if (parts.isEmpty) {
      throw MdbFormatException('Could not find table definition page');
    }
    _definitionBuffer = parts.length == 1 ? parts.single : concatBytes(parts);

    // Read row, column, and index counts
    rowCount = readUint32LE(_definitionBuffer, tableFormat.rowCountOffset);

    columnCount = readUint16LE(
      _definitionBuffer,
      tableFormat.columnCountOffset,
    );
    _variableColumnCount = readUint16LE(
      _definitionBuffer,
      tableFormat.variableColumnCountOffset,
    );

    _realIndexCount = readInt32LE(
      _definitionBuffer,
      tableFormat.realIndexCountOffset,
    );

    // Usage Map
    final usageMapBuffer = _database.findPageRow(
      readUint32LE(_definitionBuffer, tableFormat.usageMapOffset),
    );
    _dataPages = findMapPages(usageMapBuffer, _database);
  }

  /// Name of the table.
  final String name;
  final Database _database;
  final int _firstDefinitionPage;

  late final Uint8List _definitionBuffer;
  late final List<int> _dataPages;

  /// Number of rows.
  late final int rowCount;

  /// Number of columns.
  late final int columnCount;

  late final int _variableColumnCount;
  late final int _realIndexCount;

  /// Returns a column definition by its name.
  ///
  /// [name] is case sensitive.
  Column getColumn(String name) {
    for (final column in getColumns()) {
      if (column.name == name) {
        return column;
      }
    }
    throw MdbNotFoundException('Could not find column with name $name');
  }

  /// Returns an ordered list of all column definitions.
  List<Column> getColumns() {
    final columnDefinitions = _sortedByIndex(_getColumnDefinitions());
    return [for (final c in columnDefinitions) c.toColumn()];
  }

  List<ColumnDefinition> _getColumnDefinitions() {
    final format = _database.format;
    final tableFormat = format.tableDefinitionPage;
    final def = tableFormat.columnsDefinition;
    final columns = <ColumnDefinition>[];

    var curDefinitionPos =
        tableFormat.realIndexStartOffset +
        _realIndexCount * tableFormat.realIndexEntrySize;

    var namesCursorPos = curDefinitionPos + columnCount * def.entrySize;

    for (var i = 0; i < columnCount; ++i) {
      final columnBuffer = slice(
        _definitionBuffer,
        curDefinitionPos,
        curDefinitionPos + def.entrySize,
      );

      final type = getColumnType(
        readUint8(_definitionBuffer, curDefinitionPos + def.typeOffset),
      );

      final nameLength = readUintLE(
        _definitionBuffer,
        namesCursorPos,
        tableFormat.nameLengthSize,
      );
      namesCursorPos += tableFormat.nameLengthSize;
      final columnName = uncompressText(
        slice(_definitionBuffer, namesCursorPos, namesCursorPos + nameLength),
        format.textEncoding,
      );
      namesCursorPos += nameLength;

      final flags = parseColumnFlags(readUint8(columnBuffer, def.flagsOffset));

      int? precision;
      int? scale;
      if (type == ColumnType.numeric) {
        precision = readUint8(columnBuffer, 11);
        scale = readUint8(columnBuffer, 12);
      }

      ComplexColumnInfo? complex;
      if (type == ColumnType.complex) {
        final complexTypeIdOffset = def.complexTypeIdOffset;
        if (complexTypeIdOffset != null) {
          complex = ComplexColumnInfo(
            typeId: readInt32LE(columnBuffer, complexTypeIdOffset),
            tableDefinitionPage: _firstDefinitionPage,
          );
        } else {
          throw MdbUnsupportedException('Complex columns are not supported');
        }
      }

      columns.add(
        ColumnDefinition(
          name: columnName,
          type: type,
          index: readUint8(columnBuffer, def.indexOffset),
          variableIndex: readUint8(columnBuffer, def.variableIndexOffset),
          size: type == ColumnType.boolean
              ? 0
              : readUint16LE(columnBuffer, def.sizeOffset),
          fixedIndex: readUint16LE(columnBuffer, def.fixedIndexOffset),
          fixedLength: flags.fixedLength,
          nullable: flags.nullable,
          autoLong: flags.autoLong,
          autoUUID: flags.autoUUID,
          precision: precision,
          scale: scale,
          complex: complex,
        ),
      );

      curDefinitionPos += def.entrySize;
    }

    return columns;
  }

  /// Returns an ordered list of all column names.
  List<String> getColumnNames() {
    return [for (final column in getColumns()) column.name];
  }

  /// Returns data from the table, one map per row keyed by column name.
  ///
  /// [columns]: columns to be returned. Defaults to all columns.
  ///
  /// [rowOffset]: index of the first row to be returned. 0-based.
  ///
  /// [rowLimit]: maximum number of rows to be returned. Defaults to no limit.
  List<Map<String, Object?>> getData({
    List<String>? columns,
    int rowOffset = 0,
    int? rowLimit,
  }) {
    // Not upstream: upstream treats negative values like JavaScript's
    // Array.slice, which counts from the end of each page.
    if (rowOffset < 0) {
      throw ArgumentError.value(rowOffset, 'rowOffset', 'must not be negative');
    }
    if (rowLimit != null && rowLimit < 0) {
      throw ArgumentError.value(rowLimit, 'rowLimit', 'must not be negative');
    }
    return _database.withinRead(() => _getData(columns, rowOffset, rowLimit));
  }

  List<Map<String, Object?>> _getData(
    List<String>? columns,
    int rowOffset,
    int? rowLimit,
  ) {
    final columnDefinitions = _getColumnDefinitions();

    final data = <Map<String, Object?>>[];

    final selectedColumns = [
      for (final c in columnDefinitions)
        if (columns == null || columns.contains(c.name)) c,
    ];

    var rowsToSkip = rowOffset;
    // null = no limit (Infinity upstream)
    var rowsToRead = rowLimit;

    for (final dataPage in _dataPages) {
      if (rowsToRead != null && rowsToRead <= 0) {
        // All required data was loaded
        break;
      }

      final pageBuffer = _getDataPage(dataPage);
      final recordOffsets = _getRecordOffsets(pageBuffer);

      if (recordOffsets.length <= rowsToSkip) {
        // All records can be skipped
        rowsToSkip -= recordOffsets.length;
        continue;
      }

      final start = rowsToSkip;
      var end = recordOffsets.length;
      if (rowsToRead != null && rowsToRead < end - start) {
        end = start + rowsToRead;
      }
      final recordsOnPage = _getDataFromPage(
        pageBuffer,
        recordOffsets.sublist(start, end),
        selectedColumns,
      );

      data.addAll(recordsOnPage);

      if (rowsToRead != null) {
        rowsToRead -= recordsOnPage.length;
      }
      rowsToSkip = 0;
    }

    return data;
  }

  Uint8List _getDataPage(int page) {
    final pageBuffer = _database.getPage(page);
    assertPageType(pageBuffer, PageType.dataPage);

    if (readUint32LE(pageBuffer, 4) != _firstDefinitionPage) {
      throw MdbFormatException(
        'Data page $page does not belong to table $name',
      );
    }

    return pageBuffer;
  }

  List<_RecordOffset> _getRecordOffsets(Uint8List pageBuffer) {
    final format = _database.format;
    final recordCount = readUint16LE(
      pageBuffer,
      format.dataPage.recordCountOffset,
    );
    final recordOffsets = <_RecordOffset>[];
    for (var record = 0; record < recordCount; ++record) {
      const offsetMask = 0x1fff;

      var recordStart = readUint16LE(
        pageBuffer,
        format.dataPage.recordCountOffsetInRecord + 2 + record * 2,
      );
      if (recordStart & 0x4000 != 0) {
        // deleted record
        continue;
      }
      recordStart &= offsetMask; // remove flags

      final nextStart = record == 0
          ? format.pageSize
          : readUint16LE(
                  pageBuffer,
                  format.dataPage.recordCountOffsetInRecord + record * 2,
                ) &
                offsetMask;
      final recordLength = nextStart - recordStart;
      final recordEnd = recordStart + recordLength - 1;

      recordOffsets.add((start: recordStart, end: recordEnd));
    }
    return recordOffsets;
  }

  List<Map<String, Object?>> _getDataFromPage(
    Uint8List pageBuffer,
    List<_RecordOffset> recordOffsets,
    List<ColumnDefinition> columns,
  ) {
    final format = _database.format;
    var lastColumnIndex = 0;
    for (final c in columns) {
      if (c.index > lastColumnIndex) {
        lastColumnIndex = c.index;
      }
    }
    final sortedColumns = _sortedByIndex(columns);
    final data = <Map<String, Object?>>[];
    for (final (:start, :end) in recordOffsets) {
      final recordStart = start;
      final recordEnd = end;
      final rowColumnCount = readUintLE(
        pageBuffer,
        recordStart,
        format.dataPage.columnCountSize,
      );

      final bitmaskSize = roundToFullByte(rowColumnCount);

      var rowVariableColumnCount = 0;
      final variableColumnOffsets = <int>[];
      if (_variableColumnCount > 0) {
        switch (format.dataPage.variableColumnCountSize) {
          case 1:
            rowVariableColumnCount = readUint8(
              pageBuffer,
              recordEnd - bitmaskSize,
            );

            // See mdbtools src/libmdb/write.c, mdb_crack_row3.
            final recordLength = recordEnd - recordStart + 1;
            // Math.floor upstream; differs from ~/ for negative lengths.
            var jumpCount = ((recordLength - 1) / 256).floor();
            final columnPointer = recordEnd - bitmaskSize - jumpCount - 1;

            // If last jump is a dummy value, ignore it
            if ((columnPointer - recordStart - rowVariableColumnCount) / 256 <
                jumpCount) {
              --jumpCount;
            }

            var jumpsUsed = 0;
            for (var i = 0; i < rowVariableColumnCount + 1; ++i) {
              while (jumpsUsed < jumpCount &&
                  i ==
                      readUint8(
                        pageBuffer,
                        recordEnd - bitmaskSize - jumpsUsed - 1,
                      )) {
                ++jumpsUsed;
              }
              variableColumnOffsets.add(
                readUint8(pageBuffer, columnPointer - i) + jumpsUsed * 256,
              );
            }
          case 2:
            rowVariableColumnCount = readUint16LE(
              pageBuffer,
              recordEnd - bitmaskSize - 1,
            );

            // See mdbtools src/libmdb/write.c, mdb_crack_row4.
            for (var i = 0; i < rowVariableColumnCount + 1; ++i) {
              variableColumnOffsets.add(
                readUint16LE(pageBuffer, recordEnd - bitmaskSize - 3 - i * 2),
              );
            }
        }
      }

      final rowFixedColumnCount = rowColumnCount - rowVariableColumnCount;

      final nullMask = slice(
        pageBuffer,
        recordEnd - bitmaskSize + 1,
        recordEnd - bitmaskSize + 1 + roundToFullByte(lastColumnIndex + 1),
      );
      var fixedColumnsFound = 0;

      final recordValues = <String, Object?>{};
      for (final column in sortedColumns) {
        // `isNull` stands in for upstream's `value = null` before the value
        // is read; upstream's `undefined` is `isNull == false`.
        var isNull = false;
        int start;
        int size;

        if (!getBitmapValue(nullMask, column.index)) {
          isNull = true;
        }

        if (column.fixedLength && fixedColumnsFound < rowFixedColumnCount) {
          final colStart = column.fixedIndex + format.dataPage.columnCountSize;
          start = recordStart + colStart;
          size = column.size;
          ++fixedColumnsFound;
        } else if (!column.fixedLength &&
            column.variableIndex < rowVariableColumnCount) {
          final colStart = variableColumnOffsets[column.variableIndex];
          start = recordStart + colStart;
          size = variableColumnOffsets[column.variableIndex + 1] - colStart;
        } else {
          start = 0;
          isNull = true;
          size = 0;
        }

        Object? value;
        if (column.type == ColumnType.boolean) {
          value = !isNull;
        } else if (!isNull) {
          value = readFieldValue(
            slice(pageBuffer, start, start + size),
            column,
            _database,
          );
        }

        recordValues[column.name] = value;
      }

      data.add(recordValues);
    }

    return data;
  }
}

typedef _RecordOffset = ({int start, int end});

/// Stable sort by column index, like JavaScript's `Array.prototype.sort`.
List<ColumnDefinition> _sortedByIndex(List<ColumnDefinition> columns) {
  final indexed = [
    for (var i = 0; i < columns.length; i++) (position: i, column: columns[i]),
  ];
  indexed.sort((a, b) {
    final byIndex = a.column.index.compareTo(b.column.index);
    return byIndex != 0 ? byIndex : a.position.compareTo(b.position);
  });
  return [for (final entry in indexed) entry.column];
}
