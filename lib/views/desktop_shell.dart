import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../playground/code_runner.dart';
import '../screens/settings_page.dart';
import '../theme/app_theme.dart';
import 'desktop_theme.dart';
import 'devtrek_track.dart';
import 'home_view.dart';
import 'learning_view.dart';
import 'playground_view.dart';
import 'stats_view.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key, this.playgroundRunner, this.breakpoint = 900});

  final CodeRunner? playgroundRunner;
  final double breakpoint;

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final services = context.services;
    final tooltips = _navigationTooltips(s.isArabic);

    return ListenableBuilder(
      listenable: services.profile,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < widget.breakpoint) {
            return _compactShell(context);
          }
          const palette = DesktopPalette.dark;
          final track = currentTrack(services);
          return Theme(
            data: buildDesktopTheme(),
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
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, inner) =>
                                    SingleChildScrollView(
                                      child: SizedBox(
                                        height: inner.maxHeight < 780
                                            ? 780
                                            : inner.maxHeight,
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    18,
                                                    18,
                                                    18,
                                                    10,
                                                  ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color: green,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
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
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: NavigationRail(
                                                extended: true,
                                                minWidth: 72,
                                                minExtendedWidth: 232,
                                                backgroundColor:
                                                    palette.sidebar,
                                                selectedIndex: _index,
                                                onDestinationSelected:
                                                    (index) => setState(
                                                      () => _index = index,
                                                    ),
                                                destinations: [
                                                  _railDestination(
                                                    icon: Icons.home_outlined,
                                                    selectedIcon:
                                                        Icons.home_rounded,
                                                    label: s.t('home'),
                                                    tooltip: tooltips[0],
                                                  ),
                                                  _railDestination(
                                                    icon: Icons.school_outlined,
                                                    selectedIcon:
                                                        Icons.school_rounded,
                                                    label: s.t('learning'),
                                                    tooltip: tooltips[1],
                                                  ),
                                                  _railDestination(
                                                    icon:
                                                        Icons.terminal_outlined,
                                                    selectedIcon:
                                                        Icons.terminal_rounded,
                                                    label: s.t('playground'),
                                                    tooltip: tooltips[2],
                                                  ),
                                                  _railDestination(
                                                    icon:
                                                        Icons.insights_outlined,
                                                    selectedIcon:
                                                        Icons.insights_rounded,
                                                    label: s.t('statsTitle'),
                                                    tooltip: tooltips[3],
                                                  ),
                                                  _railDestination(
                                                    icon:
                                                        Icons.settings_outlined,
                                                    selectedIcon:
                                                        Icons.settings_rounded,
                                                    label: s.t('settingsTitle'),
                                                    tooltip: tooltips[4],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                            _SidebarFooter(track: track),
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
                            onOpenSettings: () => setState(() => _index = 4),
                          ),
                          LearningView(track: track),
                          TickerMode(
                            enabled: _index == 2,
                            child: PlaygroundView(
                              runner: widget.playgroundRunner,
                            ),
                          ),
                          const StatsView(),
                          const SettingsPage(showBackButton: false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _navigationTooltips(bool ar) => [
    ar ? 'لوحة المتابعة وملخص تقدّمك' : 'Dashboard and progress overview',
    ar ? 'مستويات موجّهة وبنك التمارين' : 'Guided levels and exercise bank',
    ar
        ? 'تشغيل الكود محلياً وتتبّع الخوارزميات'
        : 'Local code execution and algorithm tracing',
    ar
        ? 'تقدّم التعلّم ودقة الإجابات'
        : 'Learning progress and answer accuracy',
    ar
        ? 'المسار والتفضيلات وحول DevTrek'
        : 'Track, preferences and about DevTrek',
  ];

  NavigationRailDestination _railDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String tooltip,
  }) => NavigationRailDestination(
    icon: Tooltip(message: tooltip, child: Icon(icon)),
    selectedIcon: Tooltip(message: tooltip, child: Icon(selectedIcon)),
    label: Tooltip(message: tooltip, child: Text(label)),
  );

  Widget _compactShell(BuildContext context) {
    final services = context.services;
    final s = context.s;
    final track = currentTrack(services);
    final tooltips = _navigationTooltips(s.isArabic);
    return Theme(
      data: buildDesktopTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            devTrekBrand,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: IndexedStack(
          index: _index,
          children: [
            HomeView(
              track: track,
              onOpenLearning: () => setState(() => _index = 1),
              onOpenPlayground: () => setState(() => _index = 2),
              onOpenSettings: () => setState(() => _index = 4),
            ),
            LearningView(track: track),
            TickerMode(
              enabled: _index == 2,
              child: PlaygroundView(runner: widget.playgroundRunner),
            ),
            const StatsView(),
            const SettingsPage(showBackButton: false),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              label: s.t('home'),
              tooltip: tooltips[0],
            ),
            NavigationDestination(
              icon: const Icon(Icons.school_outlined),
              label: s.t('navLearning'),
              tooltip: tooltips[1],
            ),
            NavigationDestination(
              icon: const Icon(Icons.terminal_rounded),
              label: s.t('navPlayground'),
              tooltip: tooltips[2],
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              label: s.t('navStats'),
              tooltip: tooltips[3],
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              label: s.t('settingsTitle'),
              tooltip: tooltips[4],
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.track});

  final DevTrekTrack track;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = desktopPalette(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  track.color.withValues(alpha: 0.15),
                  palette.card,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(track.icon, size: 17, color: track.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${s.t('activeTrack')}: ${track.label(s.isArabic)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    devTrekVersion,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.subtle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
