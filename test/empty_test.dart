// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), test/empty.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

@TestOn('vm')
library;

import 'package:mdbdart/mdbdart.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('empty', () {
    for (final file in [
      'V2000/empty.mdb',
      'V2003/empty.mdb',
      'V2007/empty.accdb',
      'V2010/empty.accdb',
      'V2016/empty.accdb',
    ]) {
      test('$file should have no tables', () {
        final reader = MdbReader(readFixture(file));
        expect(reader.getTableNames(), isEmpty);
      });
    }
  });
}
