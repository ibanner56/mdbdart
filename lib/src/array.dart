// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/array.ts at 4e08263; see THIRD_PARTY_NOTICES.md

// Decimal digit arrays, least significant digit first, used to format
// currency and numeric values without 64-bit or 128-bit integer arithmetic.

import 'errors.dart';

List<int> doCarry(List<int> values) {
  final result = List<int>.of(values);
  final length = result.length;

  for (var i = 0; i < length - 1; ++i) {
    result[i + 1] += result[i] ~/ 10;
    result[i] %= 10;
  }
  result[length - 1] %= 10;

  return result;
}

List<int> multiplyArray(List<int> a, List<int> b) {
  if (a.length != b.length) {
    throw MdbFormatException('Array a and b must have the same length');
  }

  final result = List<int>.filled(a.length * 2, 0);
  for (var i = 0; i < a.length; ++i) {
    if (a[i] == 0) continue;
    for (var j = 0; j < b.length; j++) {
      result[i + j] += a[i] * b[j];
    }
  }
  return doCarry(result.sublist(0, a.length));
}

List<int> addArray(List<int> a, List<int> b) {
  if (a.length != b.length) {
    throw MdbFormatException('Array a and b must have the same length');
  }
  final length = a.length;

  final result = List<int>.filled(length, 0);
  for (var i = 0; i < length; ++i) {
    result[i] = a[i] + b[i];
  }
  return doCarry(result);
}

List<int> toArray(int v, int length) {
  return doCarry([v, ...List<int>.filled(length - 1, 0)]);
}
