import 'package:flutter/material.dart';

import '../app_scope.dart';
import 'desktop_theme.dart';
import 'devtrek_track.dart';

/// First-run welcome screen: DevTrek branding, name entry and main-track
/// selection (C / Python / Structure Machine).
class DevTrekOnboarding extends StatefulWidget {
  const DevTrekOnboarding({super.key});

  @override
  State<DevTrekOnboarding> createState() => _DevTrekOnboardingState();
}

class _DevTrekOnboardingState extends State<DevTrekOnboarding> {
  final TextEditingController _name = TextEditingController();
  DevTrekTrack _track = DevTrekTrack.c;
  bool _starting = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final name = _name.text.trim();
    if (name.isEmpty || _starting) return;
    setState(() => _starting = true);
    await context.services.profile.completeOnboarding(
      name: name,
      experience: '',
      goal: '',
      favoriteCourse: _track.courseId,
      placementScore: -1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final services = context.services;
    final ar = s.isArabic;
    final palette = DesktopPalette.dark;

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
                    Align(
                      alignment: ar
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: services.settings.toggleLanguage,
                        icon: const Icon(Icons.translate, size: 18),
                        label: Text(
                          s.t('languageShort'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFF58CC02),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF58CC02,
                              ).withValues(alpha: 0.35),
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
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        ar
                            ? 'رحلتك الأكاديمية في عالم البرمجة — اختر مسارك وابدأ التعلم الموجّه'
                            : 'Your academic journey into programming — pick a track and start guided learning',
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
                      controller: _name,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: ar ? 'اسمك' : 'Your name',
                        hintText: ar ? 'مثال: سارة' : 'e.g. Sara',
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      ar ? 'اختر مسارك الرئيسي' : 'Choose your main track',
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
                        onTap: () => setState(() => _track = track),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF58CC02),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _name.text.trim().isEmpty ? null : _start,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ar ? 'ابدأ رحلتك' : 'Start your journey',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              ar
                                  ? Icons.arrow_back_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
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
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = desktopPalette(context);
    return InkWell(
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
                    track.label(s.isArabic),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.description(s.isArabic),
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
    );
  }
}