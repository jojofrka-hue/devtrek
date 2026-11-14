import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/data/course_repository.dart';
import 'package:coding_quest/models/course.dart';
import 'package:coding_quest/models/level.dart';
import 'package:coding_quest/models/question.dart';
import 'package:coding_quest/playground/code_runner.dart';
import 'package:coding_quest/services/app_services.dart';
import 'package:coding_quest/views/desktop_shell.dart';
import 'package:coding_quest/views/devtrek_onboarding.dart';
import 'package:coding_quest/views/exercise_view.dart';
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

Course _course(String id, String name, List<Level> levels) => Course(
  id: id,
  name: name,
  subtitle: 'Track course',
  subtitleAr: 'دورة المسار',
  iconKey: 'code',
  colorHex: '7A5CFF',
  levels: levels,
);

CourseRepository _tracksRepository() => CourseRepository.fromData(
  courses: [
    _course('c', 'C Foundations', [
      _level('c-1', 'Basics of C', [
        _q('c-1-1', QType.choice),
        _q('c-1-2', QType.choice),
        _q('c-1-3', QType.order),
      ]),
      _level('c-2', 'Pointers Deep Dive', [_q('c-2-1', QType.match)]),
      _level('c-3', 'Memory Mastery', [_q('c-3-1', QType.choice)]),
    ]),
    _course('python', 'Python Foundations', [
      _level('python-1', 'Python Basics', [_q('python-1-1', QType.choice)]),
      _level('python-2', 'Python Loops', [_q('python-2-1', QType.choice)]),
      _level('python-3', 'Python Functions', [_q('python-3-1', QType.choice)]),
    ]),
  ],
);

void main() {
  late AppServices services;

  setUp(() async {
    services = await AppServices.create(
      store: MemoryStore(),
      repository: _tracksRepository(),
      clock: () => DateTime(2026, 1, 10, 9),
    );
  });

  Future<void> pumpAt(WidgetTester tester, Widget home) async {
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

  Future<void> pumpShell(WidgetTester tester) => pumpAt(
    tester,
    DesktopShell(
      playgroundRunner: CodeRunner(pythonCandidates: [], cCandidates: []),
    ),
  );

  Future<void> completeOnboarding(String trackId) async {
    await services.profile.completeOnboarding(
      name: 'Kamal',
      experience: '',
      goal: '',
      favoriteCourse: trackId,
      placementScore: -1,
    );
  }

  testWidgets('DevTrek onboarding collects the name and the main track', (
    tester,
  ) async {
    await pumpAt(
      tester,
      ListenableBuilder(
        listenable: services.profile,
        builder: (context, _) => services.profile.onboarded
            ? DesktopShell(
                playgroundRunner: CodeRunner(
                  pythonCandidates: [],
                  cCandidates: [],
                ),
              )
            : const DevTrekOnboarding(),
      ),
    );

    expect(find.text('DevTrek'), findsOneWidget);
    expect(find.text('Start your journey'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), 'Sara');
    await tester.pump();
    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start your journey'));
    await tester.pumpAndSettle();

    expect(services.profile.onboarded, isTrue);
    expect(services.profile.name, 'Sara');
    expect(services.profile.favoriteCourse, 'python');
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('YOUR TRACK'), findsOneWidget);
    expect(find.text('Python'), findsWidgets);
  });

  testWidgets('Settings is the only place that switches tracks', (
    tester,
  ) async {
    await completeOnboarding('c');
    await pumpShell(tester);

    expect(find.text('Python'), findsNothing);
    expect(services.profile.favoriteCourse, 'c');

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-track')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Python').last);
    await tester.pumpAndSettle();

    expect(services.profile.favoriteCourse, 'python');
    await tester.tap(find.text('Learning'));
    await tester.pumpAndSettle();
    expect(find.text('Python Basics'), findsOneWidget);
    expect(find.text('Basics of C'), findsNothing);
  });

  testWidgets('guided path shows locked sequence with Bloom chips', (
    tester,
  ) async {
    await completeOnboarding('c');
    await pumpShell(tester);

    await tester.tap(find.text('Learning'));
    await tester.pumpAndSettle();

    expect(find.text('Guided Path'), findsOneWidget);
    expect(find.text('Levels Bank'), findsOneWidget);
    expect(find.text('Basics of C'), findsOneWidget);
    expect(find.text('Pointers Deep Dive'), findsOneWidget);
    expect(find.text('Memory Mastery'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));
    expect(find.text('Understanding 2'), findsOneWidget);
    expect(find.text('Creation 1'), findsOneWidget);
    expect(find.text('Application 1'), findsOneWidget);
  });

  testWidgets('levels bank filters by difficulty and opens an exercise', (
    tester,
  ) async {
    await completeOnboarding('c');
    await pumpShell(tester);

    await tester.tap(find.text('Learning'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Levels Bank'));
    await tester.pumpAndSettle();

    // Every question of every level is listed, not the three level cards.
    expect(find.text('5 exercises'), findsOneWidget);
    expect(find.text('Pick one'), findsNWidgets(5));
    expect(find.text('Beginner'), findsWidgets);
    expect(find.text('Advanced'), findsWidgets);

    await tester.tap(find.text('Advanced').first);
    await tester.pumpAndSettle();
    expect(find.text('1 exercise'), findsOneWidget);
    expect(find.text('Pick one'), findsOneWidget);
    expect(find.text('Memory Mastery'), findsOneWidget);
    expect(find.text('Basics of C'), findsNothing);

    await tester.tap(find.text('Pick one'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseView), findsOneWidget);
  });

  testWidgets('machine track lists the architecture lessons', (tester) async {
    await completeOnboarding('machine');
    await pumpShell(tester);

    await tester.tap(find.text('Learning'));
    await tester.pumpAndSettle();

    expect(find.text('Machine Structure'), findsWidgets);
    expect(find.textContaining('Von Neumann'), findsWidgets);
  });
}
