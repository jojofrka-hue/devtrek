import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/playground/code_runner.dart';
import 'package:coding_quest/services/app_services.dart';
import 'package:coding_quest/views/desktop_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/memory_store.dart';

void main() {
  late AppServices services;

  setUp(() async {
    services = await AppServices.create(
      store: MemoryStore(),
      repository: buildRepository(),
      clock: () => DateTime(2026, 1, 10, 9),
    );
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    Size size = const Size(1280, 1800),
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      AppScope(
        services: services,
        child: MaterialApp(
          locale: locale,
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

  testWidgets('wide window shows the side rail and two-column grids', (
    tester,
  ) async {
    await pumpShell(tester);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Learning'), findsOneWidget);
    expect(find.text('Playground'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Machine Structure'), findsNothing);
    expect(find.text('Python'), findsNothing);
    expect(find.text('C++'), findsNothing);
    expect(find.text('Java'), findsNothing);
    expect(find.text('JavaScript'), findsNothing);
    expect(find.text('Main Courses'), findsNothing);
    expect(find.text('Your modules'), findsNothing);
    expect(find.text('DAILY GOAL'), findsOneWidget);
    expect(find.text('RECENT ACTIVITY'), findsOneWidget);
    expect(find.text('Code Playground'), findsOneWidget);
    expect(find.text('Fix the code'), findsOneWidget);
    expect(find.text('Review mistakes'), findsNothing);
    expect(find.text('Algorithm visualizer'), findsNothing);
    expect(find.text('Achievements'), findsNothing);

    final grids = tester
        .widgetList<GridView>(find.byType(GridView))
        .map((grid) => grid.gridDelegate)
        .cast<SliverGridDelegateWithFixedCrossAxisCount>()
        .toList();
    expect(grids, hasLength(1));
    for (final delegate in grids) {
      expect(delegate.crossAxisCount, 2);
    }
  });

  testWidgets('medium window uses two columns', (tester) async {
    await pumpShell(tester, size: const Size(1000, 1800));
    final grids = tester
        .widgetList<GridView>(find.byType(GridView))
        .map((grid) => grid.gridDelegate)
        .cast<SliverGridDelegateWithFixedCrossAxisCount>()
        .toList();
    expect(grids, hasLength(1));
    for (final delegate in grids) {
      expect(delegate.crossAxisCount, 2);
    }
  });

  testWidgets('rail switches between home, playground and statistics', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text('Playground'));
    await tester.pumpAndSettle();
    expect(find.text('RUN'), findsOneWidget);

    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.text('Overall accuracy'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Code Playground'), findsOneWidget);
  });

  testWidgets('playground and statistics cards jump to their rail tabs', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text('Code Playground'));
    await tester.pumpAndSettle();
    expect(find.text('RUN'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Statistics').last);
    await tester.pumpAndSettle();
    expect(find.text('Overall accuracy'), findsOneWidget);
  });

  testWidgets('shell is dark-only with no theme toggle', (tester) async {
    await pumpShell(tester);
    final shellContext = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(shellContext).brightness, Brightness.dark);
    expect(
      Theme.of(shellContext).scaffoldBackgroundColor,
      const Color(0xFF12141D),
    );
    expect(find.byIcon(Icons.light_mode_outlined), findsNothing);
    expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);
    expect(find.byIcon(Icons.brightness_6_outlined), findsNothing);

    await pumpShell(tester, size: const Size(600, 1000));
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
    expect(find.byIcon(Icons.brightness_6_outlined), findsNothing);
  });

  testWidgets('shell has no language switcher in header or sidebar', (
    tester,
  ) async {
    for (final size in const [Size(1400, 1000), Size(600, 1000)]) {
      await pumpShell(tester, size: size);
      for (final icon in const [
        Icons.translate,
        Icons.translate_rounded,
        Icons.language,
        Icons.language_rounded,
        Icons.g_translate,
      ]) {
        expect(find.byIcon(icon), findsNothing);
      }
      for (final label in const ['AR', 'EN', 'FR', 'العربية', 'Français']) {
        expect(find.text(label), findsNothing);
      }
    }
  });

  testWidgets('narrow window uses the compact DevTrek shell', (tester) async {
    await pumpShell(tester, size: const Size(600, 1000));
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Coding Quest'), findsNothing);
    expect(find.text('Playground'), findsOneWidget);

    await tester.tap(find.text('Playground'));
    await tester.pumpAndSettle();
    expect(find.text('RUN'), findsOneWidget);
  });

  testWidgets('arabic locale translates the rail labels', (tester) async {
    await pumpShell(tester, locale: const Locale('ar'));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('محرر الكود'), findsOneWidget);
  });
}
