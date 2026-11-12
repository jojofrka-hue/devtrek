import 'package:flutter/foundation.dart';

import '../data/achievements_catalog.dart';
import '../data/course_repository.dart';
import '../models/achievement.dart';
import 'progress_service.dart';
import 'review_service.dart';
import 'storage_service.dart';
import 'streak_service.dart';

class AchievementService extends ChangeNotifier {
  AchievementService(this._store, this._repository);

  final KeyValueStore _store;
  final CourseRepository _repository;
  final Set<String> _unlocked = {};

  Set<String> get unlocked => Set.unmodifiable(_unlocked);

  List<Achievement> get all =>
      achievementCatalog.map((def) => def.info).toList(growable: false);

  int get unlockedCount => _unlocked.length;

  bool isUnlocked(String id) => _unlocked.contains(id);

  Future<void> load() async {
    _unlocked
      ..clear()
      ..addAll(_store.getStringList('achievements.unlocked') ?? const []);
    notifyListeners();
  }

  Future<List<Achievement>> evaluate({
    required ProgressService progress,
    required StreakService streak,
    required ReviewService review,
    required int fixedBugs,
  }) async {
    final context = AchievementContext(
      completedLevels: progress.completedLevels,
      perfectLevels: progress.perfectLevels.length,
      totalXp: progress.totalXp,
      longestStreak: streak.longest,
      reviews: review.totalReviews,
      fixedBugs: fixedBugs,
      topics: progress.topicStats,
      stars: progress.stars,
      repository: _repository,
    );

    final newlyUnlocked = <Achievement>[];
    for (final def in achievementCatalog) {
      if (_unlocked.contains(def.info.id)) continue;
      if (def.isMet(context)) {
        _unlocked.add(def.info.id);
        newlyUnlocked.add(def.info);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await _store.setStringList('achievements.unlocked', _unlocked.toList());
      notifyListeners();
    }
    return newlyUnlocked;
  }

  Future<void> reset() async {
    _unlocked.clear();
    await _store.remove('achievements.unlocked');
    notifyListeners();
  }
}
