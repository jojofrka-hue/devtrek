# Coding Quest

A bilingual (Arabic / English) Flutter quiz game for learning programming
fundamentals: C++, C, Python, Java and JavaScript, with lesson intros,
explanations, spaced-repetition review, code-fixing challenges, an algorithm
visualizer, achievements and per-topic statistics.

## Features

- **105+ questions** loaded from JSON assets (no rebuild to add content)
- **Lesson intro cards** with key points before each level
- **Explanation after every check**, bilingual (`explanation` / `explanationAr`)
- **Hearts, combo bonus, stars** (3 stars ≥100%, 2 ≥70%, 1 ≥50%)
- **XP anti-farm rule**: full XP on the first completion of a level only
- **Daily streak** with longest-streak tracking and badges
- **Leitner spaced repetition** (boxes 1–5, intervals 0/1/3/7/16 days)
- **Fix-the-code** challenges validated with deterministic regex checks
- **Algorithm visualizer**: bubble/insertion/selection/quick sort, linear/binary search
- **12 achievements** and a topic-by-topic statistics dashboard
- **Arabic/English UI with automatic RTL**, persisted language choice
- **Mascot, sound/haptic feedback, confetti** (no extra packages, works offline)
- **Optional AI tutor** through a local Node proxy — the Claude API key never
  ships inside the app

The full design write-up, including Mermaid use-case, class and screen-flow
diagrams, is in [`docs/report.md`](docs/report.md).

## Getting started

```bash
flutter pub get
flutter run -d windows      # or: flutter run -d chrome
```

### Android note

The app makes no network calls except the optional AI helper. If you use it on
the Android emulator, set the server URL to `http://10.0.2.2:8787` in
**Settings → AI server URL** (the emulator alias for your computer).

## Tests and analysis

```bash
flutter analyze
flutter test
```

61 tests cover JSON parsing and content integrity, the XP first-attempt rule,
streak logic with an injected clock, Leitner scheduling, bug-fix validation,
achievement predicates, sorting/searching engines, persistence through an
in-memory store, and widget smoke tests for every screen.

## Content

```
assets/data/index.json            index of content files
assets/data/courses/*.json        5 courses x 3 levels x 7 questions
assets/data/bug_hunts.json        6 fix-the-code tasks
assets/data/placement.json        7 bilingual placement questions
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

To add content, extend a course file (keep `id` unique) and restart the app.

## AI helper (optional)

The app POSTs to `/explain` on a small Node server; the key stays server-side.

```bash
cd server
export ANTHROPIC_API_KEY=sk-ant-...     # PowerShell: $env:ANTHROPIC_API_KEY="..."
node index.js
```

See [`server/README.md`](server/README.md) for endpoints and platform-specific
URLs. The app keeps working offline: if the server is down it shows a friendly
message and the built-in explanation.

## Project structure

```
lib/models/     immutable domain models + JSON parsing
lib/data/       CourseRepository, achievements catalog
lib/services/   ChangeNotifier state, storage, algorithms, AI client
lib/screens/    onboarding, home, course, lesson, review, stats, bug hunt,
                visualizer, achievements, settings
lib/widgets/    question player, confetti, charts, mascot, shared UI
lib/i18n/       Arabic/English strings with English fallback
lib/theme/      colors and Material 3 theme
server/         Node Claude proxy
test/           unit tests, fixtures, in-memory store
docs/           report with diagrams
```
