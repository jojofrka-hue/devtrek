# Coding Quest — project report

Coding Quest is a bilingual (Arabic / English) Flutter quiz game that teaches
programming fundamentals. Content lives in JSON, progress is persisted locally,
and an optional small Node proxy adds an AI tutor without exposing an API key in
the app.

---

## 1. Use case diagram

```mermaid
flowchart LR
  Student((Student))
  AI[Claude API]
  Server[AI proxy server]

  subgraph App[Coding Quest]
    U1[Onboard and choose a course]
    U2[Take a placement test]
    U3[Read a lesson intro]
    U4[Answer quiz activities]
    U5[Read explanations / ask AI]
    U6[Review mistakes with Leitner]
    U7[Fix broken code]
    U8[Watch sorting and searching]
    U9[Track statistics and badges]
    U10[Switch language / reset progress]
  end

  Student --> U1
  Student --> U2
  Student --> U3
  Student --> U4
  Student --> U5
  Student --> U6
  Student --> U7
  Student --> U8
  Student --> U9
  Student --> U10

  U1 -.->|includes| U2
  U3 -.->|includes| U4
  U5 -.->|extends| U4
  U4 -.->|wrong answer enqueues card| U6
  U5 -->|POST /explain| Server
  Server -->|server-side key| AI
```

## 2. Class diagram

```mermaid
classDiagram
  direction LR

  class Course {
    +String id
    +String name
    +String subtitle
    +String subtitleAr
    +String iconKey
    +String colorHex
    +List~Level~ levels
    +subtitleFor(bool) String
  }
  class Level {
    +String id
    +String title
    +String intro
    +List~String~ keyPointsEn
    +List~String~ keyPointsAr
    +List~Question~ questions
    +keyPointsFor(bool) List~String~
  }
  class Question {
    +String id
    +QType type
    +String topic
    +String prompt
    +String promptAr
    +List~String~ options
    +int answer
    +List~List~String~~ pairs
    +String explanation
    +String explanationAr
    +promptFor(bool) String
    +correctAnswerText() String
  }
  class BugTask {
    +String id
    +String brokenCode
    +String solution
    +List~String~ mustMatchAny
    +List~String~ mustNotMatch
    +hintFor(bool) String
  }
  class ReviewCard {
    +String questionId
    +String courseId
    +int box
    +DateTime due
    +int reviews
    +int lapses
  }
  class Achievement {
    +String id
    +String icon
    +String titleEn
    +String titleAr
    +titleFor(bool) String
  }
  class TopicStat {
    +int attempts
    +int correct
    +accuracy double
    +record(bool) TopicStat
  }

  Course "1" --> "*" Level
  Level "1" --> "*" Question
  ReviewCard --> Question : questionId
  AchievementContext ..> TopicStat
  AchievementContext ..> Course : uses

  class CourseRepository {
    +List~Course~ courses
    +List~BugTask~ bugTasks
    +List~Question~ placementQuestions
    +loadFromAssets() CourseRepository
    +fromData() CourseRepository
    +courseById(id) Course
    +questionById(id) Question
    +totalQuestions int
  }
  CourseRepository "1" o-- "*" Course
  CourseRepository "1" o-- "*" BugTask

  class AppServices {
    +KeyValueStore store
    +CourseRepository repository
    +ProfileService profile
    +ProgressService progress
    +StreakService streak
    +ReviewService review
    +AchievementService achievements
    +BugHuntProgressService bugHunt
    +SettingsService settings
    +AiTutorService ai
    +SoundService sound
    +create() AppServices
    +evaluateAchievements()
    +resetAll()
  }
  AppServices *-- CourseRepository
  AppServices *-- ProgressService
  AppServices *-- ReviewService
  AppServices *-- AchievementService
  AppServices *-- AiTutorService

  class ProgressService {
    +int totalXp
    +int completedLevels
    +Map~String,TopicStat~ topicStats
    +recordLevelResult(...) int
    +recordAnswer(topic, correct)
    +grantStars(courseId, index, stars)
    +isUnlocked(courseId, index) bool
    +isFirstAttempt(courseId, index) bool
  }
  class ReviewService {
    +Map~int,int~ intervals
    +List~ReviewCard~ due()
    +enqueueWrongAnswer(id)
    +scheduleReview(id, correct) ReviewCard
  }
  class StreakService {
    +int current
    +int longest
    +bool activeToday
    +recordActivity() bool
  }
  class AchievementService {
    +Set~String~ unlocked
    +evaluate(...) List~Achievement~
  }
  class BugHuntProgressService {
    +Set~String~ solved
    +submit(task, code) BugValidationResult
  }
  class SettingsService {
    +String language
    +bool sound
    +String aiServerUrl
    +toggleLanguage()
  }
  class AiTutorService {
    +explainMistake(...) AiExplanation
  }

  ProgressService ..> TopicStat
  ReviewService ..> ReviewCard
  AchievementService ..> Achievement
  AchievementService ..> AchievementContext
```

