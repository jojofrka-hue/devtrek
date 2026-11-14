import 'dart:async';
import 'dart:io';

import 'package:coding_quest/app.dart';
import 'package:coding_quest/app_scope.dart';
import 'package:coding_quest/i18n/app_strings.dart';
import 'package:coding_quest/playground/code_runner.dart';
import 'package:coding_quest/screens/settings_page.dart';
import 'package:coding_quest/services/app_services.dart';
import 'package:coding_quest/services/storage_service.dart';
import 'package:coding_quest/views/desktop_shell.dart';
import 'package:coding_quest/views/desktop_theme.dart';
import 'package:coding_quest/views/devtrek_onboarding.dart';
import 'package:coding_quest/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixtures.dart';
import '../helpers/memory_store.dart';

class FailingStore extends MemoryStore {
  bool fail = true;

  @override
  Future<void> setString(String key, String value) async {
    if (key == 'settings.language' && fail) {
      throw StateError('Preference write failed');
    }
    await super.setString(key, value);
  }
}

class DelayedStore extends MemoryStore {
  final ready = Completer<void>();

  @override
  Future<void> setString(String key, String value) async {
    if (key == 'settings.language') await ready.future;
    await super.setString(key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all locales have matching keys and substitution placeholders', () {
    final source = File('lib/i18n/app_strings.dart').readAsStringSync();
    final maps = RegExp(
      r'const Map<String, String> _(en|ar|fr) = \{([\s\S]*?)\n\};',
    ).allMatches(source);
    Set<String>? englishKeys;
    for (final map in maps) {
      final entries = RegExp(
        r"^\s*'([^']+)':",
        multiLine: true,
      ).allMatches(map[2]!).map((entry) => entry[1]!).toList();
      final keys = entries.toSet();
      expect(entries.length, keys.length);
      englishKeys ??= keys;
      expect(keys, englishKeys);
      for (final key in keys) {
        Set<String> placeholders(String text) =>
            RegExp(r'\{[^}]+\}')
                .allMatches(text)
                .map((match) => match[0]!)
                .toSet();
        expect(
          placeholders(AppStrings(map[1]!).t(key)),
          placeholders(const AppStrings('en').t(key)),
        );
      }
    }
    expect(maps.length, 3);
  });
  Widget app(AppServices services, {double scale = 1}) => ListenableBuilder(
    listenable: Listenable.merge([services.profile, services.settings]),
    builder: (context, _) => AppScope(
      services: services,
      child: MaterialApp(
        key: ValueKey(
          services.profile.onboarded && services.profile.name.trim().isNotEmpty,
        ),
        theme: buildDesktopTheme(),
        themeMode: ThemeMode.dark,
        locale: Locale(services.settings.language),
        supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home:
            services.profile.onboarded &&
                services.profile.name.trim().isNotEmpty
            ? DesktopShell(
                playgroundRunner: CodeRunner(
                  pythonCandidates: [],
                  cCandidates: [],
                ),
              )
            : const DevTrekOnboarding(),
      ),
    ),
  );

