import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/achievement.dart';
import 'storage_service.dart';

/// Global learning progress: XP, stars, first-attempt bookkeeping and topic accuracy.
class ProgressService extends ChangeNotifier {
  ProgressService(this._store);

  final KeyValueStore _store;

  int _totalXp = 0;
  final Map<String, int> _stars = {};
  final Set<String> _attemptedLevels = {};
  final Set<String> _perfectLevels = {};
  final Map<String, TopicStat> _topicStats = {};

  int get totalXp => _totalXp;
  Map<String, int> get stars => Map.unmodifiable(_stars);
  Map<String, TopicStat> get topicStats => Map.unmodifiable(_topicStats);
  Set<String> get perfectLevels => Set.unmodifiable(_perfectLevels);

  String levelKey(String courseId, int levelIndex) => '$courseId:$levelIndex';

  int starsFor(String courseId, int levelIndex) =>
      _stars[levelKey(courseId, levelIndex)] ?? 0;

  bool isUnlocked(String courseId, int levelIndex) =>
      levelIndex == 0 || starsFor(courseId, levelIndex - 1) >= 1;

  bool isFirstAttempt(String courseId, int levelIndex) =>
      !_attemptedLevels.contains(levelKey(courseId, levelIndex));

  int get completedLevels =>
      _stars.values.where((value) => value >= 1).length;

  int get totalStars => _stars.values.fold(0, (sum, value) => sum + value);

  int rankIndexFor(int xp) {
    if (xp < 100) return 0;
    if (xp < 300) return 1;
    if (xp < 600) return 2;
    if (xp < 1000) return 3;
    return 4;
  }

  int get rankIndex => rankIndexFor(_totalXp);

  Future<void> load() async {
    _totalXp = _store.getInt('progress.totalXp') ?? 0;
    _stars
      ..clear()
      ..addAll(_decodeIntMap(_store.getString('progress.stars')));
    _attemptedLevels
      ..clear()
      ..addAll(_store.getStringList('progress.attempted') ?? const []);
    _perfectLevels
      ..clear()
      ..addAll(_store.getStringList('progress.perfect') ?? const []);
    _topicStats
      ..clear()
      ..addAll(_decodeTopics(_store.getString('progress.topics')));
    notifyListeners();
  }

  Future<void> save() async {
    await _store.setInt('progress.totalXp', _totalXp);
    await _store.setString('progress.stars', jsonEncode(_stars));
    await _store.setStringList(
      'progress.attempted',
      _attemptedLevels.toList(),
    );
    await _store.setStringList('progress.perfect', _perfectLevels.toList());
    await _store.setString(
      'progress.topics',
      jsonEncode(
        _topicStats.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
  }

  /// XP is paid in full only for the first attempt of a level.
  /// Replaying a level (practice) still updates stars but never pays XP again.
  Future<int> recordLevelResult({
    required String courseId,
    required int levelIndex,
    required int stars,
    required int rawXp,
  }) async {
    final key = levelKey(courseId, levelIndex);
    final firstAttempt = !_attemptedLevels.contains(key);
    _attemptedLevels.add(key);

    final awarded = firstAttempt ? rawXp : 0;
    _totalXp += awarded;

    if (stars > (_stars[key] ?? 0)) {
      _stars[key] = stars;
    }
    if (stars == 3) {
      _perfectLevels.add(key);
    }

    notifyListeners();
    await save();
    return awarded;
  }

  void grantStars(String courseId, int levelIndex, int stars) {
    final key = levelKey(courseId, levelIndex);
    if (stars > (_stars[key] ?? 0)) {
      _stars[key] = stars;
      notifyListeners();
      save();
    }
  }

  void recordAnswer(String topic, bool wasCorrect) {
    _topicStats[topic] = (_topicStats[topic] ?? const TopicStat()).record(
      wasCorrect,
    );
    save();
  }

  void reset() {
    _totalXp = 0;
    _stars.clear();
    _attemptedLevels.clear();
    _perfectLevels.clear();
    _topicStats.clear();
    notifyListeners();
  }

  Map<String, int> _decodeIntMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }

  Map<String, TopicStat> _decodeTopics(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(key, TopicStat.fromJson(value as Map<String, dynamic>)),
      );
    } catch (_) {
      return {};
    }
  }
}
