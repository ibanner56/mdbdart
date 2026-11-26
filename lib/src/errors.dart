// Original code for mdbdart; not ported from mdb-reader.

/// Exceptions thrown by mdbdart.
library;

/// Base class of every exception mdbdart throws.
class MdbException implements Exception {
  MdbException(this.message, {this.cause});

  /// A description of the problem.
  final String message;

  /// The underlying exception, if this one wraps another.
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (cause != null) {
      buffer.write(' (caused by: $cause)');
    }
    return buffer.toString();
  }
}

/// The file is malformed, truncated or corrupt.
class MdbFormatException extends MdbException {
  MdbFormatException(super.message, {super.cause});
}

/// The file uses a format version or feature that mdbdart does not support.
class MdbUnsupportedException extends MdbException {
  MdbUnsupportedException(super.message, {super.cause});
}

/// The database is encrypted or encoded. mdbdart cannot decrypt databases
/// yet.
class MdbEncryptedException extends MdbUnsupportedException {
  MdbEncryptedException(super.message, {super.cause});
}

/// A table or column requested by name does not exist.
class MdbNotFoundException extends MdbException {
  MdbNotFoundException(super.message, {super.cause});
}
