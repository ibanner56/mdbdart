// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/bigint.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import '../bytes.dart';

/// Reads a signed 64-bit little-endian integer as a [BigInt]. Uses two 32-bit
/// reads so it works on the web, where `int` has 53 bits of precision.
BigInt readBigInt(Uint8List buffer) {
  final low = readUint32LE(buffer, 0);
  final high = readInt32LE(buffer, 4);
  return (BigInt.from(high) << 32) + BigInt.from(low);
}
