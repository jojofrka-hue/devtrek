# DevTrek

DevTrek is a desktop-first Flutter app that teaches programming fundamentals
through short guided levels, a filterable bank of individual exercises and a
real code playground. Progress is earned, not farmed: XP and stars come from
completing Guided Path levels, while practice drills only sharpen accuracy.

Six tracks are available — **C**, **Python**, **Machine Structure**, **C++**,
**Java** and **JavaScript** — in English, Arabic (full RTL) and French, behind a
locked dark Material 3 theme.

## Key features

### Learning

- **Guided Path** — three sequential levels per track. A level unlocks only
  after the previous one earns at least one star, and each level is staged by
  Bloom's taxonomy: Understanding → Application → Creation.
- **Levels Bank** — every exercise in the track as a flat list, filterable by
  challenge type (Understanding, Fix the Code, Memory Trace, Creation) and by
  difficulty (Beginner, Intermediate, Advanced). A row opens that single
  exercise immediately, with no level navigation in between.
- **Practice drills** — bank exercises record accuracy and queue mistakes for
  review, but award no XP or stars.
- **Explanation after every check**, with the correct answer revealed on a miss.

### Code Playground

- **C and Python** tabs compile and run real code on Windows with the toolchains
  installed on the machine (gcc/clang, Python 3): sample programs, stdin, exit
  code, compile log, a 15 s run timeout and output capped at 256 KB. Missing
  toolchains are detected and reported instead of failing silently.
- **Machine** tab — a Register Tracker: a small CPU (R0–R3 plus PC, 16 memory
  cells) that runs or single-steps assembly-like programs and shows registers
  and memory changing, with operand validation and sample programs.

### Progress and motivation

- **XP** granted on the first completion of a level only, **1–3 stars** per
  level, and learner ranks.
- **Daily streak** with longest-streak tracking; Home shows today's goal and the
  last completed lesson.
- **Leitner spaced repetition** (boxes 1–5, intervals 0/1/3/7/16 days). Wrong
  answers are queued automatically and the due count is surfaced on Home.
- **12 achievements**, evaluated as challenges are completed.
- **Statistics** — overall accuracy, per-topic breakdown, XP, streaks, completed
  levels, stars, question bank size, reviews done and bugs solved.
- Celebration FX (confetti, shake), mascot, sound and haptic feedback.

### App shell

- Responsive desktop layout: an extended navigation rail on wide windows, a
  bottom navigation bar on compact ones. The sidebar footer shows the active
  track and the app version (`v1.0.0`).
- **Home** stays focused: welcome header, XP/streak/stars, a Continue banner for
  the active track, a Daily Goal / Recent Activity card, and two tools — Code
  Playground and Fix the code (six bug-hunt tasks with deterministic validation).
- **Dark-only** theme. Language and track are chosen during onboarding and
  persisted; there are no theme or language switchers in the shell, and track
  changes live in Settings.
- Works fully offline. The optional **AI tutor** calls a local proxy — the
  Anthropic API key never ships inside the app.

## Tech stack

| Layer       | Technology                                                           |
| ----------- | -------------------------------------------------------------------- |
| UI          | Flutter, Material 3, custom desktop theme and hand-written FX         |
| Language    | Dart (SDK `^3.13.7`)                                                 |
| State       | `ChangeNotifier` services behind an inherited `AppScope`              |
| Persistence | `shared_preferences` — profile, progress, streaks, review, settings    |
| Content     | JSON assets loaded by `CourseRepository`; architecture lessons in Dart |
| Networking  | `http`, used only for the local AI proxy                              |
| i18n        | `flutter_localizations` + `intl`; English / Arabic / French with RTL   |
| Desktop     | Windows runner (C++) and PowerShell launch scripts                    |
| AI proxy    | Node 18+ (`server/index.js`), with a Dart fallback when Node is absent |
| Quality     | `flutter_test` (unit + widget) and `flutter_lints`                    |

Dependencies are limited to `flutter_localizations`, `shared_preferences`,
`http`, `intl` and `cupertino_icons` — no state-management or UI frameworks.

## Getting started

```bash
flutter pub get
flutter run -d windows
```

Windows is the primary target. The Playground additionally needs a C compiler
(gcc or clang) and/or Python 3 available on the machine; everything else works
without them.

### Run the app together with the AI proxy

```powershell
powershell -ExecutionPolicy Bypass -File scripts\dev.ps1
```

The script prepares the Windows build, starts the local proxy (Node when
installed, otherwise the Dart implementation), waits until it is healthy,
launches `flutter run -d windows`, and stops the proxy when Flutter exits. In
VS Code, press **F5** — the bundled launch configuration runs the same flow.

### AI proxy on its own

Copy `server/.env.example` to `server/.env` and put your key there:

```bash
node server/index.js        # Node 18+, no dependencies
```

`server/.env` is gitignored and excluded from exports; only the placeholder
example is committed. The app POSTs to `/explain` on `http://localhost:8787`
(configurable in Settings). If the proxy is down, the app shows a friendly
message and falls back to the built-in explanation. See
[`server/README.md`](server/README.md) for endpoints and platform-specific URLs,
including the Android emulator alias `http://10.0.2.2:8787`.

## Tests and analysis

```bash
flutter analyze
flutter test
```

**136 tests** cover JSON parsing and content integrity, the XP first-attempt
rule, streak logic with an injected clock, Leitner scheduling, bug-fix
validation, achievement predicates, sorting/searching engines, the playground
runner and its UI wiring, persistence through an in-memory store, and widget
tests for the shell, dashboard, onboarding, learning tabs, exercise bank and
practice drills.

## Content

```
assets/data/index.json          index of content files
assets/data/courses/*.json      5 courses x 3 levels x 7 questions (105)
assets/data/bug_hunts.json      6 fix-the-code tasks
assets/data/placement.json      7 bilingual placement questions
lib/machine_structure/machine_lessons.dart   6 architecture lessons + quizzes
```

Each question looks like:

```json
{
  "id": "cpp-basics-1",
  "type": "choice",
  "topic": "variables",
  "prompt": "Which line declares a variable?",
  "promptAr": "أي سطر يعرّف متغيراً؟",
  "code": null,
  "options": ["int x = 3;", "x = 3;", "print(x);"],
  "answer": 0,
  "explanation": "A declaration includes a type.",
  "explanationAr": "التعريف يتضمن نوعاً."
}
```

To add content, extend a course file (keep `id` unique) and restart the app — no
code changes are needed.

## Project structure

```
lib/models/             immutable domain models + JSON parsing
lib/data/               CourseRepository, achievements catalog
lib/services/           ChangeNotifier state, storage, streaks, review, AI client
lib/views/              desktop shell, Home, Learning, Playground, Stats,
                        onboarding, challenge and exercise flows, FX,
                        register tracker
lib/playground/         C/Python code runner and samples
lib/machine_structure/  architecture lessons and lesson player
lib/screens/            settings, lesson player, bug hunt, review,
                        visualizer, achievements
lib/widgets/            question player, confetti, charts, mascot, shared UI
lib/i18n/               English/Arabic/French strings
lib/theme/              colors and Material 3 theme
server/                 AI proxy (Node, with a Dart fallback)
scripts/                proxy start/stop, Windows prep, app + proxy launcher
.vscode/                F5 configuration that starts the proxy before Flutter
test/                   unit and widget tests, fixtures, in-memory store
docs/                   design report with Mermaid diagrams
```

The design write-up — use-case, class and screen-flow diagrams — is in
[`docs/report.md`](docs/report.md).
