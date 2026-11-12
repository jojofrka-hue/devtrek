import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../i18n/app_strings.dart';
import '../models/achievement.dart';
import '../models/question.dart';
import '../models/review_card.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/question_view.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final GlobalKey<QuestionViewState> _viewKey = GlobalKey<QuestionViewState>();

  List<ReviewCard> _queue = [];
  int _index = 0;
  int _seed = 0;
  int _reviewed = 0;
  int _correct = 0;
  bool _loaded = false;
  bool _checked = false;
  bool _wasCorrect = false;
  bool _finished = false;
  bool _finishing = false;
  bool _startedWithCards = false;
  List<Achievement> _badges = const [];

  ReviewCard get _card => _queue[_index];

  Question? get _question =>
      context.services.repository.questionById(_card.questionId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    _loadQueue();
  }

  void _loadQueue() {
    final services = context.services;
    _queue = services.review
        .due()
        .where((card) => services.repository.questionById(card.questionId) != null)
        .toList();
    _startedWithCards = _queue.isNotEmpty;
    _finished = _queue.isEmpty;
  }

  void _check() {
    final view = _viewKey.currentState;
    final question = _question;
    if (view == null || question == null || !view.canCheck) return;

    final correct = view.evaluate();
    final services = context.services;
    services.review.scheduleReview(
      questionId: question.id,
      correct: correct,
      courseId: _card.courseId,
    );
    services.progress.recordAnswer(question.topic, correct);
    if (correct) {
      services.sound.correct();
    } else {
      services.sound.wrong();
    }

    setState(() {
      _checked = true;
      _wasCorrect = correct;
      _reviewed++;
      if (correct) _correct++;
    });
  }

  Future<void> _next() async {
    if (!_checked) return;
    if (_index + 1 >= _queue.length) {
      await _complete();
      return;
    }
    setState(() {
      _index++;
      _seed++;
      _checked = false;
      _wasCorrect = false;
    });
  }

  Future<void> _complete() async {
    if (_finishing) return;
    _finishing = true;
    final services = context.services;
    final before = Set<String>.of(services.achievements.unlocked);

    services.streak.recordActivity();
    await services.evaluateAchievements();

    final newIds = services.achievements.unlocked.difference(before);
    final badges = services.achievements.all
        .where((badge) => newIds.contains(badge.id))
        .toList();

    if (!mounted) return;
    setState(() {
      _finished = true;
      _badges = badges;
    });
  }

  void _restart() {
    setState(() {
      _loadQueue();
      _index = 0;
      _seed++;
      _reviewed = 0;
      _correct = 0;
      _checked = false;
      _wasCorrect = false;
      _finishing = false;
      _badges = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: _finished ? _buildDone(s) : _buildReview(s),
          ),
        ),
      ),
    );
  }

  Widget _buildReview(AppStrings s) {
    final question = _question;
    if (question == null) {
      return Center(child: Text(s.t('reviewEmpty')));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.grey.shade600),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  s.t('reviewTitle'),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${_index + 1} / ${_queue.length}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _queue.isEmpty ? 0 : _index / _queue.length,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: purple,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.t('reviewTitle').toUpperCase()}  •  '
                  '${s.t('boxLabel')} ${_card.box}',
                  style: const TextStyle(
                    color: purple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 10),
                QuestionView(
                  key: _viewKey,
                  question: question,
                  arabic: s.isArabic,
                  seed: _seed,
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
        ),
        _bottomBar(s, question),
      ],
    );
  }

  Widget _bottomBar(AppStrings s, Question question) {
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
        constraints: const BoxConstraints(maxHeight: 320),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _wasCorrect ? darkGreen : red,
                  ),
                ),
                if (!_wasCorrect)
                  Text(
                    question.correctAnswerText(),
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: red,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 8),
                if (question.explanationFor(s.isArabic).isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      question.explanationFor(s.isArabic),
                      style: const TextStyle(fontSize: 14.5, height: 1.45),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              BigButton(
                label: _checked ? s.t('next') : s.t('check'),
                onPressed: _checked
                    ? _next
                    : (_viewKey.currentState?.canCheck ?? false)
                    ? _check
                    : null,
                color: _checked && !_wasCorrect ? red : green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDone(AppStrings s) {
    final services = context.services;
    final nextDue = services.review.nextDueDate;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _startedWithCards ? Icons.task_alt : Icons.nights_stay,
            size: 82,
            color: _startedWithCards ? green : Colors.indigo,
          ),
          const SizedBox(height: 12),
          Text(
            _startedWithCards ? s.t('reviewComplete') : s.t('reviewEmpty'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          if (_startedWithCards) ...[
            const SizedBox(height: 8),
            Text(
              '${s.t('scoreLabel')}: $_correct / $_reviewed',
              style: const TextStyle(fontSize: 18),
            ),
          ],
          if (nextDue != null) ...[
            const SizedBox(height: 10),
            Text(
              '${s.t('reviewNextDue')}: '
              '${nextDue.year}-${nextDue.month.toString().padLeft(2, '0')}-'
              '${nextDue.day.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
          if (_badges.isNotEmpty) ...[
            const SizedBox(height: 14),
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
                    ),
                    child: Text(
                      '${badge.icon} ${badge.titleFor(s.isArabic)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          BigButton(
            label: s.t('reviewAgain'),
            onPressed: _restart,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                s.t('back'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
