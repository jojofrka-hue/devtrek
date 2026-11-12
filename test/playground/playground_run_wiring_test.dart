import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/playground/code_runner.dart';
import 'package:coding_quest/playground/playground_page.dart';
import 'package:coding_quest/services/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/memory_store.dart';

class _RecordingRunner extends CodeRunner {
  _RecordingRunner() : super(pythonCandidates: [], cCandidates: []);

  final List<PlayLanguage> calls = [];
  String lastSource = '';

  @override
  Future<void> detect() async {}

  @override
  Future<RunOutcome> run(
    PlayLanguage language,
    String source, {
    String input = '',
  }) async {
    calls.add(language);
    lastSource = source;
    return const RunOutcome(
      stdout: 'Hello, Coding Quest!\n',
      exitCode: 0,
      elapsed: Duration(milliseconds: 12),
    );
  }
}

void main() {
  late AppServices services;
  late _RecordingRunner runner;

  setUp(() async {
    services = await AppServices.create(
      store: MemoryStore(),
      repository: buildRepository(),
      clock: () => DateTime(2026, 1, 10, 9),
    );
    runner = _RecordingRunner();
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
          home: PlaygroundPage(runner: runner),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('RUN sends the C editor source and renders its output', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('RUN'));
    await tester.pumpAndSettle();

    expect(runner.calls, [PlayLanguage.c]);
    expect(runner.lastSource, contains('printf("Hello, Coding Quest!'));
    expect(find.textContaining('Hello, Coding Quest!\n'), findsOneWidget);
    expect(find.textContaining('exit code: 0'), findsOneWidget);
  });

  testWidgets('RUN after switching language sends Python source', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Python'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RUN'));
    await tester.pumpAndSettle();

    expect(runner.calls, [PlayLanguage.python]);
    expect(runner.lastSource, contains('print("Hello, Coding Quest!")'));
    expect(find.textContaining('Hello, Coding Quest!\n'), findsOneWidget);
    expect(find.textContaining('exit code: 0'), findsOneWidget);
  });
}