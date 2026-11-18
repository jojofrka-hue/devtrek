import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../i18n/app_strings.dart';
import '../playground/code_runner.dart';
import '../playground/playground_samples.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'desktop_theme.dart';
import 'fx.dart';
import 'algorithm_trace.dart';

enum _PlayMode { c, python, trace }

class PlaygroundView extends StatefulWidget {
  const PlaygroundView({super.key, this.runner});

  final CodeRunner? runner;

  @override
  State<PlaygroundView> createState() => _PlaygroundViewState();
}

class _PlaygroundViewState extends State<PlaygroundView> {
  late final CodeRunner _runner = widget.runner ?? CodeRunner();
  _PlayMode _mode = _PlayMode.c;
  final Map<PlayLanguage, TextEditingController> _code = {
    for (final language in PlayLanguage.values)
      language: TextEditingController(
        text: playgroundSamples[language]!.first.code,
      ),
  };
  final TextEditingController _stdin = TextEditingController();
  int _sampleIndex = 0;
  RunOutcome? _outcome;
  bool _running = false;
  bool _detecting = true;

  PlayLanguage get _language =>
      _mode == _PlayMode.python ? PlayLanguage.python : PlayLanguage.c;

  @override
  void initState() {
    super.initState();
    _detect();
  }

  Future<void> _detect() async {
    await _runner.detect();
    if (mounted) setState(() => _detecting = false);
  }

  @override
  void dispose() {
    for (final controller in _code.values) {
      controller.dispose();
    }
    _stdin.dispose();
    super.dispose();
  }

  void _switchMode(_PlayMode mode) {
    setState(() {
      _mode = mode;
      _sampleIndex = 0;
      _outcome = null;
    });
  }

