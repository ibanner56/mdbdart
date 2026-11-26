// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), test/complex.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:convert';

import 'package:mdbdart/mdbdart.dart';
import 'package:test/test.dart';

import 'helpers.dart';

Matcher isAttachment(String name, String type, String data) => isA<Attachment>()
    .having((a) => a.name, 'name', name)
    .having((a) => a.type, 'type', type)
    .having((a) => a.data, 'data', utf8.encode(data))
    .having((a) => a.url, 'url', isNull)
    .having((a) => a.timestamp, 'timestamp', isNull)
    .having((a) => a.flags, 'flags', isNull);

void main() {
  group('Complex V2016/attachments.accdb', () {
    test('should read the attachment column', () {
      final reader = MdbReader(readFixture('V2016/attachments.accdb'));
      final table = reader.getTable('Table1');
      final rows = table.getData();

      Map<String, Object?> find(String comment) =>
          rows.singleWhere((r) => r['Comment'] == comment);

      expect(find('0 Attachments')['Attachments'], isEmpty);
      expect(find('1 Attachment')['Attachments'], [
        isAttachment('attachment1.txt', 'txt', 'Attachment 1'),
      ]);
      expect(find('3 Attachments')['Attachments'], [
        isAttachment('attachment1.txt', 'txt', 'Attachment 1'),
        isAttachment('attachment2.txt', 'txt', 'Attachment 2'),
        isAttachment('attachment3.txt', 'txt', 'Attachment 3'),
      ]);
    });
  });
}
