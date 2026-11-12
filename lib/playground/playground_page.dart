import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../i18n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'code_runner.dart';
import 'playground_samples.dart';

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({super.key, this.runner});

  final CodeRunner? runner;

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  late final CodeRunner _runner = widget.runner ?? CodeRunner();
  PlayLanguage _language = PlayLanguage.c;
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

  void _switchLanguage(PlayLanguage language) {
    setState(() {
      _language = language;
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
    final samples = playgroundSamples[_language]!;
    final outcome = _outcome;

    return Scaffold(
      appBar: AppBar(title: Text(s.t('playgroundTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _toolchainBanner(s),
          const SizedBox(height: 14),
          SegmentedButton<PlayLanguage>(
            segments: const [
              ButtonSegment(
                value: PlayLanguage.c,
                label: Text('C'),
                icon: Icon(Icons.code_rounded),
              ),
              ButtonSegment(
                value: PlayLanguage.python,
                label: Text('Python'),
                icon: Icon(Icons.terminal_rounded),
              ),
            ],
            selected: {_language},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                _switchLanguage(selection.first),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ValueKey('samples-$_language'),
                  initialValue: _sampleIndex,
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
          const SizedBox(height: 14),
          Container(
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
                keyboardType: TextInputType.multiline,
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
                  hintStyle: TextStyle(color: Colors.grey.shade600),
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
          const SizedBox(height: 14),
          BigButton(
            label: s.t('run'),
            icon: Icons.play_arrow_rounded,
            onPressed: _running ? null : _run,
          ),
          if (_running) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 3),
          ],
          if (outcome != null) ...[
            const SizedBox(height: 18),
            Text(
              s.t('playgroundOutput'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
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
            if (_failureText(outcome, s) != null) ...[
              const SizedBox(height: 10),
              _notice(_failureText(outcome, s)!, red),
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
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            if (outcome.truncated) ...[
              const SizedBox(height: 8),
              Text(
                s.t('playgroundTruncated'),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ],
        ],
      ),
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

  Widget _toolchainBanner(AppStrings s) {
    if (_detecting) {
      return Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(s.t('playgroundDetecting')),
        ],
      );
    }
    return Column(
      children: [
        _toolchainRow(
          'C',
          _runner.c,
          s.t('playgroundMissingC'),
          Icons.memory_rounded,
        ),
        const SizedBox(height: 8),
        _toolchainRow(
          'Python',
          _runner.python,
          s.t('playgroundMissingPython'),
          Icons.terminal_rounded,
        ),
      ],
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