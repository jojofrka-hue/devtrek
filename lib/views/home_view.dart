import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../machine_structure/machine_structure_page.dart';
import '../models/course.dart';
import '../screens/achievements_page.dart';
import '../screens/bug_hunt_page.dart';
import '../screens/course_page.dart';
import '../screens/review_page.dart';
import '../screens/settings_page.dart';
import '../screens/sort_visualizer_page.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/course_visuals.dart';
import 'desktop_theme.dart';
import 'desktop_widgets.dart';
import 'devtrek_track.dart';

/// Desktop dashboard: track hero, stat pills, course grid and tool grid.
class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.track,
    required this.onOpenLearning,
    required this.onOpenPlayground,
    required this.onOpenStats,
  });

  final DevTrekTrack track;
  final VoidCallback onOpenLearning;
  final VoidCallback onOpenPlayground;
  final VoidCallback onOpenStats;

  List<Course> _orderedCourses(AppServices services) {
    final favorite = services.profile.favoriteCourse;
    final preferred = services.repository.courses
        .where((course) => course.id == favorite)
        .toList();
    final rest = services.repository.courses
        .where((course) => course.id != favorite)
        .toList();
    return [...preferred, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final s = context.s;
    final palette = desktopPalette(context);

    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([
          services.progress,
          services.streak,
          services.review,
          services.settings,
        ]),
        builder: (context, _) {
          final progress = services.progress;
          final streak = services.streak;
          final due = services.review.dueCount;
          final rank = s.t('rank_${progress.rankIndex}');

          return ListView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          devTrekBrand,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${services.profile.name.isEmpty ? 'Coder' : services.profile.name}'
                          '  •  ${s.t('rank')}: $rank',
                          style: TextStyle(fontSize: 13, color: palette.subtle),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: services.settings.toggleLanguage,
                    icon: const Icon(Icons.translate, size: 18),
                    label: Text(
                      s.t('languageShort'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: s.t('settingsTitle'),
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsPage(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  StatPill(
                    icon: Icons.bolt,
                    text: '${progress.totalXp} XP',
                    color: amber,
                  ),
                  StatPill(
                    icon: Icons.local_fire_department,
                    text: '${streak.current}',
                    color: streak.activeToday
                        ? const Color(0xFFFF7A00)
                        : palette.subtle,
                  ),
                  StatPill(
                    icon: Icons.star_rounded,
                    text: '${progress.totalStars}',
                    color: const Color(0xFFF5A623),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _TrackHero(
                track: track,
                services: services,
                onContinue: onOpenLearning,
              ),
              const SizedBox(height: 26),
              SectionHeading(title: s.isArabic ? 'الدورات' : 'Courses'),
              ResponsiveGrid(
                itemExtent: 118,
                children: [
                  for (final course in _orderedCourses(services))
                    _CourseCard(course: course),
                ],
              ),
              const SizedBox(height: 26),
              SectionHeading(
                title: s.isArabic ? 'الأدوات والأقسام' : 'Tools & Sections',
              ),
              ResponsiveGrid(
                children: [
                  ToolCard(
                    icon: Icons.terminal_rounded,
                    title: s.t('playgroundTitle'),
                    subtitle: s.t('playgroundSubtitle'),
                    color: green,
                    onTap: onOpenPlayground,
                  ),
                  ToolCard(
                    icon: Icons.memory_rounded,
                    title: s.t('machineTitle'),
                    subtitle: s.t('machineSubtitle'),
                    color: purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MachineStructurePage(),
                      ),
                    ),
                  ),
                  ToolCard(
                    icon: Icons.refresh_rounded,
                    title: s.t('reviewTitle'),
                    subtitle: due > 0
                        ? '$due ${s.t('reviewDue')}'
                        : s.t('reviewAllDone'),
                    color: purple,
                    badge: due > 0 ? '$due' : null,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReviewPage()),
                    ),
                  ),
                  ToolCard(
                    icon: Icons.insights_rounded,
                    title: s.t('statsTitle'),
                    subtitle: s.t('byTopic'),
                    color: blue,
                    onTap: onOpenStats,
                  ),
                  ToolCard(
                    icon: Icons.bug_report_outlined,
                    title: s.t('bugHuntTitle'),
                    subtitle: s.t('bugHuntSubtitle'),
                    color: red,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BugHuntPage()),
                    ),
                  ),
                  ToolCard(
                    icon: Icons.bar_chart_rounded,
                    title: s.t('visualizerTitle'),
                    subtitle: s.t('algorithm'),
                    color: green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SortVisualizerPage(),
                      ),
                    ),
                  ),
                  ToolCard(
                    icon: Icons.military_tech_rounded,
                    title: s.t('achievementsTitle'),
                    subtitle:
                        '${services.achievements.unlockedCount} / ${services.achievements.all.length} ${s.t('unlockedCount')}',
                    color: const Color(0xFFF5A623),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AchievementsPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrackHero extends StatelessWidget {
  const _TrackHero({
    required this.track,
    required this.services,
    required this.onContinue,
  });

  final DevTrekTrack track;
  final AppServices services;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final ar = s.isArabic;
    final palette = desktopPalette(context);
    final moduleCount = track.moduleCount(services);
    final done = track.completedCount(services);
    final stars = track.starsCount(services);
    final hasProgress = track.course(services) != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            track.color.withValues(alpha: 0.18),
            green.withValues(alpha: 0.07),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: track.color.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: track.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(track.icon, color: track.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ar ? 'مسارك الحالي' : 'YOUR TRACK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: palette.subtle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track.label(ar),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasProgress
                      ? '$done/$moduleCount ${ar ? 'وحدة مكتملة' : 'modules done'}'
                            '  •  $stars/${moduleCount * 3} ${ar ? 'نجمة' : 'stars'}'
                      : '$moduleCount ${ar ? 'درساً' : 'lessons'}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
            ),
            onPressed: onContinue,
            icon: const Icon(Icons.school_rounded, size: 18),
            label: Text(
              ar ? 'متابعة التعلم' : 'Continue',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final s = context.s;
    final palette = desktopPalette(context);
    final progress = services.progress;
    var done = 0;
    var totalStars = 0;
    for (var i = 0; i < course.levels.length; i++) {
      final stars = progress.starsFor(course.id, i);
      if (stars >= 1) done++;
      totalStars += stars;
    }
    final isFavorite = services.profile.favoriteCourse == course.id;
    final color = courseColor(course);

    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CoursePage(course: course)),
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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  courseIcon(course.iconKey),
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            course.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isFavorite) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: green,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              s.t('startHere'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      course.subtitleFor(s.isArabic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: palette.subtle),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$done/${course.levels.length} ${s.t('levelsDone')}  •  '
                      '$totalStars/${course.levels.length * 3} ${s.t('stars')}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}