import 'package:coding_quest/data/achievements_catalog.dart';
import 'package:coding_quest/data/course_repository.dart';
import 'package:coding_quest/models/achievement.dart';
import 'package:coding_quest/services/achievement_service.dart';
import 'package:coding_quest/services/progress_service.dart';
import 'package:coding_quest/services/review_service.dart';
import 'package:coding_quest/services/streak_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/memory_store.dart';

bool _isMet(String id, AchievementContext context) =>
    achievementCatalog.firstWhere((entry) => entry.info.id == id).isMet(context);

AchievementContext _context({
  int completedLevels = 0,
  int perfectLevels = 0,
  int totalXp = 0,
  int longestStreak = 0,
  int reviews = 0,
  int fixedBugs = 0,
  Map<String, TopicStat> topics = const {},
  Map<String, int> stars = const {},
  CourseRepository? repository,
}) => AchievementContext(
  completedLevels: completedLevels,
  perfectLevels: perfectLevels,
  totalXp: totalXp,
  longestStreak: longestStreak,
  reviews: reviews,
  fixedBugs: fixedBugs,
  topics: topics,
  stars: stars,
  repository: repository ?? buildRepository(),
);

void main() {
  group('achievement catalog predicates', () {
    test('unlocks the early progression badges at their thresholds', () {
      expect(_isMet('first_level', _context(completedLevels: 1)), isTrue);
      expect(_isMet('first_level', _context()), isFalse);

      expect(_isMet('perfect_level', _context(perfectLevels: 1)), isTrue);
      expect(_isMet('streak_3', _context(longestStreak: 3)), isTrue);
      expect(_isMet('streak_7', _context(longestStreak: 6)), isFalse);
      expect(_isMet('streak_30', _context(longestStreak: 30)), isTrue);
      expect(_isMet('xp_100', _context(totalXp: 100)), isTrue);
      expect(_isMet('xp_500', _context(totalXp: 499)), isFalse);
      expect(_isMet('xp_1000', _context(totalXp: 1000)), isTrue);
      expect(_isMet('review_10', _context(reviews: 10)), isTrue);
      expect(_isMet('bug_first', _context(fixedBugs: 1)), isTrue);
    });

    test('topic mastery needs 5 answers at 90% accuracy', () {
      expect(
        _isMet(
          'topic_master',
          _context(topics: {'loops': const TopicStat(attempts: 4, correct: 4)}),
        ),
        isFalse,
      );
      expect(
        _isMet(
          'topic_master',
          _context(topics: {'loops': const TopicStat(attempts: 5, correct: 4)}),
        ),
        isFalse,
        reason: '80% is not mastery',
      );
      expect(
        _isMet(
          'topic_master',
          _context(topics: {'loops': const TopicStat(attempts: 5, correct: 5)}),
        ),
        isTrue,
      );
    });

    test('course completion requires at least one star on every level', () {
      final repo = buildRepository(
        courses: [
          buildCourse(
            levels: [buildLevel(id: 'l1'), buildLevel(id: 'l2')],
          ),
        ],
      );

      expect(
        _isMet('course_complete', _context(repository: repo, stars: {'cpp:0': 2})),
        isFalse,
      );
      expect(
        _isMet(
          'course_complete',
          _context(repository: repo, stars: {'cpp:0': 2, 'cpp:1': 1}),
        ),
        isTrue,
      );
    });
  });

  group('AchievementService', () {
    test('unlocks, persists and does not re-announce badges', () async {
      final store = MemoryStore();
      final repo = buildRepository();
      final progress = ProgressService(store);
      final streak = StreakService(store, clock: () => DateTime(2026, 1, 1));
      final review = ReviewService(
        store,
        repo,
        clock: () => DateTime(2026, 1, 1),
      );
      final service = AchievementService(store, repo);

      await progress.recordLevelResult(
        courseId: 'cpp',
        levelIndex: 0,
        stars: 3,
        rawXp: 120,
      );
      streak.recordActivity();

      final first = await service.evaluate(
        progress: progress,
        streak: streak,
        review: review,
        fixedBugs: 0,
      );
      final ids = first.map((badge) => badge.id).toSet();

      expect(ids, contains('first_level'));
      expect(ids, contains('perfect_level'));
      expect(ids, contains('xp_100'));
      expect(ids, contains('course_complete'));
      expect(ids, isNot(contains('streak_3')));

      final second = await service.evaluate(
        progress: progress,
        streak: streak,
        review: review,
        fixedBugs: 0,
      );
      expect(second, isEmpty);

      final reloaded = AchievementService(store, repo);
      await reloaded.load();
      expect(reloaded.unlockedCount, ids.length);
      expect(reloaded.isUnlocked('first_level'), isTrue);
    });

    test('reset clears unlocked badges', () async {
      final store = MemoryStore();
      final repo = buildRepository();
      final progress = ProgressService(store);
      final streak = StreakService(store, clock: () => DateTime(2026, 1, 1));
      final review = ReviewService(
        store,
        repo,
        clock: () => DateTime(2026, 1, 1),
      );
      final service = AchievementService(store, repo);

      await progress.recordLevelResult(
        courseId: 'cpp',
        levelIndex: 0,
        stars: 1,
        rawXp: 10,
      );
      await service.evaluate(
        progress: progress,
        streak: streak,
        review: review,
        fixedBugs: 0,
      );
      expect(service.unlockedCount, greaterThan(0));

      await service.reset();
      expect(service.unlockedCount, 0);
      expect(store.data.containsKey('achievements.unlocked'), isFalse);
    });
  });
}
