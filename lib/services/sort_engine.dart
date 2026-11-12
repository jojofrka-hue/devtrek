import 'dart:math';

/// Immutable snapshot of the array plus highlighting information, so the UI can
/// animate algorithm execution without knowing the algorithm itself.
class SortFrame {
  SortFrame({
    required List<int> values,
    List<int> compare = const [],
    List<int> swapped = const [],
    this.pivot,
    Set<int> sorted = const {},
    this.note,
  }) : values = List.unmodifiable(values),
       compare = List.unmodifiable(compare),
       swapped = List.unmodifiable(swapped),
       sorted = Set.unmodifiable(sorted);

  final List<int> values;
  final List<int> compare;
  final List<int> swapped;
  final int? pivot;
  final Set<int> sorted;
  final String? note;
}

class SortRun {
  const SortRun({
    required this.algorithm,
    required this.frames,
    required this.comparisons,
    required this.swaps,
  });

  final String algorithm;
  final List<SortFrame> frames;
  final int comparisons;
  final int swaps;

  List<int> get result =>
      frames.isEmpty ? const [] : List<int>.of(frames.last.values);
}

class _Recorder {
  _Recorder(this.algorithm);

  final String algorithm;
  final List<SortFrame> frames = [];
  int comparisons = 0;
  int swaps = 0;

  void snap(
    List<int> values, {
    List<int> compare = const [],
    List<int> swapped = const [],
    int? pivot,
    Set<int> sorted = const {},
    String? note,
  }) {
    frames.add(
      SortFrame(
        values: values,
        compare: compare,
        swapped: swapped,
        pivot: pivot,
        sorted: sorted,
        note: note,
      ),
    );
  }

  SortRun build() => SortRun(
    algorithm: algorithm,
    frames: frames,
    comparisons: comparisons,
    swaps: swaps,
  );
}

SortRun bubbleSort(List<int> input) {
  final rec = _Recorder('bubble');
  final a = List<int>.of(input);
  final sorted = <int>{};
  rec.snap(a, note: 'start');
  if (a.length < 2) {
    sorted.addAll(List.generate(a.length, (i) => i));
    rec.snap(a, sorted: sorted, note: 'done');
    return rec.build();
  }

  for (var i = 0; i < a.length - 1; i++) {
    var swappedThisPass = false;
    for (var j = 0; j < a.length - 1 - i; j++) {
      rec.comparisons++;
      rec.snap(a, compare: [j, j + 1], sorted: {...sorted});
      if (a[j] > a[j + 1]) {
        final temp = a[j];
        a[j] = a[j + 1];
        a[j + 1] = temp;
        rec.swaps++;
        swappedThisPass = true;
        rec.snap(a, swapped: [j, j + 1], sorted: {...sorted});
      }
    }
    sorted.add(a.length - 1 - i);
    rec.snap(a, sorted: {...sorted});
    if (!swappedThisPass) break;
  }

  sorted.addAll(List.generate(a.length, (i) => i));
  rec.snap(a, sorted: {...sorted}, note: 'done');
  return rec.build();
}

SortRun insertionSort(List<int> input) {
  final rec = _Recorder('insertion');
  final a = List<int>.of(input);
  final sorted = <int>{0};
  rec.snap(a, note: 'start');
  if (a.isEmpty) {
    rec.snap(a, sorted: const {}, note: 'done');
    return rec.build();
  }

  for (var i = 1; i < a.length; i++) {
    var j = i;
    while (j > 0) {
      rec.comparisons++;
      rec.snap(a, compare: [j - 1, j], sorted: {...sorted});
      if (a[j - 1] > a[j]) {
        final temp = a[j];
        a[j] = a[j - 1];
        a[j - 1] = temp;
        rec.swaps++;
        rec.snap(a, swapped: [j - 1, j], sorted: {...sorted});
        j--;
      } else {
        break;
      }
    }
    sorted.add(i);
    rec.snap(a, sorted: {...sorted});
  }
  rec.snap(a, sorted: List.generate(a.length, (i) => i).toSet(), note: 'done');
  return rec.build();
}

