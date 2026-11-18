# DevTrek

**A specialized desktop-first learning environment for computer science students.**

DevTrek brings programming fundamentals, computer architecture and hands-on code
execution into one focused study environment. Built natively with **Flutter
Desktop**, its Windows application is designed for a desktop sidebar, keyboard
input and room to read, write and inspect code—not a mobile-only quiz app.

Follow a structured curriculum, practise individual exercises or experiment with
real C and Python programs locally. Core learning, saved progress and local code
execution work **offline**, without a hosted compiler service. An optional AI
tutor extends the built-in explanations when internet access is available.

## Key features

### Guided Path and Levels Bank: separate learning workflows

- **Guided Path** provides sequential, unlockable levels with Understanding,
  Application and Creation activities. Level cards show a single title, earned
  stars, progress and learning-stage summaries.
- **Levels Bank** is a flat list of individual exercises, not another copy of
  the guided level cards. Combine challenge-type filters—**Understanding**,
  **Fix the Code**, **Memory Trace**, **Creation**—with **Beginner**,
  **Intermediate** and **Advanced** difficulty filters.
- **Direct practice** opens one exercise immediately, with answer checking and
  feedback. Drills contribute to accuracy statistics but award no level XP or
  stars; progression remains tied to Guided Path completion.

### Local, offline C and Python execution

- **C compiler integration:** compile and run programs using an installed
  **gcc** toolchain, such as MinGW-w64. **clang** is also supported.
- **Python integration:** execute scripts with an installed **Python 3
  interpreter**; Python execution does not use gcc.
- Edit sample programs, provide standard input and inspect program output,
  compiler diagnostics and exit codes inside the desktop Code Playground.
- Toolchain detection reports missing compilers or interpreters. Compilation and
  execution have timeouts, and long output is truncated for display.
- Execution happens on the student's computer, with no remote execution API.
  Compilers and interpreters are installed separately, not bundled with DevTrek.

### Algorithm Trace: C algorithms made visible

- Three interactive C presets: **Array Sum / Loop**, **Bubble Sort
  Step-by-Step** and **Linear Search**.
- **Step** executes one statement or condition, **Run / Pause** controls automatic
  playback, and **Reset** restores the current preset to its initial state.
- A highlighted C source line stays synchronized with **Variables Watch**
  (`i`, `j`, `sum`, `temp`, `target`, and other relevant variables), a visual
  **Array State** row and a concise English/Arabic explanation of that step.
- Index markers identify the elements being read or compared; gold highlights
  distinguish array writes and changed variables. Bubble Sort exposes each
  assignment in a swap, not just the final exchanged pair.
- This is a deterministic, read-only **preset simulation**, not a debugger for
  arbitrary C source or a view into live process memory. It works offline without
  a compiler; the separate C/Python tabs provide real native execution.

### Computer science content and progress

- **Programming tracks:** C, Python, C++, Java and JavaScript, each with three
  guided levels. Native code execution is available for C and Python only.
- **Machine Structure:** six architecture lessons with quizzes, independent of
  the Algorithm Trace tool in the Playground.
- **Focused dashboard:** active-track Continue banner, XP, stars, streaks,
  Daily Goal / Recent Activity and shortcuts to practice tools.
- **Learning analytics:** first-completion XP rewards, achievements, per-topic
  accuracy and a Leitner review queue for recorded mistakes.

### Native desktop interface

- Dark Material 3 interface with a desktop navigation rail and a compact-window
  layout, rather than a mobile-only navigation experience.
- A compact footer pinned below Settings shows the selected track—for example,
  **Active Track: C**—and **v1.0.0**, updating when the track changes.
- Descriptive hover tooltips support navigation, compiler execution and trace
  controls. Settings includes an **About DevTrek** card explaining the academic
  desktop learning environment.
- Learning headers omit the red heart/lives counter; existing assessment and
  progression rules are unchanged.
- Locally persisted profile and progress; track selection is available in Settings.
- English and Arabic learning content, Arabic right-to-left layout and a
  partially translated French interface. French course content is not included.

## Tech stack

| Area | Technology |
| --- | --- |
| Desktop application | Flutter Desktop, Dart (`>=3.13.7 <4.0.0`), native Windows C++ runner |
| Interface | Material 3, custom dark theme, responsive layouts and Flutter animations |
| State | `ChangeNotifier` services exposed through an inherited `AppScope` |
| Persistence | `shared_preferences` for local profile, settings and learning progress |
| Content | JSON course assets and Dart architecture-lesson definitions |
| Local execution | Dart `Process` APIs, external gcc/clang and Python 3 |
| Localization | `flutter_localizations`, `intl` and application string tables |
| Optional AI | HTTP client with a separate Node.js proxy |
| Quality | `flutter_test` unit/widget tests and `flutter_lints` |

## Setup and installation guide

The commands below use **PowerShell on Windows**. Internet access is needed to
clone the repository and download dependencies; core learning and local code
execution work offline after setup.

### Prerequisites & Requirements

| Requirement | Purpose and setup |
| --- | --- |
| Windows 10/11, 64-bit | Target platform for the native desktop application and local code execution. |
| Git | Required to clone the project repository. |
| Flutter SDK | Install Flutter with a Dart SDK compatible with `>=3.13.7 <4.0.0`, and add the Flutter `bin` directory to `PATH`. Dart is included with Flutter. |
| Visual Studio | Install the **Desktop development with C++** workload, including MSVC, C++ CMake tools and the Windows SDK, to build the Windows application. |
| Visual Studio Code (optional editor) | Install the **Flutter** and **Dart** extensions. VS Code does **not** replace the Visual Studio C++ build toolchain. |
| GCC Compiler (MinGW-w64 / MinGW) | Required for local C execution in the Playground. Install a Windows GCC toolchain and add its `bin` directory to `PATH`, for example `C:\MinGW\bin` or `C:\msys64\ucrt64\bin`. This is separate from the MSVC toolchain that builds the Flutter app. |
| Python 3 (optional) | Required only for the Python Playground; add the interpreter directory to `PATH`. |
| Node.js 18+ (optional) | Required only for the separate AI proxy described below. |

