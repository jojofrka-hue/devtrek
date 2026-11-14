import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/data/course_repository.dart';
import 'package:coding_quest/models/course.dart';
import 'package:coding_quest/models/level.dart';
import 'package:coding_quest/models/question.dart';
import 'package:coding_quest/playground/code_runner.dart';
import 'package:coding_quest/services/app_services.dart';
import 'package:coding_quest/views/desktop_shell.dart';
import 'package:coding_quest/views/exercise_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/memory_store.dart';

Question _q(
  String id, {
  QType type = QType.choice,
  String topic = 'basics',
  String prompt = 'Pick one',
}) => Question(
  id: id,
  type: type,
  topic: topic,
  prompt: prompt,
  promptAr: 'اختر',
  options: const ['A', 'B'],
  answer: 0,
  pairs: const [
    ['a', 'b'],
  ],
  explanation: 'e',
  explanationAr: 'ش',
);

Level _level(String id, String title, List<Question> questions) => Level(
  id: id,
  title: title,
  titleAr: title,
  subtitle: 'sub',
  subtitleAr: 'sub',
  intro: 'intro',
  introAr: 'intro',
  keyPointsEn: const ['point'],
  keyPointsAr: const ['نقطة'],
  questions: questions,
);

const _conceptPrompt = 'Name the concept';
const _bugPrompt = 'Find the bug in this code.';
const _memoryPrompt = 'Trace the value in memory';
const _creationPrompt = 'Order the build steps';

CourseRepository _repository() => CourseRepository.fromData(
  courses: [
    Course(
      id: 'c',
      name: 'C Foundations',
      subtitle: 'Track course',
      subtitleAr: 'دورة',
      iconKey: 'code',
      colorHex: '7A5CFF',
      levels: [
        _level('c-1', 'Concepts Level', [
          _q('c-1-1', prompt: _conceptPrompt),
          _q('c-1-2', prompt: 'Second concept question'),
        ]),
        _level('c-2', 'Bug Fix Level', [_q('c-2-1', prompt: _bugPrompt)]),
        _level('c-3', 'Memory Level', [
          _q('c-3-1', topic: 'memory', prompt: _memoryPrompt),
        ]),
        _level('c-4', 'Creation Level', [
          _q('c-4-1', type: QType.order, prompt: _creationPrompt),
        ]),
      ],
    ),
  ],
);

void main() {
  late AppServices services;

  setUp(() async {
    services = await AppServices.create(
      store: MemoryStore(),
      repository: _repository(),
      clock: () => DateTime(2026, 1, 10, 9),
    );
    await services.profile.completeOnboarding(
      name: 'Kamal',
      experience: '',
      goal: '',
      favoriteCourse: 'c',
      placementScore: -1,
    );
  });

  Future<void> pumpShell(WidgetTester tester) async {
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
          home: DesktopShell(
            playgroundRunner: CodeRunner(pythonCandidates: [], cCandidates: []),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Learning'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Levels Bank'));
    await tester.pumpAndSettle();
  }

  testWidgets('bank lists individual exercises, not level cards', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(find.text('CHALLENGE TYPE'), findsOneWidget);
    expect(find.text('DIFFICULTY'), findsOneWidget);
    expect(find.text('Understanding'), findsWidgets);
    expect(find.text('Fix the Code'), findsWidgets);
    expect(find.text('Memory Trace'), findsWidgets);
    expect(find.text('Creation'), findsWidgets);

    // Five questions across four levels, each on its own row.
    expect(find.text('5 exercises'), findsOneWidget);
    expect(find.text(_conceptPrompt), findsOneWidget);
    expect(find.text('Second concept question'), findsOneWidget);
    expect(find.text(_bugPrompt), findsOneWidget);
    expect(find.text(_memoryPrompt), findsOneWidget);
    expect(find.text(_creationPrompt), findsOneWidget);
    // The source level is shown as context, never as a card title.
    expect(find.text('Concepts Level'), findsNWidgets(2));
  });

  testWidgets('filtering by Fix the Code keeps only the bug exercise', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text('Fix the Code').first);
    await tester.pumpAndSettle();

    expect(find.text('1 exercise'), findsOneWidget);
    expect(find.text(_bugPrompt), findsOneWidget);
    expect(find.text(_conceptPrompt), findsNothing);
    expect(find.text(_memoryPrompt), findsNothing);
    expect(find.text(_creationPrompt), findsNothing);
  });

  testWidgets('filtering by Memory Trace keeps only the memory exercise', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text('Memory Trace').first);
    await tester.pumpAndSettle();

    expect(find.text(_memoryPrompt), findsOneWidget);
    expect(find.text(_conceptPrompt), findsNothing);
    expect(find.text(_bugPrompt), findsNothing);
  });

  testWidgets('filtering by Creation keeps only the ordering exercise', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text('Creation').first);
    await tester.pumpAndSettle();

    expect(find.text(_creationPrompt), findsOneWidget);
    expect(find.text(_conceptPrompt), findsNothing);
    expect(find.text(_memoryPrompt), findsNothing);
  });

  testWidgets('difficulty and type filters combine, and reset restores all', (
    tester,
  ) async {
    await pumpShell(tester);

    // Only the creation exercise is Advanced, so this pair matches nothing.
    await tester.tap(find.text('Advanced').first);
    await tester.pumpAndSettle();
    expect(find.text(_creationPrompt), findsOneWidget);
    expect(find.text(_conceptPrompt), findsNothing);

    await tester.tap(find.text('Understanding').first);
    await tester.pumpAndSettle();
    expect(find.text('No challenges match these filters.'), findsOneWidget);

    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();
    expect(find.text('5 exercises'), findsOneWidget);
  });

  testWidgets('an exercise opens directly and a wrong answer queues review', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text(_conceptPrompt));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseView), findsOneWidget);
    expect(find.text('Concepts Level'), findsOneWidget);

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHECK'));
    await tester.pumpAndSettle();

    expect(find.text('Correct answer:'), findsOneWidget);
    expect(services.review.dueCount, 1);
    // Single drills never pay XP or stars; those stay with full levels.
    expect(services.progress.totalXp, 0);
    expect(services.progress.totalStars, 0);
  });
}
