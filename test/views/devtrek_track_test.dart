import 'package:coding_quest/models/question.dart';
import 'package:coding_quest/views/devtrek_track.dart';
import 'package:flutter_test/flutter_test.dart';

Question q(String id, QType type) => Question(
  id: id,
  type: type,
  topic: 'basics',
  prompt: 'P',
  promptAr: 'س',
  options: const ['A', 'B'],
  answer: 0,
  pairs: const [
    ['a', 'b'],
  ],
  explanation: 'e',
  explanationAr: 'ش',
);

void main() {
  test('question types map onto Bloom stages', () {
    expect(stageOfQuestion(q('a', QType.choice)), BloomStage.understanding);
    expect(stageOfQuestion(q('b', QType.match)), BloomStage.application);
    expect(stageOfQuestion(q('c', QType.order)), BloomStage.creation);
  });

  test('bloomCounts tallies every stage', () {
    final counts = bloomCounts([
      q('a', QType.choice),
      q('b', QType.choice),
      q('c', QType.match),
      q('d', QType.order),
    ]);
    expect(counts[BloomStage.understanding], 2);
    expect(counts[BloomStage.application], 1);
    expect(counts[BloomStage.creation], 1);
  });

  test('difficulty splits modules into thirds', () {
    expect(difficultyOfIndex(0, 3), ModuleDifficulty.beginner);
    expect(difficultyOfIndex(1, 3), ModuleDifficulty.intermediate);
    expect(difficultyOfIndex(2, 3), ModuleDifficulty.advanced);
    expect(difficultyOfIndex(0, 6), ModuleDifficulty.beginner);
    expect(difficultyOfIndex(3, 6), ModuleDifficulty.intermediate);
    expect(difficultyOfIndex(5, 6), ModuleDifficulty.advanced);
    expect(difficultyOfIndex(0, 1), ModuleDifficulty.beginner);
  });

  test('favorite course id maps to a track and defaults to C', () {
    expect(trackFromFavorite('c'), DevTrekTrack.c);
    expect(trackFromFavorite('python'), DevTrekTrack.python);
    expect(trackFromFavorite('machine'), DevTrekTrack.machine);
    expect(trackFromFavorite(''), DevTrekTrack.c);
    expect(trackFromFavorite('cpp'), DevTrekTrack.c);
  });

  test('track course ids match the content assets', () {
    expect(DevTrekTrack.c.courseId, 'c');
    expect(DevTrekTrack.python.courseId, 'python');
    expect(DevTrekTrack.machine.courseId, 'machine');
  });
}