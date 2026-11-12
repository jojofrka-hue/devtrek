import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// Tracks consecutive active days. A day counts as active when a lesson
/// is completed (or a review session is finished).
class StreakService extends ChangeNotifier {
  StreakService(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final KeyValueStore _store;
  final DateTime Function() _clock;

  int current = 0;
  int longest = 0;
  String? lastDay;

  bool get activeToday => lastDay == todayKey;

  static String dayKeyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String get todayKey => dayKeyFor(_clock());

  Future<void> load() async {
    current = _store.getInt('streak.current') ?? 0;
    longest = _store.getInt('streak.longest') ?? 0;
    lastDay = _store.getString('streak.lastDay');

    if (lastDay != todayKey && lastDay != _yesterdayKey) {
      current = 0;
    }
    notifyListeners();
  }

  /// Returns true when the streak counter advanced.
  bool recordActivity() {
    final today = todayKey;
    if (lastDay == today) return false;

    if (lastDay == _yesterdayKey) {
      current += 1;
    } else {
      current = 1;
    }
    longest = math.max(longest, current);
    lastDay = today;

    _store.setInt('streak.current', current);
    _store.setInt('streak.longest', longest);
    _store.setString('streak.lastDay', today);
    notifyListeners();
    return true;
  }

  Future<void> reset() async {
    current = 0;
    longest = 0;
    lastDay = null;
    await _store.remove('streak.current');
    await _store.remove('streak.longest');
    await _store.remove('streak.lastDay');
    notifyListeners();
  }

  String get _yesterdayKey {
    final now = _clock();
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    return dayKeyFor(yesterday);
  }
}
