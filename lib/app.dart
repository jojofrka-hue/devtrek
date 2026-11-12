import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'services/app_services.dart';
import 'theme/app_theme.dart';
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
        return AppScope(
          services: services,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Coding Quest',
            locale: Locale(services.settings.language),
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildAppTheme(),
            home: services.profile.onboarded
                ? const DesktopShell()
                : const DevTrekOnboarding(),
          ),
        );
      },
    );
  }
}
