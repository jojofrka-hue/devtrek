/// A "fix the code" challenge validated with deterministic regex checks.
class BugTask {
  const BugTask({
    required this.id,
    required this.language,
    required this.title,
    required this.titleAr,
    required this.prompt,
    required this.promptAr,
    required this.brokenCode,
    required this.hint,
    required this.hintAr,
    required this.solution,
    required this.explanation,
    required this.explanationAr,
    required this.mustMatchAny,
    required this.mustNotMatch,
  });

  final String id;
  final String language;
  final String title;
  final String titleAr;
  final String prompt;
  final String promptAr;
  final String brokenCode;
  final String hint;
  final String hintAr;
  final String solution;
  final String explanation;
  final String explanationAr;
  final List<String> mustMatchAny;
  final List<String> mustNotMatch;

  factory BugTask.fromJson(Map<String, dynamic> json) {
    final checks = json['checks'] as Map<String, dynamic>? ?? const {};
    return BugTask(
      id: json['id'] as String,
      language: json['language'] as String? ?? '',
      title: json['title'] as String? ?? '',
      titleAr: json['titleAr'] as String? ?? json['title'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      promptAr: json['promptAr'] as String? ?? '',
      brokenCode: json['brokenCode'] as String? ?? '',
      hint: json['hint'] as String? ?? '',
      hintAr: json['hintAr'] as String? ?? '',
      solution: json['solution'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      explanationAr: json['explanationAr'] as String? ?? '',
      mustMatchAny: ((checks['mustMatchAny'] as List?) ?? const []).cast<String>(),
      mustNotMatch: ((checks['mustNotMatch'] as List?) ?? const []).cast<String>(),
    );
  }

  String titleFor(bool arabic) => arabic && titleAr.isNotEmpty ? titleAr : title;
  String promptFor(bool arabic) => arabic && promptAr.isNotEmpty ? promptAr : prompt;
  String hintFor(bool arabic) => arabic && hintAr.isNotEmpty ? hintAr : hint;
  String explanationFor(bool arabic) =>
      arabic && explanationAr.isNotEmpty ? explanationAr : explanation;
}
