# mdbdart

A pure-Dart, read-only reader for Microsoft Access databases (`.mdb` and
`.accdb`). It needs no Microsoft software, ODBC driver or native code, has no
runtime dependencies, and its core library does not import `dart:io`, so it
can be used from Flutter apps and on the web. The tests run on the Dart VM and
in Chrome.

mdbdart is a port of [mdb-reader](https://github.com/andipaetzold/mdb-reader)
by Andi Pätzold (MIT). See [Attribution](#attribution).

## Supported files

| Access version   | Format | Covered by test files |
| ---------------- | ------ | --------------------- |
| Access 97        | Jet 3  | yes                   |
| Access 2000–2003 | Jet 4  | yes                   |
| Access 2007      | ACE 12 | yes                   |
| Access 2010      | ACE 14 | yes                   |
| Access 2013      | ACE 15 | no                    |
| Access 2016      | ACE 16 | yes                   |
| Access 2019      | ACE 17 | no                    |

ACE 15 and ACE 17 files are read with the same format rules as ACE 14 and
ACE 16, as mdb-reader does, but no test file covers them.

**Encryption is not supported yet.** Opening a Jet-encoded or
Office-encrypted database throws `MdbEncryptedException`. A Jet 4 database
password without encoding does not encrypt the data, so such files can be
read, and `getPassword()` returns the password. (A Jet 3 file with a password
is not covered by tests.)

mdbdart only reads databases; it cannot write them.

## Usage

```dart
import 'dart:typed_data';

import 'package:mdbdart/mdbdart.dart';

void printTables(Uint8List bytes) {
  final reader = MdbReader(bytes);

  print(reader.getTableNames()); // [Cats, Dogs, Cars]

  final table = reader.getTable('Cats');
  print(table.getColumnNames()); // [id, name, color]
  print(table.getData()); // [{id: 5, name: Ashley, color: black}, ...]

  // A page of rows, and only some columns:
  table.getData(columns: ['name'], rowOffset: 10, rowLimit: 10);
}
```

On platforms with `dart:io`, `package:mdbdart/io.dart` adds `openMdbFile` and
`openMdbFileSync`, which read the file and return an `MdbReader`. See
[`example/`](example/mdbdart_example.dart).

`getTableNames()` lists user tables. Pass `systemTables: true` to include
system tables (`MSys*`) or `linkedTables: true` to include linked tables.

### Values

`Table.getData()` returns one `Map<String, Object?>` per row, keyed by column
name. Null values are `null`.

| Column type (`ColumnType`) | Dart type          |
| -------------------------- | ------------------ |
| `bigInt`                   | `BigInt`           |
| `binary`, `ole`            | `Uint8List`        |
| `boolean`                  | `bool`             |
| `byte`, `integer`, `long`  | `int`              |
| `complex` (attachments)    | `List<Attachment>` |
| `currency`, `numeric`      | `String`           |
| `dateTime`                 | `DateTime` in UTC  |
| `dateTimeExtended`         | `String`           |
| `double`, `float`          | `double`           |
| `memo`, `text`             | `String`           |
| `repId`                    | `String`           |

Currency and numeric values are decimal strings such as `"3.5000"`, so no
precision is lost. Big integers are `BigInt` so they are exact on the web too.

Date/time values are stored without a time zone. mdbdart returns them as UTC
`DateTime`s whose fields are the stored wall-clock time; do not convert them
with `toLocal()` unless you know the database stored UTC.

### Errors

Every exception mdbdart throws is an `MdbException`:

- `MdbFormatException`: the file is malformed, truncated or corrupt.
- `MdbUnsupportedException`: an unsupported version or column type.
- `MdbEncryptedException` (an `MdbUnsupportedException`): the database is
  encrypted.
- `MdbNotFoundException`: no table or column with the requested name.

Files are treated as untrusted input: reads are bounds-checked and page and
long-value chains are checked for cycles. The tests read truncated and
randomly corrupted copies of the test databases and check that only
`MdbException`s are thrown.

## Differences from mdb-reader

- Encrypted databases throw `MdbEncryptedException` instead of being
  decrypted, so there is no `password` option.
- Dates are UTC `DateTime`s, big integers are `BigInt`s, and binary values are
  `Uint8List` copies rather than views of the input.
- Malformed files throw typed exceptions in a few places where mdb-reader
  would return a garbled value.

## Development

```sh
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test               # VM
dart test -p chrome     # browser
```

## Attribution

mdbdart is a port of [mdb-reader](https://github.com/andipaetzold/mdb-reader)
(MIT, Copyright (c) 2020 Andi Pätzold), from commit `4e08263`. The test
databases are copied from mdb-reader. See
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the licence texts.

## License

mdbdart is licensed under the [GNU Affero General Public License v3.0 only](LICENSE)
(AGPL-3.0-only), with the additional permission in
[LICENSE-EXCEPTION.md](LICENSE-EXCEPTION.md) for distribution through app
stores. The parts derived from mdb-reader keep mdb-reader's MIT notice, which
is in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
