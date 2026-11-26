// Hostile-input tests for mdbdart. Not ported: upstream has no equivalent
// beyond the cycle tests ported in table_test.dart, longtext_test.dart and
// ole_test.dart.
//
// Every file is untrusted input. Reading a truncated or corrupted copy of a
// fixture must either succeed or throw an MdbException; it must never throw
// any other error, hang, or allocate without bound.

@TestOn('vm')
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:mdbdart/mdbdart.dart';
import 'package:mdbdart/src/data/complex/attachment.dart';
import 'package:mdbdart/src/data/complex/complex.dart';
import 'package:mdbdart/src/column.dart';
import 'package:mdbdart/src/database.dart';
import 'package:mdbdart/src/inflate.dart';
import 'package:mdbdart/src/usage_map.dart';
import 'package:test/test.dart';

import 'helpers.dart';

const fixtures = [
  'V1997/test.mdb',
  'V2000/numeric.mdb',
  'V2003/empty.mdb',
  'creation-date/V2000.mdb',
  'V2007/numeric.accdb',
  'V2010/test.accdb',
  'V2016/attachments.accdb',
  'V2016/longtext.accdb',
  'V2016/bigint.accdb',
  'V2016/currency.accdb',
];

/// Uses every public read API on [bytes]. Returns normally or throws.
void exercise(Uint8List bytes) {
  final reader = MdbReader(bytes);
  reader.getCreationDate();
  reader.getPassword();
  reader.getDefaultSortOrder();
  final names = reader.getTableNames(
    normalTables: true,
    systemTables: true,
    linkedTables: true,
  );
  for (final name in names) {
    try {
      final table = reader.getTable(name);
      table.getColumns();
      table.getData();
    } on MdbNotFoundException {
      // Linked tables are listed but cannot be opened.
    }
  }
}

/// Runs [exercise] and fails the test if it throws anything other than an
/// [MdbException].
void expectOnlyMdbExceptions(Uint8List bytes, String description) {
  try {
    exercise(bytes);
  } on MdbException {
    // Expected for corrupt input.
  } catch (e, stack) {
    fail('$description threw ${e.runtimeType}: $e\n$stack');
  }
}

int pageSizeOf(Uint8List bytes) => bytes[0x14] == 0 ? 2048 : 4096;

const iterations = 300;

/// Pages a read can touch: the header, table definitions, data pages and
/// usage bitmaps. Most pages of the fixtures are unused.
List<int> structuralPages(Uint8List bytes, int pageSize) {
  final pages = <int>[0];
  for (var page = 1; page < bytes.length ~/ pageSize; page++) {
    if (const {1, 2, 5}.contains(bytes[page * pageSize])) {
      pages.add(page);
    }
  }
  return pages;
}

/// Overwrites 1 to 8 bytes of [bytes]. Half of the changes hit the first 64
/// bytes of a page, where page headers and row offset tables live.
List<String> mutate(
  Uint8List bytes,
  int pageSize,
  List<int> targets,
  Random random,
) {
  final changes = <String>[];
  final count = 1 + random.nextInt(8);
  for (var i = 0; i < count; i++) {
    final page = targets[random.nextInt(targets.length)];
    final within = random.nextBool()
        ? random.nextInt(64)
        : random.nextInt(pageSize);
    final offset = page * pageSize + within;
    if (offset >= bytes.length) continue;
    final value = switch (random.nextInt(4)) {
      0 => 0x00,
      1 => 0xff,
      _ => random.nextInt(256),
    };
    bytes[offset] = value;
    changes.add('[$offset]=$value');
  }
  return changes;
}

