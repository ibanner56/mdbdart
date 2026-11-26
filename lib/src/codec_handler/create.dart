// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/codec-handler/create.ts at 4e08263; see THIRD_PARTY_NOTICES.md

// Decryption is not ported yet. Where upstream would create a Jet (RC4) or
// Office codec handler for a database with a non-empty encoding key, this
// throws MdbEncryptedException instead. Upstream's handlers return the
// identity handler when the key is empty, and so does this.

import 'dart:typed_data';

import '../bytes.dart';
import '../errors.dart';
import '../jet_format/jet_format.dart';
import '../util.dart';
import 'identity.dart';
import 'types.dart';

export 'types.dart';

// Same offset in src/codec-handler/handlers/jet.ts and .../office/index.ts.
const _keyOffset = 0x3e; // 62
const _keySize = 4;

CodecHandler createCodecHandler(Uint8List databaseDefinitionPage) {
  final format = getJetFormat(databaseDefinitionPage);
  switch (format.codecType) {
    case CodecType.jet:
    case CodecType.office:
      final encodingKey = slice(
        databaseDefinitionPage,
        _keyOffset,
        _keyOffset + _keySize,
      );
      if (isEmptyBuffer(encodingKey)) {
        return createIdentityHandler();
      }
      throw MdbEncryptedException(
        format.codecType == CodecType.jet
            ? 'The database is encoded with Jet RC4 encryption, '
                  'which is not supported yet'
            : 'The database is encrypted with Office encryption, '
                  'which is not supported yet',
      );
    case CodecType.msisam:
      return createIdentityHandler();
  }
}
