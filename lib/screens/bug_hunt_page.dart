import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../i18n/app_strings.dart';
import '../models/bug_task.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';

class BugHuntPage extends StatelessWidget {
  const BugHuntPage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.services;
    final s = context.s;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: services.bugHunt,
          builder: (context, _) {
            final tasks = services.repository.bugTasks;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        s.t('bugHuntTitle'),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    StatPill(
                      icon: Icons.bug_report,
                      text:
                          '${services.bugHunt.solvedCount}/${tasks.length}',
                      color: red,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.t('bugHuntSubtitle'),
                  style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 18),
                for (final task in tasks) _taskCard(context, s, task),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _taskCard(BuildContext context, AppStrings s, BugTask task) {
    final solved = context.services.bugHunt.isSolved(task.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BugHuntDetailPage(task: task)),
        ),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: solved ? green : Colors.grey.shade300,
              width: 2,
            ),
            color: solved ? const Color(0xFFF2FFE5) : Colors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: solved ? green : red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  solved ? Icons.check_rounded : Icons.code_rounded,
                  color: solved ? Colors.white : red,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.titleFor(s.isArabic),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.language.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (solved)
                Text(
                  s.t('solved'),
                  style: const TextStyle(
                    color: darkGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class BugHuntDetailPage extends StatefulWidget {
  const BugHuntDetailPage({super.key, required this.task});

  final BugTask task;

  @override
  State<BugHuntDetailPage> createState() => _BugHuntDetailPageState();
}

class _BugHuntDetailPageState extends State<BugHuntDetailPage> {
  late final TextEditingController _controller;
  bool _showHint = false;
  bool _showSolution = false;
  bool _checked = false;
  bool _solved = false;
  List<String> _problems = const [];
  int _confetti = 0;

  BugTask get task => widget.task;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: task.brokenCode);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final services = context.services;
    final source = _controller.text;
    if (source.trim().isEmpty) {
      setState(() {
        _checked = true;
        _solved = false;
        _problems = const ['empty'];
      });
      services.sound.wrong();
      return;
    }

    final result = await services.bugHunt.submit(task, source);
    if (!mounted) return;

    if (result.isSolved) {
      services.sound.correct();
      await services.evaluateAchievements();
    } else {
      services.sound.wrong();
    }

    if (!mounted) return;
    setState(() {
      _checked = true;
      _solved = result.isSolved;
      _problems = result.problems;
      if (result.isSolved) _confetti++;
    });

    if (result.isSolved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.s.t('bugSolvedSnack')),
          backgroundColor: green,
        ),
      );
    }
  }

  void _resetCode() {
    setState(() {
      _controller.text = task.brokenCode;
      _checked = false;
      _solved = false;
      _problems = const [];
    });
  }

  String _problemText(BuildContext context, String problem) {
    final s = context.s;
    if (problem == 'empty') return s.t('fixEmpty');
    if (problem == 'missing-required-pattern') {
      return s.t('fixMissingPattern');
    }
    if (problem.startsWith('forbidden-pattern')) {
      return s.t('fixForbiddenPattern');
    }
    return problem;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(6, 8, 14, 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          task.titleFor(s.isArabic),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        task.language.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.promptFor(s.isArabic),
                          style: const TextStyle(
                            fontSize: 19,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          s.t('tapToEdit'),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.t('editCode'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2E),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextField(
                              controller: _controller,
                              maxLines: null,
                              minLines: 9,
                              keyboardType: TextInputType.multiline,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 14.5,
                                height: 1.45,
                              ),
                              cursorColor: green,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              onChanged: (_) {
                                if (_checked) {
                                  setState(() {
                                    _checked = false;
                                    _problems = const [];
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_checked && _problems.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDFE0),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: red, width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.t('notYet'),
                                  style: const TextStyle(
                                    color: red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                for (final problem in _problems)
                                  Text(
                                    '• ${_problemText(context, problem)}',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.4,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        if (_checked && _solved)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7FFB8),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: green, width: 2),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified, color: darkGreen),
                                const SizedBox(width: 8),
                                Text(
                                  s.t('solved'),
                                  style: const TextStyle(
                                    color: darkGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_showHint) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('💡', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    task.hintFor(s.isArabic),
                                    style: const TextStyle(height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_showSolution) ...[
                          const SizedBox(height: 14),
                          Text(
                            s.t('solutionLabel'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          codeBox(task.solution, fontSize: 13.5),
                          const SizedBox(height: 10),
                          Text(
                            task.explanationFor(s.isArabic),
                            style: const TextStyle(height: 1.45),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BigButton(
                        label: s.t('checkFix'),
                        onPressed: _check,
                        color: green,
                        icon: Icons.play_arrow_rounded,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _showHint = true),
                              child: Text(
                                s.t('hintBtn'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _showSolution = true),
                              child: Text(
                                s.t('showSolution'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: _resetCode,
                              child: Text(
                                s.t('resetCode'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_solved)
              Positioned.fill(child: ConfettiOverlay(trigger: _confetti)),
          ],
        ),
      ),
    );
  }
}
