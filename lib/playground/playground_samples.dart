import 'code_runner.dart';

class PlaygroundSample {
  const PlaygroundSample({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.code,
  });

  final String id;
  final String titleEn;
  final String titleAr;
  final String code;

  String title(bool arabic) => arabic ? titleAr : titleEn;
}

const Map<PlayLanguage, List<PlaygroundSample>> playgroundSamples = {
  PlayLanguage.c: [
    PlaygroundSample(
      id: 'c_hello',
      titleEn: 'Hello, world!',
      titleAr: 'مرحباً بالعالم!',
      code:
          '#include <stdio.h>\n'
          '\n'
          'int main(void) {\n'
          '    printf("Hello, DevTrek!\\n");\n'
          '    return 0;\n'
          '}\n',
    ),
    PlaygroundSample(
      id: 'c_loop',
      titleEn: 'Loop: sum 1..10',
      titleAr: 'حلقة: مجموع 1..10',
      code:
          '#include <stdio.h>\n'
          '\n'
          'int main(void) {\n'
          '    int sum = 0;\n'
          '    for (int i = 1; i <= 10; i++) {\n'
          '        sum += i;\n'
          '    }\n'
          '    printf("sum = %d\\n", sum);\n'
          '    return 0;\n'
          '}\n',
    ),
    PlaygroundSample(
      id: 'c_input',
      titleEn: 'Read input: square a number',
      titleAr: 'قراءة إدخال: مربع عدد',
      code:
          '#include <stdio.h>\n'
          '\n'
          'int main(void) {\n'
          '    int n = 0;\n'
          '    printf("Enter a number: ");\n'
          '    if (scanf("%d", &n) == 1) {\n'
          '        printf("%d * %d = %d\\n", n, n, n * n);\n'
          '    }\n'
          '    return 0;\n'
          '}\n',
    ),
    PlaygroundSample(
      id: 'c_fib',
      titleEn: 'Function: Fibonacci',
      titleAr: 'دالة: فيبوناتشي',
      code:
          '#include <stdio.h>\n'
          '\n'
          'int fib(int n) {\n'
          '    if (n < 2) return n;\n'
          '    return fib(n - 1) + fib(n - 2);\n'
          '}\n'
          '\n'
          'int main(void) {\n'
          '    for (int i = 0; i < 10; i++) {\n'
          '        printf("%d ", fib(i));\n'
          '    }\n'
          '    printf("\\n");\n'
          '    return 0;\n'
          '}\n',
    ),
  ],
  PlayLanguage.python: [
    PlaygroundSample(
      id: 'py_hello',
      titleEn: 'Hello, world!',
      titleAr: 'مرحباً بالعالم!',
      code: 'print("Hello, DevTrek!")\n',
    ),
    PlaygroundSample(
      id: 'py_loop',
      titleEn: 'Loop: sum 1..10',
      titleAr: 'حلقة: مجموع 1..10',
      code:
          'total = 0\n'
          'for i in range(1, 11):\n'
          '    total += i\n'
          'print("sum =", total)\n',
    ),
    PlaygroundSample(
      id: 'py_input',
      titleEn: 'Read input: square a number',
      titleAr: 'قراءة إدخال: مربع عدد',
      code:
          'n = int(input("Enter a number: "))\n'
          'print(f"{n} * {n} = {n * n}")\n',
    ),
    PlaygroundSample(
      id: 'py_fib',
      titleEn: 'Function: Fibonacci',
      titleAr: 'دالة: فيبوناتشي',
      code:
          'def fib(n):\n'
          '    if n < 2:\n'
          '        return n\n'
          '    return fib(n - 1) + fib(n - 2)\n'
          '\n'
          'print([fib(i) for i in range(10)])\n',
    ),
  ],
};