`KeyValueStore` is an abstract interface (`getString`, `getInt`, `setString`, …)
implemented by `PrefsStore` in production and `MemoryStore` in tests, which keeps
every service deterministic and unit-testable.

## 3. Screen flow

```mermaid
flowchart TD
  A[Onboarding: name / experience / goal / language] --> B{Beginner?}
  B -->|Yes| D[Home]
  B -->|No| C[Placement test]
  C -->|grants stars| D
  D --> E[Course levels]
  E --> F[Lesson intro card]
  F --> G[Quiz activity]
  G -->|CHECK| H{Correct?}
  H -->|Yes| I[Explanation + next activity]
  H -->|No| J[Correct answer + explanation + optional AI]
  J --> K[Leitner review queue]
  I --> L{More activities?}
  L -->|Yes| G
  L -->|No| M[Result: stars / XP / badges]
  K --> N[Review page]
  D --> N
  D --> O[Statistics]
  D --> P[Bug hunt]
  D --> Q[Algorithm visualizer]
  D --> R[Achievements]
  D --> S[Settings]
  S -->|reset| A
  M -->|next level| G
  M -->|practice again| G
```

## 4. Architecture

```
lib/
  main.dart                 bootstrap: prefs -> JSON -> AppServices -> runApp
  app.dart                  MaterialApp, locales (en/ar), home selection
  app_scope.dart            InheritedWidget: context.services / context.s
  models/                   pure data + JSON parsing (no Flutter imports)
  data/                     CourseRepository (assets), achievements catalog
  services/                 ChangeNotifier state + algorithms + storage
  screens/                  one file per screen
  widgets/                  reusable UI (question player, confetti, bars, ...)
  i18n/app_strings.dart     Arabic/English dictionaries with EN fallback
  theme/app_theme.dart      colors and Material 3 theme
assets/data/                JSON content (5 courses, bug hunts, placement)
server/                     optional Node Claude proxy
test/                       unit tests + in-memory store + fixtures
```

**Why this split.** The original prototype was a single 2,700-line file. The
current layout separates *content* (JSON), *state* (services), *presentation*
(screens/widgets), and *domain* (models), which is exactly what is graded under
"organization" and makes each layer independently testable.

## 5. Content pipeline (JSON)

`assets/data/index.json` lists course files. `CourseRepository.loadFromAssets()`
reads the index, then each course, the bug-hunt file and the placement test.
Questions carry stable `id`s, so review cards survive content edits.

To add content without touching Dart:

1. Add a level or question to `assets/data/courses/<course>.json`.
2. Keep a unique `id`, a `topic`, `prompt`/`promptAr`, the answer data and
   `explanation`/`explanationAr`.
3. Restart the app. New questions appear automatically, and new ids can be
   reviewed and tracked.

Bug-hunt tasks live in `assets/data/bug_hunts.json`. Their `checks` block uses
regular expressions (`mustMatchAny`, `mustNotMatch`).

## 6. XP anti-farm rule

`ProgressService.recordLevelResult()` keeps a persisted set of attempted level
keys (`courseId:levelIndex`):

```dart
final firstAttempt = !_attemptedLevels.contains(key);
final awarded = firstAttempt ? rawXp : 0;
```

The first completion pays full XP. "Practice again" still updates stars and
perfect-level records but pays **0 XP**, and the result screen shows
`practiceXpNote` so the rule is visible to the learner. Unit tests cover the
first attempt, replays and independent levels.

## 7. Leitner spaced repetition

`ReviewService.intervals = {1: 0, 2: 1, 3: 3, 4: 7, 5: 16}` days.

- A wrong answer in a lesson calls `enqueueWrongAnswer` → box 1, due today.
- A correct review promotes the card: `box = min(5, box + 1)` and due date moves
  forward by the box interval.
- A wrong review resets the card to box 1 and increments `lapses`.
- `due()` returns cards whose date is today or earlier; the home screen shows
  the count as a badge.

