import 'package:flutter/material.dart';

import '../machine_structure/machine_lessons.dart';
import '../models/course.dart';
import '../models/question.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';

const devTrekBrand = 'DevTrek';

/// The main specialization track the user focuses on (C / Python / Machine).
enum DevTrekTrack { c, python, machine }

extension DevTrekTrackX on DevTrekTrack {
  String get courseId => switch (this) {
    DevTrekTrack.c => 'c',
    DevTrekTrack.python => 'python',
    DevTrekTrack.machine => 'machine',
  };

  String label(bool ar) => switch (this) {
    DevTrekTrack.c => 'C',
    DevTrekTrack.python => 'Python',
    DevTrekTrack.machine => ar ? 'معمارية الحاسوب' : 'Structure Machine',
  };

  String description(bool ar) => switch (this) {
    DevTrekTrack.c => ar
        ? 'الأساسيات: printf والمؤشرات والذاكرة'
        : 'Fundamentals: printf, pointers and memory',
    DevTrekTrack.python => ar
        ? 'صياغة سهلة وأفكار برمجية قوية'
        : 'Easy syntax, powerful programming ideas',
    DevTrekTrack.machine => ar
        ? 'كيف يعمل الحاسوب: من فون نيومان إلى الذاكرة'
        : 'How computers work: von Neumann to memory',
  };

  IconData get icon => switch (this) {
    DevTrekTrack.c => Icons.terminal_rounded,
    DevTrekTrack.python => Icons.data_object_rounded,
    DevTrekTrack.machine => Icons.memory_rounded,
  };

  Color get color => switch (this) {
    DevTrekTrack.c => purple,
    DevTrekTrack.python => const Color(0xFFFFC800),
    DevTrekTrack.machine => blue,
  };

  Course? course(AppServices services) => this == DevTrekTrack.machine
      ? null
      : services.repository.courseById(courseId);

  int moduleCount(AppServices services) =>
      this == DevTrekTrack.machine
      ? machineLessons.length
      : (course(services)?.levels.length ?? 0);

  int completedCount(AppServices services) {
    final trackCourse = course(services);
    if (trackCourse == null) return 0;
    var done = 0;
    for (var i = 0; i < trackCourse.levels.length; i++) {
      if (services.progress.starsFor(trackCourse.id, i) >= 1) done++;
    }
    return done;
  }

  int starsCount(AppServices services) {
    final trackCourse = course(services);
    if (trackCourse == null) return 0;
    var stars = 0;
    for (var i = 0; i < trackCourse.levels.length; i++) {
      stars += services.progress.starsFor(trackCourse.id, i);
    }
    return stars;
  }
}

DevTrekTrack trackFromFavorite(String favorite) => switch (favorite) {
  'python' => DevTrekTrack.python,
  'machine' => DevTrekTrack.machine,
  _ => DevTrekTrack.c,
};

DevTrekTrack currentTrack(AppServices services) =>
    trackFromFavorite(services.profile.favoriteCourse);

Future<void> selectTrack(AppServices services, DevTrekTrack track) async {
  services.profile.favoriteCourse = track.courseId;
  await services.profile.save();
}

enum ModuleDifficulty { beginner, intermediate, advanced }

ModuleDifficulty difficultyOfIndex(int index, int total) {
  if (total <= 1) return ModuleDifficulty.beginner;
  return ModuleDifficulty.values[((index * 3) ~/ total).clamp(0, 2)];
}

extension ModuleDifficultyX on ModuleDifficulty {
  String label(bool ar) => switch (this) {
    ModuleDifficulty.beginner => ar ? 'مبتدئ' : 'Beginner',
    ModuleDifficulty.intermediate => ar ? 'متوسط' : 'Intermediate',
    ModuleDifficulty.advanced => ar ? 'متقدم' : 'Advanced',
  };

  Color get color => switch (this) {
    ModuleDifficulty.beginner => green,
    ModuleDifficulty.intermediate => amber,
    ModuleDifficulty.advanced => red,
  };

  IconData get icon => switch (this) {
    ModuleDifficulty.beginner => Icons.eco_rounded,
    ModuleDifficulty.intermediate => Icons.trending_up_rounded,
    ModuleDifficulty.advanced => Icons.bolt_rounded,
  };
}

/// Bloom's taxonomy stages every module is organized into.
enum BloomStage { understanding, application, creation }

extension BloomStageX on BloomStage {
  String label(bool ar) => switch (this) {
    BloomStage.understanding => ar ? 'الفهم' : 'Understanding',
    BloomStage.application => ar ? 'التطبيق' : 'Application',
    BloomStage.creation => ar ? 'الابتكار' : 'Creation',
  };

  String fullLabel(bool ar) => switch (this) {
    BloomStage.understanding => ar ? 'الفهم والاستيعاب' : 'Understanding & comprehension',
    BloomStage.application => ar ? 'التطبيق والتحليل' : 'Application & analysis',
    BloomStage.creation => ar ? 'الابتكار والتقييم' : 'Creation & evaluation',
  };

  String description(bool ar) => switch (this) {
    BloomStage.understanding => ar
        ? 'أسئلة مفهومية وتتبع مخرجات الكود'
        : 'Concept questions and code-output tracing',
    BloomStage.application => ar
        ? 'إصلاح الأخطاء وتتبع الذاكرة'
        : 'Fix the code and memory tracing',
    BloomStage.creation => ar
        ? 'كتابة كود كامل أو خوارزمية محسنة'
        : 'Write full code or an improved algorithm',
  };

  IconData get icon => switch (this) {
    BloomStage.understanding => Icons.menu_book_rounded,
    BloomStage.application => Icons.build_rounded,
    BloomStage.creation => Icons.auto_awesome_rounded,
  };

  Color get color => switch (this) {
    BloomStage.understanding => blue,
    BloomStage.application => amber,
    BloomStage.creation => purple,
  };
}

BloomStage stageOfQuestion(Question question) {
  if (question.type == QType.order) return BloomStage.creation;
  if (question.type == QType.match) return BloomStage.application;
  return BloomStage.understanding;
}

Map<BloomStage, int> bloomCounts(List<Question> questions) {
  final counts = {for (final stage in BloomStage.values) stage: 0};
  for (final question in questions) {
    counts[stageOfQuestion(question)] = counts[stageOfQuestion(question)]! + 1;
  }
  return counts;
}
