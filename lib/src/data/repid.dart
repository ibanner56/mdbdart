// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/repid.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../bytes.dart';
import '../errors.dart';

String _hex(Iterable<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// Reads a replication ID (GUID) as a lower-case string.
///
/// See mdbtools src/libmdb/data.c, mdb_uuid_to_string.
String readRepID(Uint8List buffer) {
  if (buffer.length < 16) {
    throw MdbFormatException(
      'Replication ID needs 16 bytes, got ${buffer.length}',
    );
  }
  return '${_hex(slice(buffer, 0, 4).reversed)}' // swap for little-endian
      '-${_hex(slice(buffer, 4, 6).reversed)}' // swap for little-endian
      '-${_hex(slice(buffer, 6, 8).reversed)}' // swap for little-endian
      '-${_hex(slice(buffer, 8, 10))}' // big-endian
      '-${_hex(slice(buffer, 10, 16))}'; // big-endian
}
