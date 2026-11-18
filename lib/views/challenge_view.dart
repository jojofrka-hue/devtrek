import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../machine_structure/machine_lessons.dart';
import '../models/achievement.dart';
import '../models/course.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/question_view.dart';
import 'desktop_theme.dart';
import 'devtrek_track.dart';
import 'fx.dart';

/// A level opened as three explicit Bloom stages — Understanding, Application
/// and Creation — instead of one shuffled quiz. Works for course levels
/// (choice/match/order questions) and for Structure Machine lessons
/// (key terms / quiz / synthesis). Guided-path cards route here.
class ChallengeView extends StatefulWidget {
  const ChallengeView({
    super.key,
    this.course,
    this.levelIndex = 0,
    this.machineLesson,
    this.machineIndex = 0,
    this.guided = false,
  }) : assert(
         course != null || machineLesson != null,
         'Provide a course level or a machine lesson',
       );

  final Course? course;
  final int levelIndex;
  final MachineLesson? machineLesson;
  final int machineIndex;
  final bool guided;

  @override
  State<ChallengeView> createState() => _ChallengeViewState();
}

enum _StepKind { question, quiz, concepts, synthesis, lessonIntro, practice }

class _Step {
  const _Step({
    required this.stage,
    required this.kind,
    this.question,
    this.quiz,
    this.terms,
  });

  final BloomStage stage;
  final _StepKind kind;
  final Question? question;
  final MachineQuiz? quiz;
  final List<MachineTerm>? terms;

  bool get graded => kind == _StepKind.question || kind == _StepKind.quiz;
}

class _ChallengeViewState extends State<ChallengeView> {
  final GlobalKey<QuestionViewState> _viewKey = GlobalKey<QuestionViewState>();
  final TextEditingController _synthesis = TextEditingController();

  late List<_Step> _steps;
  int _stepIndex = 0;
  int _restarts = 0;
  int _hearts = 5;
  int _correct = 0;
  int _combo = 0;
  int _rawXp = 0;
  bool _checked = false;
  bool _wasCorrect = false;
  int? _quizSelected;
  bool _shake = false;
  bool _finished = false;
  bool _finishing = false;
  int _stars = 0;
  int _awardedXp = 0;
  List<Achievement> _badges = const [];

