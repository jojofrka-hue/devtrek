import 'package:flutter/services.dart';

import 'settings_service.dart';

/// Lightweight feedback. Uses OS click/impact sounds instead of bundled audio
/// assets, so the app stays small and works offline.
class SoundService {
  SoundService(this._settings);

  final SettingsService _settings;

  void tap() {
    if (!_settings.sound) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  void correct() {
    if (!_settings.sound) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.lightImpact();
  }

  void wrong() {
    if (!_settings.sound) return;
    HapticFeedback.heavyImpact();
  }

  void levelComplete() {
    if (!_settings.sound) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }
}
