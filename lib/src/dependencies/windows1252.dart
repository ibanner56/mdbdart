// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/dependencies/iconv-lite/index.ts at 4e08263; see THIRD_PARTY_NOTICES.md

// mdb-reader's copy of this table comes from iconv-lite (MIT, Copyright (c)
// 2011 Alexander Shtuchkin); see THIRD_PARTY_NOTICES.md. The table below is
// the Windows-1252 mapping for bytes 0x80 to 0xFF, written out as code points.

import 'dart:typed_data';

/// Code points of bytes 0x80 to 0x9F. Undefined bytes map to U+FFFD.
const _windows1252High = <int>[
  0x20ac, 0xfffd, 0x201a, 0x0192, 0x201e, 0x2026, 0x2020, 0x2021, //
  0x02c6, 0x2030, 0x0160, 0x2039, 0x0152, 0xfffd, 0x017d, 0xfffd,
  0xfffd, 0x2018, 0x2019, 0x201c, 0x201d, 0x2022, 0x2013, 0x2014,
  0x02dc, 0x2122, 0x0161, 0x203a, 0x0153, 0xfffd, 0x017e, 0x0178,
];

/// Decodes CP1252 / Windows-1252.
String decodeWindows1252(Uint8List buffer) {
  final codeUnits = Uint16List(buffer.length);
  for (var i = 0; i < buffer.length; ++i) {
    final byte = buffer[i];
    codeUnits[i] = byte >= 0x80 && byte < 0xa0
        ? _windows1252High[byte - 0x80]
        : byte;
  }
  return String.fromCharCodes(codeUnits);
}
