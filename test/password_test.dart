// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), test/password/password.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

@TestOn('vm')
library;

import 'package:mdbdart/mdbdart.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Password', () {
    // TODO(upstream): test Jet 3 with password
    for (final (filename, result) in [
      ('V1997_no-password.mdb', null),
      ('V2000_with-password.mdb', 'password'),
      ('V2000_no-password.mdb', null),
      ('V2003_with-password.mdb', 'password'),
      ('V2003_no-password.mdb', null),
      ('V2010_no-password.accdb', null),
    ]) {
      test('$filename should read the password', () {
        final reader = MdbReader(readFixture('password/$filename'));
        expect(reader.getPassword(), result);
      });
    }

    // Upstream decrypts this file with the password and then asserts the
    // (masked) password field. Decryption is not supported yet, so opening it
    // throws MdbEncryptedException.
    test('V2010_with-password.accdb is encrypted', () {
      expect(
        () => MdbReader(readFixture('password/V2010_with-password.accdb')),
        throwsMdb<MdbEncryptedException>('Office encryption'),
      );
    });
  });
}
