import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/data/course_repository.dart';
import 'package:coding_quest/services/app_services.dart';
import 'package:coding_quest/views/algorithm_trace.dart';
import 'package:coding_quest/views/algorithm_trace_data.dart';
import 'package:coding_quest/views/desktop_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/memory_store.dart';

void main() {
  group('C preset execution frames', () {
    for (final preset in TracePreset.values) {
      test('${preset.name} has immutable, bilingual, bounded frames', () {
        final data = AlgorithmTraceData.forPreset(preset);
        expect(data.frames.first.line, isNull);
        expect(data.frames.first.array, isEmpty);
        expect(data.frames.first.variables.values, everyElement(isNull));
        expect(data.frames.where((frame) => frame.complete), [
          data.frames.last,
        ]);
        for (final frame in data.frames.skip(1)) {
          expect(frame.line, inInclusiveRange(1, data.lines.length));
          expect(data.lines[frame.line! - 1].trim(), isNot('}'));
          expect(frame.explanation, isNotEmpty);
          expect(frame.explanationAr, isNotEmpty);
          for (final index in {...frame.pointers.keys, ...frame.written}) {
            expect(index, inInclusiveRange(0, frame.array.length - 1));
          }
        }
        final last = data.frames.last;
        expect(data.lines[last.line! - 1].trim(), 'return 0;');
        expect(() => last.array.add(0), throwsUnsupportedError);
        expect(() => last.variables['i'] = 99, throwsUnsupportedError);
        expect(() => data.frames.clear(), throwsUnsupportedError);
      });
    }

    test('sum initializes, reads all elements and exits at the bound', () {
      final data = AlgorithmTraceData.forPreset(TracePreset.arraySum);
      final reads = data.frames
          .where(
            (frame) =>
                frame.line != null &&
                data.lines[frame.line! - 1].trim() == 'sum += a[i];',
          )
          .toList();
      expect(reads.map((frame) => frame.variables['sum']), [3, 4, 8, 9, 14]);
      expect(reads.map((frame) => frame.pointers.keys.single), [0, 1, 2, 3, 4]);
      expect(data.frames.last.variables, {'n': 5, 'i': 5, 'sum': 14});
      expect(data.frames.last.array, [3, 1, 4, 1, 5]);
      expect(
        data.frames[data.frames.length - 2].explanation,
        contains('false; leave the loop'),
      );
      expect(data.frames.every((frame) => frame.written.isEmpty), isTrue);
    });

    test(
      'bubble sort records comparisons and each separate swap assignment',
      () {
        final data = AlgorithmTraceData.forPreset(TracePreset.bubbleSort);
        var comparisons = 0;
        var writes = 0;
        for (var index = 1; index < data.frames.length; index++) {
          final frame = data.frames[index];
          final previous = data.frames[index - 1];
          final statement = data.lines[frame.line! - 1].trim();
          final j = frame.variables['j'];
          if (statement == 'if (a[j] > a[j + 1]) {') {
            comparisons++;
            expect(frame.pointers.keys, [j, j! + 1]);
            expect(frame.array, previous.array);
          } else if (statement == 'temp = a[j];') {
            expect(frame.variables['temp'], previous.array[j!]);
            expect(frame.array, previous.array);
          } else if (statement == 'a[j] = a[j + 1];') {
            writes++;
            expect(frame.array[j!], previous.array[j + 1]);
            expect(frame.array[j], frame.array[j + 1]);
            expect(frame.written, {j});
            expect(frame.variables['temp'], previous.variables['temp']);
          } else if (statement == 'a[j + 1] = temp;') {
            writes++;
            expect(frame.array[j! + 1], previous.variables['temp']);
            expect(frame.written, {j + 1});
          } else if (previous.array.isNotEmpty) {
            expect(frame.array, previous.array);
            expect(frame.written, isEmpty);
          }
        }
        expect(comparisons, 10);
        expect(writes, 8);
        expect(data.frames.last.array, [1, 2, 4, 5, 8]);
        expect(data.frames.last.variables['i'], 4);
        expect(data.frames.first.array, isEmpty);
        expect(data.frames[1].array, [5, 1, 4, 2, 8]);
      },
    );

    test('linear search skips mismatches and breaks at the matching index', () {
      final data = AlgorithmTraceData.forPreset(TracePreset.linearSearch);
      final comparisons = data.frames
          .where(
            (frame) =>
                frame.line != null &&
                data.lines[frame.line! - 1].trim() == 'if (a[i] == target) {',
          )
          .toList();
      expect(comparisons.map((frame) => frame.variables['i']), [0, 1, 2]);
      expect(comparisons.map((frame) => frame.variables['result']), [
        -1,
        -1,
        -1,
      ]);
      expect(comparisons.first.explanation, contains('not equal'));
      expect(comparisons.last.explanation, contains('a match'));
      expect(data.frames.last.variables, {
        'n': 5,
        'i': 2,
        'target': 19,
        'result': 2,
      });
      final beforeReturn = data.frames[data.frames.length - 2];
      expect(data.lines[beforeReturn.line! - 1].trim(), 'break;');
      expect(data.frames.last.array, [12, 7, 19, 4, 11]);
    });
  });

  late AppServices services;

  setUp(() async {
    services = await AppServices.create(
      store: MemoryStore(),
      repository: CourseRepository.fromData(courses: const []),
      clock: () => DateTime(2026, 1, 10, 9),
    );
  });

  Future<void> pumpTrace(
    WidgetTester tester, {
    Size size = const Size(1100, 720),
    Locale locale = const Locale('en'),
    double textScale = 1,
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
          theme: buildDesktopTheme(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: AlgorithmTrace(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder control(String name) => find.byKey(ValueKey('trace-$name'));
  String status(WidgetTester tester) =>
      tester.widget<Text>(control('status')).data!;

  Future<void> choose(WidgetTester tester, TracePreset preset) async {
    await tester.tap(control('preset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(preset.label(false)).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'ready state, line highlight, watches and reset stay synchronized',
    (tester) async {
      await pumpTrace(tester);
      expect(find.text('Variables Watch'), findsOneWidget);
      expect(find.text('Array State'), findsOneWidget);
      expect(find.text('sum = —'), findsOneWidget);
      expect(status(tester), startsWith('Ready'));
      expect(find.text('R0'), findsNothing);
      for (var i = 0; i < 6; i++) {
        await tester.tap(control('step'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Line 7'), findsOneWidget);
      expect(find.text('sum = 3'), findsOneWidget);
      expect(find.text('i = 0'), findsOneWidget);
      expect(
        tester.widget<Text>(control('explanation')).data,
        contains('sum = 0 + 3 = 3'),
      );
      final cell = tester.widget<Container>(
        find.byKey(const ValueKey('array-cell-0')),
      );
      final nextCell = tester.widget<Container>(
        find.byKey(const ValueKey('array-cell-1')),
      );
      expect(
        (cell.decoration! as BoxDecoration).border,
        isNot((nextCell.decoration! as BoxDecoration).border),
      );
      await tester.tap(control('reset'));
      await tester.pumpAndSettle();
      expect(status(tester), startsWith('Ready'));
      expect(find.text('sum = —'), findsOneWidget);
      expect(find.byKey(const ValueKey('array-cell-0')), findsNothing);
      expect(control('current-line'), findsNothing);
    },
  );

  testWidgets('Run can pause and reset cancels automatic execution', (
    tester,
  ) async {
    await pumpTrace(tester);
    await tester.tap(control('run'));
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.widget<OutlinedButton>(control('step')).onPressed, isNull);
    expect(find.text('Pause'), findsOneWidget);
    await tester.tap(control('run'));
    await tester.pumpAndSettle();
    final paused = status(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(status(tester), paused);
    expect(tester.widget<OutlinedButton>(control('step')).onPressed, isNotNull);
    await tester.tap(control('run'));
    await tester.pump();
    await tester.tap(control('reset'));
    await tester.pump(const Duration(seconds: 3));
    expect(status(tester), startsWith('Ready'));
    expect(find.text('sum = —'), findsOneWidget);
  });

  for (final preset in TracePreset.values) {
    testWidgets('${preset.name} runs to completion and can restart', (
      tester,
    ) async {
      await pumpTrace(tester);
      if (preset != TracePreset.arraySum) await choose(tester, preset);
      await tester.tap(control('run'));
      await tester.pump();
      for (
        var i = 0;
        i < AlgorithmTraceData.forPreset(preset).frames.length;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 650));
      }
      await tester.pumpAndSettle();
      expect(status(tester), startsWith('Complete'));
      expect(tester.widget<OutlinedButton>(control('step')).onPressed, isNull);
      expect(tester.widget<FilledButton>(control('run')).onPressed, isNull);
      final completed = status(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(status(tester), completed);
      await tester.tap(control('reset'));
      await tester.pumpAndSettle();
      expect(status(tester), startsWith('Ready'));
      expect(tester.widget<FilledButton>(control('run')).onPressed, isNotNull);
      expect(services.progress.totalXp, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('changing presets during Run cancels the old trace', (
    tester,
  ) async {
    await pumpTrace(tester);
    await tester.tap(control('run'));
    await tester.pump(const Duration(milliseconds: 700));
    await choose(tester, TracePreset.linearSearch);
    await tester.pump(const Duration(seconds: 3));
    expect(status(tester), startsWith('Ready'));
    expect(find.text('target = —'), findsOneWidget);
    expect(find.text('sum = —'), findsNothing);
    await tester.tap(control('run'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Step tooltip appears on mouse hover', (tester) async {
    await pumpTrace(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(control('step')));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text('Execute one C statement and inspect its effect'),
      findsOneWidget,
    );
    await mouse.removePointer();
  });

  for (final locale in const [Locale('en'), Locale('ar')]) {
    for (final size in const [
      Size(360, 720),
      Size(900, 600),
      Size(1280, 720),
    ]) {
      testWidgets('$locale trace layout is usable at $size', (tester) async {
        await pumpTrace(tester, locale: locale, size: size);
        expect(tester.takeException(), isNull);
        await tester.tap(control('step'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.text(locale.languageCode == 'ar' ? 'السطر 2' : 'Line 2'),
          findsOneWidget,
        );
        expect(
          Directionality.of(
            tester.element(find.byKey(const ValueKey('trace-line-2'))),
          ),
          TextDirection.ltr,
        );
      });
    }
  }

  testWidgets('large text uses a scrollable stacked layout', (tester) async {
    await pumpTrace(tester, textScale: 2);
    expect(find.byKey(const ValueKey('trace-stacked-layout')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
