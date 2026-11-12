import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../i18n/app_strings.dart';
import '../models/achievement.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';
import '../widgets/course_visuals.dart';
import '../widgets/mascot.dart';
import '../widgets/question_view.dart';

class LessonPage extends StatefulWidget {
  const LessonPage({
    super.key,
    required this.course,
    required this.levelIndex,
  });

  final Course course;
  final int levelIndex;

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late final List<Question> _questions;
  final GlobalKey<QuestionViewState> _viewKey = GlobalKey<QuestionViewState>();

  int _index = 0;
  int _hearts = 5;
  int _correct = 0;
  int _combo = 0;
  int _rawXp = 0;
  int _attempt = 0;
  bool _showIntro = true;
  bool _checked = false;
  bool _wasCorrect = false;
  bool _finished = false;
  bool _finishing = false;
  int _stars = 0;
  int _awardedXp = 0;
  int _confettiTrigger = 0;
  List<Achievement> _badges = const [];
  String? _aiText;
  bool _aiLoading = false;

  Level get _level => widget.course.levels[widget.levelIndex];
  Question get _question => _questions[_index];

  @override
  void initState() {
    super.initState();
    _questions = List<Question>.of(_level.questions)..shuffle();
  }

  bool get _canCheck => _viewKey.currentState?.canCheck ?? false;

  void _startLevel() {
    setState(() => _showIntro = false);
  }

