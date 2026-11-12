import 'package:coding_quest/data/course_repository.dart';
import 'package:coding_quest/models/course.dart';
import 'package:coding_quest/models/level.dart';
import 'package:coding_quest/models/question.dart';

Question choiceQuestion({
  String id = 'q1',
  String topic = 'basics',
  int answer = 1,
}) => Question(
  id: id,
  type: QType.choice,
  topic: topic,
  prompt: 'Pick one',
  promptAr: 'اختر واحداً',
  options: const ['A', 'B', 'C'],
  answer: answer,
  pairs: const [],
  explanation: 'Because B is correct.',
  explanationAr: 'لأن B هي الصحيحة.',
);

Level buildLevel({
  String id = 'cpp-l1',
  List<Question>? questions,
}) => Level(
  id: id,
  title: 'Level 1',
  titleAr: 'المستوى الأول',
  subtitle: 'Basics',
  subtitleAr: 'الأساسيات',
  intro: 'Intro',
  introAr: 'مقدمة',
  keyPointsEn: const ['Point'],
  keyPointsAr: const ['نقطة'],
  questions: questions ?? [choiceQuestion()],
);

Course buildCourse({
  String id = 'cpp',
  List<Level>? levels,
}) => Course(
  id: id,
  name: 'C++',
  subtitle: 'Learn C++',
  subtitleAr: 'تعلّم C++',
  iconKey: 'code',
  colorHex: '1CB0F4',
  levels: levels ?? [buildLevel()],
);

CourseRepository buildRepository({
  List<Course>? courses,
}) => CourseRepository.fromData(courses: courses ?? [buildCourse()]);
