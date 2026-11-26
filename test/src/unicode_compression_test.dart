// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/unicodeCompression.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:convert';
import 'dart:typed_data';

import 'package:mdbdart/src/jet_format/jet_format.dart';
import 'package:mdbdart/src/unicode_compression.dart';
import 'package:test/test.dart';

const compressionHeader = [0xff, 0xfe];

Uint8List ucs2(String s) {
  final bytes = Uint8List(s.length * 2);
  for (var i = 0; i < s.length; i++) {
    bytes[i * 2] = s.codeUnitAt(i) & 0xff;
    bytes[i * 2 + 1] = s.codeUnitAt(i) >> 8;
  }
  return bytes;
}

List<int> compressAscii(String s) => ascii.encode(s);

void main() {
  group('uncompressText', () {
    test('decodes Jet3 buffer', () {
      final inputBuffer = Uint8List.fromList([0x53, 0xe9, 0x72, 0x69, 0x65]);
      expect(uncompressText(inputBuffer, TextEncoding.unknown), 'Série');
    });

    // Not upstream: the Windows-1252-specific range 0x80-0x9F.
    test('decodes Windows-1252 0x80-0x9F', () {
      final inputBuffer = Uint8List.fromList([0x80, 0x81, 0x93, 0x94, 0x9f]);
      expect(uncompressText(inputBuffer, TextEncoding.unknown), '€�“”Ÿ');
    });

    test('decodes uncompressed Jet4 buffer', () {
      const inputString = 'This is a test';
      expect(uncompressText(ucs2(inputString), TextEncoding.ucs2), inputString);
    });

    group('decodes compressed ascii', () {
      test('without uncompressed characters', () {
        const inputString = 'This is a test';
        final fullInputBuffer = Uint8List.fromList([
          ...compressionHeader,
          ...compressAscii(inputString),
        ]);
        expect(uncompressText(fullInputBuffer, TextEncoding.ucs2), inputString);
      });

      test('with uncompressed characters', () {
        const asciiInputString = 'ASCII';
        const unicodeInputString = 'Ț✚';

        final fullInputBuffer = Uint8List.fromList([
          ...compressionHeader,
          ...compressAscii(asciiInputString),
          0x00,
          ...ucs2(unicodeInputString),
          0x00,
          ...compressAscii(asciiInputString),
        ]);

        expect(
          uncompressText(fullInputBuffer, TextEncoding.ucs2),
          '$asciiInputString$unicodeInputString$asciiInputString',
        );
      });

      test('with an uncompressed character as last char', () {
        final fullInputBuffer = Uint8List.fromList([
          ...compressionHeader,
          0x00,
          ...ucs2('Hello world'),
        ]);
        expect(
          uncompressText(fullInputBuffer, TextEncoding.ucs2),
          'Hello world',
        );
      });
    });
  });
}
