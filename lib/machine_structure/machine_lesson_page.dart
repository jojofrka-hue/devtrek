import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../i18n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'machine_lessons.dart';

class MachineLessonPage extends StatefulWidget {
  const MachineLessonPage({super.key, required this.lesson});

  final MachineLesson lesson;

  @override
  State<MachineLessonPage> createState() => _MachineLessonPageState();
}

class _MachineLessonPageState extends State<MachineLessonPage> {
  final Map<int, int> _answers = {};

  bool get _quizDone => _answers.length == widget.lesson.quiz.length;

  int get _correct {
    var count = 0;
    for (var i = 0; i < widget.lesson.quiz.length; i++) {
      if (_answers[i] == widget.lesson.quiz[i].correctIndex) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lesson = widget.lesson;

    return Scaffold(
      appBar: AppBar(title: Text(lesson.title(s.isArabic))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              lesson.summary(s.isArabic),
              style: const TextStyle(fontSize: 14.5, height: 1.6),
            ),
          ),
          const SizedBox(height: 18),
          for (final section in lesson.sections) ...[
            Text(
              section.heading(s.isArabic),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.body(s.isArabic),
              style: const TextStyle(fontSize: 14.5, height: 1.7),
            ),
            if (section.code != null) ...[
              const SizedBox(height: 10),
              codeBox(section.code!, fontSize: 13.5),
            ],
            const SizedBox(height: 18),
          ],
          Text(
            s.t('machineTerms'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          for (final term in lesson.terms)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      term.term(s.isArabic),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      term.definition(s.isArabic),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          Text(
            s.t('machineQuiz'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < lesson.quiz.length; i++) ...[
            Text(
              '${i + 1}. ${lesson.quiz[i].question(s.isArabic)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            for (var j = 0; j < lesson.quiz[i].options(s.isArabic).length; j++)
              _option(lesson.quiz[i], i, j, s),
            if (_answers.containsKey(i)) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${s.t('explanationLabel')} '
                  '${lesson.quiz[i].explanation(s.isArabic)}',
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
          if (_quizDone) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${s.t('machineQuizResult')}: '
                '$_correct/${lesson.quiz.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            BigButton(
              label: s.t('machineRetry'),
              icon: Icons.refresh_rounded,
              onPressed: () => setState(_answers.clear),
            ),
          ],
        ],
      ),
    );
  }

  Widget _option(MachineQuiz quiz, int question, int option, AppStrings s) {
    final answered = _answers.containsKey(question);
    final chosen = _answers[question] == option;
    final isCorrect = option == quiz.correctIndex;
    var border = Colors.grey.shade300;
    var background = Colors.white;
    IconData? trailing;
    if (answered) {
      if (isCorrect) {
        border = green;
        background = green.withValues(alpha: 0.1);
        trailing = Icons.check_circle_rounded;
      } else if (chosen) {
        border = red;
        background = red.withValues(alpha: 0.08);
        trailing = Icons.cancel_rounded;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: answered
            ? null
            : () => setState(() => _answers[question] = option),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  quiz.options(s.isArabic)[option],
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Icon(trailing, color: border, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}