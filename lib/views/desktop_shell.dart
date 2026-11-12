import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../playground/code_runner.dart';
import '../playground/playground_page.dart';
import '../screens/home_page.dart';
import '../screens/settings_page.dart';
import '../theme/app_theme.dart';
import 'desktop_theme.dart';
import 'devtrek_track.dart';
import 'home_view.dart';
import 'learning_view.dart';
import 'stats_view.dart';

/// Desktop-first shell: fixed side navigation + Home / Playground / Statistics.
/// Below [breakpoint] logical pixels it falls back to the classic mobile home.
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key, this.playgroundRunner, this.breakpoint = 900});

  final CodeRunner? playgroundRunner;
  final double breakpoint;

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _index = 0;
  bool _dark = true;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final services = context.services;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < widget.breakpoint) {
          return const HomePage();
        }
        final palette = _dark ? DesktopPalette.dark : DesktopPalette.light;
        final track = currentTrack(services);
        return Theme(
          data: buildDesktopTheme(dark: _dark),
          child: Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  SizedBox(
                    width: 232,
                    child: ColoredBox(
                      color: palette.sidebar,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.code_rounded,
                                    color: Colors.white,
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    devTrekBrand,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.route_rounded,
                                      size: 14,
                                      color: palette.subtle,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      s.isArabic ? 'المسار' : 'TRACK',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: palette.subtle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                for (final option in DevTrekTrack.values)
                                  _TrackButton(
                                    track: option,
                                    selected: option == track,
                                    onTap: () =>
                                        selectTrack(services, option),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: NavigationRail(
                              extended: true,
                              minWidth: 72,
                              minExtendedWidth: 232,
                              backgroundColor: palette.sidebar,
                              selectedIndex: _index,
                              onDestinationSelected: (index) =>
                                  setState(() => _index = index),
                              destinations: [
                                NavigationRailDestination(
                                  icon: const Icon(Icons.home_outlined),
                                  selectedIcon: const Icon(Icons.home_rounded),
                                  label: Text(
                                    s.isArabic ? 'الرئيسية' : 'Home',
                                  ),
                                ),
                                NavigationRailDestination(
                                  icon: const Icon(Icons.school_outlined),
                                  selectedIcon: const Icon(Icons.school_rounded),
                                  label: Text(
                                    s.isArabic ? 'التعلم' : 'Learning',
                                  ),
                                ),
                                NavigationRailDestination(
                                  icon: const Icon(Icons.terminal_outlined),
                                  selectedIcon: const Icon(
                                    Icons.terminal_rounded,
                                  ),
                                  label: Text(
                                    s.isArabic ? 'محرر الكود' : 'Playground',
                                  ),
                                ),
                                NavigationRailDestination(
                                  icon: const Icon(Icons.insights_outlined),
                                  selectedIcon: const Icon(
                                    Icons.insights_rounded,
                                  ),
                                  label: Text(s.t('statsTitle')),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  tooltip: _dark
                                      ? (s.isArabic
                                            ? 'الوضع الفاتح'
                                            : 'Light mode')
                                      : (s.isArabic
                                            ? 'الوضع الداكن'
                                            : 'Dark mode'),
                                  icon: Icon(
                                    _dark
                                        ? Icons.light_mode_outlined
                                        : Icons.dark_mode_outlined,
                                  ),
                                  onPressed: () =>
                                      setState(() => _dark = !_dark),
                                ),
                                IconButton(
                                  tooltip: s.isArabic
                                      ? 'تبديل اللغة'
                                      : 'Switch language',
                                  icon: const Icon(Icons.translate),
                                  onPressed: services.settings.toggleLanguage,
                                ),
                                IconButton(
                                  tooltip: s.t('settingsTitle'),
                                  icon: const Icon(Icons.settings_outlined),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SettingsPage(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: IndexedStack(
                      index: _index,
                      children: [
                        HomeView(
                          track: track,
                          onOpenLearning: () => setState(() => _index = 1),
                          onOpenPlayground: () => setState(() => _index = 2),
                          onOpenStats: () => setState(() => _index = 3),
                        ),
                        LearningView(track: track),
                        PlaygroundPage(runner: widget.playgroundRunner),
                        const StatsView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrackButton extends StatelessWidget {
  const _TrackButton({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? track.color.withValues(alpha: 0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                track.icon,
                size: 17,
                color: selected ? track.color : palette.subtle,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  track.label(s.isArabic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected ? null : palette.subtle,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_rounded, size: 15, color: track.color),
            ],
          ),
        ),
      ),
    );
  }
}