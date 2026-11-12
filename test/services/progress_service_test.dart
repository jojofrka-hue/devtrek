import 'package:coding_quest/services/progress_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/memory_store.dart';

void main() {
  group('ProgressService XP rules', () {
    late MemoryStore store;
    late ProgressService progress;

    setUp(() {
      store = MemoryStore();
      progress = ProgressService(store);
    });

    test('pays full XP on the first attempt only', () async {
      final first = await progress.recordLevelResult(
        courseId: 'cpp',
        levelIndex: 0,
        stars: 2,
        rawXp: 70,
      );
      expect(first, 70);
      expect(progress.totalXp, 70);
      expect(progress.isFirstAttempt('cpp', 0), isFalse);

      final replay = await progress.recordLevelResult(
        courseId: 'cpp',
        levelIndex: 0,
        stars: 2,
        rawXp: 70,
      );
      expect(replay, 0, reason: 'practice must not farm XP');
      expect(progress.totalXp, 70);
    });

    test('replays can still improve stars and count perfect levels', () async {
      await progress.recordLevelResult(
        courseId: 'cpp',
        levelIndex: 0,
        stars: 1,
        rawXp: 40,
      );
      await progress.recordLevelResult(
        courseId: 'cpp',
        levelIndex: 0,
        stars: 3,
        rawXp: 90,
      );

      expect(progress.starsFor('cpp', 0), 3);
      expect(progress.completedLevels, 1);
      expect(progress.perfectLevels, contains('cpp:0'));
      expect(progress.totalStars, 3);
      expect(progress.totalXp, 40, reason: 'stars change, XP does not repeat');
    });

    test('each level is tracked independently', () async {
      await progress.recordLevelResult(
        courseId: 'cpp',
        levelIndex: 0,
        stars: 2,
        rawXp: 50,
      );
      final secondLevel = await progress.recordLevelResult(
        courseId: 'cpp',
        levelIndex: 1,
        stars: 1,
        rawXp: 30,
      );

      expect(secondLevel, 30);
      expect(progress.totalXp, 80);
      expect(progress.isUnlocked('cpp', 0), isTrue);
      expect(progress.isUnlocked('cpp', 1), isTrue);
      expect(progress.isUnlocked('cpp', 2), isTrue);
      expect(progress.isUnlocked('cpp', 3), isFalse);
    });

    test('derives ranks from accumulated XP', () {
      expect(progress.rankIndexFor(0), 0);
      expect(progress.rankIndexFor(99), 0);
      expect(progress.rankIndexFor(100), 1);
      expect(progress.rankIndexFor(300), 2);
      expect(progress.rankIndexFor(600), 3);
      expect(progress.rankIndexFor(1500), 4);
    });

    test('persists XP, stars and attempts across service instances', () async {
      await progress.recordLevelResult(
        courseId: 'cpp',
        levelIndex: 0,
        stars: 3,
        rawXp: 90,
      );
      progress.recordAnswer('loops', true);
      progress.recordAnswer('loops', false);
      await progress.save();

      final reloaded = ProgressService(store);
      await reloaded.load();

      expect(reloaded.totalXp, 90);
      expect(reloaded.starsFor('cpp', 0), 3);
      expect(reloaded.isFirstAttempt('cpp', 0), isFalse);
      expect(reloaded.topicStats['loops']!.attempts, 2);
      expect(reloaded.topicStats['loops']!.accuracy, 0.5);
    });

    test('placement stars unlock earlier levels without granting XP', () {
      progress.grantStars('cpp', 1, 2);

      expect(progress.starsFor('cpp', 1), 2);
      expect(progress.isUnlocked('cpp', 2), isTrue);
      expect(progress.totalXp, 0);
    });
  });
}
