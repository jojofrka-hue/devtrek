import '../data/course_repository.dart';
import '../models/achievement.dart';

/// Immutable snapshot used to evaluate achievement conditions, which keeps
/// the catalog free of Flutter/service dependencies and easy to unit test.
class AchievementContext {
  const AchievementContext({
    required this.completedLevels,
    required this.perfectLevels,
    required this.totalXp,
    required this.longestStreak,
    required this.reviews,
    required this.fixedBugs,
    required this.topics,
    required this.stars,
    required this.repository,
  });

  final int completedLevels;
  final int perfectLevels;
  final int totalXp;
  final int longestStreak;
  final int reviews;
  final int fixedBugs;
  final Map<String, TopicStat> topics;
  final Map<String, int> stars;
  final CourseRepository repository;

  bool get hasTopicMastery => topics.values.any(
    (stat) => stat.attempts >= 5 && stat.accuracy >= 0.9,
  );

  bool get hasCompletedCourse => repository.courses.any((course) {
    for (var i = 0; i < course.levels.length; i++) {
      if ((stars['${course.id}:$i'] ?? 0) < 1) return false;
    }
    return true;
  });
}

class AchievementDef {
  const AchievementDef(this.info, this.isMet);

  final Achievement info;
  final bool Function(AchievementContext context) isMet;
}

final List<AchievementDef> achievementCatalog = [
  AchievementDef(
    const Achievement(
      id: 'first_level',
      icon: '🎓',
      titleEn: 'First Steps',
      titleAr: 'الخطوة الأولى',
      descriptionEn: 'Complete your first level.',
      descriptionAr: 'أكمل أول مستوى لك.',
    ),
    (ctx) => ctx.completedLevels >= 1,
  ),
  AchievementDef(
    const Achievement(
      id: 'perfect_level',
      icon: '⭐',
      titleEn: 'Perfectionist',
      titleAr: 'الكمال',
      descriptionEn: 'Earn 3 stars on a level.',
      descriptionAr: 'احصل على 3 نجوم في مستوى.',
    ),
    (ctx) => ctx.perfectLevels >= 1,
  ),
  AchievementDef(
    const Achievement(
      id: 'streak_3',
      icon: '🔥',
      titleEn: 'On Fire',
      titleAr: 'متوهّج',
      descriptionEn: 'Keep a 3-day streak.',
      descriptionAr: 'حافظ على سلسلة 3 أيام.',
    ),
    (ctx) => ctx.longestStreak >= 3,
  ),
  AchievementDef(
    const Achievement(
      id: 'streak_7',
      icon: '📅',
      titleEn: 'Week Warrior',
      titleAr: 'محارب الأسبوع',
      descriptionEn: 'Keep a 7-day streak.',
      descriptionAr: 'حافظ على سلسلة 7 أيام.',
    ),
    (ctx) => ctx.longestStreak >= 7,
  ),
  AchievementDef(
    const Achievement(
      id: 'streak_30',
      icon: '🏅',
      titleEn: 'Unstoppable',
      titleAr: 'لا يُوقف',
      descriptionEn: 'Keep a 30-day streak.',
      descriptionAr: 'حافظ على سلسلة 30 يوماً.',
    ),
    (ctx) => ctx.longestStreak >= 30,
  ),
  AchievementDef(
    const Achievement(
      id: 'xp_100',
      icon: '⚡',
      titleEn: 'Getting Started',
      titleAr: 'بداية قوية',
      descriptionEn: 'Collect 100 XP.',
      descriptionAr: 'اجمع 100 نقطة خبرة.',
    ),
    (ctx) => ctx.totalXp >= 100,
  ),
  AchievementDef(
    const Achievement(
      id: 'xp_500',
      icon: '🚀',
      titleEn: 'High Voltage',
      titleAr: 'طاقة عالية',
      descriptionEn: 'Collect 500 XP.',
      descriptionAr: 'اجمع 500 نقطة خبرة.',
    ),
    (ctx) => ctx.totalXp >= 500,
  ),
  AchievementDef(
    const Achievement(
      id: 'xp_1000',
      icon: '👑',
      titleEn: 'XP Legend',
      titleAr: 'أسطورة الخبرة',
      descriptionEn: 'Collect 1000 XP.',
      descriptionAr: 'اجمع 1000 نقطة خبرة.',
    ),
    (ctx) => ctx.totalXp >= 1000,
  ),
  AchievementDef(
    const Achievement(
      id: 'review_10',
      icon: '🧠',
      titleEn: 'Memory Master',
      titleAr: 'سيد الذاكرة',
      descriptionEn: 'Finish 10 spaced-repetition reviews.',
      descriptionAr: 'أكمل 10 مراجعات بالتكرار المتباعد.',
    ),
    (ctx) => ctx.reviews >= 10,
  ),
  AchievementDef(
    const Achievement(
      id: 'bug_first',
      icon: '🐞',
      titleEn: 'Bug Hunter',
      titleAr: 'صائد الأخطاء',
      descriptionEn: 'Fix your first broken program.',
      descriptionAr: 'أصلح أول برنامج معطوب.',
    ),
    (ctx) => ctx.fixedBugs >= 1,
  ),
  AchievementDef(
    const Achievement(
      id: 'topic_master',
      icon: '🎯',
      titleEn: 'Topic Master',
      titleAr: 'متقن الموضوع',
      descriptionEn: 'Reach 90% accuracy in a topic (5+ answers).',
      descriptionAr: 'اصل إلى دقة 90% في موضوع (5 إجابات أو أكثر).',
    ),
    (ctx) => ctx.hasTopicMastery,
  ),
  AchievementDef(
    const Achievement(
      id: 'course_complete',
      icon: '🗺️',
      titleEn: 'Course Champion',
      titleAr: 'بطل الدورة',
      descriptionEn: 'Complete every level of one course.',
      descriptionAr: 'أكمل كل مستويات دورة واحدة.',
    ),
    (ctx) => ctx.hasCompletedCourse,
  ),
];
