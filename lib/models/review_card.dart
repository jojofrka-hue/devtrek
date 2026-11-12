/// One Leitner box card, keyed by question id.
class ReviewCard {
  const ReviewCard({
    required this.questionId,
    required this.courseId,
    required this.box,
    required this.due,
    this.reviews = 0,
    this.lapses = 0,
  });

  final String questionId;
  final String courseId;
  final int box;
  final DateTime due;
  final int reviews;
  final int lapses;

  ReviewCard copyWith({
    int? box,
    DateTime? due,
    int? reviews,
    int? lapses,
  }) {
    return ReviewCard(
      questionId: questionId,
      courseId: courseId,
      box: box ?? this.box,
      due: due ?? this.due,
      reviews: reviews ?? this.reviews,
      lapses: lapses ?? this.lapses,
    );
  }

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'courseId': courseId,
    'box': box,
    'due': due.toIso8601String(),
    'reviews': reviews,
    'lapses': lapses,
  };

  factory ReviewCard.fromJson(Map<String, dynamic> json) {
    return ReviewCard(
      questionId: json['questionId'] as String,
      courseId: json['courseId'] as String? ?? '',
      box: (json['box'] as num?)?.toInt() ?? 1,
      due: DateTime.tryParse(json['due'] as String? ?? '') ?? DateTime.now(),
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      lapses: (json['lapses'] as num?)?.toInt() ?? 0,
    );
  }
}
