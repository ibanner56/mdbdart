/// A pure-Dart, read-only reader for Microsoft Access databases (.mdb and
/// .accdb).
///
/// ```dart
/// final reader = MdbReader(bytes);
/// for (final name in reader.getTableNames()) {
///   final table = reader.getTable(name);
///   print('$name: ${table.getColumnNames()}');
///   for (final row in table.getData()) {
///     print(row);
///   }
/// }
/// ```
///
/// This library does not import `dart:io`, so it works on every platform,
/// including the web. To read a file from disk, see `package:mdbdart/io.dart`.
library;

export 'src/column.dart' show Column;
export 'src/errors.dart';
export 'src/mdb_reader.dart' show MdbReader;
export 'src/table.dart' show Table;
export 'src/types.dart' show Attachment, ColumnType, SortOrder;
