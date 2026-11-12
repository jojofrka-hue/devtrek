class Achievement {
  const Achievement({
    required this.id,
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
  });

  final String id;
  final String icon;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;

  String titleFor(bool arabic) => arabic ? titleAr : titleEn;
  String descriptionFor(bool arabic) => arabic ? descriptionAr : descriptionEn;
}

class TopicStat {
  const TopicStat({this.attempts = 0, this.correct = 0});

  final int attempts;
  final int correct;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  TopicStat record(bool wasCorrect) => TopicStat(
    attempts: attempts + 1,
    correct: correct + (wasCorrect ? 1 : 0),
  );

  Map<String, dynamic> toJson() => {'a': attempts, 'c': correct};

  factory TopicStat.fromJson(Map<String, dynamic> json) => TopicStat(
    attempts: (json['a'] as num?)?.toInt() ?? 0,
    correct: (json['c'] as num?)?.toInt() ?? 0,
  );
}
