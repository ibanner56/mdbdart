// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), test/encryption/encryption.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'package:mdbdart/mdbdart.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  // Upstream decrypts these files. Decryption is not supported yet, so the
  // port asserts that opening them throws a typed exception instead.
  group('Encryption', () {
    for (final filename in [
      'office-agile-4.4.accdb',
      'office-agile-4.2.accdb',
    ]) {
      test('$filename throws MdbEncryptedException', () {
        final buffer = readFixture('encryption/$filename');
        expect(
          () => MdbReader(buffer),
          throwsMdb<MdbEncryptedException>('Office encryption'),
        );
        // An encrypted database is also "unsupported".
        expect(() => MdbReader(buffer), throwsMdb<MdbUnsupportedException>());
      });
    }
  });
}
