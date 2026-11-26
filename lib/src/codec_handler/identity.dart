// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/codec-handler/handlers/identity.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import 'types.dart';

Uint8List _identity(Uint8List b, int _) => b;
bool _alwaysTrue() => true;

CodecHandler createIdentityHandler() =>
    const CodecHandler(decryptPage: _identity, verifyPassword: _alwaysTrue);
