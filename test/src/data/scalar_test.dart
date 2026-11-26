// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/{binary,byte,double,float,integer,long,repid,datetime,datetimextended}.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:convert';
import 'dart:typed_data';

import 'package:mdbdart/src/data/bigint.dart';
import 'package:mdbdart/src/data/binary.dart';
import 'package:mdbdart/src/data/byte.dart';
import 'package:mdbdart/src/data/datetime.dart';
import 'package:mdbdart/src/data/datetimextended.dart';
import 'package:mdbdart/src/data/double.dart';
import 'package:mdbdart/src/data/float.dart';
import 'package:mdbdart/src/data/integer.dart';
import 'package:mdbdart/src/data/long.dart';
import 'package:mdbdart/src/data/repid.dart';
import 'package:mdbdart/src/errors.dart';
import 'package:test/test.dart';

ByteData bytes(int length) => ByteData(length);
Uint8List view(ByteData data) => data.buffer.asUint8List();

void main() {
  test('Binary: can read binary', () {
    final buffer = Uint8List.fromList(ascii.encode('HELLO'));
    final result = readBinary(buffer);
    expect(identical(result, buffer), isFalse);
    expect(result, buffer);
  });

  test('Byte: can read byte', () {
    expect(readByte(Uint8List.fromList([42])), 42);
  });

  test('Double: can read double', () {
    expect(
      readDouble(view(bytes(8)..setFloat64(0, 3.14159, Endian.little))),
      3.14159,
    );
  });

  test('Float: can read float', () {
    final result = readFloat(
      view(bytes(4)..setFloat32(0, 3.14159, Endian.little)),
    );
    expect(result, greaterThanOrEqualTo(3.14159));
    expect(result, lessThan(3.14159 + 0.00001));
  });

  test('Integer: can read integer', () {
    expect(readInteger(view(bytes(2)..setInt16(0, 1337, Endian.little))), 1337);
  });

  test('Long: reads a 4-byte signed integer (little-endian)', () {
    expect(
      readLong(view(bytes(4)..setInt32(0, 1234567890, Endian.little))),
      1234567890,
    );
  });

  // Not upstream (upstream tests big ints only through a fixture).
  group('BigInt', () {
    // Little-endian bytes are written by hand so the test also runs where
    // ByteData.setInt64 is unavailable (the web).
    for (final (le, expected) in [
      ([0, 0, 0, 0, 0, 0, 0, 0], BigInt.zero),
      ([42, 0, 0, 0, 0, 0, 0, 0], BigInt.from(42)),
      ([0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff], BigInt.from(-1)),
      ([0, 0, 0, 0, 0, 0, 0, 0x80], -(BigInt.one << 63)),
      (
        [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f],
        (BigInt.one << 63) - BigInt.one,
      ),
      ([0, 0, 0, 0, 1, 0, 0, 0], BigInt.one << 32),
    ]) {
      test('reads $expected', () {
        expect(readBigInt(Uint8List.fromList(le)), expected);
      });
    }
  });

  group('DateTime', () {
    test('without milliseconds', () {
      final buffer = view(bytes(8)..setFloat64(0, 32234.51375, Endian.little));
      expect(
        readDateTime(buffer).toIso8601String(),
        '1988-04-01T12:19:48.000Z',
      );
    });

    test('with milliseconds', () {
      final buffer = view(
        bytes(8)..setFloat64(0, 32234.513755787, Endian.little),
      );
      expect(
        readDateTime(buffer).toIso8601String(),
        '1988-04-01T12:19:48.500Z',
      );
    });

    // Not upstream: JavaScript would return an invalid Date.
    for (final value in [double.nan, double.infinity, 2e8, 1e300]) {
      test('rejects $value', () {
        final buffer = view(bytes(8)..setFloat64(0, value, Endian.little));
        expect(() => readDateTime(buffer), throwsA(isA<MdbFormatException>()));
      });
    }
  });

  group('DateTimeExtended', () {
    for (final (buffer, date) in [
      (
        '0000000000000000000:0000000000000000000:7 ',
        '0001.01.01 00:00:00.000000000',
      ),
      (
        '0000000000000365240:0000000452967891234:7 ',
        '1000.12.30 12:34:56.789123400',
      ),
      (
        '0000000000000738153:0000000452967891234:7 ',
        '2021.12.30 12:34:56.789123400',
      ),
      (
        '0000000000003287180:0000000452967891234:7 ',
        '9000.12.30 12:34:56.789123400',
      ),
    ]) {
      test('can read $buffer', () {
        expect(buffer, hasLength(42));
        expect(
          readDateTimeExtended(Uint8List.fromList(ascii.encode(buffer))),
          date,
        );
      });
    }

    test('rejects non-numeric text', () {
      expect(
        () => readDateTimeExtended(Uint8List.fromList(ascii.encode('x' * 42))),
        throwsA(isA<MdbFormatException>()),
      );
    });
  });

  group('RepID', () {
    // hexbuffer from v1.0.6 results, expectedResult from Access UI
    for (final (hexbuffer, expectedResult) in [
      (
        [
          0x9c,
          0xd8,
          0x5c,
          0xf7,
          0xdb,
          0xf0,
          0x9f,
          0x40,
          0xb6,
          0x47,
          0xf5,
          0x00,
          0xa8,
          0x83,
          0x16,
          0xf0,
        ],
        'F75CD89C-F0DB-409F-B647-F500A88316F0',
      ),
      (
        [
          0x58,
          0xfe,
          0x2e,
          0x52,
          0xea,
          0x2f,
          0xa3,
          0x45,
          0x9b,
          0x66,
          0x07,
          0x39,
          0x2a,
          0x40,
          0x61,
          0xdf,
        ],
        '522EFE58-2FEA-45A3-9B66-07392A4061DF',
      ),
      (
        [
          0x10,
          0x2c,
          0x51,
          0x78,
          0x61,
          0x50,
          0x00,
          0x4e,
          0x8c,
          0x8f,
          0x42,
          0xab,
          0xda,
          0xc6,
          0x8e,
          0x7e,
        ],
        '78512C10-5061-4E00-8C8F-42ABDAC68E7E',
      ),
      (
        [
          0x46,
          0xaf,
          0xae,
          0xf5,
          0xfb,
          0xe0,
          0x29,
          0x47,
          0xa0,
          0xec,
          0xa8,
          0x7e,
          0x1a,
          0x11,
          0x94,
          0x55,
        ],
        'F5AEAF46-E0FB-4729-A0EC-A87E1A119455',
      ),
      (
        [
          0x45,
          0xbe,
          0xf7,
          0xda,
          0xc9,
          0xce,
          0xfd,
          0x43,
          0x83,
          0x4e,
          0x13,
          0x25,
          0xb6,
          0x1a,
          0xcf,
          0xca,
        ],
        'DAF7BE45-CEC9-43FD-834E-1325B61ACFCA',
      ),
      (
        [
          0x99,
          0xbb,
          0xf7,
          0x5c,
          0x9e,
          0x3f,
          0x54,
          0x49,
          0xa5,
          0x09,
          0x5f,
          0x96,
          0xa2,
          0x2b,
          0x1d,
          0x70,
        ],
        '5CF7BB99-3F9E-4954-A509-5F96A22B1D70',
      ),
    ]) {
      test('reads $expectedResult', () {
        expect(
          readRepID(Uint8List.fromList(hexbuffer)),
          expectedResult.toLowerCase(),
        );
      });
    }
  });
}