  bool get _isCourse => widget.course != null;
  String get _courseId => widget.course?.id ?? 'machine';
  int get _levelIndex => _isCourse ? widget.levelIndex : widget.machineIndex;
  int get _gradedTotal => _steps.where((step) => step.graded).length;
  _Step get _step => _steps[_stepIndex];
  bool get _isLast => _stepIndex + 1 >= _steps.length;

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps();
  }

  @override
  void dispose() {
    _synthesis.dispose();
    super.dispose();
  }

  List<_Step> _buildSteps() {
    final steps = <_Step>[];
    if (_isCourse) {
      final questions = widget.course!.levels[widget.levelIndex].questions;
      if (widget.guided) {
        steps.add(
          const _Step(
            stage: BloomStage.understanding,
            kind: _StepKind.lessonIntro,
          ),
        );
      }
      for (final stage in BloomStage.values) {
        for (final question in questions) {
          if (stageOfQuestion(question) == stage) {
            steps.add(
              _Step(stage: stage, kind: _StepKind.question, question: question),
            );
          }
        }
        if (widget.guided &&
            stage == BloomStage.application &&
            !steps.any((step) => step.stage == stage)) {
          steps.add(
            const _Step(
              stage: BloomStage.application,
              kind: _StepKind.practice,
            ),
          );
        }
        if (widget.guided && stage == BloomStage.creation) {
          steps.add(
            const _Step(stage: BloomStage.creation, kind: _StepKind.synthesis),
          );
        }
      }
    } else {
      final lesson = widget.machineLesson!;
      if (widget.guided || lesson.terms.isNotEmpty) {
        steps.add(
          _Step(
            stage: BloomStage.understanding,
            kind: _StepKind.concepts,
            terms: lesson.terms,
          ),
        );
      }
      for (final quiz in lesson.quiz) {
        steps.add(
          _Step(
            stage: BloomStage.application,
            kind: _StepKind.quiz,
            quiz: quiz,
          ),
        );
      }
      steps.add(
        const _Step(stage: BloomStage.creation, kind: _StepKind.synthesis),
      );
    }
    return steps;
  }

  String _title(bool ar) => _isCourse
      ? widget.course!.levels[widget.levelIndex].titleFor(ar)
      : widget.machineLesson!.title(ar);

  bool get _canCheck {
    if (!_step.graded) return true;
    if (_step.kind == _StepKind.question) {
      return _viewKey.currentState?.canCheck ?? false;
    }
    return _quizSelected != null;
  }

  void _check() {
    if (!_step.graded || _checked || !_canCheck) return;
    final services = context.services;
    bool correct;
    String topic;
    if (_step.kind == _StepKind.question) {
      correct = _viewKey.currentState!.evaluate();
      topic = _step.question!.topic;
    } else {
      correct = _quizSelected == _step.quiz!.correctIndex;
      topic = 'machine';
    }
    services.progress.recordAnswer(topic, correct);
    if (correct) {
      services.sound.correct();
    } else {
      services.sound.wrong();
      if (_isCourse) {
        services.review.enqueueWrongAnswer(
          _step.question!.id,
          courseId: _courseId,
        );
      }
    }
    setState(() {
      _checked = true;
      _wasCorrect = correct;
      if (correct) {
        _correct++;
        _combo++;
        _rawXp += 10 + (_combo >= 3 ? 5 : 0);
      } else {
        _combo = 0;
        _hearts = _hearts > 0 ? _hearts - 1 : 0;
        _shake = true;
      }
    });
    if (!correct) {
      Future.delayed(const Duration(milliseconds: 460), () {
        if (mounted) setState(() => _shake = false);
      });
    }
  }

  bool get _canContinue =>
      !widget.guided ||
      (_step.kind != _StepKind.synthesis && _step.kind != _StepKind.practice) ||
      _synthesis.text.trim().isNotEmpty;

  Future<void> _next() async {
    if (!_canContinue || (_step.graded && !_checked)) return;
    if (_isLast || _hearts <= 0) {
      await _finish();
      return;
    }
    setState(() {
      _stepIndex++;
      _synthesis.clear();
      _checked = false;
      _wasCorrect = false;
      _quizSelected = null;
      _shake = false;
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    final ratio = _gradedTotal == 0 ? 1.0 : _correct / _gradedTotal;
    final stars = _hearts <= 0
        ? 0
        : ratio >= 1.0
        ? 3
        : ratio >= 0.7
        ? 2
        : ratio >= 0.5
        ? 1
        : 0;
    final services = context.services;
    final before = Set<String>.of(services.achievements.unlocked);
    final awarded = await services.progress.recordLevelResult(
      courseId: _courseId,
      levelIndex: _levelIndex,
      stars: stars,
      rawXp: _rawXp,
    );
    services.streak.recordActivity();
    await services.evaluateAchievements();
    final newIds = services.achievements.unlocked.difference(before);
    final badges = services.achievements.all
        .where((badge) => newIds.contains(badge.id))
        .toList();
    services.sound.levelComplete();
    if (!mounted) return;
    setState(() {
      _finished = true;
      _stars = stars;
      _awardedXp = awarded;
      _badges = badges;
    });
    if (stars > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ConfettiBurst.celebrate(context);
      });
    }
  }

  void _restart() {
    setState(() {
      _steps = _buildSteps();
      _stepIndex = 0;
      _restarts++;
      _hearts = 5;
      _correct = 0;
      _combo = 0;
      _rawXp = 0;
      _checked = false;
      _wasCorrect = false;
      _quizSelected = null;
      _shake = false;
      _finished = false;
      _finishing = false;
      _stars = 0;
      _awardedXp = 0;
      _badges = const [];
      _synthesis.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (widget.guided &&
        !isGuidedLevelUnlocked(context.services, _courseId, _levelIndex)) {
      return Scaffold(
        appBar: AppBar(title: Text(s.isArabic ? 'مستوى مقفل' : 'Locked level')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              s.isArabic
                  ? 'اجتز المستويات السابقة أولاً.'
                  : 'Pass the earlier levels first.',
            ),
          ),
        ),
      );
    }
    return Theme(
      data: buildDesktopTheme(),
      child: Scaffold(
        body: SafeArea(
          child: _finished
              ? _buildResult(s.isArabic)
              : _buildChallenge(s.isArabic),
        ),
      ),
    );
  }

  Widget _buildChallenge(bool ar) {
    final palette = desktopPalette(context);
    final stage = _step.stage;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 18, 6),
          child: Row(
            children: [
              IconButton(
                tooltip: ar ? 'إغلاق' : 'Close',
                icon: Icon(Icons.close_rounded, color: palette.subtle),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  _title(ar),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (_combo >= 2) ...[
                const Icon(Icons.local_fire_department, color: amber, size: 20),
                Text(
                  '$_combo',
                  style: const TextStyle(
                    color: amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedBar(
            value: _steps.isEmpty ? 0 : (_stepIndex + 1) / _steps.length,
            color: green,
            background: palette.track,
            height: 7,
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _StageStepper(
            current: stage,
            steps: _steps,
            stepIndex: _stepIndex,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(stage.icon, size: 16, color: stage.color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${stage.fullLabel(ar)} — ${stage.description(ar)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: stage.color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Shake(trigger: _shake, child: _buildStep(ar)),
          ),
        ),
        _bottomBar(ar),
      ],
    );
  }

  Widget _paper(Widget child) {
    final palette = desktopPalette(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.cardBorder, width: 1.5),
      ),
      child: child,
    );
  }

  Widget _buildStep(bool ar) {
    switch (_step.kind) {
      case _StepKind.question:
        return _paper(
          QuestionView(
            key: _viewKey,
            question: _step.question!,
            arabic: ar,
            seed: _stepIndex + _restarts * 100,
            onChanged: () => setState(() {}),
          ),
        );
      case _StepKind.quiz:
        return _paper(_buildQuiz(ar));
      case _StepKind.concepts:
        return _paper(_buildConcepts(ar));
      case _StepKind.synthesis:
      case _StepKind.practice:
        return _paper(_buildSynthesis(ar));
      case _StepKind.lessonIntro:
        return _paper(_buildLessonIntro(ar));
    }
  }

  Widget _buildLessonIntro(bool ar) {
    final level = widget.course!.levels[widget.levelIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'شرح الدرس' : 'Lesson explanation',
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Text(
          level.introFor(ar),
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
        const SizedBox(height: 16),
        for (final point in level.keyPointsFor(ar))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 19,
                  color: blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    point,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildConcepts(bool ar) {
    final terms = _step.terms!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar ? 'المفاهيم الأساسية' : 'Key concepts',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          ar ? 'اقرأ هذه المفاهيم جيداً ثم تابع إلى مرحلة التطبيق.' : 'Read these concepts carefully, then continue to the application stage.',
          style: TextStyle(
            fontSize: 13.5,
            color: desktopPalette(context).subtle,
          ),
        ),
        const SizedBox(height: 14),
        if (widget.guided) ...[
          Text(
            widget.machineLesson!.summary(ar),
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 12),
          for (final section in widget.machineLesson!.sections) ...[
            Text(
              section.heading(ar),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              section.body(ar),
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
            if (section.code != null) ...[
              const SizedBox(height: 8),
              codeBox(section.code!),
            ],
            const SizedBox(height: 18),
          ],
        ],
        for (final term in terms)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: blue.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    term.term(ar),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    term.definition(ar),
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: desktopPalette(context).subtle,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuiz(bool ar) {
    final quiz = _step.quiz!;
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
    final selected = _quizSelected == index;
    final palette = desktopPalette(context);
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
        onTap: _checked ? null : () => setState(() => _quizSelected = index),
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

  Widget _buildSynthesis(bool ar) {
    final practice = _step.kind == _StepKind.practice;
    final courseWriting = widget.guided && _isCourse;
    final heading = practice
        ? (ar ? 'طبّق الفكرة خطوة بخطوة' : 'Apply the idea step by step')
        : courseWriting
        ? (ar ? 'اكتب مثالاً من إنشائك' : 'Create your own example')
        : (ar ? 'لخّص ما تعلمته' : 'Synthesize what you learned');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: purple, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                heading,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          practice
              ? (ar
                    ? 'اختر مثالاً على «${_title(ar)}». تتبّع خطواته، واكتب القيم أو المخرجات المتوقعة وفسّرها.'
                    : 'Choose an example of "${_title(ar)}". Trace its steps and explain the expected values or output.')
              : courseWriting
              ? (ar
                    ? 'اكتب مثالاً قصيراً بلغة ${widget.course!.name} يطبّق «${_title(ar)}»، ثم اذكر النتيجة المتوقعة.'
                    : 'Write a short ${widget.course!.name} example for "${_title(ar)}" and state its expected result.')
              : (ar
                    ? 'بكلماتك الخاصة: اشرح الفكرة الأساسية وكيف تعمل، مع مثال من إنشائك.'
                    : 'Explain the core idea in your own words and give your own example.'),
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: desktopPalette(context).subtle,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _synthesis,
          onChanged: (_) => setState(() {}),
          textDirection: courseWriting && !practice ? TextDirection.ltr : null,
          maxLines: 5,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            fontFamily: courseWriting && !practice ? 'monospace' : null,
          ),
          decoration: InputDecoration(
            hintText: ar ? 'اشرح هنا...' : 'Explain here...',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: desktopPalette(context).sidebar,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          ar
              ? 'نشاط للمراجعة الذاتية؛ لا يتم تشغيل النص أو تقييمه آلياً. النجوم تعتمد على إجابات الاختبار.'
              : 'Self-review activity; this text is not executed or automatically graded. Stars depend on quiz answers.',
          style: TextStyle(fontSize: 12, color: desktopPalette(context).subtle),
        ),
      ],
    );
  }

  Widget _bottomBar(bool ar) {
    final palette = desktopPalette(context);
    final s = context.s;
    final graded = _step.graded;
    String label;
    VoidCallback? onPressed;
    var color = green;
    if (!graded) {
      label = ar ? 'متابعة' : 'Continue';
      onPressed = _canContinue ? _next : null;
    } else if (!_checked) {
      label = s.t('check');
      onPressed = _canCheck ? _check : null;
    } else {
      label = _isLast ? (ar ? 'إنهاء' : 'Finish') : s.t('next');
      onPressed = _next;
      if (!_wasCorrect) color = red;
    }

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
          if (graded && _checked) ...[
            Text(
              _wasCorrect ? s.t('correctExclaim') : s.t('correctAnswerLabel'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _wasCorrect ? green : red,
              ),
            ),
            if (!_wasCorrect) ...[
              const SizedBox(height: 4),
              Text(
                _step.kind == _StepKind.question
                    ? _step.question!.correctAnswerText()
                    : _step.quiz!.options(ar)[_step.quiz!.correctIndex],
                style: const TextStyle(
                  fontSize: 14,
                  color: red,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 8),
            _explanation(ar),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: HoverScale(
              hoverScale: 1.01,
              glow: onPressed == null ? null : color,
              radius: 15,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  disabledBackgroundColor: palette.track,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: onPressed,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _explanation(bool ar) {
    final text = _step.kind == _StepKind.question
        ? _step.question!.explanationFor(ar)
        : _step.quiz!.explanation(ar);
    if (text.isEmpty) return const SizedBox.shrink();
    final palette = desktopPalette(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.sidebar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.s.t('explanationLabel'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
              color: palette.subtle,
            ),
          ),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 14, height: 1.45)),
        ],
      ),
    );
  }

  Widget _buildResult(bool ar) {
    final s = context.s;
    final palette = desktopPalette(context);
    final won = _stars > 0;
    final hasNext =
        _stars >= 1 &&
        (_isCourse
            ? widget.levelIndex + 1 < widget.course!.levels.length
            : widget.machineIndex + 1 < machineLessons.length);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                won ? Icons.emoji_events_rounded : Icons.heart_broken_rounded,
                size: 84,
                color: won ? amber : red,
              ),
              const SizedBox(height: 10),
              Text(
                won
                    ? s.t('levelComplete')
                    : _hearts <= 0
                    ? s.t('outOfHearts')
                    : (ar
                          ? 'حاول مجدداً لاجتياز المستوى'
                          : 'Try again to pass this level'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              starRow(_stars, size: 42),
              const SizedBox(height: 12),
              Text(
                '${s.t('scoreLabel')}: $_correct / $_gradedTotal',
                style: TextStyle(fontSize: 18, color: palette.subtle),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _resultStat(s.t('xpEarned'), '$_awardedXp', amber),
                  const SizedBox(width: 14),
                  _resultStat(s.t('hearts'), '$_hearts', red),
                ],
              ),
              if (_badges.isNotEmpty) ...[
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final badge in _badges)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: amber.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: amber),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(badge.icon),
                            const SizedBox(width: 6),
                            Text(
                              '${s.t('newBadge')}: ${badge.titleFor(ar)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              if (hasNext) ...[
                _resultButton(
                  label: s.t('nextLevel'),
                  icon: Icons.arrow_forward_rounded,
                  color: green,
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _isCourse
                          ? ChallengeView(
                              course: widget.course,
                              levelIndex: widget.levelIndex + 1,
                              guided: widget.guided,
                            )
                          : ChallengeView(
                              machineLesson:
                                  machineLessons[widget.machineIndex + 1],
                              machineIndex: widget.machineIndex + 1,
                              guided: widget.guided,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _resultButton(
                label: s.t('practiceAgain'),
                icon: Icons.refresh_rounded,
                color: palette.cardBorder,
                onPressed: _restart,
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  s.t('backToLevels'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.subtle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultStat(String label, String value, Color color) {
    final palette = desktopPalette(context);
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: HoverScale(
        hoverScale: 1.01,
        glow: color,
        radius: 15,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 20),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// The three Bloom stages shown as an explicit, animated stepper.
class _StageStepper extends StatelessWidget {
  const _StageStepper({
    required this.current,
    required this.steps,
    required this.stepIndex,
  });

  final BloomStage current;
  final List<_Step> steps;
  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = desktopPalette(context);
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        for (final stage in BloomStage.values)
          _stageBadge(context, stage, s.isArabic, palette),
      ],
    );
  }

  Widget _stageBadge(
    BuildContext context,
    BloomStage stage,
    bool ar,
    DesktopPalette palette,
  ) {
    var total = 0;
    var done = 0;
    for (var i = 0; i < steps.length; i++) {
      if (steps[i].stage != stage) continue;
      total++;
      if (i < stepIndex) done++;
    }
    final active = stage == current;
    final value = total == 0 ? 1.0 : done / total;
    return HoverScale(
      hoverScale: 1.03,
      glow: active ? stage.color : null,
      radius: 13,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? stage.color.withValues(alpha: 0.14) : palette.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: active ? stage.color : palette.cardBorder,
            width: active ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedRing(
              value: value,
              color: stage.color,
              background: palette.track,
              size: 30,
              stroke: 3.5,
              center: Icon(stage.icon, size: 15, color: stage.color),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stage.label(ar),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: active ? stage.color : palette.subtle,
                  ),
                ),
                Text(
                  '$done/$total',
                  style: TextStyle(fontSize: 10.5, color: palette.subtle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
