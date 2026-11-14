import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../machine_structure/machine_lessons.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import '../widgets/question_view.dart';
import 'desktop_theme.dart';
import 'devtrek_track.dart';
import 'fx.dart';

/// One exercise opened straight from the Levels Bank, without the surrounding
/// lesson stages. Answers feed accuracy and the review queue; stars and XP stay
/// reserved for full levels on the Guided Path so single drills can't be farmed.
class ExerciseView extends StatefulWidget {
  const ExerciseView({
    super.key,
    this.question,
    this.quiz,
    required this.courseId,
    required this.sourceTitle,
    required this.type,
    required this.difficulty,
  }) : assert(
         question != null || quiz != null,
         'Provide a course question or a machine quiz item',
       );

  final Question? question;
  final MachineQuiz? quiz;
  final String courseId;
  final String sourceTitle;
  final ChallengeType type;
  final ModuleDifficulty difficulty;

  @override
  State<ExerciseView> createState() => _ExerciseViewState();
}

class _ExerciseViewState extends State<ExerciseView> {
  final GlobalKey<QuestionViewState> _viewKey = GlobalKey<QuestionViewState>();

  int _attempt = 0;
  int? _selected;
  bool _checked = false;
  bool _correct = false;

  bool get _isQuestion => widget.question != null;

  bool get _canCheck {
    if (_checked) return true;
    return _isQuestion
        ? _viewKey.currentState?.canCheck ?? false
        : _selected != null;
  }

  void _check() {
    if (_checked || !_canCheck) return;
    final services = context.services;
    final correct = _isQuestion
        ? _viewKey.currentState!.evaluate()
        : _selected == widget.quiz!.correctIndex;
    services.progress.recordAnswer(
      _isQuestion ? widget.question!.topic : 'machine',
      correct,
    );
    if (correct) {
      services.sound.correct();
    } else {
      services.sound.wrong();
      if (_isQuestion) {
        services.review.enqueueWrongAnswer(
          widget.question!.id,
          courseId: widget.courseId,
        );
      }
    }
    setState(() {
      _checked = true;
      _correct = correct;
    });
  }

  void _retry() {
    setState(() {
      _attempt++;
      _selected = null;
      _checked = false;
      _correct = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final ar = s.isArabic;
    final palette = desktopPalette(context);
    return Theme(
      data: buildDesktopTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.sourceTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Tag(
                            icon: widget.type.icon,
                            label: widget.type.label(ar),
                            color: widget.type.color,
                          ),
                          _Tag(
                            icon: widget.difficulty.icon,
                            label: widget.difficulty.label(ar),
                            color: widget.difficulty.color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (_isQuestion)
                        QuestionView(
                          key: _viewKey,
                          question: widget.question!,
                          arabic: ar,
                          seed: _attempt,
                          onChanged: () => setState(() {}),
                        )
                      else
                        _quizBody(ar),
                      const SizedBox(height: 16),
                      Text(
                        s.t('exercisePracticeNote'),
                        style: TextStyle(fontSize: 12, color: palette.subtle),
                      ),
                    ],
                  ),
                ),
              ),
              _bottomBar(ar),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quizBody(bool ar) {
    final quiz = widget.quiz!;
    final options = quiz.options(ar);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          quiz.question(ar),
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < options.length; i++) _quizOption(quiz, options, i),
      ],
    );
  }

  Widget _quizOption(MachineQuiz quiz, List<String> options, int index) {
    final palette = desktopPalette(context);
    final selected = _selected == index;
    var border = palette.cardBorder;
    var fill = palette.card;
    if (selected) {
      border = blue;
      fill = Color.alphaBlend(blue.withValues(alpha: 0.15), palette.card);
    }
    if (_checked) {
      if (index == quiz.correctIndex) {
        border = green;
        fill = Color.alphaBlend(green.withValues(alpha: 0.15), palette.card);
      } else if (selected) {
        border = red;
        fill = Color.alphaBlend(red.withValues(alpha: 0.15), palette.card);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _checked ? null : () => setState(() => _selected = index),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 2),
          ),
          child: Text(
            options[index],
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(bool ar) {
    final s = context.s;
    final palette = desktopPalette(context);
    final color = _checked && !_correct ? red : green;
    final label = !_checked
        ? s.t('check')
        : _correct
        ? s.t('finish')
        : s.t('practiceAgain');
    final explanation = _isQuestion
        ? widget.question!.explanationFor(ar)
        : widget.quiz!.explanation(ar);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.cardBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_checked) ...[
            Text(
              _correct ? s.t('correctExclaim') : s.t('correctAnswerLabel'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _correct ? green : red,
              ),
            ),
            if (!_correct) ...[
              const SizedBox(height: 4),
              Text(
                _isQuestion
                    ? widget.question!.correctAnswerText()
                    : widget.quiz!.options(ar)[widget.quiz!.correctIndex],
                style: const TextStyle(
                  fontSize: 14,
                  color: red,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ],
            if (explanation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.sidebar,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Text(
                  explanation,
                  style: const TextStyle(fontSize: 13.5, height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: HoverScale(
                    hoverScale: 1.01,
                    glow: _canCheck ? color : null,
                    radius: 15,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        disabledBackgroundColor: palette.track,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: !_canCheck
                          ? null
                          : !_checked
                          ? _check
                          : _correct
                          ? () => Navigator.pop(context)
                          : _retry,
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_checked && !_correct) ...[
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(s.t('back')),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
