// Tests of mdbdart's own API surface. Not ported.

@TestOn('vm')
library;

import 'package:mdbdart/io.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Table.getColumn', () {
    test('returns a column by name', () {
      final table = MdbReader(
        readFixture('V2010/test.accdb'),
      ).getTable('Table1');
      final column = table.getColumn('H');
      expect(column.type, ColumnType.currency);
      expect(column.name, 'H');
    });

    test('throws MdbNotFoundException for an unknown column', () {
      final table = MdbReader(
        readFixture('V2010/test.accdb'),
      ).getTable('Table1');
      expect(() => table.getColumn('nope'), throwsMdb<MdbNotFoundException>());
    });

    test('reports precision and scale of numeric columns', () {
      final table = MdbReader(
        readFixture('V2010/numeric.accdb'),
      ).getTable('test');
      final numeric = [
        for (final c in table.getColumns())
          if (c.type == ColumnType.numeric) c,
      ];
      expect(numeric, isNotEmpty);
      for (final c in numeric) {
        expect(c.precision, isNotNull);
        expect(c.scale, isNotNull);
      }
    });
  });

  group('getData options', () {
    test('columns selects a subset', () {
      final table = MdbReader(readFixture('V2000/test.mdb')).getTable('Table1');
      final rows = table.getData(columns: ['A', 'I']);
      expect(rows, [
        {'A': 'abcdefg', 'I': true},
        {'A': 'a', 'I': false},
      ]);
    });
  });

  group('table names', () {
    test('systemTables lists MSys tables only when asked', () {
      final reader = MdbReader(readFixture('V2010/test.accdb'));
      expect(reader.getTableNames(), isNot(contains('MSysObjects')));
      final system = reader.getTableNames(
        normalTables: false,
        systemTables: true,
      );
      expect(system, contains('MSysObjects'));
      expect(system, isNot(contains('Table1')));
    });
  });

  group('Jet encoding', () {
    // The header is RC4-obfuscated with a fixed key, so flipping a stored
    // byte flips the same bit of the decoded encoding key at 0x3e.
    for (final fixture in ['V1997/test.mdb', 'V2000/test.mdb']) {
      test('$fixture with an encoding key throws MdbEncryptedException', () {
        final bytes = readFixture(fixture);
        bytes[0x3e] ^= 0x01;
        expect(
          () => MdbReader(bytes),
          throwsMdb<MdbEncryptedException>('Jet RC4'),
        );
      });
    }
  });

  group('io.dart', () {
    test('openMdbFile reads a file', () async {
      final reader = await openMdbFile('test/data/V2003/test.mdb');
      expect(reader.getTableNames(), hasLength(4));
    });

    test('openMdbFileSync reads a file', () {
      final reader = openMdbFileSync('test/data/V1997/test.mdb');
      expect(reader.getTable('Table1').rowCount, 2);
    });
  });
}
