import 'package:coding_quest/services/sort_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sorting algorithms', () {
    const input = [9, 3, 7, 1, 8, 2, 5];
    final algorithms = <String, SortRun Function(List<int>)>{
      'bubble': bubbleSort,
      'insertion': insertionSort,
      'selection': selectionSort,
      'quick': quickSort,
    };

    algorithms.forEach((name, sort) {
      test('$name sorts items, records frames and leaves input untouched', () {
        final original = List<int>.of(input);
        final run = sort(input);

        expect(run.result, [1, 2, 3, 5, 7, 8, 9]);
        expect(run.frames, isNotEmpty);
        expect(run.frames.last.values, run.result);
        expect(run.comparisons, greaterThan(0));
        expect(input, original, reason: 'the engine must not mutate its input');
      });
    });

    test('all algorithms handle duplicates and tiny arrays', () {
      const duplicates = [5, 3, 5, 1, 3];
      for (final sort in algorithms.values) {
        expect(sort(duplicates).result, [1, 3, 3, 5, 5]);
        expect(sort(const []).result, isEmpty);
        expect(sort(const [42]).result, [42]);
      }
    });

    test('bubble sort stops early on an already sorted array', () {
      final sortedRun = bubbleSort([1, 2, 3, 4, 5]);
      final reversedRun = bubbleSort([5, 4, 3, 2, 1]);

      expect(
        sortedRun.comparisons,
        lessThan(reversedRun.comparisons),
        reason: 'early exit should reduce comparisons',
      );
      expect(sortedRun.swaps, 0);
    });

    test('insertion sort performs fewer swaps on nearly sorted data', () {
      final nearlySorted = insertionSort([2, 1, 3, 4, 5, 6]);
      expect(nearlySorted.result, [1, 2, 3, 4, 5, 6]);
      expect(nearlySorted.swaps, 1);
    });

    test('frames expose immutable value lists', () {
      final frame = SortFrame(values: [3, 1, 2]);
      expect(() => frame.values.add(4), throwsUnsupportedError);
    });
  });

  group('search algorithms', () {
    const values = [1, 3, 5, 7, 9, 11];

    test('linear search finds existing values and reports missing ones', () {
      final hit = linearSearch(values, 7);
      expect(hit.resultIndex, 3);
      expect(hit.frames.last.found, isTrue);

      final miss = linearSearch(values, 4);
      expect(miss.resultIndex, -1);
      expect(miss.comparisons, values.length);
    });

    test('binary search finds values with fewer comparisons', () {
      final run = binarySearch(values, 11);
      expect(run.resultIndex, 5);
      expect(run.comparisons, lessThanOrEqualTo(3));
    });

    test('binary search reports missing values', () {
      final run = binarySearch(values, 0);
      expect(run.resultIndex, -1);
      expect(run.frames.last.found, isFalse);
    });
  });

  group('randomValues', () {
    test('is deterministic for a seed and respects the range', () {
      final a = randomValues(12, seed: 7);
      final b = randomValues(12, seed: 7);

      expect(a, b);
      expect(a.length, 12);
      expect(a.every((value) => value >= 5 && value <= 99), isTrue);
      expect(randomValues(12, seed: 8), isNot(a));
    });
  });
}
