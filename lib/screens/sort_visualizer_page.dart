import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../i18n/app_strings.dart';
import '../services/sort_engine.dart';
import '../theme/app_theme.dart';
import '../views/desktop_theme.dart';
import '../widgets/common.dart';

class _Frame {
  const _Frame({
    required this.values,
    this.compare = const [],
    this.swapped = const [],
    this.pivot,
    this.sorted = const {},
    this.checked = const [],
    this.candidate,
    this.found = false,
  });

  final List<int> values;
  final List<int> compare;
  final List<int> swapped;
  final int? pivot;
  final Set<int> sorted;
  final List<int> checked;
  final int? candidate;
  final bool found;
}

class SortVisualizerPage extends StatefulWidget {
  const SortVisualizerPage({super.key});

  @override
  State<SortVisualizerPage> createState() => _SortVisualizerPageState();
}

class _SortVisualizerPageState extends State<SortVisualizerPage> {
  static const _sortAlgorithms = ['bubble', 'insertion', 'selection', 'quick'];
  static const _searchAlgorithms = ['linear', 'binary'];
  static const _delays = {1: 480, 2: 200, 3: 70};

  String _mode = 'sort';
  String _algorithm = 'bubble';
  int _speed = 2;

  int _seed = 7;
  List<int> _values = randomValues(12, seed: 7);
  List<_Frame> _frames = const [];
  int _index = 0;
  int _target = 0;
  int? _foundIndex;
  bool _playing = false;
  Timer? _timer;

  bool get _isSearch => _mode == 'search';

  int get _maxValue => _values.fold(0, math.max);

  _Frame get _frame => _frames.isEmpty
      ? _Frame(values: _values)
      : _frames[_index.clamp(0, _frames.length - 1)];

