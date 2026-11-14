import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/playground/code_runner.dart';
import 'package:coding_quest/playground/playground_page.dart';
import 'package:coding_quest/services/app_services.dart';
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

  Future<void> pumpPage(WidgetTester tester) async {
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
          home: PlaygroundPage(
            runner: CodeRunner(pythonCandidates: [], cCandidates: []),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders language switch and toolchain status', (tester) async {
    await pumpPage(tester);
    expect(find.text('Code Playground'), findsOneWidget);
    expect(find.text('Python'), findsOneWidget);
    expect(find.textContaining('No C compiler found'), findsOneWidget);
    expect(find.textContaining('Python is not installed'), findsOneWidget);
  });

  testWidgets('running without a toolchain shows a friendly notice', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'print(1)');
    await tester.tap(find.text('RUN'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Python is not installed'), findsNWidgets(2));
  });
}