  void _check() {
    final view = _viewKey.currentState;
    if (view == null || !view.canCheck) return;

    final correct = view.evaluate();
    final services = context.services;
    services.progress.recordAnswer(_question.topic, correct);

    if (correct) {
      services.sound.correct();
    } else {
      services.sound.wrong();
      services.review.enqueueWrongAnswer(
        _question.id,
        courseId: widget.course.id,
      );
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
      }
    });
  }

  Future<void> _next() async {
    if (!_checked) return;
    if (_hearts <= 0 || _index + 1 >= _questions.length) {
      await _finish();
      return;
    }
    setState(() {
      _index++;
      _attempt++;
      _checked = false;
      _wasCorrect = false;
      _aiText = null;
      _aiLoading = false;
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;

    final ratio = _correct / _questions.length;
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
      courseId: widget.course.id,
      levelIndex: widget.levelIndex,
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
      _confettiTrigger++;
    });
  }

  void _restart() {
    setState(() {
      _questions
        ..clear()
        ..addAll(_level.questions);
      _questions.shuffle();
      _index = 0;
      _hearts = 5;
      _correct = 0;
      _combo = 0;
      _rawXp = 0;
      _attempt++;
      _showIntro = false;
      _checked = false;
      _wasCorrect = false;
      _finished = false;
      _finishing = false;
      _stars = 0;
      _awardedXp = 0;
      _badges = const [];
      _aiText = null;
      _aiLoading = false;
    });
  }

  Future<void> _askAi() async {
    final s = context.s;
    final view = _viewKey.currentState;
    setState(() => _aiLoading = true);

    final result = await context.services.ai.explainMistake(
      language: context.services.settings.language,
      question: _question.promptFor(s.isArabic),
      userAnswer: view?.chosenAnswerText() ?? '',
      correctAnswer: _question.correctAnswerText(),
      code: _question.code,
    );

    if (!mounted) return;
    setState(() {
      _aiLoading = false;
      _aiText = result.ok ? result.text : s.t('aiOffline');
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    if (_finished) return Scaffold(body: SafeArea(child: _buildResult(s)));
    if (_showIntro) return Scaffold(body: SafeArea(child: _buildIntro(s)));
    return Scaffold(body: SafeArea(child: _buildLesson(s)));
  }

  // ---------------------------------------------------------------- intro card

  Widget _buildIntro(AppStrings s) {
    final level = _level;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _startLevel,
                    child: Text(s.t('levelIntroSkip')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: courseColor(widget.course).withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            courseIcon(widget.course.iconKey),
                            color: courseColor(widget.course),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            level.titleFor(s.isArabic),
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      s.t('beforeStart'),
                      style: const TextStyle(
                        color: blue,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      level.introFor(s.isArabic),
                      style: const TextStyle(fontSize: 17, height: 1.55),
                    ),
                    const SizedBox(height: 22),
                    Mascot(
                      mood: 'idle',
                      message: s.isArabic
                          ? 'رتّب أفكارك، ثم ابدأ التمارين. لا تقلق من الأخطاء، سنشرحها لك.'
                          : "Read the key ideas, then start. Mistakes are fine — I'll explain them.",
                    ),
                    const SizedBox(height: 22),
                    Text(
                      s.t('keyPoints'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final point in level.keyPointsFor(s.isArabic))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: green,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                point,
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: BigButton(
                label: s.t('startLevel'),
                icon: Icons.play_arrow_rounded,
                onPressed: _startLevel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------- lesson

  String _typeLabel(AppStrings s) {
    if (_question.type == QType.order) return s.t('typeOrder');
    if (_question.type == QType.match) return s.t('typeMatch');
    if (_question.code != null) return s.t('typeRead');
    return s.t('typeChoose');
  }

  Widget _buildLesson(AppStrings s) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 10, 14, 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.close, color: Colors.grey.shade600),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _index / _questions.length,
                    minHeight: 14,
                    backgroundColor: Colors.grey.shade300,
                    color: green,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_combo >= 2) ...[
                const Icon(Icons.local_fire_department, color: Colors.orange),
                Text(
                  '$_combo',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              const Icon(Icons.favorite, color: red),
              const SizedBox(width: 4),
              Text(
                '$_hearts',
                style: const TextStyle(
                  color: red,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.course.name.toUpperCase()}  •  ${_typeLabel(s)}',
                  style: TextStyle(
                    color: courseColor(widget.course),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 10),
                QuestionView(
                  key: _viewKey,
                  question: _question,
                  arabic: s.isArabic,
                  seed: _attempt,
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
        ),
        _bottomBar(s),
      ],
    );
  }

  Widget _bottomBar(AppStrings s) {
    final background = !_checked
        ? Colors.white
        : _wasCorrect
        ? const Color(0xFFD7FFB8)
        : const Color(0xFFFFDFE0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 340),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_checked) ...[
                Text(
                  _wasCorrect ? s.t('correctExclaim') : s.t('correctAnswerLabel'),
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: _wasCorrect ? darkGreen : red,
                  ),
                ),
                if (!_wasCorrect)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _question.correctAnswerText(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: red,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ),
                if (_wasCorrect && _combo >= 3)
                  Text(
                    s.t('comboBonus').replaceFirst('{combo}', '$_combo'),
                    style: const TextStyle(
                      color: Color(0xFFE07800),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 10),
                _explanationBox(s),
                if (!_wasCorrect) ...[
                  const SizedBox(height: 10),
                  if (_aiText != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: purple.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: purple,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'AI',
                                style: const TextStyle(
                                  color: purple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(_aiText!, style: const TextStyle(height: 1.4)),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _aiLoading ? null : _askAi,
                        icon: _aiLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(
                          _aiLoading ? s.t('aiThinking') : s.t('explainMistake'),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
              ],
              BigButton(
                label: _checked ? s.t('next') : s.t('check'),
                onPressed: _checked ? _next : (_canCheck ? _check : null),
                color: _checked && !_wasCorrect ? red : green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _explanationBox(AppStrings s) {
    final text = _question.explanationFor(s.isArabic);
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.t('explanationLabel'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 14.5, height: 1.45)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------- result

  Widget _buildResult(AppStrings s) {
    final won = _hearts > 0;
    final hasNext =
        _stars >= 1 &&
        widget.levelIndex + 1 < widget.course.levels.length;

    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    won ? Icons.emoji_events : Icons.heart_broken,
                    size: 84,
                    color: won ? Colors.amber : red,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    won ? s.t('levelComplete') : s.t('outOfHearts'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  starRow(_stars, size: 42),
                  const SizedBox(height: 10),
                  Text(
                    '${s.t('scoreLabel')}: $_correct / ${_questions.length}',
                    style: const TextStyle(fontSize: 19),
                  ),
                  if (!won)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        s.t('tryAgainHint'),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statCard(
                        s.t('xpEarned'),
                        '$_awardedXp',
                        Colors.amber.shade800,
                      ),
                      const SizedBox(width: 14),
                      _statCard(s.t('hearts'), '$_hearts', red),
                    ],
                  ),
                  if (_awardedXp == 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      s.t('practiceXpNote'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
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
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.amber.shade600,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(badge.icon),
                                const SizedBox(width: 6),
                                Text(
                                  '${s.t('newBadge')}: ${badge.titleFor(s.isArabic)}',
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
                    BigButton(
                      label: s.t('nextLevel'),
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonPage(
                            course: widget.course,
                            levelIndex: widget.levelIndex + 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (hasNext)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _restart,
                        child: Text(
                          s.t('practiceAgain'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  else
                    BigButton(
                      label: s.t('practiceAgain'),
                      onPressed: _restart,
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        s.t('backToLevels'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (won && _stars > 0)
          Positioned.fill(
            child: ConfettiOverlay(trigger: _confettiTrigger),
          ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      width: 128,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
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
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
