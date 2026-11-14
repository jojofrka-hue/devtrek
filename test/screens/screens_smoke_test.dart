import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/playground/code_runner.dart';
import 'package:coding_quest/screens/achievements_page.dart';
import 'package:coding_quest/screens/bug_hunt_page.dart';
import 'package:coding_quest/screens/review_page.dart';
import 'package:coding_quest/screens/settings_page.dart';
import 'package:coding_quest/screens/sort_visualizer_page.dart';
import 'package:coding_quest/services/app_services.dart';
import 'package:coding_quest/views/desktop_shell.dart';
import 'package:coding_quest/views/desktop_theme.dart';
import 'package:coding_quest/views/stats_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/memory_store.dart';

Future<void> _pumpScreen(
  WidgetTester tester,
  AppServices services,
  Widget page,
) async {
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
        locale: const Locale('en'),
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
