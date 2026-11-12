import 'package:flutter/widgets.dart';

import 'i18n/app_strings.dart';
import 'services/app_services.dart';

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.services != services;
}

extension AppContextX on BuildContext {
  AppServices get services => AppScope.of(this);

  AppStrings get s => AppStrings.of(this);

  bool get isArabic => s.isArabic;
}
