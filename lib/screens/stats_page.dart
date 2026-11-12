import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../i18n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/bar_chart.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.t('statsTitle'),
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _accuracyCard(s, accuracy, correct, attempts),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.75,
                  children: [
                    MiniStat(
                      label: s.t('totalXp'),
                      value: '${progress.totalXp}',
                      color: amber,
                    ),
                    MiniStat(
                      label: s.t('currentStreak'),
                      value: '${streak.current}',
                      color: const Color(0xFFFF7A00),
                    ),
                    MiniStat(
                      label: s.t('longestStreak'),
                      value: '${streak.longest}',
                      color: purple,
                    ),
                    MiniStat(
                      label: s.t('completedLevels'),
                      value: '${progress.completedLevels}',
                      color: green,
                    ),
                    MiniStat(
                      label: s.t('starsCollected'),
                      value: '${progress.totalStars}',
                      color: const Color(0xFFF5A623),
                    ),
                    MiniStat(
                      label: s.t('questionBank'),
                      value: '${services.repository.totalQuestions}',
                      color: blue,
                    ),
                    MiniStat(
                      label: s.t('reviewsDone'),
                      value: '${services.review.totalReviews}',
                      color: darkGreen,
                    ),
                    MiniStat(
                      label: s.t('bugsSolved'),
                      value: '${services.bugHunt.solvedCount}',
                      color: red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  s.t('byTopic'),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (ordered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insights, color: Colors.grey.shade500),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.t('noData'),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final entry in ordered)
                    TopicBar(
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
      ),
    );
  }

  String _topicLabel(AppStrings s, String topic) {
    final label = s.t('topic_$topic');
    return label == 'topic_$topic' ? topic : label;
  }

  Widget _accuracyCard(
    AppStrings s,
    double accuracy,
    int correct,
    int attempts,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE7F8D4), Color(0xFFDDF4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green.withValues(alpha: 0.4), width: 2),
      ),
      child: Row(
        children: [
          Text(
            '${(accuracy * 100).round()}%',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: darkGreen,
            ),
          ),
          const SizedBox(width: 14),
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
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
