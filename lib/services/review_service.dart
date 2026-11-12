import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/course_repository.dart';
import '../models/review_card.dart';
import 'storage_service.dart';

/// Leitner boxes: a correct review promotes the card and pushes it further
/// into the future; a wrong answer sends it back to box 1.
class ReviewService extends ChangeNotifier {
  ReviewService(
    this._store,
    this._repository, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const Map<int, int> intervals = {1: 0, 2: 1, 3: 3, 4: 7, 5: 16};

  final KeyValueStore _store;
  final CourseRepository _repository;
  final DateTime Function() _clock;

  final Map<String, ReviewCard> _cards = {};

  Map<String, ReviewCard> get cards => Map.unmodifiable(_cards);

  int get cardCount => _cards.length;

  int get totalReviews =>
      _cards.values.fold(0, (sum, card) => sum + card.reviews);

  int get dueCount => due().length;

  List<ReviewCard> due([DateTime? now]) {
    final today = _dateOnly(now ?? _clock());
    final list = _cards.values
        .where((card) => !card.due.isAfter(today))
        .toList()
      ..sort((a, b) {
        final byDue = a.due.compareTo(b.due);
        return byDue != 0 ? byDue : a.box.compareTo(b.box);
      });
    return list;
  }

  DateTime? get nextDueDate {
    if (_cards.isEmpty) return null;
    final dates = _cards.values.map((card) => card.due).toList()..sort();
    return dates.first;
  }

  Future<void> load() async {
    final raw = _store.getString('review.cards');
    _cards.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        for (final entry in decoded) {
          final card = ReviewCard.fromJson(entry as Map<String, dynamic>);
          if (_repository.questionById(card.questionId) != null) {
            _cards[card.questionId] = card;
          }
        }
      } catch (error) {
        debugPrint('Could not read review cards: $error');
      }
    }
    notifyListeners();
  }

  Future<void> save() async {
    await _store.setString(
      'review.cards',
      jsonEncode(_cards.values.map((card) => card.toJson()).toList()),
    );
  }

  /// Records a wrong answer from a normal lesson: the question joins the
  /// review queue (or returns to box 1 if it was already there).
  Future<void> enqueueWrongAnswer(String questionId, {String? courseId}) async {
    final existing = _cards[questionId];
    final today = _dateOnly(_clock());
    _cards[questionId] = ReviewCard(
      questionId: questionId,
      courseId: courseId ?? existing?.courseId ?? _repository.courseIdOfQuestion(questionId) ?? '',
      box: 1,
      due: today,
      reviews: existing?.reviews ?? 0,
      lapses: (existing?.lapses ?? 0) + 1,
    );
    notifyListeners();
    await save();
  }

  /// Applies the Leitner rule after a review answer.
  Future<ReviewCard> scheduleReview({
    required String questionId,
    required bool correct,
    String? courseId,
  }) async {
    final existing = _cards[questionId];
    final today = _dateOnly(_clock());
    final nextBox = correct
        ? math.min(5, (existing?.box ?? 1) + 1)
        : 1;
    final card = ReviewCard(
      questionId: questionId,
      courseId: courseId ?? existing?.courseId ?? _repository.courseIdOfQuestion(questionId) ?? '',
      box: nextBox,
      due: today.add(Duration(days: intervals[nextBox]!)),
      reviews: (existing?.reviews ?? 0) + 1,
      lapses: correct ? (existing?.lapses ?? 0) : (existing?.lapses ?? 0) + 1,
    );
    _cards[questionId] = card;
    notifyListeners();
    await save();
    return card;
  }

  Future<void> reset() async {
    _cards.clear();
    await _store.remove('review.cards');
    notifyListeners();
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
