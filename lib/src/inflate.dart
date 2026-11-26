// Original code for mdbdart; not ported from mdb-reader. Upstream calls
// Node's zlib (or pako in browsers) to inflate compressed attachments. This
// is a small zlib (RFC 1950) / DEFLATE (RFC 1951) decoder so the library
// needs no runtime dependencies and no dart:io.
//
// Input is untrusted: every read is bounds-checked, invalid codes throw
// MdbFormatException, and output stops at [maxOutput] bytes.

import 'dart:typed_data';

import 'errors.dart';

/// Inflates zlib-wrapped data.
///
/// Decoding stops once [maxOutput] bytes have been produced; the result is
/// then the first [maxOutput] bytes and the trailing checksum is not checked.
/// Otherwise the Adler-32 checksum is verified.
Uint8List zlibInflate(Uint8List input, {required int maxOutput}) {
  if (input.length < 2) {
    throw MdbFormatException('Truncated zlib header');
  }
  final cmf = input[0];
  final flg = input[1];
  if (cmf & 0x0f != 8 || cmf >> 4 > 7 || (cmf * 256 + flg) % 31 != 0) {
    throw MdbFormatException('Invalid zlib header');
  }
  if (flg & 0x20 != 0) {
    throw MdbUnsupportedException('zlib preset dictionaries are not supported');
  }

  final inflater = _Inflater(input, 2, maxOutput < 0 ? 0 : maxOutput);
  final complete = inflater.run();
  final output = inflater.output;
  if (!complete) {
    return output;
  }

  // Adler-32 trailer, big-endian, starting at the next byte boundary.
  final pos = inflater.bytePosition;
  if (pos + 4 > input.length) {
    throw MdbFormatException('Truncated zlib checksum');
  }
  final expected =
      input[pos] * 0x1000000 +
      input[pos + 1] * 0x10000 +
      input[pos + 2] * 0x100 +
      input[pos + 3];
  if (_adler32(output) != expected) {
    throw MdbFormatException('zlib checksum mismatch');
  }
  return output;
}

int _adler32(Uint8List data) {
  var a = 1;
  var b = 0;
  for (final byte in data) {
    a = (a + byte) % 65521;
    b = (b + a) % 65521;
  }
  return b * 65536 + a;
}

const _maxBits = 15;

const _lengthBase = [
  3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, //
  35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258,
];
const _lengthExtra = [
  0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, //
  3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0,
];
const _distanceBase = [
  1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, //
  257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289,
  16385, 24577,
];
const _distanceExtra = [
  0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, //
  7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13,
];
const _codeLengthOrder = [
  16,
  17,
  18,
  0,
  8,
  7,
  9,
  6,
  10,
  5,
  11,
  4,
  12,
  3,
  13,
  2,
  14,
  1,
  15,
];

/// A canonical Huffman code: the number of codes of each length and the
/// symbols ordered by code.
class _Huffman {
  _Huffman(List<int> lengths) {
    for (final length in lengths) {
      counts[length]++;
    }
    // Reject over-subscribed codes. Incomplete codes are allowed; decoding a
    // missing code throws.
    var left = 1;
    for (var len = 1; len <= _maxBits; len++) {
      left <<= 1;
      left -= counts[len];
      if (left < 0) {
        throw MdbFormatException('Invalid deflate code lengths');
      }
    }
    final offsets = List<int>.filled(_maxBits + 1, 0);
    for (var len = 1; len < _maxBits; len++) {
      offsets[len + 1] = offsets[len] + counts[len];
    }
    symbols = List<int>.filled(lengths.length, 0);
    for (var symbol = 0; symbol < lengths.length; symbol++) {
      if (lengths[symbol] != 0) {
        symbols[offsets[lengths[symbol]]++] = symbol;
      }
    }
  }

  final counts = List<int>.filled(_maxBits + 1, 0);
  late final List<int> symbols;
}

class _Inflater {
  _Inflater(this._input, this._pos, this._maxOutput);

  final Uint8List _input;
  int _pos;
  final int _maxOutput;

  int _bitBuffer = 0;
  int _bitCount = 0;

  Uint8List _out = Uint8List(1024);
  int _outLength = 0;

  Uint8List get output => Uint8List.sublistView(_out, 0, _outLength);

  int get bytePosition => _pos;

  int _bits(int need) {
    while (_bitCount < need) {
      if (_pos >= _input.length) {
        throw MdbFormatException('Truncated deflate stream');
      }
      _bitBuffer |= _input[_pos++] << _bitCount;
      _bitCount += 8;
    }
    final value = _bitBuffer & ((1 << need) - 1);
    _bitBuffer >>= need;
    _bitCount -= need;
    return value;
  }

  /// Appends [byte]; returns false once the output limit is reached.
  bool _emit(int byte) {
    if (_outLength >= _maxOutput) {
      return false;
    }
    if (_outLength == _out.length) {
      var newLength = _out.length * 2;
      if (newLength > _maxOutput) {
        newLength = _maxOutput;
      }
      _out = Uint8List(newLength)..setRange(0, _outLength, _out);
    }
    _out[_outLength++] = byte;
    return true;
  }

