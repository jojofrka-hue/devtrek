import 'package:coding_quest/services/review_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/memory_store.dart';

void main() {
  group('ReviewService (Leitner)', () {
    late MemoryStore store;
    late DateTime now;
    late ReviewService review;

    setUp(() {
      store = MemoryStore();
      now = DateTime(2026, 1, 10, 8);
      review = ReviewService(
        store,
        buildRepository(),
        clock: () => now,
      );
    });

    test('wrong answers enter box 1 and are due immediately', () async {
      await review.enqueueWrongAnswer('q1');

      final card = review.cards['q1']!;
      expect(card.box, 1);
      expect(card.lapses, 1);
      expect(review.dueCount, 1);
      expect(review.due().single.questionId, 'q1');
    });

    test('a correct review promotes the card and schedules it in the future', () async {
      await review.enqueueWrongAnswer('q1');
      await review.scheduleReview(questionId: 'q1', correct: true);

      final card = review.cards['q1']!;
      expect(card.box, 2);
      expect(card.due, DateTime(2026, 1, 11));
      expect(card.reviews, 1);
      expect(review.dueCount, 0);

      now = DateTime(2026, 1, 11, 8);
      expect(review.dueCount, 1);
    });

    test('box intervals follow 1, 3, 7 and 16 days', () async {
      await review.enqueueWrongAnswer('q1');

      await review.scheduleReview(questionId: 'q1', correct: true);
      expect(review.cards['q1']!.due, DateTime(2026, 1, 11));

      await review.scheduleReview(questionId: 'q1', correct: true);
      expect(review.cards['q1']!.box, 3);
      expect(review.cards['q1']!.due, DateTime(2026, 1, 13));

      await review.scheduleReview(questionId: 'q1', correct: true);
      expect(review.cards['q1']!.box, 4);
      expect(review.cards['q1']!.due, DateTime(2026, 1, 17));

      await review.scheduleReview(questionId: 'q1', correct: true);
      expect(review.cards['q1']!.box, 5);

      await review.scheduleReview(questionId: 'q1', correct: true);
      expect(review.cards['q1']!.box, 5, reason: 'box 5 is the cap');
      expect(review.cards['q1']!.due, DateTime(2026, 1, 26));
    });

    test('a wrong review sends the card back to box 1 due today', () async {
      await review.enqueueWrongAnswer('q1');
      await review.scheduleReview(questionId: 'q1', correct: true);
      await review.scheduleReview(questionId: 'q1', correct: true);
      expect(review.cards['q1']!.box, 3);

      await review.scheduleReview(questionId: 'q1', correct: false);

      final card = review.cards['q1']!;
      expect(card.box, 1);
      expect(card.due, DateTime(2026, 1, 10));
      expect(card.lapses, 2);
      expect(review.dueCount, 1);
    });

    test('review cards persist across service instances', () async {
      await review.enqueueWrongAnswer('q1');
      await review.scheduleReview(questionId: 'q1', correct: true);

      final reloaded = ReviewService(store, buildRepository(), clock: () => now);
      await reloaded.load();

      expect(reloaded.cardCount, 1);
      expect(reloaded.cards['q1']!.box, 2);
      expect(reloaded.cards['q1']!.courseId, 'cpp');
    });

    test('cards tied to unknown questions are dropped on load', () async {
      store.data['review.cards'] =
          '[{"questionId":"ghost","courseId":"cpp","box":1,"due":"2026-01-10","reviews":0,"lapses":0}]';

      await review.load();
      expect(review.cardCount, 0);
    });

    test('totalReviews counts every review answer', () async {
      await review.enqueueWrongAnswer('q1');
      await review.scheduleReview(questionId: 'q1', correct: true);
      await review.scheduleReview(questionId: 'q1', correct: false);

      expect(review.totalReviews, 2);
    });
  });
}
