// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/Database.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'dart:typed_data';

import 'bytes.dart';
import 'codec_handler/create.dart';
import 'crypto/rc4.dart';
import 'data/memo.dart';
import 'data/datetime.dart';
import 'errors.dart';
import 'jet_format/jet_format.dart';
import 'page_type.dart';
import 'types.dart';
import 'unicode_compression.dart';
import 'util.dart';

const _passwordOffset = 0x42;

class Database implements LongValueSource {
  Database(Uint8List buffer) : _buffer = buffer {
    assertPageType(_buffer, PageType.databaseDefinitionPage);

    format = getJetFormat(_buffer);

    // Copy the first page so that decrypting the header leaves the input
    // untouched. A file shorter than one page is zero-padded, as upstream's
    // Buffer.alloc + copy does.
    _databaseDefinitionPage = Uint8List(format.pageSize);
    final firstPageLength = _buffer.length < format.pageSize
        ? _buffer.length
        : format.pageSize;
    _databaseDefinitionPage.setRange(0, firstPageLength, _buffer);
    _decryptHeader(_databaseDefinitionPage, format);
    _codecHandler = createCodecHandler(_databaseDefinitionPage);

    if (!_codecHandler.verifyPassword()) {
      throw MdbEncryptedException('Wrong password');
    }
  }

  final Uint8List _buffer;
  late final JetFormat format;
  late final CodecHandler _codecHandler;
  late final Uint8List _databaseDefinitionPage;

  /// Nesting depth of complex-column reads. Not upstream: guards against a
  /// hostile file whose attachment table refers back to itself.
  int complexReadDepth = 0;

  /// Nesting depth of [Table.getData] calls. Not upstream: the budgets below
  /// are per top-level call, shared by the nested reads that complex columns
  /// make.
  int _readDepth = 0;
  int _longValueBudget = 0;
  int _inflateBudget = 0;

  /// Rows of tables read while resolving complex columns, cached for the
  /// duration of one top-level read. Not upstream: upstream re-reads them for
  /// every cell.
  final Map<Object, Object> readCache = {};

  /// Slack on top of the file size for long values. Upstream zero-pads a
  /// long value whose chain ends a few bytes early.
  static const longValueSlack = 1024 * 1024;

  /// Runs [read] as one read, so that budgets and caches are shared by the
  /// reads nested inside it.
  T withinRead<T>(T Function() read) {
    if (_readDepth == 0) {
      _longValueBudget = _buffer.length + longValueSlack;
      _inflateBudget = _buffer.length * 16 > 256 * 1024 * 1024
          ? _buffer.length * 16
          : 256 * 1024 * 1024;
    }
    _readDepth++;
    try {
      return read();
    } finally {
      _readDepth--;
      if (_readDepth == 0) {
        readCache.clear();
      }
    }
  }

  /// Not upstream. Each long value (memo, OLE) is stored once in the file,
  /// so in a valid database the long values one read returns add up to at
  /// most the file size. A hostile file can point many rows at one chain or
  /// declare lengths its chain does not hold; this stops that from
  /// allocating more than the file size (plus [longValueSlack]) per read.
  @override
  void chargeLongValue(int bytes) {
    if (_readDepth == 0) {
      return;
    }
    _longValueBudget -= bytes;
    if (_longValueBudget < 0) {
      throw MdbFormatException(
        'Long values in this read exceed the size of the file',
      );
    }
  }

  /// Not upstream. Bounds the decompressed attachment data one read
  /// produces: at most 16 times the file size, and at least 256 MiB.
  void chargeInflate(int bytes) {
    if (_readDepth == 0) {
      return;
    }
    _inflateBudget -= bytes;
    if (_inflateBudget < 0) {
      throw MdbFormatException(
        'Decompressed attachments in this read exceed the size limit',
      );
    }
  }

  /// Number of pages in the file, counting a partial last page.
  int get pageCount =>
      (_buffer.length + format.pageSize - 1) ~/ format.pageSize;

