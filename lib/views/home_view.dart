import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../machine_structure/machine_lessons.dart';
import '../screens/bug_hunt_page.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'desktop_theme.dart';
import 'desktop_widgets.dart';
import 'devtrek_track.dart';
import 'fx.dart';

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.track,
    required this.onOpenLearning,
    required this.onOpenPlayground,
    required this.onOpenSettings,
  });

  final DevTrekTrack track;
  final VoidCallback onOpenLearning;
  final VoidCallback onOpenPlayground;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final s = context.s;
    final palette = desktopPalette(context);

    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([
          services.progress,
          services.profile,
          services.streak,
          services.review,
          services.settings,
        ]),
        builder: (context, _) {
          final progress = services.progress;
          final streak = services.streak;
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
                          '${services.profile.name.trim().isEmpty ? s.t('welcomeBack') : s.t('welcomeName').replaceAll('{name}', services.profile.name)}'
                          '  •  ${s.t('rank')}: $rank',
                          style: TextStyle(fontSize: 13, color: palette.subtle),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: s.t('settingsTitle'),
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: onOpenSettings,
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
              const SizedBox(height: 16),
              _DailyGoalCard(
                track: track,
                services: services,
                onOpenLearning: onOpenLearning,
              ),
              const SizedBox(height: 28),
              SectionHeading(title: s.t('toolsSections')),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.card.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: palette.cardBorder, width: 1),
                ),
                child: ResponsiveGrid(
                  maxColumns: 2,
                  itemExtent: 124 * MediaQuery.textScalerOf(context).scale(1),
                  spacing: 16,
                  children: [
                    ToolCard(
                      icon: Icons.terminal_rounded,
                      title: s.t('playgroundTitle'),
                      subtitle: s.t('playgroundSubtitle'),
                      color: green,
                      onTap: onOpenPlayground,
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
                  ],
                ),
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
    final palette = desktopPalette(context);
    final moduleCount = track.moduleCount(services);
    final done = track.completedCount(services);
    final stars = track.starsCount(services);

    return HoverScale(
      glow: track.color,
      radius: 20,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AnimatedRing(
                  value: moduleCount == 0 ? 0 : done / moduleCount,
                  color: track.color,
                  background: palette.track,
                  size: 54,
                  stroke: 5,
                  center: Icon(track.icon, color: track.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.t('yourTrack'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: palette.subtle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.t('track_${track.name}'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$done/$moduleCount ${s.t('modulesDone')}'
                        '  •  $stars/${moduleCount * 3} ${s.t('stars')}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
              ),
              onPressed: onContinue,
              icon: const Icon(Icons.school_rounded, size: 18),
              label: Text(
                s.t('continueLearning'),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact progress summary: today's goal on one side, the most recent
/// activity on the other. Replaces the module grid, which lives in Learning.
class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({
    required this.track,
    required this.services,
    required this.onOpenLearning,
  });

  final DevTrekTrack track;
  final AppServices services;
  final VoidCallback onOpenLearning;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final ar = s.isArabic;
    final palette = desktopPalette(context);
    final streak = services.streak;
    final reached = streak.activeToday;
    final goalColor = reached ? green : amber;
    final due = services.review.dueCount;
    final count = track.moduleCount(services);
    final course = track.course(services);

    var lastIndex = -1;
    for (var i = count - 1; i >= 0; i--) {
      if (services.progress.starsFor(track.courseId, i) > 0) {
        lastIndex = i;
        break;
      }
    }
    final lastTitle = lastIndex < 0
        ? s.t('noActivityYet')
        : course == null
        ? machineLessons[lastIndex].title(ar)
        : course.levels[lastIndex].titleFor(ar);

    final goal = Row(
      children: [
        AnimatedRing(
          value: reached ? 1 : 0,
          color: goalColor,
          background: palette.track,
          size: 46,
          stroke: 4,
          center: Icon(
            reached ? Icons.check_rounded : Icons.flag_rounded,
            color: goalColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryLabel(text: s.t('dailyGoal'), color: palette.subtle),
              const SizedBox(height: 4),
              Text(
                reached ? s.t('dailyGoalDone') : s.t('dailyGoalPending'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${streak.current} ${s.t('streakDays')}',
                style: TextStyle(fontSize: 11.5, color: goalColor),
              ),
            ],
          ),
        ),
      ],
    );

    final recent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryLabel(text: s.t('recentActivity'), color: palette.subtle),
        const SizedBox(height: 4),
        Text(
          '${s.t('lastCompleted')}: $lastTitle',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              due > 0 ? Icons.replay_rounded : Icons.done_all_rounded,
              size: 15,
              color: due > 0 ? amber : green,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                due > 0 ? '$due ${s.t('reviewDue')}' : s.t('reviewAllDone'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: palette.subtle),
              ),
            ),
          ],
        ),
      ],
    );

    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenLearning,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.cardBorder, width: 1.5),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    goal,
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: palette.cardBorder),
                    ),
                    recent,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: goal),
                  Container(
                    width: 1,
                    height: 62,
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    color: palette.cardBorder,
                  ),
                  Expanded(child: recent),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SummaryLabel extends StatelessWidget {
  const _SummaryLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }
}
