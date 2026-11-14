import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/data/course_repository.dart';
import 'package:coding_quest/models/course.dart';
import 'package:coding_quest/models/level.dart';
import 'package:coding_quest/models/question.dart';
import 'package:coding_quest/playground/code_runner.dart';
import 'package:coding_quest/services/app_services.dart';
import 'package:coding_quest/views/desktop_shell.dart';
import 'package:coding_quest/views/desktop_theme.dart';
import 'package:coding_quest/views/fx.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/memory_store.dart';

Question _q(String id) => Question(
  id: id,
  type: QType.choice,
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

Level _level(String id, String title) => Level(
  id: id,
  title: title,
  titleAr: title,
  subtitle: 'sub',
  subtitleAr: 'sub',
  intro: 'intro',
  introAr: 'intro',
  keyPointsEn: const ['point'],
  keyPointsAr: const ['نقطة'],
  questions: [_q('$id-q')],
);

Course _course(String id, String name) => Course(
  id: id,
  name: name,
  subtitle: 'Track course',
  subtitleAr: 'دورة المسار',
  iconKey: 'code',
  colorHex: '7A5CFF',
  levels: [_level('$id-1', '$name Level 1'), _level('$id-2', '$name Level 2')],
);

void main() {
  late AppServices services;

  setUp(() async {
    services = await AppServices.create(
      store: MemoryStore(),
      repository: CourseRepository.fromData(
        courses: [
          _course('c', 'C Foundations'),
          _course('python', 'Python Foundations'),
          _course('cpp', 'C++'),
          _course('java', 'Java'),
          _course('javascript', 'JavaScript'),
        ],
      ),
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
  }

  testWidgets('dashboard shows the daily summary and focused tools', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(find.text('Main Courses'), findsNothing);
    expect(find.text('Your modules'), findsNothing);
    expect(find.text('DAILY GOAL'), findsOneWidget);
    expect(find.text('RECENT ACTIVITY'), findsOneWidget);
    expect(find.text('Tools & Sections'), findsOneWidget);
    // Level cards belong to Learning only.
    expect(find.text('C Foundations Level 1'), findsNothing);
    expect(find.text('C Foundations Level 2'), findsNothing);
    expect(find.text('Python'), findsNothing);
    expect(find.text('C++'), findsNothing);
    expect(find.text('Java'), findsNothing);
    expect(find.text('JavaScript'), findsNothing);
    expect(find.text('Machine Structure'), findsNothing);
    expect(find.text('Code Playground'), findsOneWidget);
    expect(find.text('Fix the code'), findsOneWidget);
    expect(find.text('Achievements'), findsNothing);
  });

  testWidgets('track changes only from Settings and refreshes Learning', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings-track')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Python').last);
    await tester.pumpAndSettle();

    expect(services.profile.favoriteCourse, 'python');
    await tester.tap(find.text('Learning'));
    await tester.pumpAndSettle();
    expect(find.text('Python Foundations Level 1'), findsOneWidget);
    expect(find.text('C Foundations Level 1'), findsNothing);
  });

  testWidgets('XP or star gains fire a confetti celebration', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('Learning'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);

    services.progress.grantStars('c', 0, 3);
    await tester.pump();
    await tester.pump();
    // The burst lives in an overlay entry while animating.
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();
    expect(services.progress.starsFor('c', 0), 3);
  });

  testWidgets('Shake replays when the trigger flips to true', (tester) async {
    final key = GlobalKey<ShakeState>();
    var trigger = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => trigger = true),
            child: Shake(
              key: key,
              trigger: trigger,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ),
    );

    expect(key.currentState!.offset, 0);
    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(key.currentState!.offset.abs(), greaterThan(0.5));
    await tester.pumpAndSettle();
    expect(key.currentState!.offset, 0);
  });

  testWidgets('HoverScale grows the card while the mouse is inside', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: HoverScale(
            child: SizedBox(width: 200, height: 100, child: Text('card')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, 1.0);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.text('card')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
      greaterThan(1.0),
    );
  });

  test('dark secondary text meets WCAG AAA contrast on cards and sidebar', () {
    const palette = DesktopPalette.dark;
    expect(_contrast(palette.subtle, palette.card), greaterThanOrEqualTo(7.0));
    expect(
      _contrast(palette.subtle, palette.sidebar),
      greaterThanOrEqualTo(7.0),
    );
  });
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}