Algorithm Trace uses built-in simulations and does not require GCC. The C
Playground also supports clang as an alternative compiler.

### Clone Instructions

Open PowerShell in the directory where you keep development projects:

```powershell
git clone https://github.com/jojofrka-hue/devtrek.git
cd devtrek
```

Run the remaining project commands from this cloned `devtrek` directory, which
contains the Flutter package manifest.

### Environment Setup (.env)

**Recommended:** add the Flutter SDK's `bin` directory and the GCC installation's
`bin` directory to your Windows **user Path**, then reopen PowerShell or VS Code.
DevTrek discovers compilers through `PATH` and common installation locations;
**the Flutter app does not automatically load a `.env` file**.

For an optional, session-only setup, create a local `.devtrek.env` file in your
Windows home folder (`%USERPROFILE%\.devtrek.env`), **outside the repository**.
Use these sample entries, replacing the unquoted paths with your installations:

```dotenv
FLUTTER_BIN=C:\flutter\bin
GCC_BIN=C:\MinGW\bin
```

Import only these directory entries into the current PowerShell session:

```powershell
$localPaths = @{}
Get-Content -LiteralPath "$env:USERPROFILE\.devtrek.env" | ForEach-Object {
    if ($_ -match '^(FLUTTER_BIN|GCC_BIN)=(.+)$') {
        $localPaths[$matches[1]] = $matches[2].Trim()
    }
}
$env:Path = "$($localPaths['FLUTTER_BIN']);$($localPaths['GCC_BIN']);$env:Path"
```

`FLUTTER_BIN` and `GCC_BIN` are conveniences for this setup snippet, not settings
read by DevTrek. Launch Flutter from the same terminal so the app inherits the
updated `PATH`; repeat the import for a new terminal session. Keep local path
files out of version control and exports.

**Do not add API keys to this desktop path file or import `server/.env` into the
Flutter terminal.** The optional Anthropic key belongs only in the separate
proxy's `server/.env`, as described in **Optional AI tutor** below.

Verify the tools before installing project dependencies:

```powershell
flutter --version
flutter doctor -v
gcc --version
flutter devices
```

Resolve any Windows toolchain issues reported by `flutter doctor -v` and confirm
that `flutter devices` lists **Windows**. If GCC is not found, check the compiler
folder in `PATH`, reopen the terminal and restart DevTrek after correcting it.

### Installation & Running

1. **Install Flutter package dependencies** from the cloned project directory:

   ```powershell
   flutter pub get
   ```

2. **Build and launch the Windows desktop app** from the same terminal:

   ```powershell
   flutter run -d windows
   ```

3. **Check local C execution:** open **Playground → C**, select a sample and
   click **Run**. The compiler status and output panel confirm whether GCC was
   detected and the program ran successfully.

To produce a release build, close any running DevTrek/F5 debug session first,
then run:

```powershell
flutter build windows --release
```

The release output is in `build\windows\x64\runner\Release\`. When distributing
it, keep the executable together with its generated DLLs and `data` directory.
A browser preview or mobile build does not provide native Windows code execution.

> The Playground is not a security sandbox. Programs run with the current
> user's permissions and can access files and the network. Timeouts and output
> truncation are usability limits, not isolation; run only code you trust.

## Optional AI tutor

The Flutter client sends explanation requests to a separate local proxy; only
the proxy communicates with Anthropic. AI requires internet access and a key,
while built-in explanations remain available offline.

1. Copy `server/.env.example` to `server/.env` and configure
   `ANTHROPIC_API_KEY` there.
2. Start the proxy in a separate process:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\start_proxy.ps1
   ```

3. Run Flutter from a clean terminal. The default AI server address in Settings
   is `http://localhost:8787`. Install **Node.js 18+** to run the proxy shipped
   in this repository.
4. Stop the proxy after use:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\stop_proxy.ps1
   ```

Never put the key in Flutter source, assets or build arguments. `server/.env`
is gitignored and must be excluded from exports; only the placeholder
`server/.env.example` belongs in version control. Avoid the combined app/proxy
launcher with a configured key because it shares environment variables with the
app. Keep the unauthenticated development proxy private, not publicly exposed.

## Testing

```bash
flutter analyze
flutter test
```

Coverage includes content parsing, persistence, progression rewards, streaks,
review scheduling, code-runner behavior, onboarding, desktop navigation, level
cards, bank filtering, direct exercise practice, line-accurate algorithm frames,
trace playback/reset and desktop tooltips. Widget tests use in-memory
storage rather than the learner's saved profile.

## Project organization

| Location | Responsibility |
| --- | --- |
| `lib/views/` | Desktop shell, dashboard, learning modes, Playground, statistics and exercise flows |
| `lib/playground/` | Native C/Python runner and sample programs |
| `lib/machine_structure/` | Architecture lessons and quizzes |
| `lib/models/`, `lib/data/` | Domain models, content repository and achievement catalog |
| `lib/services/` | Persistence, progress, streaks, review scheduling and AI client |
| `lib/widgets/`, `lib/theme/`, `lib/i18n/` | Shared components, theming and localization |
| `lib/screens/` | Settings and supporting lesson/practice screens |
| `assets/data/` | Bundled course and exercise content |
| `windows/` | Native Flutter Desktop host |
| `server/`, `scripts/` | Optional AI proxy and local development launchers |
| `test/` | Unit and widget regression tests |
