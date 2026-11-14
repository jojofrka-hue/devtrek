import 'package:flutter/material.dart';

import '../machine_structure/machine_lessons.dart';
import '../models/course.dart';
import '../models/question.dart';
import '../services/app_services.dart';
import '../theme/app_theme.dart';

const devTrekBrand = 'DevTrek';

enum DevTrekTrack { c, python, machine, cpp, java, javascript }

extension DevTrekTrackX on DevTrekTrack {
  String get courseId => name;

  String label(bool ar) => switch (this) {
    DevTrekTrack.c => 'C',
    DevTrekTrack.python => 'Python',
    DevTrekTrack.cpp => 'C++',
    DevTrekTrack.java => 'Java',
    DevTrekTrack.javascript => 'JavaScript',
    DevTrekTrack.machine => ar ? 'معمارية الحاسوب' : 'Machine Structure',
  };

  String description(bool ar) => switch (this) {
    DevTrekTrack.c =>
      ar
          ? 'الأساسيات: printf والمؤشرات والذاكرة'
          : 'Fundamentals: printf, pointers and memory',
    DevTrekTrack.python =>
      ar
          ? 'صياغة سهلة وأفكار برمجية قوية'
          : 'Easy syntax, powerful programming ideas',
    DevTrekTrack.machine =>
      ar
          ? 'كيف يعمل الحاسوب: من فون نيومان إلى الذاكرة'
          : 'How computers work: von Neumann to memory',
    DevTrekTrack.cpp =>
      ar
          ? 'من الأساسيات إلى الأصناف والكائنات'
          : 'From fundamentals to classes and objects',
    DevTrekTrack.java =>
      ar
          ? 'البرمجة الكائنية وبناء التطبيقات'
          : 'Object-oriented programming and applications',
    DevTrekTrack.javascript =>
      ar ? 'أساسيات لغة الويب والتفاعل' : 'Web programming and interactivity',
  };

  IconData get icon => switch (this) {
    DevTrekTrack.c => Icons.terminal_rounded,
    DevTrekTrack.python => Icons.data_object_rounded,
    DevTrekTrack.machine => Icons.memory_rounded,
    DevTrekTrack.cpp => Icons.code_rounded,
    DevTrekTrack.java => Icons.coffee_rounded,
    DevTrekTrack.javascript => Icons.javascript_rounded,
  };

  Color get color => switch (this) {
    DevTrekTrack.c => purple,
    DevTrekTrack.python => const Color(0xFFFFC800),
    DevTrekTrack.machine => blue,
    DevTrekTrack.cpp => const Color(0xFF1CB0F6),
    DevTrekTrack.java => const Color(0xFFFF9600),
    DevTrekTrack.javascript => const Color(0xFFFF4B8B),
  };

  Course? course(AppServices services) => this == DevTrekTrack.machine
      ? null
      : services.repository.courseById(courseId);

  int moduleCount(AppServices services) => this == DevTrekTrack.machine
      ? machineLessons.length
      : (course(services)?.levels.length ?? 0);

  int completedCount(AppServices services) {
    var done = 0;
    for (var i = 0; i < moduleCount(services); i++) {
      if (services.progress.starsFor(courseId, i) >= 1) done++;
    }
    return done;
  }

  int starsCount(AppServices services) {
    var stars = 0;
    for (var i = 0; i < moduleCount(services); i++) {
      stars += services.progress.starsFor(courseId, i);
    }
    return stars;
  }
}

DevTrekTrack trackFromFavorite(String favorite) => switch (favorite) {
  'python' => DevTrekTrack.python,
  'machine' => DevTrekTrack.machine,
  'cpp' => DevTrekTrack.cpp,
  'java' => DevTrekTrack.java,
  'javascript' => DevTrekTrack.javascript,
  _ => DevTrekTrack.c,
};

DevTrekTrack currentTrack(AppServices services) =>
    trackFromFavorite(services.profile.favoriteCourse);

