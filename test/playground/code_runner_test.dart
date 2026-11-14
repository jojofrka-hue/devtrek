import 'package:coding_quest/playground/code_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detect with empty candidates finds nothing', () async {
    final runner = CodeRunner(pythonCandidates: [], cCandidates: []);
    await runner.detect();
    expect(runner.python, isNull);
    expect(runner.c, isNull);
  });

  test('empty source fails fast', () async {
    final runner = CodeRunner(pythonCandidates: [], cCandidates: []);
    final result = await runner.run(PlayLanguage.c, '   ');
    expect(result.failure, RunFailure.emptySource);
  });

  test('missing toolchain is reported, not crashed', () async {
    final runner = CodeRunner(pythonCandidates: [], cCandidates: []);
    final result = await runner.run(PlayLanguage.python, 'print(1)');
    expect(result.failure, RunFailure.missingToolchain);
  });

  test('C hello world compiles and runs when gcc exists', () async {
    final runner = CodeRunner();
    await runner.detect();
    if (runner.c == null) return;
    final result = await runner.run(
      PlayLanguage.c,
      '#include <stdio.h>\n'
      'int main(void) { printf("HELLO_C\\n"); return 0; }\n',
    );
    expect(result.failure, isNull);
    expect(result.timedOut, isFalse);
    expect(result.exitCode, 0);
    expect(result.stdout, contains('HELLO_C'));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('C stdin reaches the running program', () async {
    final runner = CodeRunner();
    await runner.detect();
    if (runner.c == null) return;
    final result = await runner.run(
      PlayLanguage.c,
      '#include <stdio.h>\n'
      'int main(void) { int n = 0; scanf("%d", &n); printf("%d\\n", n * n); return 0; }\n',
      input: '7\n',
    );
    expect(result.exitCode, 0);
    expect(result.stdout.trim(), '49');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('runaway C loop is killed by the time limit', () async {
    final runner = CodeRunner(runTimeout: const Duration(seconds: 1));
    await runner.detect();
    if (runner.c == null) return;
    final result = await runner.run(
      PlayLanguage.c,
      'int main(void) { for (;;) {} return 0; }\n',
    );
    expect(result.timedOut, isTrue);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('C compile errors surface compiler output', () async {
    final runner = CodeRunner();
    await runner.detect();
    if (runner.c == null) return;
    final result = await runner.run(
      PlayLanguage.c,
      'int main(void) { this_is_not_c; }\n',
    );
    expect(result.failure, RunFailure.compileFailed);
    expect(result.compileLog, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('Python runs when an interpreter exists', () async {
    final runner = CodeRunner();
    await runner.detect();
    if (runner.python == null) return;
    final result = await runner.run(PlayLanguage.python, 'print(40 + 2)\n');
    expect(result.failure, isNull);
    expect(result.exitCode, 0);
    expect(result.stdout.trim(), '42');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
