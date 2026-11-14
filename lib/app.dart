import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'services/app_services.dart';
import 'views/desktop_theme.dart';
import 'views/devtrek_track.dart';
import 'views/desktop_shell.dart';
import 'views/devtrek_onboarding.dart';

class CodingQuestApp extends StatelessWidget {
  const CodingQuestApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([services.settings, services.profile]),
      builder: (context, _) {
        final onboarded =
            services.profile.onboarded &&
            services.profile.name.trim().isNotEmpty;
        return AppScope(
          services: services,
          child: MaterialApp(
            key: ValueKey(onboarded),
            debugShowCheckedModeBanner: false,
            title: devTrekBrand,
            locale: Locale(services.settings.language),
            supportedLocales: const [Locale('en'), Locale('fr'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildDesktopTheme(),
            themeMode: ThemeMode.dark,
            home: onboarded ? const DesktopShell() : const DevTrekOnboarding(),
          ),
        );
      },
    );
  }
}
