// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), test/bigint.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

@TestOn('vm')
library;

import 'package:mdbdart/mdbdart.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('BigInt V2016/bigint.accdb', () {
    // See Jackcess DatabaseTest, testBigInt.
    test('getData(): returns correct big int data', () {
      final reader = MdbReader(readFixture('V2016/bigint.accdb'));
      final table = reader.getTable('Table');
      final rows = table.getData();

      expect(rows, hasLength(1));
      expect(rows[0]['Numeric'], BigInt.from(42));
    });
  });
}
