import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../machine_structure/machine_structure_page.dart';
import '../models/course.dart';
import '../playground/playground_page.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/course_visuals.dart';
import '../widgets/mascot.dart';
import 'achievements_page.dart';
import 'bug_hunt_page.dart';
import 'course_page.dart';
import 'review_page.dart';
import 'settings_page.dart';
import 'sort_visualizer_page.dart';
import 'stats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.t('appName'),
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
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
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${services.profile.name.isEmpty ? 'Coder' : services.profile.name}'
                  '  •  ${s.t('rank')}: $rank',
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                          : Colors.grey,
                    ),
                    StatPill(
                      icon: Icons.star_rounded,
                      text: '${progress.totalStars}',
                      color: const Color(0xFFF5A623),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Mascot(
                  mood: streak.activeToday ? 'happy' : 'idle',
                  message: streak.activeToday
                      ? (s.isArabic
                            ? 'أحسنت! حافظت على سلسلتك اليوم. واصل التقدم!'
                            : 'Great job! Your streak is safe today. Keep going!')
                      : (s.isArabic
                            ? 'أكمل مستوى واحداً اليوم للحفاظ على سلسلتك!'
                            : 'Finish one level today to keep your streak alive!'),
                ),
                const SizedBox(height: 22),
                Text(
                  s.t('chooseLanguage'),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                for (final course in _orderedCourses(services))
                  _courseCard(context, services, course),
                const SizedBox(height: 10),
                _quickActions(context, services, due),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _courseCard(
    BuildContext context,
    AppServices services,
    Course course,
  ) {
    final s = context.s;
    final progress = services.progress;
    var done = 0;
    var totalStars = 0;
    for (var i = 0; i < course.levels.length; i++) {
      final stars = progress.starsFor(course.id, i);
      if (stars >= 1) done++;
      totalStars += stars;
    }
    final isFavorite = services.profile.favoriteCourse == course.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CoursePage(course: course)),
        ),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: courseColor(course),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  courseIcon(course.iconKey),
                  color: Colors.white,
                  size: 29,
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
                            course.name,
                            style: const TextStyle(
                              fontSize: 18,
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
                    const SizedBox(height: 2),
                    Text(
                      course.subtitleFor(s.isArabic),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$done/${course.levels.length} ${s.t('levelsDone')}  •  '
                      '$totalStars/${course.levels.length * 3} ${s.t('stars')}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActions(
    BuildContext context,
    AppServices services,
    int due,
  ) {
    final s = context.s;
    return Column(
      children: [
        SectionCard(
          icon: Icons.terminal_rounded,
          title: s.t('playgroundTitle'),
          subtitle: s.t('playgroundSubtitle'),
          color: darkGreen,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlaygroundPage()),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.memory_rounded,
          title: s.t('machineTitle'),
          subtitle: s.t('machineSubtitle'),
          color: purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MachineStructurePage()),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
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
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.insights_rounded,
          title: s.t('statsTitle'),
          subtitle: s.t('byTopic'),
          color: blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StatsPage()),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.bug_report_outlined,
          title: s.t('bugHuntTitle'),
          subtitle: s.t('bugHuntSubtitle'),
          color: red,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BugHuntPage()),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.bar_chart_rounded,
          title: s.t('visualizerTitle'),
          subtitle: s.t('algorithm'),
          color: darkGreen,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SortVisualizerPage()),
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          icon: Icons.military_tech_rounded,
          title: s.t('achievementsTitle'),
          subtitle:
              '${services.achievements.unlockedCount} / ${services.achievements.all.length} ${s.t('unlockedCount')}',
          color: const Color(0xFFF5A623),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AchievementsPage()),
          ),
        ),
      ],
    );
  }
}
