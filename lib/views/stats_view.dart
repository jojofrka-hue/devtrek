import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../i18n/app_strings.dart';
import '../theme/app_theme.dart';
import 'desktop_theme.dart';
import 'desktop_widgets.dart';

/// Desktop statistics: accuracy hero, stat-tile grid and per-topic bars.
class StatsView extends StatelessWidget {
  const StatsView({super.key});

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
        ]),
        builder: (context, _) {
          final progress = services.progress;
          final streak = services.streak;
          final topics = progress.topicStats;

          var attempts = 0;
          var correct = 0;
          for (final stat in topics.values) {
            attempts += stat.attempts;
            correct += stat.correct;
          }
          final accuracy = attempts == 0 ? 0.0 : correct / attempts;

          final ordered = topics.entries.toList()
            ..sort((a, b) => b.value.attempts.compareTo(a.value.attempts));

          return ListView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
            children: [
              Text(
                s.t('statsTitle'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      green.withValues(alpha: 0.16),
                      blue.withValues(alpha: 0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: green.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '${(accuracy * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.t('overallAccuracy'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${s.t('correctAnswers')} $correct / $attempts '
                            '${s.t('attempts')}',
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.subtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ResponsiveGrid(
                itemExtent: 92 * MediaQuery.textScalerOf(context).scale(1),
                children: [
                  StatTile(
                    label: s.t('totalXp'),
                    value: '${progress.totalXp}',
                    color: amber,
                    icon: Icons.bolt_rounded,
                  ),
                  StatTile(
                    label: s.t('currentStreak'),
                    value: '${streak.current}',
                    color: const Color(0xFFFF7A00),
                    icon: Icons.local_fire_department_rounded,
                  ),
                  StatTile(
                    label: s.t('longestStreak'),
                    value: '${streak.longest}',
                    color: purple,
                    icon: Icons.trending_up_rounded,
                  ),
                  StatTile(
                    label: s.t('completedLevels'),
                    value: '${progress.completedLevels}',
                    color: green,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  StatTile(
                    label: s.t('starsCollected'),
                    value: '${progress.totalStars}',
                    color: const Color(0xFFF5A623),
                    icon: Icons.star_rounded,
                  ),
                  StatTile(
                    label: s.t('questionBank'),
                    value: '${services.repository.totalQuestions}',
                    color: blue,
                    icon: Icons.quiz_outlined,
                  ),
                  StatTile(
                    label: s.t('reviewsDone'),
                    value: '${services.review.totalReviews}',
                    color: darkGreen,
                    icon: Icons.refresh_rounded,
                  ),
                  StatTile(
                    label: s.t('bugsSolved'),
                    value: '${services.bugHunt.solvedCount}',
                    color: red,
                    icon: Icons.bug_report_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              SectionHeading(title: s.t('byTopic')),
              if (ordered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: palette.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.cardBorder, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insights, color: palette.subtle),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.t('noData'),
                          style: TextStyle(color: palette.subtle),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final entry in ordered)
                  _TopicRow(
                    label: _topicLabel(s, entry.key),
                    accuracy: entry.value.accuracy,
                    trailing:
                        '${entry.value.correct}/${entry.value.attempts} '
                        '${s.t('attempts')}',
                  ),
            ],
          );
        },
      ),
    );
  }

  String _topicLabel(AppStrings s, String topic) {
    final label = s.t('topic_$topic');
    return label == 'topic_$topic' ? topic : label;
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({
    required this.label,
    required this.accuracy,
    required this.trailing,
  });

  final String label;
  final double accuracy;
  final String trailing;

  Color get _color {
    if (accuracy >= 0.75) return green;
    if (accuracy >= 0.5) return amber;
    return red;
  }

  @override
  Widget build(BuildContext context) {
    final palette = desktopPalette(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                trailing,
                style: TextStyle(fontSize: 12, color: palette.subtle),
              ),
              const SizedBox(width: 8),
              Text(
                '${(accuracy * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: accuracy.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: palette.track,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
