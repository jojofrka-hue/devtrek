enum TracePreset { arraySum, bubbleSort, linearSearch }

extension TracePresetLabel on TracePreset {
  String label(bool ar) => switch (this) {
    TracePreset.arraySum => ar ? 'مجموع المصفوفة / الحلقة' : 'Array Sum / Loop',
    TracePreset.bubbleSort =>
      ar ? 'الترتيب الفقاعي خطوة بخطوة' : 'Bubble Sort Step-by-Step',
    TracePreset.linearSearch => ar ? 'البحث الخطي' : 'Linear Search',
  };
}

class TraceFrame {
  TraceFrame({
    this.line,
    required Map<String, int?> variables,
    required List<int> array,
    Map<int, String> pointers = const {},
    Set<int> written = const {},
    required this.explanation,
    required this.explanationAr,
    this.complete = false,
  }) : variables = Map.unmodifiable(variables),
       array = List.unmodifiable(array),
       pointers = Map.unmodifiable(pointers),
       written = Set.unmodifiable(written);

  final int? line;
  final Map<String, int?> variables;
  final List<int> array;
  final Map<int, String> pointers;
  final Set<int> written;
  final String explanation;
  final String explanationAr;
  final bool complete;

  String note(bool ar) => ar ? explanationAr : explanation;
}

class AlgorithmTraceData {
  AlgorithmTraceData._(List<String> lines, List<TraceFrame> frames)
    : lines = List.unmodifiable(lines),
      frames = List.unmodifiable(frames);

  final List<String> lines;
  final List<TraceFrame> frames;

  static AlgorithmTraceData forPreset(TracePreset preset) => switch (preset) {
    TracePreset.arraySum => _arraySum(),
    TracePreset.bubbleSort => _bubbleSort(),
    TracePreset.linearSearch => _linearSearch(),
  };
}

class _TraceRecorder {
  _TraceRecorder(String source, List<String> names)
    : lines = source.split('\n'),
      variables = {for (final name in names) name: null} {
    frames.add(
      TraceFrame(
        variables: variables,
        array: array,
        explanation: 'Press Step to execute the first C statement. Values appear after initialization.',
        explanationAr: 'اضغط خطوة لتنفيذ أول تعليمة C. تظهر القيم بعد التهيئة.',
      ),
    );
  }

  final List<String> lines;
  final Map<String, int?> variables;
  final List<int> array = [];
  final List<TraceFrame> frames = [];

  void record(
    String statement,
    String en,
    String ar, {
    Map<int, String> pointers = const {},
    Set<int> written = const {},
    bool complete = false,
  }) {
    final line = lines.indexWhere((line) => line.trim() == statement);
    assert(line >= 0, 'Trace statement must exist in the displayed C source.');
    frames.add(
      TraceFrame(
        line: line + 1,
        variables: variables,
        array: array,
        pointers: pointers,
        written: written,
        explanation: en,
        explanationAr: ar,
        complete: complete,
      ),
    );
  }

  AlgorithmTraceData finish() => AlgorithmTraceData._(lines, frames);
}

AlgorithmTraceData _arraySum() {
  final r = _TraceRecorder(
    '''int main(void) {
  int a[] = {3, 1, 4, 1, 5};
  int n = 5;
  int sum = 0;
  int i = 0;
  while (i < n) {
    sum += a[i];
    i++;
  }
  return 0;
}''',
    ['n', 'i', 'sum'],
  );
  r.array.addAll([3, 1, 4, 1, 5]);
  r.record(
    'int a[] = {3, 1, 4, 1, 5};',
    'Initialize a with five integers. Array indices start at 0.',
    'تهيئة a بخمسة أعداد صحيحة. تبدأ فهارس المصفوفة من 0.',
  );
  r.variables['n'] = 5;
  r.record(
    'int n = 5;',
    'Set n = 5, the number of array elements.',
    'تعيين n = 5، وهو عدد عناصر المصفوفة.',
  );
  r.variables['sum'] = 0;
  r.record(
    'int sum = 0;',
    'Initialize the accumulator: sum = 0.',
    'تهيئة متغير المجموع: sum = 0.',
  );
  r.variables['i'] = 0;
  r.record(
    'int i = 0;',
    'Start at the first element: i = 0.',
    'البدء بالعنصر الأول: i = 0.',
  );
  while (true) {
    final i = r.variables['i']!;
    final inside = i < r.array.length;
    r.record(
      'while (i < n) {',
      'Check $i < 5: ${inside ? 'true; enter the loop' : 'false; leave the loop'}.',
      'فحص $i < 5: ${inside ? 'صحيح؛ دخول الحلقة' : 'خطأ؛ الخروج من الحلقة'}.',
    );
    if (!inside) break;
    final before = r.variables['sum']!;
    r.variables['sum'] = before + r.array[i];
    r.record(
      'sum += a[i];',
      'Read a[$i] = ${r.array[i]}. sum = $before + ${r.array[i]} = ${r.variables['sum']}.',
      'قراءة a[$i] = ${r.array[i]}. المجموع = $before + ${r.array[i]} = ${r.variables['sum']}.',
      pointers: {i: 'i'},
    );
    r.variables['i'] = i + 1;
    r.record(
      'i++;',
      'Increment i: $i → ${i + 1}.',
      'زيادة i: من $i إلى ${i + 1}.',
    );
  }
  r.record(
    'return 0;',
    'Finished. The sum is ${r.variables['sum']}; main returns 0.',
    'اكتمل التنفيذ. المجموع ${r.variables['sum']}؛ تعيد main القيمة 0.',
    complete: true,
  );
  return r.finish();
}

