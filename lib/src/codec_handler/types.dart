// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/codec-handler/types.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

typedef DecryptPage = Uint8List Function(Uint8List pageBuffer, int pageIndex);
typedef VerifyPassword = bool Function();

class CodecHandler {
  const CodecHandler({required this.decryptPage, required this.verifyPassword});

  final DecryptPage decryptPage;
  final VerifyPassword verifyPassword;
}
