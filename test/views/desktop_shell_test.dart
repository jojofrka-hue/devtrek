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

  testWidgets('wide window shows the side rail and a 3-column tool grid', (
    tester,
  ) async {
    await pumpShell(tester);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Learning'), findsOneWidget);
    expect(find.text('Playground'), findsOneWidget);
    expect(find.text('Structure Machine'), findsOneWidget);
    expect(find.text('C'), findsNWidgets(2));
    expect(find.text('Code Playground'), findsOneWidget);
    expect(find.text('Machine Structure'), findsOneWidget);
    expect(find.text('Review mistakes'), findsOneWidget);
    expect(find.text('Fix the code'), findsOneWidget);
    expect(find.text('Algorithm visualizer'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);

    final grids = tester
        .widgetList<GridView>(find.byType(GridView))
        .map((grid) => grid.gridDelegate)
        .cast<SliverGridDelegateWithFixedCrossAxisCount>()
        .toList();
    expect(grids, hasLength(2));
    for (final delegate in grids) {
      expect(delegate.crossAxisCount, 3);
    }
  });

  testWidgets('medium window uses two columns', (tester) async {
    await pumpShell(tester, size: const Size(1000, 1800));
    final grids = tester
        .widgetList<GridView>(find.byType(GridView))
        .map((grid) => grid.gridDelegate)
        .cast<SliverGridDelegateWithFixedCrossAxisCount>()
        .toList();
    expect(grids, hasLength(2));
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

  testWidgets('dark mode is the default and can be toggled to light', (
    tester,
  ) async {
    await pumpShell(tester);
    final shellContext = tester.element(find.byType(Scaffold).first);
    expect(
      Theme.of(shellContext).scaffoldBackgroundColor,
      const Color(0xFF12141D),
    );

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();
    expect(
      Theme.of(shellContext).scaffoldBackgroundColor,
      const Color(0xFFFAFBFD),
    );
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });

  testWidgets('narrow window falls back to the classic home page', (
    tester,
  ) async {
    await pumpShell(tester, size: const Size(600, 1000));
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Coding Quest'), findsOneWidget);
    expect(find.text('Code Playground'), findsOneWidget);
  });

  testWidgets('arabic locale translates the rail labels', (tester) async {
    await pumpShell(tester, locale: const Locale('ar'));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('محرر الكود'), findsOneWidget);
  });
}