bool isGuidedLevelUnlocked(AppServices services, String courseId, int index) {
  for (var i = 0; i < index; i++) {
    if (services.progress.starsFor(courseId, i) < 1) return false;
  }
  return true;
}

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
    BloomStage.understanding =>
      ar ? 'الفهم والاستيعاب' : 'Understanding & comprehension',
    BloomStage.application =>
      ar ? 'التطبيق والتحليل' : 'Application & analysis',
    BloomStage.creation => ar ? 'الابتكار والتقييم' : 'Creation & evaluation',
  };

  String description(bool ar) => switch (this) {
    BloomStage.understanding =>
      ar
          ? 'أسئلة مفهومية وتتبع مخرجات الكود'
          : 'Concept questions and code-output tracing',
    BloomStage.application =>
      ar ? 'إصلاح الأخطاء وتتبع الذاكرة' : 'Fix the code and memory tracing',
    BloomStage.creation =>
      ar
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
  if (question.type == QType.match ||
      typeOfQuestion(question) == ChallengeType.fixCode ||
      typeOfQuestion(question) == ChallengeType.memory) {
    return BloomStage.application;
  }
  return BloomStage.understanding;
}

Map<BloomStage, int> bloomCounts(List<Question> questions) {
  final counts = {for (final stage in BloomStage.values) stage: 0};
  for (final question in questions) {
    counts[stageOfQuestion(question)] = counts[stageOfQuestion(question)]! + 1;
  }
  return counts;
}

/// The kind of challenge a level offers, used by the Levels Bank filter.
/// Finer-grained than Bloom: splits "application" into fixing code and
/// tracing memory, grounded in the question content itself.
enum ChallengeType { understanding, fixCode, memory, creation }

ChallengeType typeOfQuestion(Question question) {
  if (question.type == QType.order) return ChallengeType.creation;
  final prompt = '${question.prompt} ${question.promptAr}'.toLowerCase();
  if (RegExp(r'\b(bug|fix|debug|repair)\b|أصلح|اصلح|إصلاح|صحح')
      .hasMatch(prompt)) {
    return ChallengeType.fixCode;
  }
  final topic = question.topic.toLowerCase();
  if (RegExp(r'memory|pointer|address|register|stack|heap|cache')
          .hasMatch(topic) ||
      RegExp(
        r'\b(memory|pointers?|registers?|addresses|heap|stack)\b|ذاكرة|مؤشر|مسجل',
      ).hasMatch(prompt)) {
    return ChallengeType.memory;
  }
  return ChallengeType.understanding;
}

Set<ChallengeType> challengeTypesOf(List<Question> questions) =>
    questions.map(typeOfQuestion).toSet();

/// Architecture lessons teach concepts (understanding) and, when they cover
/// memory/registers/stack, memory tracing. They have no fix/create activities.
Set<ChallengeType> machineChallengeTypes(MachineLesson lesson) {
  final haystack = '${lesson.titleEn} ${lesson.summaryEn} ${lesson.id}'
      .toLowerCase();
  final types = <ChallengeType>{ChallengeType.understanding};
  const memoryKeys = ['memory', 'register', 'stack', 'cache', 'ram', 'heap'];
  if (memoryKeys.any(haystack.contains)) types.add(ChallengeType.memory);
  return types;
}

extension ChallengeTypeX on ChallengeType {
  String label(bool ar) => switch (this) {
    ChallengeType.understanding => ar ? 'الفهم' : 'Understanding',
    ChallengeType.fixCode => ar ? 'إصلاح الكود' : 'Fix the Code',
    ChallengeType.memory => ar ? 'تتبع الذاكرة' : 'Memory Trace',
    ChallengeType.creation => ar ? 'الابتكار' : 'Creation',
  };

  String description(bool ar) => switch (this) {
    ChallengeType.understanding =>
      ar
          ? 'أسئلة مفهومية وتتبع المخرجات'
          : 'Concept questions and output tracing',
    ChallengeType.fixCode =>
      ar ? 'اعثر على الخطأ وأصلح الكود' : 'Find the bug and fix the code',
    ChallengeType.memory =>
      ar ? 'تتبع الذاكرة والمؤشرات' : 'Trace memory and pointers',
    ChallengeType.creation =>
      ar ? 'رتّب أو اكتب الكود كاملاً' : 'Arrange or write full code',
  };

  IconData get icon => switch (this) {
    ChallengeType.understanding => Icons.menu_book_rounded,
    ChallengeType.fixCode => Icons.bug_report_rounded,
    ChallengeType.memory => Icons.memory_rounded,
    ChallengeType.creation => Icons.auto_awesome_rounded,
  };

  Color get color => switch (this) {
    ChallengeType.understanding => blue,
    ChallengeType.fixCode => red,
    ChallengeType.memory => purple,
    ChallengeType.creation => green,
  };
}
