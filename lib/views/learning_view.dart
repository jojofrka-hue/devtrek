import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../machine_structure/machine_lessons.dart';
import '../models/course.dart';
import '../models/question.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'challenge_view.dart';
import 'desktop_theme.dart';
import 'devtrek_track.dart';
import 'exercise_view.dart';
import 'fx.dart';

class LearningView extends StatefulWidget {
  const LearningView({super.key, required this.track});

  final DevTrekTrack track;

  @override
  State<LearningView> createState() => _LearningViewState();
}

class _LearningViewState extends State<LearningView> {
  int _tab = 0;
  ModuleDifficulty? _difficulty;
  ChallengeType? _challengeType;

  // Celebration trigger: fires the confetti burst the first time XP or
  // stars grow after the view is alive (e.g. returning from a lesson).
  ProgressService? _progress;
  int? _lastXp;
  int? _lastStars;
  bool _celebrating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final progress = context.services.progress;
    if (!identical(progress, _progress)) {
      _progress?.removeListener(_onProgress);
      _progress = progress;
      progress.addListener(_onProgress);
      _lastXp = progress.totalXp;
      _lastStars = progress.totalStars;
    }
  }

  void _onProgress() {
    final progress = _progress;
    if (progress == null) return;
    final xp = progress.totalXp;
    final stars = progress.totalStars;
    final gained =
        (_lastXp != null && xp > _lastXp!) ||
        (_lastStars != null && stars > _lastStars!);
    _lastXp = xp;
    _lastStars = stars;
    if (!gained || _celebrating || !mounted) return;
    _celebrating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ConfettiBurst.celebrate(context);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _celebrating = false);
      });
    });
  }

  @override
  void didUpdateWidget(covariant LearningView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track != widget.track) {
      _difficulty = null;
      _challengeType = null;
    }
  }

  @override
  void dispose() {
    _progress?.removeListener(_onProgress);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final s = context.s;
    final ar = s.isArabic;
    final palette = desktopPalette(context);
    final track = widget.track;
    final course = track.course(services);
    final moduleCount = track.moduleCount(services);

    return SafeArea(
      child: ListenableBuilder(
        listenable: services.progress,
        builder: (context, _) {
          final done = track.completedCount(services);
          final stars = track.starsCount(services);
          return ListView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: track.color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(track.icon, color: track.color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.label(ar),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.description(ar),
                          style: TextStyle(fontSize: 13, color: palette.subtle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (moduleCount > 0) ...[
                    StatPill(
                      icon: Icons.check_circle_outline_rounded,
                      text: '$done/$moduleCount',
                      color: green,
                    ),
                    StatPill(
                      icon: Icons.star_rounded,
                      text: '$stars/${moduleCount * 3}',
                      color: const Color(0xFFF5A623),
                    ),
                  ],
                  StatPill(
                    icon: Icons.bolt,
                    text: '${services.progress.totalXp} XP',
                    color: amber,
                  ),
                ],
              ),
              if (moduleCount > 0) ...[
                const SizedBox(height: 16),
                AnimatedBar(
                  value: moduleCount == 0 ? 0 : done / moduleCount,
                  color: green,
                  background: palette.track,
                  height: 8,
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  _TabPill(
                    icon: Icons.map_rounded,
                    label: ar ? 'المسار الموجه' : 'Guided Path',
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                  const SizedBox(width: 10),
                  _TabPill(
                    icon: Icons.grid_view_rounded,
                    label: ar ? 'بنك المستويات' : 'Levels Bank',
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (moduleCount == 0)
                _emptyState(ar, palette)
              else if (_tab == 0)
                ..._guidedModules(context, course, moduleCount)
              else
                ..._levelsBank(context, course, moduleCount, ar),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState(bool ar, DesktopPalette palette) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_open_rounded, color: palette.subtle),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ar
                  ? 'لا توجد وحدات في هذا المسار بعد.'
                  : 'This track has no modules yet.',
              style: TextStyle(color: palette.subtle),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _guidedModules(BuildContext context, Course? course, int count) {
    final widgets = <Widget>[
      Text(
        context.s.isArabic
            ? 'اقرأ الشرح ثم افهم وطبّق وابتكر. اجتز كل مستوى لفتح المستوى التالي.'
            : 'Read, understand, apply and create. Pass each level to unlock the next.',
        style: TextStyle(color: desktopPalette(context).subtle, height: 1.5),
      ),
      const SizedBox(height: 16),
    ];
    for (var i = 0; i < count; i++) {
      if (i > 0) {
        widgets.add(
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 36),
              child: Container(
                width: 2,
                height: 18,
                color: desktopPalette(context).cardBorder,
              ),
            ),
          ),
        );
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: course == null
              ? _MachineModuleCard(lesson: machineLessons[i], index: i)
              : _CourseModuleCard(course: course, index: i),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _levelsBank(
    BuildContext context,
    Course? course,
    int count,
    bool ar,
  ) {
    final s = context.s;
    final palette = desktopPalette(context);
    final difficulties = <ModuleDifficulty?>[null, ...ModuleDifficulty.values];
    final types = <ChallengeType?>[null, ...ChallengeType.values];
    final all = _exercises(course, count, ar);
    final filtered = [
      for (final exercise in all)
        if ((_difficulty == null || exercise.difficulty == _difficulty) &&
            (_challengeType == null || exercise.type == _challengeType))
          exercise,
    ];
    return [
      Text(
        ar
            ? 'كل تمارين المسار في مكان واحد — صفِّ حسب النوع أو الصعوبة وابدأ أي تمرين مباشرة.'
            : 'Every exercise in this track — filter by type or difficulty and jump straight in.',
        style: TextStyle(color: palette.subtle, height: 1.5),
      ),
      const SizedBox(height: 16),
      _FilterLabel(
        text: ar ? 'نوع التحدي' : 'CHALLENGE TYPE',
        color: palette.subtle,
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final type in types)
            _ChallengeTypeChip(
              type: type,
              selected: _challengeType == type,
              onTap: () => setState(() => _challengeType = type),
            ),
        ],
      ),
      const SizedBox(height: 16),
      _FilterLabel(text: ar ? 'الصعوبة' : 'DIFFICULTY', color: palette.subtle),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final difficulty in difficulties)
            _DifficultyChip(
              difficulty: difficulty,
              selected: _difficulty == difficulty,
              onTap: () => setState(() => _difficulty = difficulty),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (filtered.isEmpty) ...[
        Text(
          ar
              ? 'لا توجد تحديات تطابق التصفية.'
              : 'No challenges match these filters.',
        ),
        TextButton(
          onPressed: () => setState(() {
            _difficulty = null;
            _challengeType = null;
          }),
          child: Text(ar ? 'إعادة ضبط التصفية' : 'Reset filters'),
        ),
      ] else ...[
        Text(
          '${filtered.length} '
          '${s.t(filtered.length == 1 ? 'exercise' : 'exercises')}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: palette.subtle,
          ),
        ),
        const SizedBox(height: 10),
        for (final exercise in filtered)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ExerciseRow(exercise: exercise),
          ),
      ],
    ];
  }

  List<_Exercise> _exercises(Course? course, int count, bool ar) {
    final exercises = <_Exercise>[];
    for (var i = 0; i < count; i++) {
      final difficulty = difficultyOfIndex(i, count);
      if (course == null) {
        final lesson = machineLessons[i];
        final type =
            machineChallengeTypes(lesson).contains(ChallengeType.memory)
            ? ChallengeType.memory
            : ChallengeType.understanding;
        for (final quiz in lesson.quiz) {
          exercises.add(
            _Exercise(
              title: quiz.question(ar),
              sourceTitle: lesson.title(ar),
              type: type,
              difficulty: difficulty,
              courseId: 'machine',
              quiz: quiz,
            ),
          );
        }
      } else {
        final level = course.levels[i];
        for (final question in level.questions) {
          exercises.add(
            _Exercise(
              title: question.promptFor(ar),
              sourceTitle: level.titleFor(ar),
              type: typeOfQuestion(question),
              difficulty: difficulty,
              courseId: course.id,
              question: question,
            ),
          );
        }
      }
    }
    return exercises;
  }
}

/// One practice item flattened out of its level, so the bank can list and
/// filter exercises instead of repeating the guided level cards.
class _Exercise {
  const _Exercise({
    required this.title,
    required this.sourceTitle,
    required this.type,
    required this.difficulty,
    required this.courseId,
    this.question,
    this.quiz,
  });

  final String title;
  final String sourceTitle;
  final ChallengeType type;
  final ModuleDifficulty difficulty;
  final String courseId;
  final Question? question;
  final MachineQuiz? quiz;
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise});

  final _Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = desktopPalette(context);
    final type = exercise.type;
    final difficulty = exercise.difficulty;

    return HoverScale(
      hoverScale: 1.008,
      glow: type.color,
      radius: 16,
      child: Material(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExerciseView(
                question: exercise.question,
                quiz: exercise.quiz,
                courseId: exercise.courseId,
                sourceTitle: exercise.sourceTitle,
                type: type,
                difficulty: difficulty,
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.cardBorder, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(type.icon, size: 19, color: type.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            type.label(s.isArabic),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: type.color,
                            ),
                          ),
                          Text(
                            difficulty.label(s.isArabic),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: difficulty.color,
                            ),
                          ),
                          Text(
                            exercise.sourceTitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.subtle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.play_arrow_rounded, color: type.color, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = desktopPalette(context);
    return Expanded(
      child: HoverScale(
        hoverScale: 1.015,
        glow: selected ? green : null,
        radius: 12,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected ? green.withValues(alpha: 0.16) : palette.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? green.withValues(alpha: 0.55)
                    : palette.cardBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? green : palette.subtle),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: selected ? green : palette.subtle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final ModuleDifficulty? difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = desktopPalette(context);
    final color = difficulty?.color ?? palette.subtle;
    final label =
        difficulty?.label(s.isArabic) ?? (s.isArabic ? 'الكل' : 'All');
    return HoverScale(
      hoverScale: 1.05,
      glow: color,
      radius: 11,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.16) : palette.card,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected ? color : palette.cardBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (difficulty != null) ...[
                Icon(difficulty!.icon, size: 15, color: color),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? color : palette.subtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeTypeChip extends StatelessWidget {
  const _ChallengeTypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final ChallengeType? type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = desktopPalette(context);
    final color = type?.color ?? palette.subtle;
    final label = type?.label(s.isArabic) ?? (s.isArabic ? 'الكل' : 'All');
    final tooltip = type?.description(s.isArabic);
    final chip = HoverScale(
      hoverScale: 1.05,
      glow: color,
      radius: 11,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.16) : palette.card,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected ? color : palette.cardBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (type != null) ...[
                Icon(type!.icon, size: 15, color: color),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? color : palette.subtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip, child: chip);
  }
}

class BloomChips extends StatelessWidget {
  const BloomChips({super.key, required this.counts});

  final Map<BloomStage, int> counts;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final stage in BloomStage.values)
          Tooltip(
            message:
                '${stage.fullLabel(s.isArabic)} — ${stage.description(s.isArabic)}',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: stage.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(stage.icon, size: 13, color: stage.color),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${stage.label(s.isArabic)} ${counts[stage] ?? 0}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: stage.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _CourseModuleCard extends StatelessWidget {
  const _CourseModuleCard({required this.course, required this.index});

  final Course course;
  final int index;

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final s = context.s;
    final palette = desktopPalette(context);
    final level = course.levels[index];
    final stars = services.progress.starsFor(course.id, index);
    final locked = !isGuidedLevelUnlocked(services, course.id, index);

    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: HoverScale(
        glow: locked ? null : green,
        child: Material(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: locked
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChallengeView(
                        course: course,
                        levelIndex: index,
                        guided: true,
                      ),
                    ),
                  ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.cardBorder, width: 1.5),
              ),
              child: Row(
                children: [
                  AnimatedRing(
                    value: stars / 3,
                    color: stars > 0 ? green : palette.subtle,
                    background: palette.track,
                    size: 44,
                    stroke: 4,
                    center: locked
                        ? Icon(
                            Icons.lock_rounded,
                            size: 18,
                            color: palette.subtle,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: stars > 0 ? green : palette.subtle,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                level.titleFor(s.isArabic),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            starRow(stars, size: 16),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          level.subtitleFor(s.isArabic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: palette.subtle),
                        ),
                        const SizedBox(height: 8),
                        AnimatedBar(
                          value: stars / 3,
                          color: green,
                          background: palette.track,
                          height: 6,
                        ),
                        const SizedBox(height: 9),
                        BloomChips(counts: bloomCounts(level.questions)),
                      ],
                    ),
                  ),
                  if (!locked) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.chevron_right_rounded, color: palette.subtle),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MachineModuleCard extends StatelessWidget {
  const _MachineModuleCard({required this.lesson, required this.index});

  final MachineLesson lesson;
  final int index;

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final s = context.s;
    final palette = desktopPalette(context);
    final stars = services.progress.starsFor('machine', index);
    final locked = !isGuidedLevelUnlocked(services, 'machine', index);
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: HoverScale(
        glow: locked ? null : blue,
        child: Material(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: locked
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChallengeView(
                        machineLesson: lesson,
                        machineIndex: index,
                        guided: true,
                      ),
                    ),
                  ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.cardBorder, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      locked ? Icons.lock_rounded : lesson.icon,
                      size: 20,
                      color: locked ? palette.subtle : blue,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${index + 1}. ${lesson.title(s.isArabic)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (stars > 0) ...[
                              const SizedBox(width: 8),
                              starRow(stars, size: 15),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lesson.summary(s.isArabic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: palette.subtle),
                        ),
                        const SizedBox(height: 9),
                        BloomChips(
                          counts: {
                            BloomStage.understanding: lesson.terms.length,
                            BloomStage.application: lesson.quiz.length,
                            BloomStage.creation: 1,
                          },
                        ),
                      ],
                    ),
                  ),
                  if (!locked) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.chevron_right_rounded, color: palette.subtle),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