SortRun selectionSort(List<int> input) {
  final rec = _Recorder('selection');
  final a = List<int>.of(input);
  final sorted = <int>{};
  rec.snap(a, note: 'start');
  for (var i = 0; i < a.length; i++) {
    var minIndex = i;
    for (var j = i + 1; j < a.length; j++) {
      rec.comparisons++;
      rec.snap(a, compare: [minIndex, j], sorted: {...sorted});
      if (a[j] < a[minIndex]) minIndex = j;
    }
    if (minIndex != i) {
      final temp = a[i];
      a[i] = a[minIndex];
      a[minIndex] = temp;
      rec.swaps++;
      rec.snap(a, swapped: [i, minIndex], sorted: {...sorted});
    }
    sorted.add(i);
    rec.snap(a, sorted: {...sorted});
  }
  rec.snap(a, sorted: List.generate(a.length, (i) => i).toSet(), note: 'done');
  return rec.build();
}

SortRun quickSort(List<int> input) {
  final rec = _Recorder('quick');
  final a = List<int>.of(input);
  final sorted = <int>{};
  rec.snap(a, note: 'start');

  void sort(int low, int high) {
    if (low > high) return;
    if (low == high) {
      sorted.add(low);
      rec.snap(a, sorted: {...sorted});
      return;
    }

    final pivotValue = a[high];
    var store = low;
    for (var j = low; j < high; j++) {
      rec.comparisons++;
      rec.snap(a, compare: [j, high], pivot: high, sorted: {...sorted});
      if (a[j] < pivotValue) {
        if (store != j) {
          final temp = a[store];
          a[store] = a[j];
          a[j] = temp;
          rec.swaps++;
          rec.snap(a, swapped: [store, j], pivot: high, sorted: {...sorted});
        }
        store++;
      }
    }
    if (store != high) {
      final temp = a[store];
      a[store] = a[high];
      a[high] = temp;
      rec.swaps++;
    }
    sorted.add(store);
    rec.snap(a, pivot: store, sorted: {...sorted});
    sort(low, store - 1);
    sort(store + 1, high);
  }

  sort(0, a.length - 1);
  rec.snap(a, sorted: List.generate(a.length, (i) => i).toSet(), note: 'done');
  return rec.build();
}

class SearchFrame {
  SearchFrame({
    required List<int> values,
    List<int> checked = const [],
    this.candidate,
    this.found = false,
    this.note,
  }) : values = List.unmodifiable(values),
       checked = List.unmodifiable(checked);

  final List<int> values;
  final List<int> checked;
  final int? candidate;
  final bool found;
  final String? note;
}

class SearchRun {
  const SearchRun({
    required this.algorithm,
    required this.frames,
    required this.comparisons,
    required this.resultIndex,
  });

  final String algorithm;
  final List<SearchFrame> frames;
  final int comparisons;
  final int resultIndex;
}

SearchRun linearSearch(List<int> values, int target) {
  final frames = <SearchFrame>[];
  var comparisons = 0;
  var result = -1;
  for (var i = 0; i < values.length; i++) {
    comparisons++;
    final hit = values[i] == target;
    frames.add(
      SearchFrame(
        values: values,
        checked: [i],
        candidate: i,
        found: hit,
        note: hit ? 'found' : 'compare',
      ),
    );
    if (hit) {
      result = i;
      break;
    }
  }
  if (result < 0) {
    frames.add(SearchFrame(values: values, note: 'missing'));
  }
  return SearchRun(
    algorithm: 'linear',
    frames: frames,
    comparisons: comparisons,
    resultIndex: result,
  );
}

/// Requires a sorted list. Returns the index of [target] or -1.
SearchRun binarySearch(List<int> values, int target) {
  final frames = <SearchFrame>[];
  var comparisons = 0;
  var low = 0;
  var high = values.length - 1;
  var result = -1;

  while (low <= high) {
    final mid = (low + high) ~/ 2;
    comparisons++;
    final value = values[mid];
    final hit = value == target;
    frames.add(
      SearchFrame(
        values: values,
        checked: [low, high],
        candidate: mid,
        found: hit,
        note: hit ? 'found' : 'compare',
      ),
    );
    if (hit) {
      result = mid;
      break;
    }
    if (value < target) {
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }

  if (result < 0) {
    frames.add(SearchFrame(values: values, note: 'missing'));
  }
  return SearchRun(
    algorithm: 'binary',
    frames: frames,
    comparisons: comparisons,
    resultIndex: result,
  );
}

List<int> randomValues(int count, {int seed = 7, int max = 99}) {
  final random = Random(seed);
  return List<int>.generate(count, (_) => 5 + random.nextInt(max - 5));
}
