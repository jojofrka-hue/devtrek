import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../views/desktop_theme.dart';
import '../views/devtrek_track.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _serverController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _serverController.text = context.services.settings.aiServerUrl;
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  Future<void> _saveServer() async {
    final services = context.services;
    await services.settings.setAiServerUrl(_serverController.text);
    if (!mounted) return;
    _serverController.text = services.settings.aiServerUrl;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.s.t('savedMsg')), backgroundColor: green),
    );
  }

  Future<void> _reset() async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.t('resetProgress')),
        content: Text(s.t('resetWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(s.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(s.t('confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.services.resetAll();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final s = context.s;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([services.settings, services.profile]),
          builder: (context, _) {
            final settings = services.settings;
            final profile = services.profile;
            final favorite = services.repository.courseById(
              profile.favoriteCourse,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Row(
                  children: [
                    if (widget.showBackButton) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.t('settingsTitle'),
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            s.t('settingsSubtitle'),
                            style: TextStyle(
                              fontSize: 12,
                              color: desktopPalette(context).subtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionTitle(s.t('activeTrackSettings')),
                DropdownButtonFormField<DevTrekTrack>(
                  key: const ValueKey('settings-track'),
                  initialValue: currentTrack(services),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      currentTrack(services).icon,
                      color: currentTrack(services).color,
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final track in DevTrekTrack.values)
                      DropdownMenuItem(
                        value: track,
                        child: Text(s.t('track_${track.name}')),
                      ),
                  ],
                  onChanged: (track) {
                    if (track != null) selectTrack(services, track);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  s.t('activeTrackSettingsHint'),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: desktopPalette(context).subtle,
                  ),
                ),
                const Divider(height: 28),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(
                    s.t('soundLabel'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  secondary: Icon(
                    settings.sound
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: settings.sound
                        ? green
                        : desktopPalette(context).subtle,
                  ),
                  activeThumbColor: green,
                  value: settings.sound,
                  onChanged: settings.setSound,
                ),
                const Divider(height: 28),
                _sectionTitle(s.t('aiServerLabel')),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _serverController,
                        keyboardType: TextInputType.url,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          hintText: 'http://localhost:8787',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveServer,
                        child: Text(
                          s.t('save'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.t('aiOffline'),
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: desktopPalette(context).subtle,
                  ),
                ),
                const Divider(height: 28),
                _sectionTitle(s.t('profileTitle')),
                _profileRow(
                  s.t('nameLabel'),
                  profile.name.isEmpty ? '—' : profile.name,
                ),
                _profileRow(
                  s.t('experienceLabel'),
                  profile.experience.isEmpty ? '—' : s.t(profile.experience),
                ),
                _profileRow(
                  s.t('goalLabel'),
                  profile.goal.isEmpty ? '—' : s.t(profile.goal),
                ),
                _profileRow(
                  s.t('activeTrackSettings'),
                  favorite?.name ?? s.t('track_${currentTrack(services).name}'),
                ),
                _profileRow(
                  s.t('quickTestLabel'),
                  profile.placementScore < 0
                      ? '—'
                      : '${profile.placementScore} / '
                            '${services.repository.placementQuestions.length}',
                ),
                const Divider(height: 28),
                BigButton(
                  label: s.t('rerunSetup'),
                  icon: Icons.restart_alt,
                  color: red,
                  onPressed: _reset,
                ),
                const SizedBox(height: 6),
                Text(
                  s.t('resetWarning'),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: desktopPalette(context).subtle,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: desktopPalette(context).subtle,
      ),
    ),
  );

  Widget _profileRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: desktopPalette(context).subtle,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
}