  Future<void> pump(
    WidgetTester tester,
    Widget widget, {
    double width = 1280,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> chooseLanguage(WidgetTester tester, String code) async {
    await tap(tester, find.byKey(const ValueKey('onboarding-language')));
    final label = {'en': 'English', 'fr': 'Français', 'ar': 'العربية'}[code]!;
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  for (final code in ['en', 'fr', 'ar']) {
    for (final width in [360.0, 900.0, 1280.0]) {
      testWidgets('$code onboarding and persisted Dashboard at $width', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final services = await AppServices.create(
          store: PrefsStore(prefs),
          repository: buildRepository(),
        );
        await pump(tester, app(services, scale: 1.2), width: width);
        expect(find.byType(HomeView), findsNothing);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('onboarding-start')),
              )
              .onPressed,
          isNull,
        );
        await tester.enterText(
          find.byKey(const ValueKey('onboarding-name')),
          '   ',
        );
        await tester.pump();
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('onboarding-start')),
              )
              .onPressed,
          isNull,
        );
        final name = code == 'ar' ? 'سارة أحمد' : 'Émilie Martin';
        await tester.enterText(
          find.byKey(const ValueKey('onboarding-name')),
          '  $name  ',
        );
        await chooseLanguage(tester, code);
        final s = AppStrings(code);
        expect(find.text(s.t('welcomeTitle')), findsOneWidget);
        expect(
          Directionality.of(
            tester.element(find.byKey(const ValueKey('onboarding-name'))),
          ),
          code == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(services.profile.onboarded, isFalse);
        await tap(tester, find.byKey(const ValueKey('onboarding-start')));
        expect(services.profile.onboarded, isTrue);
        expect(services.profile.name, name);
        expect(services.settings.language, code);
        expect(prefs.getString('userName'), name);
        expect(prefs.getString('settings.language') ?? 'en', code);
        expect(prefs.getBool('onboarded'), isTrue);
        expect(
          find.textContaining(s.t('welcomeName').replaceAll('{name}', name)),
          findsOneWidget,
        );
        expect(find.text(s.t('dailyGoal').toUpperCase()), findsOneWidget);
        expect(find.text(s.t('recentActivity').toUpperCase()), findsOneWidget);
        expect(find.byIcon(Icons.translate), findsNothing);
        expect(find.byIcon(Icons.translate_rounded), findsNothing);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        expect(find.byIcon(Icons.light_mode_outlined), findsNothing);
        expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);
        expect(find.byIcon(Icons.brightness_6_outlined), findsNothing);
        expect(
          Theme.of(tester.element(find.byType(HomeView))).brightness,
          Brightness.dark,
        );
        expect(tester.takeException(), isNull);

