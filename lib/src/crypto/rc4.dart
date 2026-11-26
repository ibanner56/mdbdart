// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/crypto/rc4.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

/// Decrypts [data] with RC4 and [key]. Returns a new list; [data] is not
/// modified.
Uint8List decryptRC4(Uint8List key, Uint8List data) {
  final decrypt = createRC4Decrypter(key);
  return decrypt(data);
}

Uint8List Function(Uint8List data) createRC4Decrypter(Uint8List key) {
  final s = _createKeyStream(key);

  var i = 0;
  var j = 0;

  return (Uint8List data) {
    final result = Uint8List.fromList(data);

    // Pseudo-random generation algorithm (PRGA)
    for (var k = 0; k < data.length; ++k) {
      i = (i + 1) % 256;
      j = (j + s[i]) % 256;
      final t = s[i];
      s[i] = s[j];
      s[j] = t;
      result[k] ^= s[(s[i] + s[j]) % 256];
    }

    return result;
  };
}

/// Key-scheduling algorithm (KSA)
Uint8List _createKeyStream(Uint8List key) {
  final s = Uint8List(256);
  for (var i = 0; i < 256; ++i) {
    s[i] = i;
  }
  if (key.isEmpty) {
    // Upstream would compute with `undefined` key bytes; an empty key never
    // occurs in practice. Treat it as an all-zero key.
    key = Uint8List(1);
  }
  var j = 0;
  for (var i = 0; i < 256; ++i) {
    j = (j + s[i] + key[i % key.length]) % 256;
    final t = s[i];
    s[i] = s[j];
    s[j] = t;
  }

  return s;
}