The clock is injected (`clock: () => ...`) so tests advance days without
waiting.

## 8. Achievements and statistics

`achievements_catalog.dart` holds 12 declarative achievements, each a
`bool Function(AchievementContext)`. The context is an immutable snapshot of
progress, streak, reviews, bug fixes, topic stats, stars and the repository, so
conditions are pure functions and easy to test.

`ProgressService.recordAnswer(topic, correct)` builds `TopicStat` values.
`StatsPage` derives overall accuracy, per-topic bars, XP, streaks, levels, stars,
bank size, reviews and fixed bugs. Topic labels are localized with a
`topic_<key>` lookup and fall back to the raw key.

## 9. Fix-the-code validation

`validateBugFix` normalizes line endings, trims, then:

- at least one `mustMatchAny` regex must match;
- no `mustNotMatch` regex may match.

This is deterministic and fully testable; solutions do not require executing
user code, so there is no sandbox/security risk on the device.

## 10. Algorithm visualizer

`sort_engine.dart` records immutable frames while running bubble, insertion,
selection or quick sort, and linear or binary search. Each frame carries the
array plus comparison/swap/pivot/sorted/checked highlights. The screen plays the
frames with a `Timer.periodic`; speed, algorithm and array can be changed, and
searches pick a target from the sorted array. The engine is independent of
Flutter and tested with plain Dart tests.

## 11. Bilingual UI and RTL

- `SettingsService.language` is persisted and drives `MaterialApp.locale`.
- `GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations` and
  `GlobalCupertinoLocalizations` enable automatic RTL.
- UI strings live in `AppStrings` with English fallback.
- Content is bilingual: `promptAr`, `explanationAr`, `introAr`,
  `keyPoints.ar`, bug-task Arabic fields, achievement titles/descriptions.
- Code blocks are forced to `TextDirection.ltr` so code always reads correctly
  inside an RTL screen.

**Known limitation:** option tokens and code snippets stay in their source
language (English syntax); only prose is translated. This is intentional, since
translating `int x = 3;` would teach wrong syntax.

## 12. AI tutor security

The Flutter app calls `POST {aiServerUrl}/explain` with the question, the
student's answer, the correct answer and optional code. The Node server
(`server/index.js`) is the only component that reads `ANTHROPIC_API_KEY` and
talks to Anthropic. The app has no key and no SDK.

Server safeguards: 16 KB body cap, 20 requests/minute per IP, strict field
validation, 350-token answer limit, and no user code execution.

If the server is unreachable, the lesson shows the offline message and the
built-in explanation still works.

## 13. Testing

`flutter test` runs 61 tests:

| Area | File | What is verified |
|---|---|---|
| JSON models | `test/models/question_test.dart` | parsing, bilingual fallback, answer text |
| XP rule | `test/services/progress_service_test.dart` | first attempt vs replay, stars, ranks, persistence |
| Streak | `test/services/streak_service_test.dart` | fake clock, gaps, stale load, reset |
| Leitner | `test/services/review_service_test.dart` | box promotion, intervals, lapse reset, persistence |
| Achievements | `test/data/achievements_test.dart` | every threshold, course completion, persistence |
| Bug fixes | `test/services/bug_validation_test.dart` | regex checks, CRLF, progress service |
| Algorithms | `test/services/sort_engine_test.dart` | sorted output, frames, comparisons, search |
| Content | `test/data/content_integrity_test.dart` | unique ids, valid answers, bilingual text, bug solutions pass their checks |
| Screens | `test/screens/screens_smoke_test.dart` | every screen pumps and renders without errors |

Tests use `MemoryStore` (no SharedPreferences) and fixture builders, so they are
fast and deterministic. The content test already caught a real bug: the
out-of-bounds task's forbidden regex matched the array declaration, not just the
bad read; the check was narrowed to `cout << arr[3]`.

## 14. How to run

```bash
flutter pub get
flutter run -d windows      # or chrome / android
flutter test
flutter analyze
```

Optional AI helper:

```bash
cd server
export ANTHROPIC_API_KEY=sk-ant-...
node index.js
```

Then set the address in the app under **Settings → AI server URL**
(Android emulator: `http://10.0.2.2:8787`).

## 15. Known limitations / future work

- Question content is static JSON; a remote CMS would be the next step.
- The AI helper depends on network + a running proxy; it degrades gracefully.
- Sound effects use OS clicks/haptics rather than bundled audio assets.
- Story/level map art is icon-based; sprites could be added later.