  /// Returns true when the final block ended, false when the output limit
  /// stopped decoding.
  bool run() {
    var last = false;
    while (!last) {
      last = _bits(1) == 1;
      final type = _bits(2);
      final bool more;
      switch (type) {
        case 0:
          more = _stored();
        case 1:
          more = _codes(_fixedLengths, _fixedDistances);
        case 2:
          final (lengths, distances) = _dynamicTables();
          more = _codes(lengths, distances);
        default:
          throw MdbFormatException('Invalid deflate block type');
      }
      if (!more) {
        return false;
      }
    }
    return true;
  }

  bool _stored() {
    // Discard the remaining bits of the current byte.
    _bitBuffer = 0;
    _bitCount = 0;
    if (_pos + 4 > _input.length) {
      throw MdbFormatException('Truncated deflate stream');
    }
    final length = _input[_pos] | (_input[_pos + 1] << 8);
    final complement = _input[_pos + 2] | (_input[_pos + 3] << 8);
    _pos += 4;
    if (length != (~complement & 0xffff)) {
      throw MdbFormatException('Invalid deflate stored block length');
    }
    if (_pos + length > _input.length) {
      throw MdbFormatException('Truncated deflate stream');
    }
    for (var i = 0; i < length; i++) {
      if (!_emit(_input[_pos++])) {
        return false;
      }
    }
    return true;
  }

  int _decode(_Huffman huffman) {
    var code = 0;
    var first = 0;
    var index = 0;
    for (var len = 1; len <= _maxBits; len++) {
      code |= _bits(1);
      final count = huffman.counts[len];
      if (code - first < count) {
        return huffman.symbols[index + (code - first)];
      }
      index += count;
      first += count;
      first <<= 1;
      code <<= 1;
    }
    throw MdbFormatException('Invalid deflate code');
  }

  bool _codes(_Huffman lengths, _Huffman distances) {
    while (true) {
      final symbol = _decode(lengths);
      if (symbol < 256) {
        if (!_emit(symbol)) {
          return false;
        }
      } else if (symbol == 256) {
        return true;
      } else {
        final lengthIndex = symbol - 257;
        if (lengthIndex >= _lengthBase.length) {
          throw MdbFormatException('Invalid deflate length code');
        }
        final length =
            _lengthBase[lengthIndex] + _bits(_lengthExtra[lengthIndex]);
        final distanceIndex = _decode(distances);
        if (distanceIndex >= _distanceBase.length) {
          throw MdbFormatException('Invalid deflate distance code');
        }
        final distance =
            _distanceBase[distanceIndex] + _bits(_distanceExtra[distanceIndex]);
        if (distance > _outLength) {
          throw MdbFormatException('Invalid deflate distance');
        }
        for (var i = 0; i < length; i++) {
          if (!_emit(_out[_outLength - distance])) {
            return false;
          }
        }
      }
    }
  }

  (_Huffman, _Huffman) _dynamicTables() {
    final literalCount = _bits(5) + 257;
    final distanceCount = _bits(5) + 1;
    final codeLengthCount = _bits(4) + 4;
    if (literalCount > 286 || distanceCount > 30) {
      throw MdbFormatException('Invalid deflate table counts');
    }

    final codeLengthLengths = List<int>.filled(19, 0);
    for (var i = 0; i < codeLengthCount; i++) {
      codeLengthLengths[_codeLengthOrder[i]] = _bits(3);
    }
    final codeLengthCode = _Huffman(codeLengthLengths);

    final lengths = List<int>.filled(literalCount + distanceCount, 0);
    var index = 0;
    while (index < lengths.length) {
      final symbol = _decode(codeLengthCode);
      if (symbol < 16) {
        lengths[index++] = symbol;
        continue;
      }
      var value = 0;
      int repeat;
      if (symbol == 16) {
        if (index == 0) {
          throw MdbFormatException('Invalid deflate repeat');
        }
        value = lengths[index - 1];
        repeat = 3 + _bits(2);
      } else if (symbol == 17) {
        repeat = 3 + _bits(3);
      } else {
        repeat = 11 + _bits(7);
      }
      if (index + repeat > lengths.length) {
        throw MdbFormatException('Invalid deflate repeat');
      }
      for (var i = 0; i < repeat; i++) {
        lengths[index++] = value;
      }
    }

    if (lengths[256] == 0) {
      throw MdbFormatException('Deflate table has no end-of-block code');
    }

    return (
      _Huffman(lengths.sublist(0, literalCount)),
      _Huffman(lengths.sublist(literalCount)),
    );
  }
}

final _Huffman _fixedLengths = _Huffman([
  for (var i = 0; i < 144; i++) 8,
  for (var i = 144; i < 256; i++) 9,
  for (var i = 256; i < 280; i++) 7,
  for (var i = 280; i < 288; i++) 8,
]);

final _Huffman _fixedDistances = _Huffman([for (var i = 0; i < 30; i++) 5]);
