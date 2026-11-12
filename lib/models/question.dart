enum QType { choice, order, match }

/// A single quiz activity. Immutable: content is loaded from JSON once.
class Question {
  const Question({
    required this.id,
    required this.type,
    required this.topic,
    required this.prompt,
    required this.promptAr,
    required this.options,
    required this.answer,
    required this.pairs,
    required this.explanation,
    required this.explanationAr,
    this.code,
  });

  final String id;
  final QType type;
  final String topic;
  final String prompt;
  final String promptAr;
  final String? code;
  final List<String> options;
  final int answer;
  final List<List<String>> pairs;
  final String explanation;
  final String explanationAr;

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    final type = switch (rawType) {
      'order' => QType.order,
      'match' => QType.match,
      _ => QType.choice,
    };
    return Question(
      id: json['id'] as String,
      type: type,
      topic: json['topic'] as String? ?? 'basics',
      prompt: json['prompt'] as String,
      promptAr: json['promptAr'] as String? ?? '',
      code: json['code'] as String?,
      options: ((json['options'] as List?) ?? const []).cast<String>(),
      answer: (json['answer'] as num?)?.toInt() ?? 0,
      pairs: ((json['pairs'] as List?) ?? const [])
          .map((row) => (row as List).cast<String>())
          .toList(growable: false),
      explanation: json['explanation'] as String? ?? '',
      explanationAr: json['explanationAr'] as String? ?? '',
    );
  }

  String promptFor(bool arabic) =>
      arabic && promptAr.isNotEmpty ? promptAr : prompt;

  String explanationFor(bool arabic) =>
      arabic && explanationAr.isNotEmpty ? explanationAr : explanation;

  String correctAnswerText() {
    if (type == QType.choice) return options[answer];
    if (type == QType.order) return options.join(' ');
    return pairs.map((pair) => '${pair[0]} = ${pair[1]}').join('\n');
  }
}
