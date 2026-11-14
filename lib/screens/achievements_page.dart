import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../theme/app_theme.dart';
import '../views/desktop_theme.dart';
import '../widgets/common.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = desktopPalette(context);
    final services = context.services;
    final s = context.s;

    return Scaffold(
      backgroundColor: palette.sidebar,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: services.achievements,
          builder: (context, _) {
            final all = services.achievements.all;
            final unlocked = services.achievements.unlockedCount;
            final ratio = all.isEmpty ? 0.0 : unlocked / all.length;

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
                    Expanded(
                      child: Text(
                        s.t('achievementsTitle'),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StatPill(
                      icon: Icons.military_tech,
                      text: '$unlocked/${all.length}',
                      color: const Color(0xFFF5A623),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      const Color(0xFFF5A623).withValues(alpha: 0.15),
                      palette.card,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.cardBorder, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$unlocked / ${all.length} ${s.t('unlockedCount')}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 12,
                          backgroundColor: palette.track,
                          color: const Color(0xFFF5A623),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: all.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.86,
                  ),
                  itemBuilder: (context, index) {
                    final badge = all[index];
                    final isUnlocked = services.achievements.isUnlocked(
                      badge.id,
                    );
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? Color.alphaBlend(
                                const Color(0xFFF5A623).withValues(alpha: 0.15),
                                palette.card,
                              )
                            : palette.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: palette.cardBorder, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            badge.icon,
                            style: TextStyle(
                              fontSize: 34,
                              color: isUnlocked ? null : palette.subtle,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            badge.titleFor(s.isArabic),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked
                                  ? Theme.of(context).colorScheme.onSurface
                                  : palette.subtle,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              badge.descriptionFor(s.isArabic),
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: palette.subtle,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                isUnlocked
                                    ? Icons.check_circle
                                    : Icons.lock_outline,
                                size: 15,
                                color: isUnlocked ? green : palette.subtle,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isUnlocked
                                    ? s.t('unlockedCount')
                                    : s.t('lockedLabel'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? green : palette.subtle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
