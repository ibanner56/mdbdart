// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), test/reader.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'package:mdbdart/mdbdart.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('MdbReader', () {
    for (final filename in [
      'V1997/test.mdb',
      'V2000/test.mdb',
      'V2003/test.mdb',
      'V2007/test.accdb',
      'V2010/test.accdb',
    ]) {
      group(filename, () {
        group('getTable()', () {
          test('returns table', () {
            final reader = MdbReader(readFixture(filename));
            final table = reader.getTable('Table1');
            expect(table.name, 'Table1');
            expect(table.rowCount, 2);
          });

          test('throws error for unknown table', () {
            final reader = MdbReader(readFixture(filename));
            expect(
              () => reader.getTable('unknown'),
              throwsMdb<MdbNotFoundException>(),
            );
          });
        });

        test('getTableNames()', () {
          final reader = MdbReader(readFixture(filename));
          expect(reader.getTableNames(), [
            'Table1',
            'Table2',
            'Table3',
            'Table4',
          ]);
        });

        test('should not modify the input buffer', () {
          final buffer = readFixture(filename);
          final reader = MdbReader(buffer);
          for (final name in reader.getTableNames()) {
            reader.getTable(name).getData();
          }
          expect(buffer, readFixture(filename));
        });
      });
    }
  });
}
