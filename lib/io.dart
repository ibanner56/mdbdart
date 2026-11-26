/// Convenience loaders that read a database file from disk with `dart:io`.
///
/// Not available on the web; use `MdbReader(bytes)` from
/// `package:mdbdart/mdbdart.dart` there.
library;

import 'dart:io';

import 'mdbdart.dart';

export 'mdbdart.dart';

/// Reads the database file at [path].
///
/// Throws a [FileSystemException] if the file cannot be read and an
/// [MdbException] if it is not a database mdbdart can read.
Future<MdbReader> openMdbFile(String path) async {
  final bytes = await File(path).readAsBytes();
  return MdbReader(bytes);
}

/// Synchronous version of [openMdbFile].
MdbReader openMdbFileSync(String path) {
  return MdbReader(File(path).readAsBytesSync());
}
