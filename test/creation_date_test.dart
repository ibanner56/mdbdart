// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), test/creation-date/creation-date.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'package:mdbdart/mdbdart.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Creation Date', () {
    // Expected values are UTC instants, so the test does not depend on the
    // time zone.
    for (final (filename, expected) in [
      ('V1997.mdb', null),
      ('V2000.mdb', DateTime.utc(2022, 1, 7, 16, 20, 28, 23)),
      ('V2010.accdb', DateTime.utc(2022, 1, 7, 16, 20, 39, 512)),
    ]) {
      test('$filename should read the creation date', () {
        final reader = MdbReader(readFixture('creation-date/$filename'));
        final date = reader.getCreationDate();
        if (expected == null) {
          expect(date, isNull);
        } else {
          expect(date!.isUtc, isTrue);
          expect(date.toIso8601String(), expected.toIso8601String());
          expect(date, expected);
        }
      });
    }
  });
}
