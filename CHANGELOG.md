# Changelog

## 0.1.0

- Initial release: a read-only port of mdb-reader (commit `4e08263`).
- Reads Jet 3, Jet 4 and ACE 12–17 databases: table and column listing, and
  rows of every column type mdb-reader supports.
- Encrypted databases throw `MdbEncryptedException`.
- `package:mdbdart/io.dart` adds file loaders for platforms with `dart:io`.
