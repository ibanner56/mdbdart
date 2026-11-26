// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/longValue.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:convert';
import 'dart:typed_data';

import 'package:mdbdart/src/data/memo.dart';
import 'package:mdbdart/src/data/ole.dart';
import 'package:mdbdart/src/errors.dart';
import 'package:mdbdart/src/jet_format/jet_format.dart';
import 'package:test/test.dart';

Uint8List header(int length, [int pointer = 256]) {
  final data = ByteData(12)
    ..setUint8(0, length & 0xff)
    ..setUint8(1, (length >> 8) & 0xff)
    ..setUint8(2, (length >> 16) & 0xff)
    ..setUint32(4, pointer, Endian.little);
  return data.buffer.asUint8List();
}

Uint8List row(int next, [String payload = 'ab']) {
  final data = ByteData(4)..setUint32(0, next, Endian.little);
  return Uint8List.fromList([
    ...data.buffer.asUint8List(),
    ...ascii.encode(payload),
  ]);
}

/// Stands in for upstream's stubbed database object.
class _Rows implements LongValueSource {
  _Rows(this.rows, this.limit);

  final Map<int, Uint8List> rows;
  final int limit;
  int lookups = 0;

  @override
  Uint8List findPageRow(int pageRow) {
    if (++lookups > limit) {
      throw StateError('Lookup limit exceeded');
    }
    final buffer = rows[pageRow];
    if (buffer == null) {
      throw StateError('Unexpected lookup $pageRow');
    }
    return buffer;
  }

  @override
  void chargeLongValue(int bytes) {}
}

void main() {
  for (final kind in ['OLE', 'Memo']) {
    String read(Uint8List headerBuffer, LongValueSource source) {
      if (kind == 'OLE') {
        return latin1.decode(readOLE(headerBuffer, source));
      }
      return readMemo(headerBuffer, source, TextEncoding.unknown);
    }

    group('$kind long-value chains', () {
      String decode(int length, Map<int, Uint8List> rows, [int pointer = 256]) {
        return read(header(length, pointer), _Rows(rows, rows.length));
      }

      for (final (name, links, repeated) in [
        ('self-loop', [(256, 256)], 256),
        ('two-row cycle', [(256, 512), (512, 256)], 256),
        ('cycle after a prefix', [(256, 512), (512, 768), (768, 512)], 512),
        ('unsigned pointer cycle', [(0x80000100, 0x80000100)], 0x80000100),
      ]) {
        test('rejects a $name before fetching a row twice', () {
          final rows = {
            for (final (pointer, next) in links) pointer: row(next),
          };
          expect(
            () => decode(10, rows, links[0].$1),
            throwsA(
              isA<MdbFormatException>().having(
                (e) => e.message,
                'message',
                'Cyclic $kind long-value chain at page-row $repeated',
              ),
            ),
          );
        });
      }

      for (final length in [0, 1, 2, 3, 4]) {
        test('rejects a row of $length bytes without payload', () {
          expect(
            () => decode(10, {256: Uint8List(length)}),
            throwsA(
              isA<MdbFormatException>().having(
                (e) => e.message,
                'message',
                'Invalid $kind long-value row: no payload',
              ),
            ),
          );
        });
      }

      test('returns an empty value without lookups', () {
        expect(decode(0, {}), '');
      });

      test('preserves early null termination', () {
        expect(
          decode(4, {256: row(0)}),
          kind == 'OLE' ? 'ab\u0000\u0000' : 'ab',
        );
      });

      for (final trailing in [256, 999]) {
        test('ignores trailing pointer $trailing after exact completion', () {
          expect(decode(4, {256: row(257), 257: row(trailing, 'cd')}), 'abcd');
        });
      }

      test('reads distinct rows on the same page', () {
        expect(
          decode(6, {256: row(257), 257: row(258, 'cd'), 258: row(0, 'ef')}),
          'abcdef',
        );
      });

      test('permits independent reads of the same chain', () {
        final source = _Rows({256: row(257), 257: row(0, 'cd')}, 4);
        for (var i = 0; i < 2; i++) {
          expect(read(header(4), source), 'abcd');
        }
        expect(source.lookups, 4);
      });

      test('reads initial and continuation pointers as unsigned', () {
        expect(
          decode(4, {
            0x80000100: row(0x80000101),
            0x80000101: row(0, 'cd'),
          }, 0x80000100),
          'abcd',
        );
      });

      test('preserves final chunk overflow handling', () {
        expect(
          decode(3, {256: row(257), 257: row(999, 'cd')}),
          kind == 'OLE' ? 'abc' : 'ab',
        );
      });
    });
  }
}