void main() {
  group('truncated fixtures', () {
    for (final fixture in fixtures) {
      test(fixture, () {
        final original = readFixture(fixture);
        final pageSize = pageSizeOf(original);
        final lengths = <int>{
          0,
          1,
          0x14,
          0x15,
          100,
          pageSize - 1,
          pageSize,
          pageSize + 1,
          2 * pageSize,
          3 * pageSize - 7,
          original.length ~/ 4,
          original.length ~/ 2,
          original.length - pageSize,
          original.length - 1,
        };
        for (final length in lengths) {
          if (length < 0 || length > original.length) continue;
          expectOnlyMdbExceptions(
            Uint8List.sublistView(original, 0, length),
            '$fixture truncated to $length bytes',
          );
        }
      }, timeout: const Timeout(Duration(minutes: 2)));
    }

    test('an empty file throws MdbFormatException', () {
      expect(() => MdbReader(Uint8List(0)), throwsMdb<MdbFormatException>());
    });

    test('a file of one page throws an MdbException', () {
      final bytes = Uint8List.sublistView(
        readFixture('V2010/test.accdb'),
        0,
        4096,
      );
      expect(() => MdbReader(bytes), throwsMdb<MdbException>());
    });

    test('an unknown version throws MdbUnsupportedException', () {
      final bytes = readFixture('V2010/test.accdb');
      bytes[0x14] = 0x42;
      expect(
        () => MdbReader(bytes),
        throwsMdb<MdbUnsupportedException>("Unsupported version '66'"),
      );
    });
  });

  group('corrupted fixtures', () {
    for (final fixture in fixtures) {
      test(fixture, () {
        final original = readFixture(fixture);
        final pageSize = pageSizeOf(original);
        final targets = structuralPages(original, pageSize);
        // Fixed seed per fixture, so failures are reproducible.
        final random = Random(fixture.hashCode ^ 0x5eed);
        for (var iteration = 0; iteration < iterations; iteration++) {
          final bytes = Uint8List.fromList(original);
          final changes = mutate(bytes, pageSize, targets, random);
          expectOnlyMdbExceptions(bytes, '$fixture with ${changes.join(', ')}');
        }
      }, timeout: const Timeout(Duration(minutes: 2)));
    }
  });

  group('usage map bound', () {
    test('a usage map pointing past the end of the file stays bounded', () {
      // A type-1 usage map whose every map page is a usage bitmap with every
      // bit set. Without the bound this lists over 30 million pages.
      final bytes = readFixture('V2010/test.accdb');
      final database = Database(bytes);
      const bitmapPage = 1;
      final page = bitmapPage * 4096;
      bytes[page] = 0x05; // PageType.pageUsageBitmaps
      bytes.fillRange(page + 4, page + 4096, 0xff);
      final mapCount = 1000;
      final usageMap = Uint8List(1 + mapCount * 4)..[0] = 0x01;
      for (var i = 0; i < mapCount; i++) {
        writeUint32LE(usageMap, 1 + i * 4, bitmapPage);
      }

      final pages = findMapPages(usageMap, database);
      expect(pages.length, lessThanOrEqualTo(database.pageCount + mapCount));
      // The first page past the end is kept, so reading fails there.
      expect(pages.where((p) => p >= database.pageCount), isNotEmpty);
    });

    test('reading data from a page past the end throws', () {
      final bytes = readFixture('V2010/test.accdb');
      final database = Database(bytes);
      expect(
        () => database.getPage(database.pageCount + 5),
        throwsMdb<MdbFormatException>('does not exist'),
      );
    });
  });

  group('inflate', () {
    Uint8List compress(List<int> data) =>
        Uint8List.fromList(ZLibEncoder().convert(data));

    test('round-trips data compressed by dart:io', () {
      final random = Random(1);
      final data = [
        for (var i = 0; i < 200000; i++)
          i % 7 == 0 ? random.nextInt(256) : i % 251,
      ];
      expect(zlibInflate(compress(data), maxOutput: data.length), data);
      // Stored (level 0) blocks.
      final stored = Uint8List.fromList(ZLibEncoder(level: 0).convert(data));
      expect(zlibInflate(stored, maxOutput: data.length), data);
    });

    test('stops at maxOutput on a highly compressed stream', () {
      final bomb = compress(Uint8List(20 * 1024 * 1024));
      expect(bomb.length, lessThan(64 * 1024));
      expect(zlibInflate(bomb, maxOutput: 1000), hasLength(1000));
    });

    test('rejects a corrupt checksum', () {
      final stream = compress(List<int>.generate(1000, (i) => i % 256));
      stream[stream.length - 1] ^= 0xff;
      expect(
        () => zlibInflate(stream, maxOutput: 1000),
        throwsMdb<MdbFormatException>('checksum'),
      );
    });

    test('rejects truncated and corrupt streams with MdbException only', () {
      final stream = compress(List<int>.generate(5000, (i) => (i * i) % 256));
      final random = Random(2);
      for (var length = 0; length < stream.length; length += 7) {
        expect(
          () => zlibInflate(
            Uint8List.sublistView(stream, 0, length),
            maxOutput: 5000,
          ),
          throwsMdb<MdbException>(),
        );
      }
      for (var i = 0; i < 2000; i++) {
        final corrupt = Uint8List.fromList(stream);
        corrupt[random.nextInt(corrupt.length)] = random.nextInt(256);
        try {
          zlibInflate(corrupt, maxOutput: 5000);
        } on MdbException {
          // Expected.
        }
      }
    });

    test('decodeAttachmentFileData bounds output by the stored length', () {
      final bomb = compress([
        8, 0, 0, 0, // header length
        ...Uint8List(20 * 1024 * 1024),
      ]);
      final wrapper = Uint8List(8 + bomb.length);
      writeUint32LE(wrapper, 0, 1); // compressed
      writeUint32LE(wrapper, 4, 108); // stored length
      wrapper.setRange(8, wrapper.length, bomb);
      expect(decodeAttachmentFileData(wrapper), hasLength(100));
    });
  });

  group('complex columns', () {
    test('a nested complex read throws instead of recursing', () {
      final database = Database(readFixture('V2016/attachments.accdb'));
      final column = ColumnDefinition(
        name: 'Attachments',
        type: ColumnType.complex,
        size: 4,
        fixedLength: true,
        nullable: true,
        autoLong: false,
        autoUUID: false,
        index: 0,
        variableIndex: 0,
        fixedIndex: 0,
        complex: ComplexColumnInfo(typeId: 1, tableDefinitionPage: 1),
      );
      database.complexReadDepth = 1;
      expect(
        () => readComplex(Uint8List.fromList([1, 0, 0, 0]), column, database),
        throwsMdb<MdbFormatException>('Nested complex column'),
      );
    });
  });
}
