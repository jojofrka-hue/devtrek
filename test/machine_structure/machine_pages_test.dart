import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/machine_structure/machine_structure_page.dart';
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

  Future<void> pumpPage(WidgetTester tester, Locale locale) async {
    tester.view.physicalSize = const Size(1000, 2200);
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
          home: const MachineStructurePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lesson opens and the quiz scores both answers', (tester) async {
    await pumpPage(tester, const Locale('en'));
    expect(find.text('Machine Structure'), findsOneWidget);
    expect(find.text('1. Von Neumann architecture'), findsOneWidget);

    await tester.tap(find.text('1. Von Neumann architecture'));
    await tester.pumpAndSettle();
    expect(find.text('One memory for everything'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('In the same memory as data'),
      300,
    );
    await tester.tap(find.text('In the same memory as data'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Why? The stored-program idea puts code and data in one addressable memory.',
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Sharing one bus for instructions and data'),
      300,
    );
    await tester.tap(find.text('Sharing one bus for instructions and data'));
    await tester.pumpAndSettle();
    expect(find.text('Quiz result: 2/2'), findsOneWidget);
  });

  testWidgets('Arabic locale renders RTL lesson content', (tester) async {
    await pumpPage(tester, const Locale('ar'));
    expect(find.text('معمارية الحاسوب'), findsOneWidget);
    expect(find.text('1. معمارية فون نيومان'), findsOneWidget);

    await tester.tap(find.text('1. معمارية فون نيومان'));
    await tester.pumpAndSettle();
    expect(find.text('ذاكرة واحدة لكل شيء'), findsOneWidget);
    expect(find.text('مصطلحات أساسية'), findsOneWidget);
  });
}