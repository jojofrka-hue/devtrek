import 'package:flutter/material.dart';

import '../models/question.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Renders one activity (choice / order / match) and owns the answer state.
/// The parent calls [QuestionViewState.evaluate] when the learner presses CHECK.
class QuestionView extends StatefulWidget {
  const QuestionView({
    super.key,
    required this.question,
    required this.arabic,
    this.seed = 0,
    this.onChanged,
  });

  final Question question;
  final bool arabic;
  final int seed;
  final VoidCallback? onChanged;

  @override
  State<QuestionView> createState() => QuestionViewState();
}

class QuestionViewState extends State<QuestionView> {
  int? _selected;
  List<int> _bank = [];
  List<int> _placed = [];
  List<int> _rightOrder = [];
  Map<int, int> _assign = {};
  int? _matchLeft;
  bool _checked = false;
  bool _wasCorrect = false;

  Question get question => widget.question;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(covariant QuestionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id ||
        oldWidget.seed != widget.seed) {
      _prepare();
    }
  }

  void _prepare() {
    _selected = null;
    _placed = [];
    _assign = {};
    _matchLeft = null;
    _checked = false;
    _wasCorrect = false;

    if (question.type == QType.order) {
      final n = question.options.length;
      _bank = List<int>.generate(n, (i) => i)..shuffle();
      for (var attempt = 0; attempt < 5 && n > 1 && _isIdentity(_bank); attempt++) {
        _bank.shuffle();
      }
    } else {
      _bank = [];
    }

    if (question.type == QType.match) {
      final n = question.pairs.length;
      _rightOrder = List<int>.generate(n, (i) => i)..shuffle();
      for (var attempt = 0; attempt < 5 && n > 1 && _isIdentity(_rightOrder); attempt++) {
        _rightOrder.shuffle();
      }
    } else {
      _rightOrder = [];
    }
  }

  bool _isIdentity(List<int> list) {
    for (var i = 0; i < list.length; i++) {
      if (list[i] != i) return false;
    }
    return true;
  }

  bool get isChecked => _checked;

  bool get wasCorrect => _wasCorrect;

  bool get canCheck {
    if (_checked) return true;
    switch (question.type) {
      case QType.choice:
        return _selected != null;
      case QType.order:
        return _placed.length == question.options.length;
      case QType.match:
        return _assign.length == question.pairs.length;
    }
  }

  bool evaluate() {
    if (_checked) return _wasCorrect;
    final correct = _evaluate();
    setState(() {
      _checked = true;
      _wasCorrect = correct;
    });
    widget.onChanged?.call();
    return correct;
  }

  bool _evaluate() {
    switch (question.type) {
      case QType.choice:
        return _selected == question.answer;
      case QType.order:
        for (var i = 0; i < _placed.length; i++) {
          if (question.options[_placed[i]] != question.options[i]) return false;
        }
        return true;
      case QType.match:
        for (var i = 0; i < question.pairs.length; i++) {
          if (_assign[i] != i) return false;
        }
        return true;
    }
  }

  String chosenAnswerText() {
    switch (question.type) {
      case QType.choice:
        return _selected == null ? '' : question.options[_selected!];
      case QType.order:
        return _placed.map((i) => question.options[i]).join(' ');
      case QType.match:
        final entries = _assign.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        return entries
            .map(
              (e) =>
                  '${question.pairs[e.key][0]} = ${question.pairs[e.value][1]}',
            )
            .join('\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          q.promptFor(widget.arabic),
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        if (q.code != null) ...[
          const SizedBox(height: 18),
          codeBox(q.code!),
        ],
        const SizedBox(height: 20),
        if (q.type == QType.choice)
          for (var i = 0; i < q.options.length; i++) _optionTile(i)
        else if (q.type == QType.order)
          _buildOrder()
        else
          _buildMatch(),
      ],
    );
  }

  Widget _optionTile(int index) {
    final isSelected = _selected == index;
    var border = Colors.grey.shade300;
    var fill = Colors.white;

    if (isSelected) {
      border = const Color(0xFF84D8FF);
      fill = const Color(0xFFDDF4FF);
    }
    if (_checked) {
      if (index == question.answer) {
        border = green;
        fill = const Color(0xFFD7FFB8);
      } else if (isSelected) {
        border = red;
        fill = const Color(0xFFFFDFE0);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _checked ? null : () => _touch(() => _selected = index),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 2),
          ),
          child: Text(
            question.options[index],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  void _touch(VoidCallback change) {
    setState(change);
    widget.onChanged?.call();
  }

  Widget _chip(String text, {VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400, width: 2),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildOrder() {
    var areaFill = Colors.grey.shade100;
    var areaBorder = Colors.grey.shade300;
    if (_checked) {
      areaFill = _wasCorrect
          ? const Color(0xFFD7FFB8)
          : const Color(0xFFFFDFE0);
      areaBorder = _wasCorrect ? green : red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.arabic
              ? 'اضغط القطع بالترتيب الصحيح.'
              : 'Tap the pieces in the correct order.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: areaFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: areaBorder, width: 2),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final index in _placed)
                _chip(
                  question.options[index],
                  onTap: _checked
                      ? null
                      : () => _touch(() => _placed.remove(index)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final index in _bank)
              if (!_placed.contains(index))
                _chip(
                  question.options[index],
                  onTap: _checked
                      ? null
                      : () => _touch(() => _placed.add(index)),
                ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.arabic
              ? 'اضغط عنصراً في اليسار ثم شريكه في اليمين.'
              : 'Tap an item on the left, then its partner on the right.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < question.pairs.length; i++)
                    _matchLeftTile(i),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  for (final j in _rightOrder) _matchRightTile(j),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _matchTile(
    String text,
    Color border,
    Color fill,
    VoidCallback? onTap, {
    bool mono = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 76,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 2),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _matchLeftTile(int index) {
    var border = Colors.grey.shade300;
    var fill = Colors.white;

    if (_matchLeft == index) {
      border = blue;
      fill = const Color(0xFFDDF4FF);
    } else if (_assign.containsKey(index)) {
      final color = pairColors[index % pairColors.length];
      border = color;
      fill = color.withValues(alpha: 0.16);
    }
    if (_checked && _assign.containsKey(index)) {
      final ok = _assign[index] == index;
      border = ok ? green : red;
      fill = ok ? const Color(0xFFD7FFB8) : const Color(0xFFFFDFE0);
    }

    return _matchTile(
      question.pairs[index][0],
      border,
      fill,
      _checked ? null : () => _touch(() => _matchLeft = index),
      mono: true,
    );
  }

  Widget _matchRightTile(int index) {
    int? owner;
    for (final entry in _assign.entries) {
      if (entry.value == index) owner = entry.key;
    }

    var border = Colors.grey.shade300;
    var fill = Colors.white;

    if (owner != null) {
      final color = pairColors[owner % pairColors.length];
      border = color;
      fill = color.withValues(alpha: 0.16);
    }
    if (_checked && owner != null) {
      final ok = owner == index;
      border = ok ? green : red;
      fill = ok ? const Color(0xFFD7FFB8) : const Color(0xFFFFDFE0);
    }

    return _matchTile(
      question.pairs[index][1],
      border,
      fill,
      _checked
          ? null
          : () {
              if (_matchLeft == null) return;
              _touch(() {
                _assign.removeWhere((key, value) => value == index);
                _assign[_matchLeft!] = index;
                _matchLeft = null;
              });
            },
    );
  }
}