  int get _liveComparisons {
    var count = 0;
    for (var i = 0; i <= _index && i < _frames.length; i++) {
      final frame = _frames[i];
      if (_isSearch ? frame.candidate != null : frame.compare.isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  int get _liveSwaps {
    var count = 0;
    for (var i = 0; i <= _index && i < _frames.length; i++) {
      if (_frames[i].swapped.isNotEmpty) count++;
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    _buildFrames();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _buildFrames() {
    _timer?.cancel();
    _playing = false;
    _index = 0;
    _foundIndex = null;

    if (_isSearch) {
      final sorted = [..._values]..sort();
      _values = sorted;
      _target = sorted[math.Random(_seed * 31).nextInt(sorted.length)];
      final run = _algorithm == 'binary'
          ? binarySearch(sorted, _target)
          : linearSearch(sorted, _target);
      _frames = run.frames.map(_fromSearch).toList();
      _foundIndex = run.resultIndex;
      return;
    }

    final run = _algorithm == 'insertion'
        ? insertionSort(_values)
        : _algorithm == 'selection'
        ? selectionSort(_values)
        : _algorithm == 'quick'
        ? quickSort(_values)
        : bubbleSort(_values);
    _frames = run.frames.map(_fromSort).toList();
  }

  _Frame _fromSort(SortFrame frame) => _Frame(
    values: frame.values,
    compare: frame.compare,
    swapped: frame.swapped,
    pivot: frame.pivot,
    sorted: frame.sorted,
  );

  _Frame _fromSearch(SearchFrame frame) => _Frame(
    values: frame.values,
    checked: frame.checked,
    candidate: frame.candidate,
    found: frame.found,
  );

  void _togglePlay() {
    if (_playing) {
      _timer?.cancel();
      setState(() => _playing = false);
      return;
    }
    if (_frames.isEmpty) return;
    if (_index >= _frames.length - 1) {
      setState(() {
        _index = 0;
        _foundIndex = null;
      });
    }
    setState(() => _playing = true);
    _timer = Timer.periodic(Duration(milliseconds: _delays[_speed] ?? 200), (
      timer,
    ) {
      if (_index >= _frames.length - 1) {
        timer.cancel();
        setState(() => _playing = false);
        return;
      }
      setState(() => _index++);
    });
  }

  void _newArray() {
    setState(() {
      _seed++;
      _values = randomValues(12, seed: _seed);
      _buildFrames();
    });
  }

  void _setMode(String mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _algorithm = mode == 'sort' ? _sortAlgorithms.first : 'linear';
      _buildFrames();
    });
  }

  void _setAlgorithm(String? algorithm) {
    if (algorithm == null || algorithm == _algorithm) return;
    setState(() {
      _algorithm = algorithm;
      _buildFrames();
    });
  }

  String _algorithmName(AppStrings s) => switch (_algorithm) {
    'insertion' => s.t('insertionSort'),
    'selection' => s.t('selectionSort'),
    'quick' => s.t('quickSort'),
    'linear' => s.t('linearSearch'),
    'binary' => s.t('binarySearch'),
    _ => s.t('bubbleSort'),
  };

  @override
  Widget build(BuildContext context) {
    final palette = desktopPalette(context);
    final s = context.s;

    return Scaffold(
      backgroundColor: palette.sidebar,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    s.t('visualizerTitle'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _modeChip('sort', s.t('sorting'))),
                const SizedBox(width: 10),
                Expanded(child: _modeChip('search', s.t('searching'))),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: palette.cardBorder, width: 2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _algorithm,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more),
                  onChanged: _setAlgorithm,
                  items: [
                    for (final key
                        in _isSearch ? _searchAlgorithms : _sortAlgorithms)
                      DropdownMenuItem(
                        value: key,
                        child: Text(switch (key) {
                          'insertion' => s.t('insertionSort'),
                          'selection' => s.t('selectionSort'),
                          'quick' => s.t('quickSort'),
                          'linear' => s.t('linearSearch'),
                          'binary' => s.t('binarySearch'),
                          _ => s.t('bubbleSort'),
                        }, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),
            if (_isSearch) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '${s.t('targetLabel')}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_target',
                      style: const TextStyle(
                        color: blue,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Container(
              height: 240,
              padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.cardBorder, width: 2),
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < _frame.values.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _bar(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${s.t('step')} ${math.min(_index + 1, _frames.length)} '
                    '${s.t('of')} ${_frames.length}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: palette.subtle,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${s.t('comparisons')}: $_liveComparisons',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                const SizedBox(width: 10),
                if (!_isSearch)
                  Text(
                    '${s.t('swaps')}: $_liveSwaps',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: purple,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  s.t('speed'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: palette.subtle,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _speed.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    activeColor: green,
                    label: switch (_speed) {
                      1 => 'x0.5',
                      3 => 'x2',
                      _ => 'x1',
                    },
                    onChanged: (value) =>
                        setState(() => _speed = value.round()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            BigButton(
              label: _playing ? s.t('pause') : s.t('run'),
              icon: _playing ? Icons.pause : Icons.play_arrow_rounded,
              onPressed: _togglePlay,
              color: _playing ? amber : green,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _newArray,
                      icon: const Icon(Icons.shuffle, size: 18),
                      label: Text(
                        s.t('newArray'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _statusCard(s),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(String mode, String label) {
    final palette = desktopPalette(context);
    final selected = _mode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _setMode(mode),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(green.withValues(alpha: 0.15), palette.card)
              : palette.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.cardBorder, width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected ? green : palette.subtle,
          ),
        ),
      ),
    );
  }

  Widget _bar(int index) {
    final palette = desktopPalette(context);
    final frame = _frame;
    var color = palette.subtle;
    if (frame.found && frame.candidate == index) {
      color = green;
    } else if (frame.swapped.contains(index)) {
      color = red;
    } else if (frame.compare.contains(index)) {
      color = amber;
    } else if (frame.pivot == index) {
      color = purple;
    } else if (frame.checked.contains(index)) {
      color = blue;
    } else if (frame.candidate == index) {
      color = blue;
    } else if (frame.sorted.contains(index)) {
      color = green;
    }

    final value = frame.values[index];
    final height = 24 + (value / math.max(1, _maxValue)) * 160;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: palette.subtle,
          ),
        ),
        const SizedBox(height: 3),
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
      ],
    );
  }

  Widget _statusCard(AppStrings s) {
    final palette = desktopPalette(context);
    final done = _frames.isNotEmpty && _index >= _frames.length - 1;
    String text;
    Color color;
    IconData icon;

    if (!_isSearch) {
      if (done) {
        text = s.t('sortedNote');
        color = green;
        icon = Icons.check_circle;
      } else {
        text = '${s.t('algorithm')}: ${_algorithmName(s)}';
        color = green;
        icon = Icons.bar_chart;
      }
    } else if (done) {
      if (_foundIndex != null && _foundIndex! >= 0) {
        text = s.t('foundAt').replaceAll('{i}', '$_foundIndex');
        color = green;
        icon = Icons.my_location;
      } else {
        text = s.t('notFound');
        color = red;
        icon = Icons.search_off;
      }
    } else {
      text = '${s.t('algorithm')}: ${_algorithmName(s)}';
      color = blue;
      icon = Icons.search;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withValues(alpha: 0.15), palette.card),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.cardBorder, width: 2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
