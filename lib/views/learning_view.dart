import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../machine_structure/machine_lesson_page.dart';
import '../machine_structure/machine_lessons.dart';
import '../models/course.dart';
import '../screens/lesson_page.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'desktop_theme.dart';
import 'desktop_widgets.dart';
import 'devtrek_track.dart';

/// Dual-tab learning interface for the selected track:
/// tab 1 = Guided Path (sequential academic modules),
/// tab 2 = Levels Bank (browse by difficulty, direct entry).
class LearningView extends StatefulWidget {
  const LearningView({super.key, required this.track});

  final DevTrekTrack track;

  @override
  State<LearningView> createState() => _LearningViewState();
}

class _LearningViewState extends State<LearningView> {
  int _tab = 0;
  ModuleDifficulty? _difficulty;

  @override
  void didUpdateWidget(covariant LearningView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track != widget.track) _difficulty = null;
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
    final done = track.completedCount(services);
    final stars = track.starsCount(services);

    return SafeArea(
      child: ListenableBuilder(
        listenable: services.progress,
        builder: (context, _) {
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
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.subtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (course != null) ...[
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
                ],
              ),
              if (course != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: moduleCount == 0 ? 0 : done / moduleCount,
                    minHeight: 8,
                    backgroundColor: palette.track,
                    color: green,
                  ),
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
    final widgets = <Widget>[];
    for (var i = 0; i < count; i++) {
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
    final difficulties = <ModuleDifficulty?>[null, ...ModuleDifficulty.values];
    final filtered = [
      for (var i = 0; i < count; i++)
        if (_difficulty == null ||
            difficultyOfIndex(i, count) == _difficulty)
          i,
    ];
    return [
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
      const SizedBox(height: 14),
      if (filtered.isEmpty)
        _emptyState(ar, desktopPalette(context))
      else
        ResponsiveGrid(
          itemExtent: 152,
          children: [
            for (final i in filtered)
              course == null
                  ? _MachineChallengeCard(
                      lesson: machineLessons[i],
                      index: i,
                      total: count,
                    )
                  : _CourseChallengeCard(
                      course: course,
                      index: i,
                      total: count,
                    ),
          ],
        ),
    ];
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
              Icon(
                icon,
                size: 18,
                color: selected ? green : palette.subtle,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? green : palette.subtle,
                ),
              ),
            ],
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
    final label = difficulty?.label(s.isArabic) ?? (s.isArabic ? 'الكل' : 'All');
    return InkWell(
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
    );
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
                  Text(
                    '${stage.label(s.isArabic)} ${counts[stage] ?? 0}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: stage.color,
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
    final locked = !services.progress.isUnlocked(course.id, index);

    return Opacity(
      opacity: locked ? 0.55 : 1,
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
                    builder: (_) =>
                        LessonPage(course: course, levelIndex: index),
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
                    color: stars > 0
                        ? green.withValues(alpha: 0.18)
                        : palette.cardBorder.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: locked
                      ? Icon(Icons.lock_rounded, size: 19, color: palette.subtle)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 16,
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
                          Flexible(
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
                          Text(
                            difficultyOfIndex(index, course.levels.length)
                                .label(s.isArabic),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: difficultyOfIndex(
                                index,
                                course.levels.length,
                              ).color,
                            ),
                          ),
                          const Spacer(),
                          starRow(stars, size: 16),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        level.subtitleFor(s.isArabic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.subtle,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: stars / 3,
                          minHeight: 6,
                          backgroundColor: palette.track,
                          color: green,
                        ),
                      ),
                      const SizedBox(height: 9),
                      BloomChips(counts: bloomCounts(level.questions)),
                    ],
                  ),
                ),
                if (!locked) ...[
                  const SizedBox(width: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.subtle,
                  ),
                ],
              ],
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
    final s = context.s;
    final palette = desktopPalette(context);
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MachineLessonPage(lesson: lesson)),
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
                child: Icon(lesson.icon, size: 20, color: blue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${lesson.title(s.isArabic)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lesson.summary(s.isArabic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.subtle,
                      ),
                    ),
                    const SizedBox(height: 9),
                    BloomChips(
                      counts: {
                        BloomStage.understanding: lesson.terms.length,
                        BloomStage.application: lesson.quiz.length,
                        BloomStage.creation: 0,
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: palette.subtle),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseChallengeCard extends StatelessWidget {
  const _CourseChallengeCard({
    required this.course,
    required this.index,
    required this.total,
  });

  final Course course;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final s = context.s;
    final palette = desktopPalette(context);
    final level = course.levels[index];
    final stars = services.progress.starsFor(course.id, index);
    final difficulty = difficultyOfIndex(index, total);

    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonPage(course: course, levelIndex: index),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.cardBorder, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: difficulty.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(difficulty.icon, size: 13, color: difficulty.color),
                        const SizedBox(width: 5),
                        Text(
                          difficulty.label(s.isArabic),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: difficulty.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  starRow(stars, size: 15),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                level.titleFor(s.isArabic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                level.subtitleFor(s.isArabic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: palette.subtle),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 14,
                    color: palette.subtle,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${level.questions.length} '
                    '${s.isArabic ? 'سؤال' : 'questions'}',
                    style: TextStyle(fontSize: 11, color: palette.subtle),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    difficultyOfIndex(index, total).icon,
                    size: 14,
                    color: difficultyOfIndex(index, total).color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MachineChallengeCard extends StatelessWidget {
  const _MachineChallengeCard({
    required this.lesson,
    required this.index,
    required this.total,
  });

  final MachineLesson lesson;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = desktopPalette(context);
    final difficulty = difficultyOfIndex(index, total);
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MachineLessonPage(lesson: lesson)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.cardBorder, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: difficulty.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      difficulty.label(s.isArabic),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: difficulty.color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(lesson.icon, size: 20, color: blue),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                lesson.title(s.isArabic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${lesson.quiz.length} '
                '${s.isArabic ? 'اختبار' : 'quiz questions'}',
                style: TextStyle(fontSize: 11, color: palette.subtle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}