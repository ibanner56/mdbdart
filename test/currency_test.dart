// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), test/currency.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:mdbdart/mdbdart.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Currency V2016/currency.accdb', () {
    test(
      'getData(): preserves negative currency data across repeated reads and '
      'readers',
      () {
        final buffer = readFixture('V2016/currency.accdb');
        // 420000 as a little-endian 64-bit integer.
        final positivePattern = [0xa0, 0x68, 0x06, 0, 0, 0, 0, 0];
        final matches = <int>[];
        for (var offset = 0; offset + 8 <= buffer.length; offset++) {
          var match = true;
          for (var i = 0; i < 8 && match; i++) {
            match = buffer[offset + i] == positivePattern[i];
          }
          if (match) {
            matches.add(offset);
          }
        }
        expect(matches, hasLength(1));
        // -420000 as a little-endian 64-bit integer.
        buffer.setRange(matches[0], matches[0] + 8, [
          0x60, 0x97, 0xf9, 0xff, 0xff, 0xff, 0xff, 0xff, //
        ]);
        final snapshot = Uint8List.fromList(buffer);

        final reader = MdbReader(buffer);
        expect(buffer, snapshot);
        final table = reader.getTable('Table');
        expect(table.getData(), [
          {'ID': 1, 'Money': '-42.0000'},
        ]);
        expect(buffer, snapshot);
        expect(table.getData(), [
          {'ID': 1, 'Money': '-42.0000'},
        ]);
        expect(buffer, snapshot);

        final secondReader = MdbReader(buffer);
        expect(buffer, snapshot);
        expect(secondReader.getTable('Table').getData(), [
          {'ID': 1, 'Money': '-42.0000'},
        ]);
        expect(buffer, snapshot);
      },
    );

    test('getData(): returns correct currency data', () {
      final reader = MdbReader(readFixture('V2016/currency.accdb'));
      final rows = reader.getTable('Table').getData();

      expect(rows, hasLength(1));
      expect(rows[0]['Money'], '42.0000');
    });
  });
}
