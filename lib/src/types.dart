// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/types.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

/// The type of a column.
///
/// The Dart type of a value read from each column type:
///
/// | Column type        | Dart type          |
/// | ------------------ | ------------------ |
/// | [bigInt]           | [BigInt]           |
/// | [binary]           | [Uint8List]        |
/// | [boolean]          | [bool]             |
/// | [byte]             | [int]              |
/// | [complex]          | `List<Attachment>` |
/// | [currency]         | [String]           |
/// | [dateTime]         | [DateTime] (UTC)   |
/// | [dateTimeExtended] | [String]           |
/// | [double]           | [double]           |
/// | [float]            | [double]           |
/// | [integer]          | [int]              |
/// | [long]             | [int]              |
/// | [memo]             | [String]           |
/// | [numeric]          | [String]           |
/// | [ole]              | [Uint8List]        |
/// | [repId]            | [String]           |
/// | [text]             | [String]           |
///
/// Null values are always `null`.
enum ColumnType {
  boolean('boolean'),
  byte('byte'),
  integer('integer'),
  long('long'),
  currency('currency'),
  float('float'),
  double('double'),
  dateTime('datetime'),
  binary('binary'),
  text('text'),
  ole('ole'),
  memo('memo'),
  repId('repid'),
  numeric('numeric'),
  complex('complex'),
  bigInt('bigint'),
  dateTimeExtended('datetimextended');

  const ColumnType(this.value);

  /// The name mdb-reader uses for this type.
  final String value;
}

/// A decoded item of a complex (attachment) column.
class Attachment {
  Attachment({
    required this.name,
    required this.type,
    required this.data,
    this.url,
    this.timestamp,
    this.flags,
  });

  /// Original file name.
  final String name;

  /// File extension or MIME type.
  final String type;

  /// Decoded file bytes.
  final Uint8List data;

  /// URL, if the attachment was linked.
  final String? url;

  /// Modification timestamp, if stored.
  final DateTime? timestamp;

  /// Flags, if stored and non-zero.
  final int? flags;

  @override
  String toString() =>
      'Attachment(name: $name, type: $type, ${data.length} bytes)';
}

/// A sort order (collation) of a database.
class SortOrder {
  const SortOrder({required this.value, required this.version});

  final int value;
  final int version;

  @override
  bool operator ==(Object other) =>
      other is SortOrder && other.value == value && other.version == version;

  @override
  int get hashCode => Object.hash(value, version);

  @override
  String toString() => 'SortOrder(value: $value, version: $version)';
}
