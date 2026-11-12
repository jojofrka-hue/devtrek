import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/screens/achievements_page.dart';
import 'package:coding_quest/screens/bug_hunt_page.dart';
import 'package:coding_quest/screens/home_page.dart';
import 'package:coding_quest/screens/review_page.dart';
import 'package:coding_quest/screens/settings_page.dart';
import 'package:coding_quest/screens/sort_visualizer_page.dart';
import 'package:coding_quest/screens/stats_page.dart';
import 'package:coding_quest/services/app_services.dart';
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
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('ar')],
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

  testWidgets('home page renders courses and quick actions', (tester) async {
    await _pumpScreen(tester, services, const HomePage());

    expect(find.text('Coding Quest'), findsOneWidget);
    expect(find.text('Choose a language'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Fix the code'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
  });

  testWidgets('stats page renders summary and empty topic state', (
    tester,
  ) async {
    await _pumpScreen(tester, services, const StatsPage());

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Overall accuracy'), findsOneWidget);
    expect(
      find.text('Answer some questions to see your statistics.'),
      findsOneWidget,
    );
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

  testWidgets('settings page renders language, sound and AI sections', (
    tester,
  ) async {
    await _pumpScreen(tester, services, const SettingsPage());

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('LANGUAGE'), findsOneWidget);
    expect(find.text('Sound & haptics'), findsOneWidget);
    expect(find.text('AI SERVER URL'), findsOneWidget);
    expect(find.text('http://localhost:8787'), findsWidgets);
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
