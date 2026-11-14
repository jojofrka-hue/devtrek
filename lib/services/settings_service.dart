import 'package:flutter/foundation.dart';

import 'storage_service.dart';

class SettingsService extends ChangeNotifier {
  SettingsService(this._store);

  static const defaultAiServer = 'http://localhost:8787';

  final KeyValueStore _store;

  String language = 'en';
  bool sound = true;
  String aiServerUrl = defaultAiServer;

  bool get isArabic => language == 'ar';

  Future<void> load() {
    language = _store.getString('settings.language') ?? 'en';
    sound = _store.getBool('settings.sound') ?? true;
    aiServerUrl = _store.getString('settings.aiServer') ?? defaultAiServer;
    notifyListeners();
    return Future.value();
  }

  Future<void> setLanguage(String code) async {
    if (code == language) return;
    language = code;
    await _store.setString('settings.language', code);
    notifyListeners();
  }

  Future<void> setSound(bool enabled) async {
    sound = enabled;
    await _store.setBool('settings.sound', enabled);
    notifyListeners();
  }

  Future<void> setAiServerUrl(String url) async {
    aiServerUrl = url.trim().isEmpty ? defaultAiServer : url.trim();
    await _store.setString('settings.aiServer', aiServerUrl);
    notifyListeners();
  }
}
