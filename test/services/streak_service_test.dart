import 'package:coding_quest/services/streak_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/memory_store.dart';

void main() {
  group('StreakService', () {
    late MemoryStore store;
    late DateTime now;
    late StreakService streak;

    setUp(() {
      store = MemoryStore();
      now = DateTime(2026, 3, 10, 9, 30);
      streak = StreakService(store, clock: () => now);
    });

    test('formats day keys with zero padding', () {
      expect(StreakService.dayKeyFor(DateTime(2026, 1, 5)), '2026-01-05');
      expect(StreakService.dayKeyFor(DateTime(2026, 11, 30)), '2026-11-30');
    });

    test('first activity starts the streak, second activity same day is a no-op', () {
      expect(streak.recordActivity(), isTrue);
      expect(streak.current, 1);
      expect(streak.activeToday, isTrue);

      expect(streak.recordActivity(), isFalse);
      expect(streak.current, 1);
    });

    test('consecutive days increase the streak and longest value', () {
      streak.recordActivity();
      now = now.add(const Duration(days: 1));
      streak.recordActivity();
      now = now.add(const Duration(days: 1));
      streak.recordActivity();

      expect(streak.current, 3);
      expect(streak.longest, 3);
    });

    test('skipping a day resets the current streak but keeps the record', () {
      streak.recordActivity();
      now = now.add(const Duration(days: 1));
      streak.recordActivity();
      now = now.add(const Duration(days: 3));
      streak.recordActivity();

      expect(streak.current, 1);
      expect(streak.longest, 2);
    });

    test('load drops a stale streak while preserving the record', () async {
      store.data['streak.current'] = 6;
      store.data['streak.longest'] = 9;
      store.data['streak.lastDay'] = '2026-02-01';

      await streak.load();

      expect(streak.current, 0);
      expect(streak.longest, 9);
      expect(streak.activeToday, isFalse);
    });

    test('load keeps a streak that was active yesterday', () async {
      store.data['streak.current'] = 4;
      store.data['streak.longest'] = 4;
      store.data['streak.lastDay'] = '2026-03-09';

      await streak.load();
      expect(streak.current, 4);

      streak.recordActivity();
      expect(streak.current, 5, reason: 'today follows the stored yesterday');
    });

    test('reset clears persisted streak data', () async {
      streak.recordActivity();
      await streak.reset();

      expect(streak.current, 0);
      expect(streak.lastDay, isNull);
      expect(store.data.containsKey('streak.lastDay'), isFalse);
    });
  });
}
