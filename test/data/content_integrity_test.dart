import 'dart:convert';
import 'dart:io';

import 'package:coding_quest/models/bug_task.dart';
import 'package:coding_quest/models/course.dart';
import 'package:coding_quest/models/question.dart';
import 'package:coding_quest/services/bug_validation.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  group('course assets', () {
    final index = _readJson('assets/data/index.json');
    final coursePaths = (index['courses'] as List).cast<String>();
    final courses = [
      for (final path in coursePaths) Course.fromJson(_readJson(path)),
    ];

    test('the index lists at least five courses', () {
      expect(coursePaths.length, greaterThanOrEqualTo(5));
      expect(courses.map((course) => course.id).toSet().length, courses.length);
    });

    test('every question has a unique id and valid answer data', () {
      final ids = <String>{};
      for (final course in courses) {
        expect(course.levels, isNotEmpty, reason: course.id);
        for (final level in course.levels) {
          expect(level.questions, isNotEmpty, reason: level.id);
          for (final question in level.questions) {
            expect(ids.add(question.id), isTrue, reason: 'duplicate ${question.id}');
            expect(question.topic, isNotEmpty, reason: question.id);
            expect(question.prompt, isNotEmpty, reason: question.id);
            expect(question.promptAr, isNotEmpty, reason: question.id);
            expect(question.explanation, isNotEmpty, reason: question.id);
            expect(question.explanationAr, isNotEmpty, reason: question.id);

            switch (question.type) {
              case QType.choice:
                expect(question.options.length, greaterThanOrEqualTo(2));
                expect(question.answer, inInclusiveRange(0, question.options.length - 1));
              case QType.order:
                expect(question.options.length, greaterThanOrEqualTo(2));
              case QType.match:
                expect(question.pairs, isNotEmpty);
                for (final pair in question.pairs) {
                  expect(pair.length, 2, reason: question.id);
                  expect(pair[0], isNotEmpty);
                  expect(pair[1], isNotEmpty);
                }
            }
          }
        }
      }
      expect(ids.length, greaterThanOrEqualTo(100));
    });

    test('every level has an intro, key points and a level id', () {
      for (final course in courses) {
        for (final level in course.levels) {
          expect(level.id, isNotEmpty);
          expect(level.intro, isNotEmpty, reason: level.id);
          expect(level.introAr, isNotEmpty, reason: level.id);
          expect(level.keyPointsFor(false), isNotEmpty, reason: level.id);
          expect(level.keyPointsFor(true), isNotEmpty, reason: level.id);
        }
      }
    });
  });

  group('bug hunt assets', () {
    final index = _readJson('assets/data/index.json');
    final raw = _readJson(index['bugHunts'] as String);
    final tasks = [
      for (final entry in raw['tasks'] as List)
        BugTask.fromJson(entry as Map<String, dynamic>),
    ];

    test('tasks have unique ids and bilingual prose', () {
      final ids = <String>{};
      for (final task in tasks) {
        expect(ids.add(task.id), isTrue, reason: 'duplicate ${task.id}');
        expect(task.title, isNotEmpty);
        expect(task.titleAr, isNotEmpty);
        expect(task.hint, isNotEmpty);
        expect(task.hintAr, isNotEmpty);
      }
    });

    test('each reference solution satisfies its own checks', () {
      for (final task in tasks) {
        final result = validateBugFix(task, task.solution);
        expect(result.isSolved, isTrue, reason: task.id);
      }
    });

    test('each broken program fails its own checks', () {
      for (final task in tasks) {
        final result = validateBugFix(task, task.brokenCode);
        expect(result.isSolved, isFalse, reason: task.id);
      }
    });
  });

  group('placement assets', () {
    test('placement questions parse with answers and explanations', () {
      final index = _readJson('assets/data/index.json');
      final raw = _readJson(index['placement'] as String);
      final questions = [
        for (final entry in raw['questions'] as List)
          Question.fromJson(entry as Map<String, dynamic>),
      ];

      expect(questions.length, greaterThanOrEqualTo(5));
      for (final question in questions) {
        expect(question.prompt, isNotEmpty);
        expect(question.promptAr, isNotEmpty);
        expect(question.explanation, isNotEmpty);
        expect(question.answer, inInclusiveRange(0, question.options.length - 1));
      }
    });
  });
}
