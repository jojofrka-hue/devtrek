import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum PlayLanguage { c, python }

enum RunFailure {
  emptySource,
  missingToolchain,
  unsupportedPlatform,
  compileFailed,
  spawnFailed,
}

class ToolchainInfo {
  const ToolchainInfo({required this.executable, required this.version});

  final String executable;
  final String version;
}

class RunOutcome {
  const RunOutcome({
    this.stdout = '',
    this.stderr = '',
    this.exitCode,
    this.timedOut = false,
    this.truncated = false,
    this.failure,
    this.failureDetail = '',
    this.compileLog = '',
    this.elapsed = Duration.zero,
  });

  final String stdout;
  final String stderr;
  final int? exitCode;
  final bool timedOut;
  final bool truncated;
  final RunFailure? failure;
  final String failureDetail;
  final String compileLog;
  final Duration elapsed;

  bool get ok => failure == null && !timedOut && exitCode == 0;
}

/// Runs user code locally with the toolchains installed on this machine.
class CodeRunner {
  CodeRunner({
    this.runTimeout = const Duration(seconds: 15),
    this.compileTimeout = const Duration(seconds: 60),
    List<String>? pythonCandidates,
    List<String>? cCandidates,
  }) : pythonCandidates = pythonCandidates ?? _defaultPythonCandidates(),
       cCandidates = cCandidates ?? _defaultCCandidates();

  static const _maxOutput = 256 * 1024;
  static const _probeArgs = ['-c', 'import sys; print(sys.version.split()[0])'];

  final Duration runTimeout;
  final Duration compileTimeout;
  final List<String> pythonCandidates;
  final List<String> cCandidates;

  ToolchainInfo? _python;
  ToolchainInfo? _c;
  bool _detected = false;

  ToolchainInfo? get python => _python;
  ToolchainInfo? get c => _c;

  Future<void> detect() async {
    _detected = true;
    _python = await _probe(pythonCandidates, _probeArgs);
    _c = await _probe(cCandidates, ['--version']);
  }

