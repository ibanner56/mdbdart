// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/data/util.ts at 4e08263; see THIRD_PARTY_NOTICES.md

/// Formats a decimal digit array (least significant digit first) with
/// [scale] digits after the decimal point.
///
/// See mdbtools src/libmdb/money.c, array_to_string.
String buildValue(List<int> array, int scale, bool negative) {
  final length = array.length;

  final value = StringBuffer();
  if (negative) {
    value.write('-');
  }

  var top = length;
  while (top > 0 && top - 1 > scale && array[top - 1] == 0) {
    top--;
  }

  if (top == 0) {
    value.write('0');
  } else {
    for (var i = top; i > 0; i--) {
      if (i == scale) {
        value.write('.');
      }
      value.write(array[i - 1]);
    }
  }

  return value.toString();
}
