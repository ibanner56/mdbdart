// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), test/longtext.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

@TestOn('vm')
library;

import 'package:mdbdart/mdbdart.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('LongText', () {
    test('rejects a pointer-only cycle', () {
      final buffer = readFixture('V2016/longtext.accdb');
      const page = 91 * 4096;
      writeUint16LE(buffer, page + 14, 4092);
      writeUint32LE(buffer, page + 4092, 91 << 8);
      final table = MdbReader(buffer).getTable('Table1');
      expect(
        () => table.getData(),
        throwsMdb<MdbFormatException>(
          'Invalid Memo long-value row: no payload',
        ),
      );
    });

    test('multiple pages', () {
      final reader = MdbReader(readFixture('V2016/longtext.accdb'));
      final data = reader.getTable('Table1').getData();
      expect(
        data[0]['LongText'],
        isA<String>().having((s) => s.length, 'length', 5000),
      );
    });
  });
}