AlgorithmTraceData _bubbleSort() {
  final r = _TraceRecorder(
    '''int main(void) {
  int a[] = {5, 1, 4, 2, 8};
  int n = 5;
  int i = 0;
  int j = 0;
  int temp = 0;
  while (i < n - 1) {
    j = 0;
    while (j < n - i - 1) {
      if (a[j] > a[j + 1]) {
        temp = a[j];
        a[j] = a[j + 1];
        a[j + 1] = temp;
      }
      j++;
    }
    i++;
  }
  return 0;
}''',
    ['n', 'i', 'j', 'temp'],
  );
  r.array.addAll([5, 1, 4, 2, 8]);
  r.record(
    'int a[] = {5, 1, 4, 2, 8};',
    'Initialize the unsorted array a.',
    'تهيئة المصفوفة a غير المرتبة.',
  );
  r.variables['n'] = 5;
  r.record(
    'int n = 5;',
    'Set n = 5, the array length.',
    'تعيين n = 5، طول المصفوفة.',
  );
  r.variables['i'] = 0;
  r.record(
    'int i = 0;',
    'Initialize the pass counter: i = 0.',
    'تهيئة عداد المرور: i = 0.',
  );
  r.variables['j'] = 0;
  r.record(
    'int j = 0;',
    'Initialize the comparison index: j = 0.',
    'تهيئة فهرس المقارنة: j = 0.',
  );
  r.variables['temp'] = 0;
  r.record(
    'int temp = 0;',
    'Initialize temporary storage: temp = 0.',
    'تهيئة التخزين المؤقت: temp = 0.',
  );
  while (true) {
    final i = r.variables['i']!;
    final inside = i < r.array.length - 1;
    r.record(
      'while (i < n - 1) {',
      'Check $i < 4: ${inside ? 'true; start pass ${i + 1}' : 'false; sorting is complete'}.',
      'فحص $i < 4: ${inside ? 'صحيح؛ بدء المرور ${i + 1}' : 'خطأ؛ اكتمل الترتيب'}.',
    );
    if (!inside) break;
    r.variables['j'] = 0;
    r.record(
      'j = 0;',
      'Reset j = 0 for this pass.',
      'إعادة j إلى 0 لهذا المرور.',
    );
    while (true) {
      final j = r.variables['j']!;
      final limit = r.array.length - i - 1;
      final inside = j < limit;
      r.record(
        'while (j < n - i - 1) {',
        'Check $j < $limit: ${inside ? 'true; compare the next pair' : 'false; this pass ends'}.',
        'فحص $j < $limit: ${inside ? 'صحيح؛ مقارنة الزوج التالي' : 'خطأ؛ انتهى هذا المرور'}.',
      );
      if (!inside) break;
      final swap = r.array[j] > r.array[j + 1];
      final pair = {j: 'j', j + 1: 'j + 1'};
      r.record(
        'if (a[j] > a[j + 1]) {',
        'Compare a[$j] = ${r.array[j]} with a[${j + 1}] = ${r.array[j + 1]}: ${swap ? 'out of order; swap' : 'already ordered; skip the swap'}.',
        'مقارنة a[$j] = ${r.array[j]} مع a[${j + 1}] = ${r.array[j + 1]}: ${swap ? 'ترتيب خاطئ؛ تبديل' : 'مرتبتان؛ لا تبديل'}.',
        pointers: pair,
      );
      if (swap) {
        r.variables['temp'] = r.array[j];
        r.record(
          'temp = a[j];',
          'Save a[$j] = ${r.array[j]} in temp before overwriting it.',
          'حفظ a[$j] = ${r.array[j]} في temp قبل استبدالها.',
          pointers: {j: 'j'},
        );
        r.array[j] = r.array[j + 1];
        r.record(
          'a[j] = a[j + 1];',
          'Copy a[${j + 1}] into a[$j]. temp still holds ${r.variables['temp']}.',
          'نسخ a[${j + 1}] إلى a[$j]. تحتفظ temp بالقيمة ${r.variables['temp']}.',
          pointers: pair,
          written: {j},
        );
        r.array[j + 1] = r.variables['temp']!;
        r.record(
          'a[j + 1] = temp;',
          'Write temp = ${r.variables['temp']} into a[${j + 1}]. The swap is complete.',
          'كتابة temp = ${r.variables['temp']} في a[${j + 1}]. اكتمل التبديل.',
          pointers: pair,
          written: {j + 1},
        );
      }
      r.variables['j'] = j + 1;
      r.record(
        'j++;',
        'Advance the comparison index: j = ${j + 1}.',
        'تقديم فهرس المقارنة: j = ${j + 1}.',
      );
    }
    r.variables['i'] = i + 1;
    r.record(
      'i++;',
      'Pass ${i + 1} ends. The last ${i + 1} element(s) are in their final positions.',
      'انتهى المرور ${i + 1}. آخر ${i + 1} من العناصر في مواقعها النهائية.',
    );
  }
  r.record(
    'return 0;',
    'Finished. a = [${r.array.join(', ')}]; main returns 0.',
    'اكتمل التنفيذ. a = [${r.array.join(', ')}]؛ تعيد main القيمة 0.',
    complete: true,
  );
  return r.finish();
}

