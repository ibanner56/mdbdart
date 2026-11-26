// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), test/table.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import 'package:mdbdart/mdbdart.dart';
import 'package:mdbdart/src/database.dart';
import 'package:mdbdart/src/table.dart' as internal;
import 'package:test/test.dart';

import 'helpers.dart';

/// Counts page reads, like upstream's test that wraps Database.getPage.
class _CountingDatabase extends Database {
  _CountingDatabase(super.buffer, this.budget);

  final int budget;
  int reads = 0;

  @override
  Uint8List getPage(int page) {
    if (++reads > budget) {
      throw StateError('Test read budget exceeded');
    }
    return super.getPage(page);
  }
}

void main() {
  group('Table', () {
    // The test databases are slightly different, so we need some extra
    // arguments here
    for (final (
          filename,
          reverseRows,
          columnALength,
          columnBLength,
          table4Length,
        )
        in [
          ('V1997/test.mdb', true, 50, 100, 50),
          ('V2000/test.mdb', false, 100, 200, 100),
          ('V2003/test.mdb', false, 100, 200, 100),
          ('V2007/test.accdb', true, 100, 200, 100),
          ('V2010/test.accdb', true, 100, 200, 100),
        ]) {
      group(filename, () {
        test('getData()', () {
          final reader = MdbReader(readFixture(filename));
          final table = reader.getTable('Table1');
          var rows = table.getData();

          if (reverseRows) {
            rows = rows.reversed.toList();
          }

          expect(rows[0]['A'], 'abcdefg');
          expect(rows[0]['B'], 'hijklmnop');
          expect(rows[0]['C'], 2);
          expect(rows[0]['D'], 222);
          expect(rows[0]['E'], 333333333);
          expect(rows[0]['F'], 444.555);
          final g0 = rows[0]['G'] as DateTime;
          expect(g0.isUtc, isTrue);
          expect(g0.millisecondsSinceEpoch, 148953600000);
          expect(rows[0]['H'], '3.5000');
          expect(rows[0]['I'], true);

          expect(rows[1]['A'], 'a');
          expect(rows[1]['B'], 'b');
          expect(rows[1]['C'], 0);
          expect(rows[1]['D'], 0);
          expect(rows[1]['E'], 0);
          expect(rows[1]['F'], 0);
          final g1 = rows[1]['G'] as DateTime;
          expect(g1.isUtc, isTrue);
          expect(g1.millisecondsSinceEpoch, 376963200000);
          expect(rows[1]['H'], '0.0000');
          expect(rows[1]['I'], false);
        });

        group('getColumns()', () {
          test('returns correct data types', () {
            final reader = MdbReader(readFixture(filename));
            final columns = reader.getTable('Table1').getColumns();

            expect(columns[0].name, 'A');
            expect(columns[0].type, ColumnType.text);
            expect(columns[0].type.value, 'text');
            expect(columns[0].size, columnALength);

            expect(columns[1].name, 'B');
            expect(columns[1].type, ColumnType.text);
            expect(columns[1].size, columnBLength);

            expect(columns[2].name, 'C');
            expect(columns[2].type, ColumnType.byte);

            expect(columns[3].name, 'D');
            expect(columns[3].type, ColumnType.integer);

            expect(columns[4].name, 'E');
            expect(columns[4].type, ColumnType.long);

            expect(columns[5].name, 'F');
            expect(columns[5].type, ColumnType.double);

            expect(columns[6].name, 'G');
            expect(columns[6].type, ColumnType.dateTime);

            expect(columns[7].name, 'H');
            expect(columns[7].type, ColumnType.currency);

            expect(columns[8].name, 'I');
            expect(columns[8].type, ColumnType.boolean);
          });

          test('can handle many columns', () {
            final reader = MdbReader(readFixture(filename));
            final columns = reader.getTable('Table2').getColumns();

            expect(columns, hasLength(89));
            for (var i = 0; i < 89; ++i) {
              expect(columns[i].name, 'column${i + 1}');
              expect(columns[i].type, ColumnType.text);
              expect(columns[i].size, table4Length);
            }
          });
        });

        test('getColumnNames()', () {
          final reader = MdbReader(readFixture(filename));
          expect(reader.getTable('Table1').getColumnNames(), [
            'A',
            'B',
            'C',
            'D',
            'E',
            'F',
            'G',
            'H',
            'I',
          ]);
        });
      });
    }

    group('getData()', () {
      group('real/ASampleDatabase.accdb', () {
        late Table table;

        setUpAll(() {
          final reader = MdbReader(readFixture('real/ASampleDatabase.accdb'));
          table = reader.getTable('Asset Items');
        });

        void expectRows(List<Map<String, Object?>> rows, int count) {
          expect(rows, hasLength(count));
          final assetNumbers = rows.map((row) => row['Asset No']).toSet();
          expect(assetNumbers, hasLength(count));
        }

        test('no options', () => expectRows(table.getData(), 65));
        test(
          'with rowOffset',
          () => expectRows(table.getData(rowOffset: 30), 35),
        );
        test(
          'with rowOffset > rowCount',
          () => expectRows(table.getData(rowOffset: 100), 0),
        );
        test(
          'with rowLimit',
          () => expectRows(table.getData(rowLimit: 40), 40),
        );
        test(
          'with rowLimit > rowCount',
          () => expectRows(table.getData(rowLimit: 100), 65),
        );
        test(
          'with rowOffset & rowLimit',
          () => expectRows(table.getData(rowOffset: 30, rowLimit: 15), 15),
        );
      });

      test('V2016/withdeletedcol.accdb: with offset column indices due to a '
          'column deletion', () {
        final reader = MdbReader(readFixture('V2016/withdeletedcol.accdb'));
        expect(reader.getTable('Table1').getData(), [
          {
            'col1': 0,
            'col2': 1,
            'col3': 2,
            'col5': 4,
            'col6': 5,
            'col7': 6,
            'col8': 7,
          },
        ]);
      });

      test('V2016/withinsertedcol.accdb: with offset column indices due to a '
          'column insertion', () {
        final reader = MdbReader(readFixture('V2016/withinsertedcol.accdb'));
        expect(reader.getTable('Table1').getData(), [
          {'col1': true, 'col2': true, 'col3': false},
        ]);
      });
    });
  });

  group('cyclic table definitions', () {
    for (final (filename, pageSize, firstPage, secondPage) in [
      ('V1997/test.mdb', 2048, 34, 44),
      ('V2000/test.mdb', 4096, 30, 708),
      ('V2003/test.mdb', 4096, 30, 708),
      ('V2007/test.accdb', 4096, 67, 78),
      ('V2010/test.accdb', 4096, 79, 90),
    ]) {
      group(filename, () {
        for (final (chain, useSecondPage, repeatSecondPage) in [
          ('A→A', false, false),
          ('A→B→A', true, false),
          ('A→B→B', true, true),
        ]) {
          test('rejects $chain', () {
            final buffer = readFixture(filename);
            final repeatedPage = repeatSecondPage ? secondPage : firstPage;
            writeUint32LE(
              buffer,
              firstPage * pageSize + 4,
              useSecondPage ? secondPage : firstPage,
            );
            if (useSecondPage) {
              writeUint32LE(buffer, secondPage * pageSize + 4, repeatedPage);
            }
            final originalBuffer = Uint8List.fromList(buffer);
            final database = _CountingDatabase(buffer, 4);

            expect(
              () => internal.Table('Table2', database, firstPage),
              throwsMdb<MdbFormatException>(
                'Cyclic table definition for table "Table2": '
                'repeated page $repeatedPage',
              ),
            );
            expect(database.reads, useSecondPage ? 2 : 1);
            expect(buffer, originalBuffer);
          });
        }

        test('rejects a catalog self-loop', () {
          final buffer = readFixture(filename);
          writeUint32LE(buffer, 2 * pageSize + 4, 2);
          final originalBuffer = Uint8List.fromList(buffer);
          final database = _CountingDatabase(buffer, 4);

          expect(
            () => internal.Table('MSysObjects', database, 2),
            throwsMdb<MdbFormatException>(
              'Cyclic table definition for table "MSysObjects": '
              'repeated page 2',
            ),
          );
          expect(database.reads, 1);
          expect(buffer, originalBuffer);
        });
      });
    }
  });
}