        await prefs.reload();
        final restored = await AppServices.create(
          store: PrefsStore(prefs),
          repository: buildRepository(),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(app(restored, scale: 1.2));
        await tester.pumpAndSettle();
        expect(find.byType(DevTrekOnboarding), findsNothing);
        expect(
          find.textContaining(s.t('welcomeName').replaceAll('{name}', name)),
          findsOneWidget,
        );
        expect(
          Localizations.localeOf(tester.element(find.byType(HomeView)))
              .languageCode,
          code,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('language preview preserves name without finishing onboarding', (
    tester,
  ) async {
    final services = await AppServices.create(
      store: MemoryStore(),
      repository: buildRepository(),
    );
    await pump(tester, app(services));
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-name')),
      'Ada Lovelace',
    );
    for (final code in ['ar', 'fr', 'en']) {
      await chooseLanguage(tester, code);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('onboarding-name')))
            .controller!
            .text,
        'Ada Lovelace',
      );
      expect(services.profile.onboarded, isFalse);
      expect(find.text(AppStrings(code).t('welcomeTitle')), findsOneWidget);
    }
  });

  testWidgets('saving blocks duplicate submission and retries failed storage', (
    tester,
  ) async {
    final store = FailingStore();
    final services = await AppServices.create(
      store: store,
      repository: buildRepository(),
    );
    await pump(tester, app(services));
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-name')),
      'Retry User',
    );
    await chooseLanguage(tester, 'fr');
    await tap(tester, find.byKey(const ValueKey('onboarding-start')));
    expect(services.profile.onboarded, isFalse);
    expect(
      find.text(const AppStrings('fr').t('saveProfileError')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('onboarding-start')))
          .onPressed,
      isNotNull,
    );
    store.fail = false;
    await tap(tester, find.byKey(const ValueKey('onboarding-start')));
    expect(store.getString('settings.language'), 'fr');
    expect(services.profile.onboarded, isTrue);
  });

  testWidgets('Dashboard waits until preferences finish saving', (
    tester,
  ) async {
    final store = DelayedStore();
    final services = await AppServices.create(
      store: store,
      repository: buildRepository(),
    );
    await pump(tester, app(services));
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-name')),
      'Pending User',
    );
    await chooseLanguage(tester, 'fr');
    final button = find.byKey(const ValueKey('onboarding-start'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(find.byType(HomeView), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('onboarding-name')))
          .enabled,
      isFalse,
    );
    store.ready.complete();
    await tester.pumpAndSettle();
    expect(find.byType(HomeView), findsOneWidget);
  });

  testWidgets('Settings has no language picker and reset returns to welcome', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final services = await AppServices.create(
      store: PrefsStore(prefs),
      repository: buildRepository(),
    );
    await services.settings.setLanguage('fr');
    await services.profile.completeOnboarding(
      name: 'Saved User',
      experience: '',
      goal: '',
      favoriteCourse: 'c',
      placementScore: -1,
    );
    await pump(tester, app(services));
    await tap(tester, find.byIcon(Icons.settings_outlined).first);
    const s = AppStrings('fr');
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('English'), findsNothing);
    expect(find.text('العربية'), findsNothing);
    expect(find.text('Français'), findsNothing);
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(SettingsPage))).brightness,
      Brightness.dark,
    );
    await tap(tester, find.text(s.t('rerunSetup')));
    expect(
      Theme.of(tester.element(find.byType(AlertDialog))).brightness,
      Brightness.dark,
    );
    await tap(tester, find.text(s.t('cancel')));
    expect(services.profile.onboarded, isTrue);
    expect(find.byType(SettingsPage), findsOneWidget);
    await tap(tester, find.text(s.t('rerunSetup')));
    await tap(tester, find.text(s.t('confirm')));
    expect(find.byType(DevTrekOnboarding), findsOneWidget);
    expect(find.byType(SettingsPage), findsNothing);
    expect(find.text(s.t('welcomeTitle')), findsOneWidget);
    expect(prefs.getBool('onboarded'), isFalse);
    expect(prefs.getString('userName'), '');
    expect(prefs.getString('settings.language'), 'fr');
    expect(services.progress.totalXp, 0);
    expect(tester.takeException(), isNull);

    await prefs.reload();
    final restored = await AppServices.create(
      store: PrefsStore(prefs),
      repository: buildRepository(),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(restored));
    await tester.pumpAndSettle();
    expect(find.byType(DevTrekOnboarding), findsOneWidget);
    expect(find.byType(HomeView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'production app supports French and rejects incomplete saved profile',
    (tester) async {
      final store = MemoryStore();
      await store.setBool('onboarded', true);
      await store.setString('userName', '   ');
      await store.setString('settings.language', 'fr');
      final services = await AppServices.create(
        store: store,
        repository: buildRepository(),
      );
      await pump(tester, CodingQuestApp(services: services));
      expect(find.byType(DevTrekOnboarding), findsOneWidget);
      expect(
        find.text(const AppStrings('fr').t('welcomeTitle')),
        findsOneWidget,
      );
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.supportedLocales, contains(const Locale('fr')));
      expect(materialApp.theme?.brightness, Brightness.dark);
      expect(materialApp.themeMode, ThemeMode.dark);
      expect(materialApp.title, 'DevTrek');
    },
  );

  testWidgets('long names and course/tool navigation still work', (
    tester,
  ) async {
    final services = await AppServices.create(
      store: MemoryStore(),
      repository: buildRepository(),
    );
    await services.settings.setLanguage('fr');
    await services.profile.completeOnboarding(
      name: List.filled(12, 'Émilie').join(' '),
      experience: '',
      goal: '',
      favoriteCourse: 'c',
      placementScore: -1,
    );
    await pump(tester, app(services, scale: 1.2), width: 360);
    expect(find.textContaining('Bienvenue, Émilie'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Atelier de code'),
      400,
      scrollable: find
          .descendant(
            of: find.byType(HomeView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tap(tester, find.text('Atelier de code'));
    expect(find.text(const AppStrings('fr').t('run')), findsOneWidget);
    await tap(tester, find.text('Accueil'));
    expect(find.byType(HomeView), findsOneWidget);
    await tap(tester, find.text(const AppStrings('fr').t('navStats')).last);
    expect(find.byType(DevTrekOnboarding), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
