// Ported from mdb-reader (MIT, Copyright (c) 2020 Andi Pätzold), src/array.spec.ts at 4e08263; see THIRD_PARTY_NOTICES.md

import 'package:mdbdart/src/array.dart';
import 'package:test/test.dart';

void main() {
  group('doCarry', () {
    for (final (input, output) in [
      ([0, 0, 0], [0, 0, 0]),
      ([1, 2, 3], [1, 2, 3]),
      ([9, 9, 9], [9, 9, 9]),
    ]) {
      test('does not carry if all < 10: $input', () {
        expect(doCarry(input), output);
      });
    }

    for (final (input, output) in [
      ([10, 0, 0], [0, 1, 0]),
      ([0, 20, 0], [0, 0, 2]),
      ([13, 25, 0], [3, 6, 2]),
      ([100, 0, 0], [0, 0, 1]),
      ([111, 0, 0], [1, 1, 1]),
    ]) {
      test('carries over: $input', () {
        expect(doCarry(input), output);
      });
    }

    for (final (input, output) in [
      ([1000, 0, 0], [0, 0, 0]),
      ([1111, 0, 0], [1, 1, 1]),
      ([1111, 222, 0], [1, 3, 3]),
    ]) {
      test('cuts overflow and keeps array length: $input', () {
        expect(doCarry(input), output);
      });
    }
  });

  group('multiplyArray', () {
    for (final (a, b, output) in [
      ([0, 0, 0], [5, 0, 0], [0, 0, 0]),
      ([1, 1, 1], [5, 0, 0], [5, 5, 5]),
      ([2, 4, 3], [2, 0, 0], [4, 8, 6]),
      ([2, 4, 3], [0, 0, 0], [0, 0, 0]),
      ([2, 2, 0], [5, 5, 5], [0, 1, 2]),
      ([5, 5, 0], [10, 0, 0], [0, 5, 5]),
      ([3, 4, 4], [5, 6, 7], [5, 9, 8]),
    ]) {
      test('multiply without carry: $a * $b', () {
        expect(multiplyArray(a, b), output);
      });
    }
  });
}
