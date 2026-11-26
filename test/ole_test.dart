// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), test/ole.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:mdbdart/mdbdart.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('OLE', () {
    late Uint8List buffer;

    setUp(() {
      buffer = readFixture('V2007/ole.accdb');
    });

    test('reads complete ole data', () {
      final data = MdbReader(buffer).getTable('Table1').getData();
      expect(data, hasLength(11));
      final payload = data.singleWhere((entry) => entry['ID'] == 2)['ole_data'];
      expect(payload, isA<Uint8List>());
      payload as Uint8List;
      expect(payload, hasLength(94602));
      expect(
        sha256.convert(payload).toString(),
        '334e3631b06b696ac63fe0dd484109c9f9e75cf58c3655e08ede032d557071dc',
      );
    });

    test('rejects cyclic OLE data through getData', () {
      final rowOffset = readUint16(buffer, 136 * 4096 + 14);
      writeUint32LE(buffer, 136 * 4096 + rowOffset, 136 * 256);

      expect(
        () => MdbReader(buffer).getTable('Table1').getData(),
        throwsMdb<MdbFormatException>(
          'Cyclic OLE long-value chain at page-row 34816',
        ),
      );
    });
  });
}
