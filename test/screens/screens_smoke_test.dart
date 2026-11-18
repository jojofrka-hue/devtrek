import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/playground/code_runner.dart';
import 'package:coding_quest/screens/achievements_page.dart';
import 'package:coding_quest/screens/bug_hunt_page.dart';
import 'package:coding_quest/screens/lesson_page.dart';
import 'package:coding_quest/screens/review_page.dart';
import 'package:coding_quest/screens/settings_page.dart';
import 'package:coding_quest/screens/sort_visualizer_page.dart';
import 'package:coding_quest/services/app_services.dart';
import 'package:coding_quest/views/desktop_shell.dart';
import 'package:coding_quest/views/desktop_theme.dart';
import 'package:coding_quest/views/devtrek_track.dart';
import 'package:coding_quest/widgets/question_view.dart';
import 'package:coding_quest/views/stats_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/memory_store.dart';

Future<void> _pumpScreen(
  WidgetTester tester,
  AppServices services,
  Widget page, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = const Size(1000, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    AppScope(
      services: services,
      child: MaterialApp(
        theme: buildDesktopTheme(),
        themeMode: ThemeMode.dark,
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late AppServices services;

  setUp(() async {
    services = await AppServices.create(
      store: MemoryStore(),
      repository: buildRepository(),
      clock: () => DateTime(2026, 1, 10, 9),
    );
  });

  testWidgets('desktop shell renders courses and quick actions', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      services,
      DesktopShell(
        playgroundRunner: CodeRunner(pythonCandidates: [], cCandidates: []),
      ),
    );

    expect(find.text('Main Courses'), findsNothing);
    expect(find.text('Your modules'), findsNothing);
    expect(find.text('DAILY GOAL'), findsOneWidget);
    expect(find.text('Code Playground'), findsOneWidget);
    expect(find.text('Fix the code'), findsOneWidget);
    expect(find.text('Achievements'), findsNothing);
    expect(find.text('Coding Quest'), findsNothing);
  });

  testWidgets('stats view renders the accuracy summary', (tester) async {
    await _pumpScreen(tester, services, const StatsView());

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Overall accuracy'), findsOneWidget);
  });

  testWidgets('bug hunt page renders the header without tasks', (tester) async {
    await _pumpScreen(tester, services, const BugHuntPage());

    expect(find.text('Fix the code'), findsOneWidget);
  });

  testWidgets('achievements page lists all badges', (tester) async {
    await _pumpScreen(tester, services, const AchievementsPage());

    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('First Steps'), findsOneWidget);
    expect(find.text('0 / 12 unlocked'), findsOneWidget);
  });

  testWidgets('visualizer page renders the sort controls', (tester) async {
    await _pumpScreen(tester, services, const SortVisualizerPage());

    expect(find.text('Algorithm visualizer'), findsOneWidget);
    expect(find.text('Sorting'), findsOneWidget);
    expect(find.text('Searching'), findsOneWidget);
    expect(find.text('RUN'), findsOneWidget);
  });

  testWidgets('settings page renders sound and AI sections without language', (
    tester,
  ) async {
    await _pumpScreen(tester, services, const SettingsPage());

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('LANGUAGE'), findsNothing);
    expect(find.text('English'), findsNothing);
    expect(find.text('Sound & haptics'), findsOneWidget);
    expect(find.text('AI SERVER URL'), findsOneWidget);
    expect(find.text('http://localhost:8787'), findsWidgets);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.dark,
    );
  });

  for (final language in ['en', 'ar']) {
    final ar = language == 'ar';
    testWidgets('$language settings shows a dark About card before reset', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        services,
        const SettingsPage(),
        locale: Locale(language),
      );
      final about = find.byKey(const ValueKey('settings-about'));
      await tester.ensureVisible(about);
      final card = tester.widget<Card>(about);
      expect(card.color, DesktopPalette.dark.card);
      expect(
        (card.shape! as RoundedRectangleBorder).side.color,
        DesktopPalette.dark.cardBorder,
      );
      expect(Theme.of(tester.element(about)).brightness, Brightness.dark);
      expect(
        Directionality.of(tester.element(about)),
        ar ? TextDirection.rtl : TextDirection.ltr,
      );
      for (final text in [
        ar ? 'حول DevTrek' : 'About DevTrek',
        devTrekVersion,
        ar
            ? 'تعلّم لغة C والخوارزميات لطلاب علوم الحاسوب، بتجربة مصممة لسطح المكتب ومبنية باستخدام Flutter Desktop.'
            : 'Desktop-first C & Algorithms learning for computer science students, built with Flutter Desktop.',
        ar
            ? 'شغّل كود C وPython محلياً. اتبع دراسة موجّهة عبر مستويات منظّمة، أو اختر التدريب الفردي من بنك التمارين.'
            : 'Run C/Python code locally. Follow guided study through structured levels, or choose individual practice from the exercise bank.',
      ]) {
        expect(
          find.descendant(of: about, matching: find.text(text)),
          findsOneWidget,
        );
      }
      final s = tester.element(find.byType(SettingsPage)).s;
      expect(
        tester.getRect(about).top,
        greaterThan(tester.getRect(find.text(s.t('quickTestLabel'))).bottom),
      );
      expect(
        tester.getRect(about).bottom,
        lessThan(tester.getRect(find.text(s.t('rerunSetup'))).top),
      );
      expect(find.byTooltip(ar ? 'رجوع' : 'Back'), findsOneWidget);
    });

    testWidgets('$language lesson hides the counter and retains scoring', (
      tester,
    ) async {
      final course = buildCourse();
      await _pumpScreen(
        tester,
        services,
        LessonPage(course: course, levelIndex: 0),
        locale: Locale(language),
      );
      final s = tester.element(find.byType(LessonPage)).s;
      expect(find.byTooltip(ar ? 'إغلاق' : 'Close'), findsOneWidget);
      await tester.tap(find.text(s.t('startLevel')));
      await tester.pumpAndSettle();
      expect(find.byType(QuestionView), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(find.byTooltip(ar ? 'إغلاق' : 'Close'), findsOneWidget);

      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(s.t('check')));
      await tester.pumpAndSettle();
      expect(find.text(s.t('correctExclaim')), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
      await tester.tap(find.text(s.t('next')));
      await tester.pumpAndSettle();
      expect(find.text(s.t('levelComplete')), findsOneWidget);
      expect(find.text(s.t('hearts')), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(services.progress.starsFor(course.id, 0), 3);
      expect(services.progress.totalXp, 10);
      expect(services.review.cardCount, 0);
    });
  }

  testWidgets('hidden lesson counter still enforces the mistake budget', (
    tester,
  ) async {
    final course = buildCourse(
      levels: [
        buildLevel(
          questions: List.generate(6, (index) => choiceQuestion(id: 'q$index')),
        ),
      ],
    );
    await _pumpScreen(
      tester,
      services,
      LessonPage(course: course, levelIndex: 0),
    );
    await tester.tap(find.text('START LEVEL'));
    await tester.pumpAndSettle();

    for (var attempt = 0; attempt < 5; attempt++) {
      expect(find.byType(QuestionView), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
      await tester.tap(find.text('A'));
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
    expect(services.progress.starsFor(course.id, 0), 0);
    expect(services.progress.totalXp, 0);
    expect(services.progress.isFirstAttempt(course.id, 0), isFalse);
    expect(services.review.cardCount, 5);
  });

  testWidgets('review page shows the empty state when nothing is due', (
    tester,
  ) async {
    await _pumpScreen(tester, services, const ReviewPage());

    expect(
      find.text('Nothing due right now. Come back later!'),
      findsOneWidget,
    );
  });
}
