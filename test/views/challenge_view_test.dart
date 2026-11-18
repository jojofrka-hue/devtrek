import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/data/course_repository.dart';
import 'package:coding_quest/machine_structure/machine_lessons.dart';
import 'package:coding_quest/models/course.dart';
import 'package:coding_quest/models/level.dart';
import 'package:coding_quest/models/question.dart';
import 'package:coding_quest/services/app_services.dart';
import 'package:coding_quest/views/challenge_view.dart';
import 'package:coding_quest/widgets/question_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/memory_store.dart';

Question _q(String id, QType type) => Question(
  id: id,
  type: type,
  topic: 'basics',
  prompt: 'Pick one',
  promptAr: 'اختر',
  options: const ['A', 'B'],
  answer: 0,
  pairs: const [
    ['a', 'b'],
  ],
  explanation: 'e',
  explanationAr: 'ش',
);

Level _level(List<Question> questions) => Level(
  id: 'l1',
  title: 'Mixed level',
  titleAr: 'مستوى',
  subtitle: 'sub',
  subtitleAr: 'sub',
  intro: 'intro',
  introAr: 'intro',
  keyPointsEn: const ['point'],
  keyPointsAr: const ['نقطة'],
  questions: questions,
);

Course _course(Level level) => Course(
  id: 'c',
  name: 'C Foundations',
  subtitle: 'Track course',
  subtitleAr: 'دورة',
  iconKey: 'code',
  colorHex: '7A5CFF',
  levels: [level],
);

const MachineLesson _lesson = MachineLesson(
  id: 'test_lesson',
  titleEn: 'Test Lesson',
  titleAr: 'درس اختبار',
  summaryEn: 'summary',
  summaryAr: 'ملخص',
  icon: Icons.memory_rounded,
  sections: [],
  terms: [
    MachineTerm(termEn: 'Bit', termAr: 'بت', defEn: '0 or 1', defAr: '0 أو 1'),
  ],
  quiz: [
    MachineQuiz(
      questionEn: 'Which one?',
      questionAr: 'أي واحد؟',
      optionsEn: ['A', 'B'],
      optionsAr: ['أ', 'ب'],
      correctIndex: 0,
      explanationEn: 'because',
      explanationAr: 'لأن',
    ),
  ],
);

void main() {
  late AppServices services;

  setUp(() async {
    services = await AppServices.create(
      store: MemoryStore(),
      repository: CourseRepository.fromData(
        courses: [
          _course(_level([_q('q1', QType.choice)])),
        ],
      ),
      clock: () => DateTime(2026, 1, 10, 9),
    );
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1280, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('course level is split into the three Bloom stages', (
    tester,
  ) async {
    final course = _course(
      _level([
        _q('q1', QType.choice),
        _q('q2', QType.match),
        _q('q3', QType.order),
      ]),
    );
    await pump(tester, ChallengeView(course: course, levelIndex: 0));

    // The explicit stepper labels each stage once.
    expect(find.text('Understanding'), findsOneWidget);
    expect(find.text('Application'), findsOneWidget);
    expect(find.text('Creation'), findsOneWidget);
    // The first stage banner is understanding, and a question is shown.
    expect(
      find.textContaining('Understanding & comprehension'),
      findsOneWidget,
    );
    expect(find.byType(QuestionView), findsOneWidget);
    expect(find.text('CHECK'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets(
    'machine lesson flows concepts → quiz → synthesis and completes',
    (tester) async {
      await pump(
        tester,
        const ChallengeView(machineLesson: _lesson, machineIndex: 0),
      );

      // Stage 1: understanding (key concepts), non-graded.
      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(find.text('Key concepts'), findsOneWidget);
      expect(find.text('Bit'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Stage 2: application (quiz), graded.
      expect(find.text('Which one?'), findsOneWidget);
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CHECK'));
      await tester.pumpAndSettle();
      expect(find.text('Correct!'), findsOneWidget);
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // Stage 3: creation (synthesis), non-graded, last step.
      expect(find.text('Synthesize what you learned'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Result: perfect score awards three stars for the machine track.
      expect(find.text('Level complete!'), findsOneWidget);
      expect(services.progress.starsFor('machine', 0), 3);
      expect(services.progress.totalXp, 10);
      expect(find.text('Hearts'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    },
  );

  testWidgets('hidden challenge counter still enforces the mistake budget', (
    tester,
  ) async {
    final course = _course(
      _level(List.generate(6, (index) => _q('q$index', QType.choice))),
    );
    await pump(tester, ChallengeView(course: course, levelIndex: 0));

    for (var attempt = 0; attempt < 5; attempt++) {
      expect(find.byType(QuestionView), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CHECK'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite), findsNothing);
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Out of hearts!'), findsOneWidget);
    expect(find.text('Score: 0 / 6'), findsOneWidget);
    expect(find.text('Hearts'), findsOneWidget);
    expect(find.byType(QuestionView), findsNothing);
    expect(services.progress.starsFor('c', 0), 0);
    expect(services.progress.totalXp, 0);
    expect(services.progress.isFirstAttempt('c', 0), isFalse);
    expect(services.review.cardCount, 5);
  });
}
