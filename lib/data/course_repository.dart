import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/bug_task.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../models/question.dart';

/// Loads courses and bug-hunt tasks from JSON assets so content can change
/// without touching the UI code.
class CourseRepository {
  CourseRepository._(this.courses, this.bugTasks, this.placementQuestions) {
    for (final course in courses) {
      _coursesById[course.id] = course;
      for (final level in course.levels) {
        _levelsById[level.id] = level;
        for (final question in level.questions) {
          _questionsById[question.id] = question;
          _courseIdByQuestion[question.id] = course.id;
        }
      }
    }
    for (final question in placementQuestions) {
      _questionsById[question.id] = question;
    }
  }

  final List<Course> courses;
  final List<BugTask> bugTasks;
  final List<Question> placementQuestions;

  final Map<String, Course> _coursesById = {};
  final Map<String, Level> _levelsById = {};
  final Map<String, Question> _questionsById = {};
  final Map<String, String> _courseIdByQuestion = {};

  static const indexAsset = 'assets/data/index.json';

  factory CourseRepository.fromData({
    required List<Course> courses,
    List<BugTask> bugTasks = const [],
    List<Question> placementQuestions = const [],
  }) => CourseRepository._(courses, bugTasks, placementQuestions);

  static Future<CourseRepository> loadFromAssets({
    AssetBundle? bundle,
  }) async {
    final assets = bundle ?? rootBundle;
    final index =
        jsonDecode(await assets.loadString(indexAsset)) as Map<String, dynamic>;

    final coursePaths = ((index['courses'] as List?) ?? const []).cast<String>();
    final courses = <Course>[];
    for (final path in coursePaths) {
      final raw = jsonDecode(await assets.loadString(path)) as Map<String, dynamic>;
      courses.add(Course.fromJson(raw));
    }

    final bugPaths = index['bugHunts'] as String?;
    final bugTasks = <BugTask>[];
    if (bugPaths != null) {
      final raw = jsonDecode(await assets.loadString(bugPaths)) as Map<String, dynamic>;
      for (final task in (raw['tasks'] as List?) ?? const []) {
        bugTasks.add(BugTask.fromJson(task as Map<String, dynamic>));
      }
    }

    final placementPath = index['placement'] as String?;
    final placementQuestions = <Question>[];
    if (placementPath != null) {
      final raw =
          jsonDecode(await assets.loadString(placementPath)) as Map<String, dynamic>;
      for (final question in (raw['questions'] as List?) ?? const []) {
        placementQuestions.add(
          Question.fromJson(question as Map<String, dynamic>),
        );
      }
    }

    return CourseRepository._(courses, bugTasks, placementQuestions);
  }

  Course? courseById(String id) => _coursesById[id];

  Level? levelById(String id) => _levelsById[id];

  Question? questionById(String id) => _questionsById[id];

  String? courseIdOfQuestion(String questionId) =>
      _courseIdByQuestion[questionId];

  int get totalLevels =>
      courses.fold(0, (sum, course) => sum + course.levels.length);

  int get totalQuestions => _questionsById.length;
}