  void _loadSample(int index) {
    setState(() {
      _sampleIndex = index;
      _code[_language]!.text = playgroundSamples[_language]![index].code;
      _outcome = null;
    });
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _outcome = null;
    });
    final result = await _runner.run(
      _language,
      _code[_language]!.text,
      input: _stdin.text,
    );
    if (mounted) {
      setState(() {
        _outcome = result;
        _running = false;
      });
    }
  }

  String? _failureText(RunOutcome outcome, AppStrings s) {
    switch (outcome.failure) {
      case RunFailure.emptySource:
        return s.t('playgroundEmpty');
      case RunFailure.missingToolchain:
        return _language == PlayLanguage.c
            ? s.t('playgroundMissingC')
            : s.t('playgroundMissingPython');
      case RunFailure.unsupportedPlatform:
        return s.t('playgroundNotWindows');
      case RunFailure.compileFailed:
        return s.t('playgroundCompileFailed');
      case RunFailure.spawnFailed:
        return '${s.t('playgroundSpawnError')} ${outcome.failureDetail}';
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final palette = desktopPalette(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal_rounded, color: green, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.t('playgroundTitle'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Tooltip(
                message: s.isArabic
                    ? 'كتابة برامج C وترجمتها وتشغيلها محلياً'
                    : 'Write, compile and run C programs locally',
                child: _ModeButton(
                  icon: Icons.code_rounded,
                  label: 'C',
                  color: purple,
                  selected: _mode == _PlayMode.c,
                  onTap: () => _switchMode(_PlayMode.c),
                ),
              ),
              Tooltip(
                message: s.isArabic
                    ? 'كتابة برامج Python وتشغيلها محلياً'
                    : 'Write and run Python programs locally',
                child: _ModeButton(
                  icon: Icons.terminal_rounded,
                  label: 'Python',
                  color: const Color(0xFFFFC800),
                  selected: _mode == _PlayMode.python,
                  onTap: () => _switchMode(_PlayMode.python),
                ),
              ),
              Tooltip(
                message: s.isArabic
                    ? 'تتبّع خوارزميات C الجاهزة خطوة بخطوة'
                    : 'Trace preset C algorithms one statement at a time',
                child: _ModeButton(
                  icon: Icons.account_tree_rounded,
                  label: s.isArabic ? 'تتبّع الخوارزميات' : 'Algorithm Trace',
                  color: blue,
                  selected: _mode == _PlayMode.trace,
                  onTap: () => _switchMode(_PlayMode.trace),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_mode != _PlayMode.trace) ...[
            _toolchainBanner(s, palette),
            const SizedBox(height: 14),
          ],
          Expanded(
            child: _mode == _PlayMode.trace
                ? const AlgorithmTrace()
                : _codeWorkspace(s, palette),
          ),
        ],
      ),
    );
  }

  Widget _codeWorkspace(AppStrings s, DesktopPalette palette) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 520 * MediaQuery.textScalerOf(context).scale(1),
                  child: _editorPane(s, palette),
                ),
                const SizedBox(height: 16),
                SizedBox(height: 280, child: _outputPane(s, palette)),
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: _editorPane(s, palette)),
            const SizedBox(width: 16),
            Expanded(flex: 6, child: _outputPane(s, palette)),
          ],
        );
      },
    );
  }

  Widget _editorPane(AppStrings s, DesktopPalette palette) {
    final samples = playgroundSamples[_language]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('samples-$_language'),
                initialValue: _sampleIndex,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: s.t('playgroundSamples'),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (var i = 0; i < samples.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(samples[i].title(s.isArabic)),
                    ),
                ],
                onChanged: (index) {
                  if (index != null) _loadSample(index);
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: s.t('resetCode'),
              onPressed: () => _loadSample(_sampleIndex),
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _code[_language],
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                cursorColor: green,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.5,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: _language == PlayLanguage.c
                      ? '#include <stdio.h>'
                      : 'print("...")',
                  hintStyle: const TextStyle(color: Colors.white38),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            controller: _stdin,
            maxLines: 2,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              labelText: s.t('playgroundStdin'),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 12),
        HoverScale(
          hoverScale: 1.01,
          glow: _running ? null : green,
          radius: 16,
          child: Tooltip(
            message: _language == PlayLanguage.c
                ? (s.isArabic
                      ? 'ترجمة كود C وتشغيله محلياً باستخدام الإدخال المحدد'
                      : 'Compile and run C locally with the supplied input')
                : (s.isArabic
                      ? 'تشغيل Python محلياً باستخدام الإدخال المحدد'
                      : 'Run Python locally with the supplied input'),
            child: BigButton(
              label: s.t('run'),
              icon: Icons.play_arrow_rounded,
              onPressed: _running ? null : _run,
            ),
          ),
        ),
        if (_running) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(minHeight: 3),
        ],
      ],
    );
  }

  Widget _outputPane(AppStrings s, DesktopPalette palette) {
    final outcome = _outcome;
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.cardBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.output_rounded, size: 18, color: palette.subtle),
              const SizedBox(width: 8),
              Text(
                s.t('playgroundOutput'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: outcome == null
                ? Center(
                    child: Text(
                      s.isArabic
                          ? 'شغّل الكود لرؤية المخرجات هنا'
                          : 'Run your code to see the output here',
                      style: TextStyle(color: palette.subtle, fontSize: 13),
                    ),
                  )
                : SingleChildScrollView(
                    child: _outcomeBody(outcome, s, palette),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _outcomeBody(
    RunOutcome outcome,
    AppStrings s,
    DesktopPalette palette,
  ) {
    final failure = _failureText(outcome, s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatPill(
              icon: Icons.logout_rounded,
              text: '${s.t('playgroundExit')}: ${outcome.exitCode ?? '-'}',
              color: outcome.ok ? green : red,
            ),
            StatPill(
              icon: Icons.timer_outlined,
              text: '${outcome.elapsed.inMilliseconds} ms',
              color: blue,
            ),
          ],
        ),
        if (outcome.timedOut) ...[
          const SizedBox(height: 10),
          _notice(s.t('playgroundTimeout'), red),
        ],
        if (failure != null) ...[
          const SizedBox(height: 10),
          _notice(failure, red),
        ],
        if (outcome.compileLog.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            s.t('playgroundCompileError'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          codeBox(outcome.compileLog, fontSize: 13),
        ],
        if (outcome.stdout.isNotEmpty) ...[
          const SizedBox(height: 10),
          codeBox(outcome.stdout, fontSize: 14),
        ],
        if (outcome.stderr.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'stderr',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 6),
          codeBox(outcome.stderr, fontSize: 13),
        ],
        if (outcome.stdout.isEmpty &&
            outcome.stderr.isEmpty &&
            outcome.compileLog.isEmpty &&
            outcome.failure == null &&
            !outcome.timedOut) ...[
          const SizedBox(height: 10),
          Text(
            s.t('playgroundNoOutput'),
            style: TextStyle(color: palette.subtle),
          ),
        ],
        if (outcome.truncated) ...[
          const SizedBox(height: 8),
          Text(
            s.t('playgroundTruncated'),
            style: TextStyle(color: palette.subtle, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _notice(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 13)),
    );
  }

  Widget _toolchainBanner(AppStrings s, DesktopPalette palette) {
    if (_detecting) {
      return Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(
            s.t('playgroundDetecting'),
            style: TextStyle(color: palette.subtle),
          ),
        ],
      );
    }
    final isC = _language == PlayLanguage.c;
    return _toolchainRow(
      isC ? 'C' : 'Python',
      isC ? _runner.c : _runner.python,
      isC ? s.t('playgroundMissingC') : s.t('playgroundMissingPython'),
      isC ? Icons.memory_rounded : Icons.terminal_rounded,
    );
  }

  Widget _toolchainRow(
    String label,
    ToolchainInfo? info,
    String missing,
    IconData icon,
  ) {
    final ok = info != null;
    final color = ok ? green : red;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ok ? '$label: ${info.version}' : missing,
              style: TextStyle(fontSize: 12.5, color: color),
            ),
          ),
          Icon(
            ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: color,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = desktopPalette(context);
    return HoverScale(
      hoverScale: 1.03,
      glow: selected ? color : null,
      radius: 12,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.16) : palette.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : palette.cardBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? color : palette.subtle),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: selected ? color : palette.subtle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
