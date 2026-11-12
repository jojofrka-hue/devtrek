import 'package:coding_quest/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Question.fromJson', () {
    test('parses a choice question with bilingual content', () {
      final question = Question.fromJson({
        'id': 'cpp-basics-1',
        'type': 'choice',
        'topic': 'variables',
        'prompt': 'Which line declares a variable?',
        'promptAr': 'أي سطر يعرّف متغيراً؟',
        'options': ['int x = 3;', 'x = 3;', 'print(x);'],
        'answer': 0,
        'explanation': 'A declaration includes a type.',
        'explanationAr': 'التعريف يتضمن نوعاً.',
      });

      expect(question.type, QType.choice);
      expect(question.topic, 'variables');
      expect(question.promptFor(false), 'Which line declares a variable?');
      expect(question.promptFor(true), 'أي سطر يعرّف متغيراً؟');
      expect(question.explanationFor(true), 'التعريف يتضمن نوعاً.');
      expect(question.correctAnswerText(), 'int x = 3;');
    });

    test('falls back to English when Arabic is missing', () {
      final question = Question.fromJson({
        'id': 'q',
        'prompt': 'Hello',
        'options': ['a', 'b'],
      });

      expect(question.type, QType.choice);
      expect(question.promptFor(true), 'Hello');
      expect(question.explanation, '');
      expect(question.answer, 0);
    });

    test('parses order questions and joins the public answer', () {
      final question = Question.fromJson({
        'id': 'order-1',
        'type': 'order',
        'prompt': 'Arrange',
        'options': ['for (', 'i = 0;', ')'],
        'answer': 0,
        'explanation': 'Order matters',
      });

      expect(question.type, QType.order);
      expect(question.correctAnswerText(), 'for ( i = 0; )');
    });

    test('parses match pairs', () {
      final question = Question.fromJson({
        'id': 'match-1',
        'type': 'match',
        'prompt': 'Match',
        'pairs': [
          ['int', 'whole number'],
          ['float', 'decimal'],
        ],
        'answer': 0,
        'explanation': 'Types',
      });

      expect(question.type, QType.match);
      expect(question.pairs.length, 2);
      expect(question.correctAnswerText(), 'int = whole number\nfloat = decimal');
    });
  });
}
