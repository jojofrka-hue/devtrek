import 'package:coding_quest/machine_structure/machine_lessons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog covers the core architecture topics', () {
    expect(machineLessons.length, greaterThanOrEqualTo(6));
    expect(
      machineLessons.map((l) => l.id).toSet().length,
      machineLessons.length,
    );
  });

  test('every lesson is fully bilingual and non-empty', () {
    for (final lesson in machineLessons) {
      expect(lesson.titleEn, isNotEmpty);
      expect(lesson.titleAr, isNotEmpty);
      expect(lesson.summaryEn, isNotEmpty);
      expect(lesson.summaryAr, isNotEmpty);
      expect(lesson.sections, isNotEmpty);
      expect(lesson.terms, isNotEmpty);
      expect(lesson.quiz, isNotEmpty);
      for (final section in lesson.sections) {
        expect(section.headingEn, isNotEmpty);
        expect(section.headingAr, isNotEmpty);
        expect(section.bodyEn, isNotEmpty);
        expect(section.bodyAr, isNotEmpty);
      }
      for (final term in lesson.terms) {
        expect(term.termEn, isNotEmpty);
        expect(term.termAr, isNotEmpty);
        expect(term.defEn, isNotEmpty);
        expect(term.defAr, isNotEmpty);
      }
    }
  });

  test('quiz options align across languages and answers are valid', () {
    for (final lesson in machineLessons) {
      for (final quiz in lesson.quiz) {
        expect(quiz.optionsEn.length, quiz.optionsAr.length);
        expect(quiz.optionsEn.length, greaterThanOrEqualTo(2));
        expect(quiz.correctIndex, inInclusiveRange(0, quiz.optionsEn.length - 1));
        expect(quiz.questionEn, isNotEmpty);
        expect(quiz.questionAr, isNotEmpty);
        expect(quiz.explanationEn, isNotEmpty);
        expect(quiz.explanationAr, isNotEmpty);
        for (final option in [...quiz.optionsEn, ...quiz.optionsAr]) {
          expect(option, isNotEmpty);
        }
      }
    }
  });
}