// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/crypto/rc4.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:convert';
import 'dart:typed_data';

import 'package:mdbdart/src/crypto/rc4.dart';
import 'package:test/test.dart';

void main() {
  group('decryptRC4', () {
    // https://en.wikipedia.org/wiki/RC4#Test_vectors
    for (final (key, encrypted, expected) in [
      (
        'Key',
        [0xbb, 0xf3, 0x16, 0xe8, 0xd9, 0x40, 0xaf, 0x0a, 0xd3],
        'Plaintext',
      ),
      ('Wiki', [0x10, 0x21, 0xbf, 0x04, 0x20], 'pedia'),
      (
        'Secret',
        [
          0x45,
          0xa0,
          0x1f,
          0x64,
          0x5f,
          0xc3,
          0x5b,
          0x38,
          0x35,
          0x52,
          0x54,
          0x4b,
          0x9b,
          0xf5,
        ],
        'Attack at dawn',
      ),
    ]) {
      test(key, () {
        final result = decryptRC4(
          Uint8List.fromList(ascii.encode(key)),
          Uint8List.fromList(encrypted),
        );
        expect(ascii.decode(result), expected);
      });
    }
  });
}
