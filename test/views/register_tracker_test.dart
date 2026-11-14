import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/data/course_repository.dart';
import 'package:coding_quest/services/app_services.dart';
import 'package:coding_quest/views/desktop_theme.dart';
import 'package:coding_quest/views/register_tracker.dart';
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

  Future<void> pumpTracker(WidgetTester tester) async {
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
            child: const Scaffold(body: RegisterTracker()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders registers, memory, controls and a ready status', (
    tester,
  ) async {
    await pumpTracker(tester);

    expect(find.text('CPU Emulator & Register Tracker'), findsOneWidget);
    expect(find.text('Step'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.textContaining('READY'), findsOneWidget);
    for (final name in ['R0', 'R1', 'R2', 'R3', 'PC']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Press Step to begin'), findsOneWidget);
  });

  testWidgets('a single step executes MOV and logs the effect', (tester) async {
    await pumpTracker(tester);

    await tester.tap(find.text('Step'));
    await tester.pumpAndSettle();

    expect(find.textContaining('R0 = 5'), findsOneWidget);
    expect(find.textContaining('· 1 steps'), findsOneWidget);
  });

  testWidgets('reset clears the machine back to ready', (tester) async {
    await pumpTracker(tester);

    await tester.tap(find.text('Step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('Press Step to begin'), findsOneWidget);
    expect(find.textContaining('READY'), findsOneWidget);
    expect(find.textContaining('· 0 steps'), findsOneWidget);
  });

  testWidgets('an unknown instruction surfaces a parse error', (tester) async {
    await pumpTracker(tester);

    await tester.enterText(find.byType(TextField), 'BOGUS R0');
    await tester.pumpAndSettle();

    expect(find.textContaining('not a known instruction'), findsWidgets);
    expect(find.textContaining('ERROR'), findsOneWidget);
  });

  testWidgets('run animates the arithmetic program to a halt', (tester) async {
    await pumpTracker(tester);

    await tester.tap(find.text('Run'));
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 340));
    }
    await tester.pumpAndSettle();

    expect(find.textContaining('HALTED'), findsOneWidget);
    // 5 + 7 stored into memory[0].
    expect(find.textContaining('mem[0] = R0 = 12'), findsOneWidget);
  });
}