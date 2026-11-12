import 'question.dart';

class Level {
  const Level({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.subtitle,
    required this.subtitleAr,
    required this.intro,
    required this.introAr,
    required this.keyPointsEn,
    required this.keyPointsAr,
    required this.questions,
  });

  final String id;
  final String title;
  final String titleAr;
  final String subtitle;
  final String subtitleAr;
  final String intro;
  final String introAr;
  final List<String> keyPointsEn;
  final List<String> keyPointsAr;
  final List<Question> questions;

  factory Level.fromJson(Map<String, dynamic> json) {
    final points = json['keyPoints'] as Map<String, dynamic>? ?? const {};
    return Level(
      id: json['id'] as String,
      title: json['title'] as String,
      titleAr: json['titleAr'] as String? ?? json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      subtitleAr: json['subtitleAr'] as String? ?? json['subtitle'] as String? ?? '',
      intro: json['intro'] as String? ?? '',
      introAr: json['introAr'] as String? ?? '',
      keyPointsEn: ((points['en'] as List?) ?? const []).cast<String>(),
      keyPointsAr: ((points['ar'] as List?) ?? const []).cast<String>(),
      questions: ((json['questions'] as List?) ?? const [])
          .map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  String titleFor(bool arabic) => arabic && titleAr.isNotEmpty ? titleAr : title;
  String subtitleFor(bool arabic) =>
      arabic && subtitleAr.isNotEmpty ? subtitleAr : subtitle;
  String introFor(bool arabic) => arabic && introAr.isNotEmpty ? introAr : intro;
  List<String> keyPointsFor(bool arabic) =>
      arabic && keyPointsAr.isNotEmpty ? keyPointsAr : keyPointsEn;
}
