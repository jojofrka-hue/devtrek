import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../i18n/app_strings.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'home_page.dart';

class PlacementPage extends StatefulWidget {
  const PlacementPage({
    super.key,
    required this.questions,
    required this.name,
    required this.experience,
    required this.goal,
    required this.favoriteCourse,
  });

  final List<Question> questions;
  final String name;
  final String experience;
  final String goal;
  final String favoriteCourse;

  @override
  State<PlacementPage> createState() => _PlacementPageState();
}

class _PlacementPageState extends State<PlacementPage> {
  int index = 0;
  int? selected;
  int score = 0;
  bool done = false;

  Question get question => widget.questions[index];

  void _answer() {
    if (selected == null) return;
    setState(() {
      if (selected == question.answer) score++;
      if (index + 1 >= widget.questions.length) {
        done = true;
      } else {
        index++;
        selected = null;
      }
    });
  }

  Future<void> _complete(int finalScore) async {
    final services = context.services;
    for (final course in services.repository.courses) {
      if (finalScore >= 3) {
        services.progress.grantStars(course.id, 0, 1);
      }
      if (finalScore >= 5 && course.levels.length > 1) {
        services.progress.grantStars(course.id, 1, 1);
      }
    }

    await services.profile.completeOnboarding(
      name: widget.name,
      experience: widget.experience,
      goal: widget.goal,
      favoriteCourse: widget.favoriteCourse,
      placementScore: finalScore,
    );
    await services.evaluateAchievements();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  String get _levelLabel {
    final s = context.s;
    if (score >= 5) return s.t('placementAdvanced');
    if (score >= 3) return s.t('placementIntermediate');
    return s.t('placementBeginner');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: done ? _buildResult(s) : _buildQuestion(s),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(AppStrings s) {
    final q = question;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 12, 8, 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.grey.shade600),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: index / widget.questions.length,
                    minHeight: 14,
                    backgroundColor: Colors.grey.shade300,
                    color: green,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _complete(0),
                child: Text(s.t('skip')),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.t('quickTest')}  •  ${index + 1} / ${widget.questions.length}',
                  style: const TextStyle(
                    color: blue,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  q.promptFor(s.isArabic),
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (q.code != null) ...[
                  const SizedBox(height: 18),
                  codeBox(q.code!),
                ],
                const SizedBox(height: 20),
                for (var i = 0; i < q.options.length; i++)
                  ChoiceCard(
                    title: q.options[i],
                    selected: selected == i,
                    onTap: () => setState(() => selected = i),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: BigButton(
            label: s.t('next'),
            onPressed: selected == null ? null : _answer,
          ),
        ),
      ],
    );
  }

  Widget _buildResult(AppStrings s) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flag_rounded, size: 86, color: green),
            const SizedBox(height: 12),
            Text(
              s.t('placementTitle'),
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '${s.t('placementScore')}: $score / ${widget.questions.length}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 6),
            Text(
              _levelLabel,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 28),
            BigButton(
              label: s.t('placementStart'),
              onPressed: () => _complete(score),
            ),
          ],
        ),
      ),
    );
  }
}
