import 'package:coding_quest/models/bug_task.dart';
import 'package:coding_quest/services/bug_hunt_progress_service.dart';
import 'package:coding_quest/services/bug_validation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/memory_store.dart';

BugTask _semicolonTask() => BugTask.fromJson({
  'id': 'cpp-semicolon',
  'language': 'cpp',
  'title': 'Missing semicolon',
  'titleAr': 'فاصلة منقوطة ناقصة',
  'prompt': 'Fix the declaration.',
  'promptAr': 'أصلح التعريف.',
  'brokenCode': 'int x = 5\ncout << x;',
  'hint': 'Statements end with a semicolon.',
  'hintAr': 'تنتهي التعليمات بفاصلة منقوطة.',
  'solution': 'int x = 5;\ncout << x;',
  'explanation': 'Each C++ statement needs a semicolon.',
  'explanationAr': 'كل تعليمة في C++ تحتاج فاصلة منقوطة.',
  'checks': {
    'mustMatchAny': [r'int\s+x\s*=\s*5\s*;'],
    'mustNotMatch': [r'=\s*5\s*\n'],
  },
});

void main() {
  group('BugTask.fromJson', () {
    test('reads checks and falls back for missing Arabic fields', () {
      final task = BugTask.fromJson({
        'id': 'js-const',
        'title': 'Use const',
        'brokenCode': 'let x = 1;',
        'checks': {
          'mustMatchAny': [r'\bconst\b'],
        },
      });

      expect(task.title, 'Use const');
      expect(task.titleFor(true), 'Use const');
      expect(task.mustMatchAny, [r'\bconst\b']);
      expect(task.mustNotMatch, isEmpty);
      expect(task.language, '');
    });
  });

  group('validateBugFix', () {
    test('accepts the reference solution', () {
      final result = validateBugFix(_semicolonTask(), 'int x = 5;\ncout << x;');

      expect(result.isSolved, isTrue);
      expect(result.problems, isEmpty);
    });

    test('reports a missing required pattern for the broken program', () {
      final result = validateBugFix(_semicolonTask(), 'int x = 5\ncout << x;');

      expect(result.isSolved, isFalse);
      expect(result.problems, contains('missing-required-pattern'));
      expect(result.problems, contains(startsWith('forbidden-pattern')));
    });

    test('normalizes CRLF input', () {
      final result = validateBugFix(
        _semicolonTask(),
        'int x = 5;\r\ncout << x;',
      );
      expect(result.isSolved, isTrue);
    });

    test('a task without checks accepts any non-empty code', () {
      final task = BugTask.fromJson({
        'id': 'free',
        'title': 'Free',
        'brokenCode': '',
      });
      expect(validateBugFix(task, 'anything').isSolved, isTrue);
    });
  });

  group('BugHuntProgressService', () {
    test('marks solved tasks, persists them and stays idempotent', () async {
      final store = MemoryStore();
      final service = BugHuntProgressService(store);
      final task = _semicolonTask();

      final wrong = await service.submit(task, 'int x = 5');
      expect(wrong.isSolved, isFalse);
      expect(service.solvedCount, 0);

      final fixed = await service.submit(task, task.solution);
      expect(fixed.isSolved, isTrue);
      expect(service.solvedCount, 1);

      await service.submit(task, task.solution);
      expect(service.solvedCount, 1);

      final reloaded = BugHuntProgressService(store);
      await reloaded.load();
      expect(reloaded.isSolved(task.id), isTrue);
    });
  });
}
