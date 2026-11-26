// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/JetFormat/index.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:convert';
import 'dart:typed_data';

import '../bytes.dart';
import '../errors.dart';
import 'jet12_format.dart';
import 'jet14_format.dart';
import 'jet15_format.dart';
import 'jet16_format.dart';
import 'jet17_format.dart';
import 'jet3_format.dart';
import 'jet4_format.dart';
import 'msisam_format.dart';
import 'types.dart';

export 'types.dart';

const _offsetVersion = 0x14;
const _offsetEngineName = 0x4;
const _msisamEngine = 'MSISAM Database';

/// Returns the database format of the given buffer.
///
/// [buffer] is the full buffer or the buffer of the first page.
///
/// See mdbtools HACKING.md, "Database Definition Page", and Jackcess
/// JetFormat.
JetFormat getJetFormat(Uint8List buffer) {
  final version = buffer.length > _offsetVersion
      ? buffer[_offsetVersion]
      : null;
  switch (version) {
    case 0x00: // JET 3
      return jet3Format;
    case 0x01: // JET 4
      final engine = slice(
        buffer,
        _offsetEngineName,
        _offsetEngineName + _msisamEngine.length,
      );
      if (latin1.decode(engine.map((b) => b & 0x7f).toList()) ==
          _msisamEngine) {
        return msisamFormat;
      }
      return jet4Format;
    case 0x02: // ACCESS 2007
      return jet12Format;
    case 0x03: // ACCESS 2010
      return jet14Format;
    case 0x04: // ACCESS 2013
      return jet15Format;
    case 0x05: // ACCESS 2016
      return jet16Format;
    case 0x06: // ACCESS 2019
      return jet17Format;
    default:
      throw MdbUnsupportedException("Unsupported version '$version'");
  }
}
