// Prints every user table of an Access database.
//
// Usage: dart run example/mdbdart_example.dart path/to/database.mdb

import 'dart:io';

import 'package:mdbdart/io.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart run example/mdbdart_example.dart <file>');
    exitCode = 64;
    return;
  }

  final MdbReader reader;
  try {
    reader = openMdbFileSync(arguments.single);
  } on MdbEncryptedException catch (e) {
    stderr.writeln('Encrypted databases are not supported: ${e.message}');
    exitCode = 1;
    return;
  } on MdbException catch (e) {
    stderr.writeln('Cannot read ${arguments.single}: ${e.message}');
    exitCode = 1;
    return;
  }

  for (final name in reader.getTableNames()) {
    final table = reader.getTable(name);
    print('$name (${table.rowCount} rows)');
    for (final column in table.getColumns()) {
      print('  ${column.name}: ${column.type.value}');
    }
    for (final row in table.getData(rowLimit: 5)) {
      print('  $row');
    }
  }
}
