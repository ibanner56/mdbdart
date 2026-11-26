// Runs representative fixture checks in a browser, where Dart integers are
// JavaScript numbers and bitwise operators work on 32 bits. Not ported; the
// expected values are the ones upstream asserts (see the other tests).

@TestOn('browser')
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:mdbdart/mdbdart.dart';
import 'package:test/test.dart';

Future<Uint8List> fixture(String path) async {
  final channel = spawnHybridUri('hybrid_read_fixture.dart', message: path);
  final data = await channel.stream.first;
  return Uint8List.fromList((data as List<Object?>).cast<int>());
}

void main() {
  test('Table1 of every version', () async {
    for (final (filename, reverse) in [
      ('V1997/test.mdb', true),
      ('V2000/test.mdb', false),
      ('V2003/test.mdb', false),
      ('V2007/test.accdb', true),
      ('V2010/test.accdb', true),
    ]) {
      final reader = MdbReader(await fixture(filename));
      expect(reader.getTableNames(), ['Table1', 'Table2', 'Table3', 'Table4']);
      var rows = reader.getTable('Table1').getData();
      if (reverse) rows = rows.reversed.toList();
      expect(rows[0]['A'], 'abcdefg', reason: filename);
      expect(rows[0]['E'], 333333333);
      expect(rows[0]['F'], 444.555);
      expect((rows[0]['G'] as DateTime).millisecondsSinceEpoch, 148953600000);
      expect(rows[0]['H'], '3.5000');
      expect(rows[0]['I'], true);
      expect(rows[1]['H'], '0.0000');
      expect(rows[1]['I'], false);
    }
  });

  test('numeric', () async {
    for (final filename in [
      'V2000/numeric.mdb',
      'V2003/numeric.mdb',
      'V2007/numeric.accdb',
      'V2010/numeric.accdb',
    ]) {
      final row = MdbReader(
        await fixture(filename),
      ).getTable('test').getData().single;
      expect(
        [for (var i = 2; i <= 7; i++) row['col$i']],
        ['1', '0', '0', '4', '-1', '1'],
        reason: filename,
      );
    }
  });

  test('currency and bigint', () async {
    final currency = MdbReader(await fixture('V2016/currency.accdb'));
    expect(currency.getTable('Table').getData().single['Money'], '42.0000');
    final bigint = MdbReader(await fixture('V2016/bigint.accdb'));
    expect(
      bigint.getTable('Table').getData().single['Numeric'],
      BigInt.from(42),
    );
  });

  test('attachments', () async {
    final reader = MdbReader(await fixture('V2016/attachments.accdb'));
    final rows = reader.getTable('Table1').getData();
    final three = rows.singleWhere((r) => r['Comment'] == '3 Attachments');
    final attachments = (three['Attachments'] as List<Object?>)
        .cast<Attachment>();
    expect(
      [for (final a in attachments) utf8.decode(a.data)],
      ['Attachment 1', 'Attachment 2', 'Attachment 3'],
    );
  });

  test('OLE, long text and creation date', () async {
    final ole = MdbReader(await fixture('V2007/ole.accdb'));
    final payload = ole
        .getTable('Table1')
        .getData()
        .singleWhere((r) => r['ID'] == 2)['ole_data'];
    expect((payload as Uint8List).length, 94602);
    final longText = MdbReader(await fixture('V2016/longtext.accdb'));
    expect(
      (longText.getTable('Table1').getData()[0]['LongText'] as String).length,
      5000,
    );
    final created = MdbReader(await fixture('creation-date/V2010.accdb'));
    expect(
      created.getCreationDate(),
      DateTime.utc(2022, 1, 7, 16, 20, 39, 512),
    );
  });

  test('system tables and flags', () async {
    final reader = MdbReader(await fixture('V2010/test.accdb'));
    final system = reader.getTableNames(
      normalTables: false,
      systemTables: true,
    );
    expect(system, contains('MSysObjects'));
    expect(system, isNot(contains('Table1')));
  });

  test('encrypted database', () async {
    final bytes = await fixture('encryption/office-agile-4.4.accdb');
    expect(() => MdbReader(bytes), throwsA(isA<MdbEncryptedException>()));
  });
}
