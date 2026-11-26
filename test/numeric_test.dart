// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), test/numeric.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'package:mdbdart/mdbdart.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Numeric', () {
    for (final filename in [
      'V2000/numeric.mdb',
      'V2003/numeric.mdb',
      'V2007/numeric.accdb',
      'V2010/numeric.accdb',
    ]) {
      // See Jackcess DatabaseTest, testNumericColumns.
      test('$filename getData(): returns correct numeric data', () {
        final reader = MdbReader(readFixture(filename));
        final rows = reader.getTable('test').getData();

        expect(rows, hasLength(1));

        final row = rows[0];
        expect(row['col2'], '1');
        expect(row['col3'], '0');
        expect(row['col4'], '0');
        expect(row['col5'], '4');
        expect(row['col6'], '-1');
        expect(row['col7'], '1');
      });
    }
  });
}