AlgorithmTraceData _linearSearch() {
  final r = _TraceRecorder(
    '''int main(void) {
  int a[] = {12, 7, 19, 4, 11};
  int n = 5;
  int target = 19;
  int result = -1;
  int i = 0;
  while (i < n) {
    if (a[i] == target) {
      result = i;
      break;
    }
    i++;
  }
  return 0;
}''',
    ['n', 'i', 'target', 'result'],
  );
  r.array.addAll([12, 7, 19, 4, 11]);
  r.record(
    'int a[] = {12, 7, 19, 4, 11};',
    'Initialize the array to search.',
    'تهيئة المصفوفة المراد البحث فيها.',
  );
  r.variables['n'] = 5;
  r.record(
    'int n = 5;',
    'Set n = 5, the array length.',
    'تعيين n = 5، طول المصفوفة.',
  );
  r.variables['target'] = 19;
  r.record(
    'int target = 19;',
    'Search for the value target = 19.',
    'البحث عن القيمة target = 19.',
  );
  r.variables['result'] = -1;
  r.record(
    'int result = -1;',
    'Set result = -1: no match has been found yet.',
    'تعيين result = -1: لم يُعثر على تطابق بعد.',
  );
  r.variables['i'] = 0;
  r.record(
    'int i = 0;',
    'Begin searching at index i = 0.',
    'بدء البحث من الفهرس i = 0.',
  );
  while (true) {
    final i = r.variables['i']!;
    final inside = i < r.array.length;
    r.record(
      'while (i < n) {',
      'Check $i < 5: ${inside ? 'true; examine this element' : 'false; no match exists'}.',
      'فحص $i < 5: ${inside ? 'صحيح؛ فحص هذا العنصر' : 'خطأ؛ لا يوجد تطابق'}.',
    );
    if (!inside) break;
    final found = r.array[i] == r.variables['target'];
    r.record(
      'if (a[i] == target) {',
      'Compare a[$i] = ${r.array[i]} with target = 19: ${found ? 'a match' : 'not equal'}.',
      'مقارنة a[$i] = ${r.array[i]} مع target = 19: ${found ? 'تطابق' : 'غير متساويين'}.',
      pointers: {i: 'i'},
    );
    if (found) {
      r.variables['result'] = i;
      r.record(
        'result = i;',
        'Store the matching index: result = $i (element ${i + 1}).',
        'حفظ فهرس التطابق: result = $i (العنصر رقم ${i + 1}).',
        pointers: {i: 'i'},
      );
      r.record(
        'break;',
        'Leave the loop immediately; later elements are not checked.',
        'الخروج من الحلقة فوراً؛ لا تُفحص العناصر التالية.',
        pointers: {i: 'i'},
      );
      break;
    }
    r.variables['i'] = i + 1;
    r.record(
      'i++;',
      'No match. Move to index i = ${i + 1}.',
      'لا تطابق. الانتقال إلى الفهرس i = ${i + 1}.',
    );
  }
  r.record(
    'return 0;',
    'Finished. target = 19 was found at index ${r.variables['result']}; main returns 0.',
    'اكتمل التنفيذ. وُجد target = 19 عند الفهرس ${r.variables['result']}؛ تعيد main القيمة 0.',
    complete: true,
  );
  return r.finish();
}
