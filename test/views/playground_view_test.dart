import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/data/course_repository.dart';
import 'package:coding_quest/playground/code_runner.dart';
import 'package:coding_quest/services/app_services.dart';
import 'package:coding_quest/views/desktop_theme.dart';
import 'package:coding_quest/views/playground_view.dart';
import 'package:coding_quest/views/algorithm_trace.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/memory_store.dart';

void main() {
  late AppServices services;

  setUp(() async {
    services = await AppServices.create(
      store: MemoryStore(),
      repository: CourseRepository.fromData(courses: const []),
      clock: () => DateTime(2026, 1, 10, 9),
    );
  });

  Future<void> pumpView(WidgetTester tester) async {
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
          home: Theme(
            data: buildDesktopTheme(),
            child: Scaffold(
              body: PlaygroundView(
                runner: CodeRunner(pythonCandidates: [], cCandidates: []),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'defaults to the C editor with a single RUN and toolchain status',
    (tester) async {
      await pumpView(tester);

      expect(find.text('Code Playground'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
      expect(find.text('Algorithm Trace'), findsOneWidget);
      expect(find.text('RUN'), findsOneWidget);
      expect(find.textContaining('No C compiler found'), findsOneWidget);
      expect(find.byType(AlgorithmTrace), findsNothing);
    },
  );

  testWidgets('Algorithm Trace mode hosts the C visualizer', (tester) async {
    await pumpView(tester);

    await tester.tap(find.text('Algorithm Trace'));
    await tester.pumpAndSettle();

    expect(find.byType(AlgorithmTrace), findsOneWidget);
    expect(find.text('Algorithm & C Execution Visualizer'), findsOneWidget);
    expect(find.text('Variables Watch'), findsOneWidget);
    expect(find.text('Array State'), findsOneWidget);
    expect(find.text('Structure Machine'), findsNothing);
    expect(find.text('RUN'), findsNothing);
  });

  testWidgets('trace playback does not alter the C editor or leave a timer', (
    tester,
  ) async {
    await pumpView(tester);
    const source = 'int main(void) { return 7; }';
    await tester.enterText(find.byType(TextField).first, source);
    expect(
      find.byTooltip('Compile and run C locally with the supplied input'),
      findsOneWidget,
    );
    await tester.tap(find.text('Algorithm Trace'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trace-run')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.tap(find.text('C'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(AlgorithmTrace), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      source,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching back to Python restores the editor and RUN', (
    tester,
  ) async {
    await pumpView(tester);

    await tester.tap(find.text('Algorithm Trace'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();

    expect(find.byType(AlgorithmTrace), findsNothing);
    expect(find.text('RUN'), findsOneWidget);
    expect(find.textContaining('Python is not installed'), findsOneWidget);
  });
}
