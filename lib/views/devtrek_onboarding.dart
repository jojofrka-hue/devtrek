import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'desktop_theme.dart';
import 'devtrek_track.dart';
import 'fx.dart';

class DevTrekOnboarding extends StatefulWidget {
  const DevTrekOnboarding({super.key});

  @override
  State<DevTrekOnboarding> createState() => _DevTrekOnboardingState();
}

class _DevTrekOnboardingState extends State<DevTrekOnboarding> {
  final TextEditingController _name = TextEditingController();
  DevTrekTrack _track = DevTrekTrack.c;
  String _language = 'en';
  bool _initialized = false;
  bool _starting = false;
  bool _saveFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final services = context.services;
    _name.text = services.profile.name;
    _track = currentTrack(services);
    final language = services.settings.language;
    _language = const ['en', 'fr', 'ar'].contains(language) ? language : 'en';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final name = _name.text.trim();
    if (name.isEmpty || _starting) return;
    final services = context.services;
    setState(() {
      _starting = true;
      _saveFailed = false;
    });
    try {
      await services.settings.setLanguage(_language);
      await services.profile.completeOnboarding(
        name: name,
        experience: '',
        goal: '',
        favoriteCourse: _track.courseId,
        placementScore: -1,
      );
    } catch (_) {
      services.profile.onboarded = false;
      await services.settings.load();
      if (!mounted) return;
      setState(() {
        _starting = false;
        _saveFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    locale: Locale(_language),
    child: Builder(builder: _buildWelcome),
  );

  Widget _buildWelcome(BuildContext context) {
    final s = context.s;
    final palette = DesktopPalette.dark;
    final canStart = _name.text.trim().isNotEmpty && !_starting;

    return Theme(
      data: buildDesktopTheme(),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFF58CC02),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF58CC02)
                                  .withValues(alpha: 0.35),
                              blurRadius: 26,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        devTrekBrand,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.t('welcomeTitle'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        s.t('welcomeIntro'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: palette.subtle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      key: const ValueKey('onboarding-name'),
                      controller: _name,
                      enabled: !_starting,
                      autofillHints: const [AutofillHints.name],
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _start(),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: s.t('yourName'),
                        hintText: s.t('nameExample'),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('onboarding-language'),
                      initialValue: _language,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: s.t('preferredLanguage'),
                        prefixIcon: const Icon(Icons.translate_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'fr', child: Text('Français')),
                        DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      ],
                      onChanged: _starting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _language = value);
                              }
                            },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      s.t('preferencesSavedLocally'),
                      style: TextStyle(fontSize: 12, color: palette.subtle),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      s.t('chooseTrack'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final track in DevTrekTrack.values) ...[
                      _TrackOption(
                        track: track,
                        selected: track == _track,
                        onTap: _starting
                            ? null
                            : () => setState(() => _track = track),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_saveFailed) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          s.t('saveProfileError'),
                          style: const TextStyle(color: Color(0xFFFF4B4B)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    HoverScale(
                      hoverScale: 1.01,
                      glow: canStart ? const Color(0xFF58CC02) : null,
                      radius: 16,
                      child: FilledButton.icon(
                        key: const ValueKey('onboarding-start'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF58CC02),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: canStart ? _start : null,
                        icon: _starting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                s.isArabic
                                    ? Icons.arrow_back_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 20,
                              ),
                        label: Text(
                          s.t(_starting ? 'saving' : 'startJourney'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackOption extends StatelessWidget {
  const _TrackOption({
    required this.track,
    required this.selected,
    required this.onTap,
  });

  final DevTrekTrack track;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = desktopPalette(context);
    return HoverScale(
      hoverScale: 1.02,
      glow: selected ? track.color : null,
      radius: 16,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? track.color.withValues(alpha: 0.12)
                : palette.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? track.color : palette.cardBorder,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: track.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(track.icon, color: track.color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.t('track_${track.name}'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.t('track_${track.name}_desc'),
                      style: TextStyle(fontSize: 12, color: palette.subtle),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: track.color)
              else
                Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: palette.subtle,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
