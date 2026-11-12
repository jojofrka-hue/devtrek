import '../models/bug_task.dart';

class BugValidationResult {
  const BugValidationResult({required this.isSolved, required this.problems});

  final bool isSolved;
  final List<String> problems;
}

/// Deterministic validation of a "fix the code" answer.
/// The task declares regex requirements: at least one accepted shape must
/// appear, and no forbidden shape may remain.
BugValidationResult validateBugFix(BugTask task, String code) {
  final source = code.replaceAll('\r\n', '\n').trim();
  final problems = <String>[];

  if (task.mustMatchAny.isNotEmpty) {
    final matched = task.mustMatchAny.any(
      (pattern) => RegExp(pattern, multiLine: true).hasMatch(source),
    );
    if (!matched) problems.add('missing-required-pattern');
  }

  for (final pattern in task.mustNotMatch) {
    if (RegExp(pattern, multiLine: true).hasMatch(source)) {
      problems.add('forbidden-pattern: $pattern');
    }
  }

  return BugValidationResult(isSolved: problems.isEmpty, problems: problems);
}