  String? getPassword() {
    var passwordBuffer = slice(
      _databaseDefinitionPage,
      _passwordOffset,
      _passwordOffset + format.databaseDefinitionPage.passwordSize,
    );

    final mask = _getPasswordMask();
    if (mask != null) {
      passwordBuffer = xor(passwordBuffer, mask);
    }

    if (isEmptyBuffer(passwordBuffer)) {
      return null;
    }

    var password = uncompressText(passwordBuffer, format.textEncoding);
    final nullCharIndex = password.indexOf('\u0000');
    if (nullCharIndex >= 0) {
      password = password.substring(0, nullCharIndex);
    }
    return password;
  }

  Uint8List? _getPasswordMask() {
    final creationDateOffset = format.databaseDefinitionPage.creationDateOffset;
    if (creationDateOffset == null) {
      return null;
    }

    final mask = Uint8List(format.databaseDefinitionPage.passwordSize);
    final dateValue = readFloat64LE(
      _databaseDefinitionPage,
      creationDateOffset,
    );
    // Node's writeInt32LE writes 0 for NaN and throws for values outside the
    // 32-bit range.
    final floored = dateValue.isNaN ? 0.0 : dateValue.floorToDouble();
    if (floored < -0x80000000 || floored > 0x7fffffff) {
      throw MdbFormatException(
        'Creation date $dateValue cannot be used as a password mask',
      );
    }
    mask.setRange(0, 4, intToBuffer(floored.toInt()));
    for (var i = 0; i < mask.length; ++i) {
      mask[i] = mask[i % 4];
    }
    return mask;
  }

  DateTime? getCreationDate() {
    final creationDateOffset = format.databaseDefinitionPage.creationDateOffset;
    if (creationDateOffset == null) {
      return null;
    }

    final creationDateBuffer = slice(
      _databaseDefinitionPage,
      creationDateOffset,
      creationDateOffset + 8,
    );
    return readDateTime(creationDateBuffer);
  }

  SortOrder getDefaultSortOrder() {
    final sortOrderFormat = format.databaseDefinitionPage;
    final value = readUint16LE(
      _databaseDefinitionPage,
      sortOrderFormat.defaultSortOrderOffset + 3,
    );

    if (value == 0) {
      return format.defaultSortOrder;
    }

    var version = format.defaultSortOrder.version;
    if (sortOrderFormat.defaultSortOrderSize == 4) {
      version = readUint8(
        _databaseDefinitionPage,
        sortOrderFormat.defaultSortOrderOffset + 3,
      );
    }

    return SortOrder(value: value, version: version);
  }

  Uint8List getPage(int page) {
    if (page == 0) {
      // already decrypted
      return _databaseDefinitionPage;
    }

    final offset = page * format.pageSize;
    if (page < 0 || _buffer.length < offset) {
      throw MdbFormatException('Page $page does not exist');
    }

    final pageBuffer = slice(_buffer, offset, offset + format.pageSize);
    return _codecHandler.decryptPage(pageBuffer, page);
  }

  /// [pageRow]: the lower byte contains the row number, the upper three
  /// contain the page. Read as unsigned.
  ///
  /// See mdbtools src/libmdb/data.c, mdb_find_pg_row.
  @override
  Uint8List findPageRow(int pageRow) {
    final page = pageRow ~/ 256;
    final row = pageRow & 0xff;

    final pageBuffer = getPage(page);
    return findRow(pageBuffer, row);
  }

  /// [pageBuffer]: buffer of a data page.
  ///
  /// See mdbtools src/libmdb/data.c, mdb_find_row.
  Uint8List findRow(Uint8List pageBuffer, int row) {
    final rco = format.dataPage.recordCountOffset;

    if (row > 1000) {
      throw MdbFormatException('Cannot read rows > 1000');
    }

    final start = readUint16LE(pageBuffer, rco + 2 + row * 2);
    final nextStart = row == 0
        ? format.pageSize
        : readUint16LE(pageBuffer, rco + row * 2);

    return slice(pageBuffer, start, nextStart);
  }
}

const _encryptionStart = 0x18;
const _encryptionKey = [0xc7, 0xda, 0x39, 0x6b];

void _decryptHeader(Uint8List buffer, JetFormat format) {
  final decryptedBuffer = decryptRC4(
    Uint8List.fromList(_encryptionKey),
    slice(
      buffer,
      _encryptionStart,
      _encryptionStart + format.databaseDefinitionPage.encryptedSize,
    ),
  );
  buffer.setRange(
    _encryptionStart,
    _encryptionStart + decryptedBuffer.length,
    decryptedBuffer,
  );
}