  Future<RunOutcome> run(
    PlayLanguage language,
    String source, {
    String input = '',
  }) async {
    final sw = Stopwatch()..start();
    if (!Platform.isWindows) {
      return RunOutcome(failure: RunFailure.unsupportedPlatform, elapsed: sw.elapsed);
    }
    if (source.trim().isEmpty) {
      return RunOutcome(failure: RunFailure.emptySource, elapsed: sw.elapsed);
    }
    if (!_detected) await detect();
    final tool = language == PlayLanguage.c ? _c : _python;
    if (tool == null) {
      return RunOutcome(failure: RunFailure.missingToolchain, elapsed: sw.elapsed);
    }

    final dir = await Directory.systemTemp.createTemp('cq_play_');
    try {
      final sep = Platform.pathSeparator;
      if (language == PlayLanguage.python) {
        final file = File('${dir.path}${sep}main.py');
        await file.writeAsString(source);
        return await _execute(tool.executable, [file.path], dir, input, sw);
      }
      final src = File('${dir.path}${sep}main.c');
      final exe = File('${dir.path}${sep}main.exe');
      await src.writeAsString(source);
      final compile = await _execute(
        tool.executable,
        [src.path, '-o', exe.path, '-std=c11', '-Wall'],
        dir,
        '',
        sw,
        timeout: compileTimeout,
      );
      if (compile.failure != null || compile.timedOut || compile.exitCode != 0) {
        return RunOutcome(
          failure: compile.timedOut ? null : RunFailure.compileFailed,
          timedOut: compile.timedOut,
          compileLog: '${compile.stdout}${compile.stderr}',
          elapsed: sw.elapsed,
        );
      }
      return await _execute(exe.path, [], dir, input, sw, compileLog: compile.stderr);
    } finally {
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<ToolchainInfo?> _probe(List<String> candidates, List<String> args) async {
    for (final exe in candidates) {
      if (exe.contains(Platform.pathSeparator) && !File(exe).existsSync()) {
        continue;
      }
      final dir = await Directory.systemTemp.createTemp('cq_probe_');
      try {
        final r = await _execute(
          exe,
          args,
          dir,
          '',
          Stopwatch()..start(),
          timeout: const Duration(seconds: 8),
        );
        if (r.failure == null && !r.timedOut && r.exitCode == 0 && r.stdout.trim().isNotEmpty) {
          return ToolchainInfo(
            executable: exe,
            version: r.stdout.trim().split('\n').first.trim(),
          );
        }
      } finally {
        try {
          await dir.delete(recursive: true);
        } catch (_) {}
      }
    }
    return null;
  }

  Future<RunOutcome> _execute(
    String exe,
    List<String> args,
    Directory dir,
    String input,
    Stopwatch sw, {
    Duration? timeout,
    String compileLog = '',
  }) async {
    final limit = timeout ?? runTimeout;
    Process proc;
    try {
      proc = await Process.start(exe, args, workingDirectory: dir.path);
    } on ProcessException catch (e) {
      return RunOutcome(
        failure: RunFailure.spawnFailed,
        failureDetail: e.message,
        compileLog: compileLog,
        elapsed: sw.elapsed,
      );
    }
    final out = StringBuffer();
    final err = StringBuffer();
    var truncated = false;
    void add(StringBuffer buf, List<int> bytes) {
      if (truncated) return;
      buf.write(utf8.decode(bytes, allowMalformed: true));
      if (buf.length > _maxOutput) truncated = true;
    }

    final outSub = proc.stdout.listen((b) => add(out, b));
    final errSub = proc.stderr.listen((b) => add(err, b));
    if (input.isNotEmpty) {
      try {
        proc.stdin.write(input);
      } catch (_) {}
    }
    try {
      await proc.stdin.close();
    } catch (_) {}

    var timedOut = false;
    int? code;
    try {
      code = await proc.exitCode.timeout(limit);
    } on TimeoutException {
      timedOut = true;
      proc.kill();
      try {
        code = await proc.exitCode.timeout(const Duration(seconds: 3));
      } catch (_) {
        code = null;
      }
    }
    await outSub.cancel();
    await errSub.cancel();
    return RunOutcome(
      stdout: out.toString(),
      stderr: err.toString(),
      exitCode: code,
      timedOut: timedOut,
      truncated: truncated,
      compileLog: compileLog,
      elapsed: sw.elapsed,
    );
  }

  static String _join(List<String> parts) =>
      parts.where((p) => p.isNotEmpty).join(Platform.pathSeparator);

  static List<String> _defaultPythonCandidates() {
    final found = <String>[];
    final sep = Platform.isWindows ? ';' : ':';
    for (final dir in (Platform.environment['PATH'] ?? '').split(sep)) {
      // The WindowsApps alias is a Store stub, not an interpreter.
      if (dir.trim().isEmpty || dir.contains('WindowsApps')) continue;
      found.add(_join([dir, 'python.exe']));
      found.add(_join([dir, 'python3.exe']));
    }
    found.addAll(['python.exe', 'python3.exe']);
    final roots = <String>[
      _join([Platform.environment['LOCALAPPDATA'] ?? '', 'Programs', 'Python']),
      Platform.environment['PROGRAMFILES'] ?? r'C:\Program Files',
      r'C:\',
    ];
    for (final root in roots) {
      final d = Directory(root);
      if (!d.existsSync()) continue;
      for (final e in d.listSync()) {
        final name = e.path.split(Platform.pathSeparator).last;
        if (e is Directory && name.startsWith('Python')) {
          found.add(_join([e.path, 'python.exe']));
        }
      }
    }
    return found.toSet().toList();
  }

  static List<String> _defaultCCandidates() {
    final found = <String>[];
    final sep = Platform.isWindows ? ';' : ':';
    for (final dir in (Platform.environment['PATH'] ?? '').split(sep)) {
      if (dir.trim().isEmpty) continue;
      found.add(_join([dir, 'gcc.exe']));
      found.add(_join([dir, 'clang.exe']));
    }
    found.addAll([
      'gcc.exe',
      'clang.exe',
      r'C:\MinGW\bin\gcc.exe',
      r'C:\msys64\mingw64\bin\gcc.exe',
      r'C:\msys64\ucrt64\bin\gcc.exe',
      r'C:\TDM-GCC-64\bin\gcc.exe',
    ]);
    return found.toSet().toList();
  }
}