import 'package:flutter/material.dart';

class MachineSection {
  const MachineSection({
    required this.headingEn,
    required this.headingAr,
    required this.bodyEn,
    required this.bodyAr,
    this.code,
  });

  final String headingEn;
  final String headingAr;
  final String bodyEn;
  final String bodyAr;
  final String? code;

  String heading(bool arabic) => arabic ? headingAr : headingEn;
  String body(bool arabic) => arabic ? bodyAr : bodyEn;
}

class MachineTerm {
  const MachineTerm({
    required this.termEn,
    required this.termAr,
    required this.defEn,
    required this.defAr,
  });

  final String termEn;
  final String termAr;
  final String defEn;
  final String defAr;

  String term(bool arabic) => arabic ? termAr : termEn;
  String definition(bool arabic) => arabic ? defAr : defEn;
}

class MachineQuiz {
  const MachineQuiz({
    required this.questionEn,
    required this.questionAr,
    required this.optionsEn,
    required this.optionsAr,
    required this.correctIndex,
    required this.explanationEn,
    required this.explanationAr,
  });

  final String questionEn;
  final String questionAr;
  final List<String> optionsEn;
  final List<String> optionsAr;
  final int correctIndex;
  final String explanationEn;
  final String explanationAr;

  String question(bool arabic) => arabic ? questionAr : questionEn;
  List<String> options(bool arabic) => arabic ? optionsAr : optionsEn;
  String explanation(bool arabic) => arabic ? explanationAr : explanationEn;
}

class MachineLesson {
  const MachineLesson({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.summaryEn,
    required this.summaryAr,
    required this.icon,
    required this.sections,
    required this.terms,
    required this.quiz,
  });

  final String id;
  final String titleEn;
  final String titleAr;
  final String summaryEn;
  final String summaryAr;
  final IconData icon;
  final List<MachineSection> sections;
  final List<MachineTerm> terms;
  final List<MachineQuiz> quiz;

  String title(bool arabic) => arabic ? titleAr : titleEn;
  String summary(bool arabic) => arabic ? summaryAr : summaryEn;
}

const List<MachineLesson> machineLessons = [
  MachineLesson(
    id: 'von_neumann',
    titleEn: 'Von Neumann architecture',
    titleAr: 'معمارية فون نيومان',
    summaryEn:
        'The stored-program idea: one memory holds both data and instructions.',
    summaryAr:
        'فكرة البرنامج المخزن: ذاكرة واحدة تحمل البيانات والتعليمات معاً.',
    icon: Icons.account_tree_rounded,
    sections: [
      MachineSection(
        headingEn: 'One memory for everything',
        headingAr: 'ذاكرة واحدة لكل شيء',
        bodyEn:
            'In the von Neumann model the program is not wired into the machine: '
            'instructions live in the same memory as data, as binary numbers. The '
            'CPU reads them one by one and obeys them. Changing the program means '
            'changing memory contents, not rebuilding hardware.',
        bodyAr:
            'في نموذج فون نيومان ليس البرنامج أسلاكاً داخل الآلة: التعليمات تسكن في '
            'الذاكرة نفسها التي تسكن فيها البيانات، كأرقام ثنائية. يقرأها المعالج '
            'واحدة تلو الأخرى وينفذها. تغيير البرنامج يعني تغيير محتوى الذاكرة، '
            'لا إعادة بناء العتاد.',
      ),
      MachineSection(
        headingEn: 'The four blocks',
        headingAr: 'الكتل الأربع',
        bodyEn:
            'Every von Neumann machine has: memory (stores data and instructions), '
            'the CPU (ALU + control unit + registers), input/output devices, and '
            'buses that connect them all. Sharing one bus for data and instructions '
            'creates the so-called von Neumann bottleneck.',
        bodyAr:
            'كل آلة فون نيومان تضم: الذاكرة (تخزن البيانات والتعليمات)، والمعالج '
            '(وحدة الحساب والمنطق + وحدة التحكم + المسجلات)، وأجهزة الإدخال '
            'والإخراج، والناقلات التي تربطها جميعاً. ومشاركة ناقل واحد للبيانات '
            'والتعليمات تخلق ما يسمى عنق فون نيومان.',
      ),
      MachineSection(
        headingEn: 'Why it matters to you',
        headingAr: 'لماذا يهمك هذا',
        bodyEn:
            'When your C program crashes with a bad pointer, or your Python list '
            'grows slowly, you are feeling this architecture: code and data share '
            'one address space, and memory is finite and addressed by number.',
        bodyAr:
            'حين ينهار برنامج C بسبب مؤشر خاطئ، أو تتباطأ قائمة Python وهي تكبر، '
            'فأنت تشعر بهذه المعمارية: الكود والبيانات يتشاركان فضاء عنونة واحداً، '
            'والذاكرة محدودة ومعنونة بالأرقام.',
      ),
    ],
    terms: [
      MachineTerm(
        termEn: 'Stored program',
        termAr: 'البرنامج المخزن',
        defEn:
            'Instructions kept in memory as data, loaded and changed freely.',
        defAr: 'تعليمات محفوظة في الذاكرة كبيانات، تُحمّل وتُغيّر بحرية.',
      ),
      MachineTerm(
        termEn: 'Bus',
        termAr: 'الناقل',
        defEn: 'Shared wires carrying address, data or control signals.',
        defAr: 'أسلاك مشتركة تحمل إشارات العنوان أو البيانات أو التحكم.',
      ),
      MachineTerm(
        termEn: 'Address',
        termAr: 'العنوان',
        defEn: 'The number identifying one byte (or word) in memory.',
        defAr: 'الرقم الذي يعرّف بايتاً (أو كلمة) في الذاكرة.',
      ),
      MachineTerm(
        termEn: 'Von Neumann bottleneck',
        termAr: 'عنق فون نيومان',
        defEn: 'Speed limit from sharing one path for instructions and data.',
        defAr: 'حد سرعة ناتج عن مشاركة مسار واحد للتعليمات والبيانات.',
      ),
    ],
    quiz: [
      MachineQuiz(
        questionEn: 'Where do instructions live in a von Neumann machine?',
        questionAr: 'أين تسكن التعليمات في آلة فون نيومان؟',
        optionsEn: [
          'In the same memory as data',
          'In a separate instruction-only memory',
          'Inside the power supply',
        ],
        optionsAr: [
          'في الذاكرة نفسها مع البيانات',
          'في ذاكرة منفصلة للتعليمات فقط',
          'داخل مزود الطاقة',
        ],
        correctIndex: 0,
        explanationEn: 'The stored-program idea puts code and data in one addressable memory.',
        explanationAr:
            'فكرة البرنامج المخزن تضع الكود والبيانات في ذاكرة واحدة معنونة.',
      ),
      MachineQuiz(
        questionEn: 'The von Neumann bottleneck is...',
        questionAr: 'عنق فون نيومان هو...',
        optionsEn: [
          'Sharing one bus for instructions and data',
          'A slow hard disk',
          'Too many CPU cores',
        ],
        optionsAr: [
          'مشاركة ناقل واحد للتعليمات والبيانات',
          'قرص صلب بطيء',
          'عدد أنوية معالج كبير جداً',
        ],
        correctIndex: 0,
        explanationEn:
            'One shared path means instruction fetch and data access compete.',
        explanationAr: 'المسار المشترك الواحد يجعل جلب التعليمات والوصول للبيانات يتنافسان.',
      ),
    ],
  ),
  MachineLesson(
    id: 'cpu_inside',
    titleEn: 'Inside the CPU',
    titleAr: 'داخل المعالج',
    summaryEn:
        'ALU, control unit and registers: the three teams inside every core.',
    summaryAr: 'وحدة الحساب والمنطق ووحدة التحكم والمسجلات: الفرق الثلاث داخل كل نواة.',
    icon: Icons.memory_rounded,
    sections: [
      MachineSection(
        headingEn: 'The ALU: doing the math',
        headingAr: 'وحدة الحساب والمنطق: إجراء الحساب',
        bodyEn:
            'The arithmetic-logic unit adds, subtracts, compares and performs '
            'AND/OR/shift operations. After each operation it raises flags (zero, '
            'carry, sign) that tell the control unit what happened, so conditions '
            'like if (x == 0) become flag checks.',
        bodyAr:
            'وحدة الحساب والمنطق تجمع وتطرح وتقارن وتنفذ عمليات AND/OR والإزاحة. '
            'وبعد كل عملية ترفع أعلاماً (صفر، حمل، إشارة) تخبر وحدة التحكم بما حدث، '
            'فتتحول شروط مثل if (x == 0) إلى فحوصات أعلام.',
      ),
      MachineSection(
        headingEn: 'The control unit: the conductor',
        headingAr: 'وحدة التحكم: المايسترو',
        bodyEn:
            'The control unit fetches each instruction, decodes it, and opens or '
            'closes the right paths between registers, ALU and memory at the right '
            'clock tick. It does not compute; it coordinates.',
        bodyAr:
            'وحدة التحكم تجلب كل تعليمة وتفك تشفيرها، ثم تفتح أو تغلق المسارات '
            'الصحيحة بين المسجلات ووحدة الحساب والمنطق والذاكرة في نبضة الساعة '
            'المناسبة. هي لا تحسب؛ هي تنسّق.',
      ),
      MachineSection(
        headingEn: "Registers: the CPU's pockets",
        headingAr: 'المسجلات: جيوب المعالج',
        bodyEn:
            'Registers are tiny, fastest storage inside the core: the program '
            'counter (PC) holds the next instruction address, the instruction '
            'register (IR) holds the current one, and general registers hold '
            'operands. Register access takes about one cycle; RAM takes hundreds.',
        bodyAr:
            'المسجلات تخزين صغير وأسرع ما يكون داخل النواة: عداد البرنامج (PC) يحمل '
            'عنوان التعليمة التالية، ومسجل التعليمة (IR) يحمل الحالية، والمسجلات '
            'العامة تحمل المعاملات. الوصول للمسجل يستغرق دورة واحدة تقريباً، '
            'بينما تستغرق RAM مئات الدورات.',
      ),
    ],
    terms: [
      MachineTerm(
        termEn: 'ALU',
        termAr: 'وحدة الحساب والمنطق',
        defEn: 'The circuit that computes and compares.',
        defAr: 'الدائرة التي تحسب وتقارن.',
      ),
      MachineTerm(
        termEn: 'Control unit',
        termAr: 'وحدة التحكم',
        defEn: 'Decodes instructions and steers data paths.',
        defAr: 'تفك تشفير التعليمات وتوجّه مسارات البيانات.',
      ),
      MachineTerm(
        termEn: 'Register',
        termAr: 'مسجل',
        defEn: 'A few bytes of ultra-fast storage inside the CPU.',
        defAr: 'بايتات قليلة من تخزين فائق السرعة داخل المعالج.',
      ),
      MachineTerm(
        termEn: 'Program counter',
        termAr: 'عداد البرنامج',
        defEn: 'Register holding the address of the next instruction.',
        defAr: 'مسجل يحمل عنوان التعليمة التالية.',
      ),
    ],
    quiz: [
      MachineQuiz(
        questionEn: 'Which part performs addition and comparisons?',
        questionAr: 'أي جزء ينفذ الجمع والمقارنات؟',
        optionsEn: ['The ALU', 'The control unit', 'RAM'],
        optionsAr: ['وحدة الحساب والمنطق', 'وحدة التحكم', 'RAM'],
        correctIndex: 0,
        explanationEn: 'Computing and comparing is exactly the ALU job.',
        explanationAr: 'الحساب والمقارنة هما وظيفة وحدة الحساب والمنطق بالضبط.',
      ),
      MachineQuiz(
        questionEn: 'The program counter (PC) holds...',
        questionAr: 'عداد البرنامج (PC) يحمل...',
        optionsEn: [
          'The address of the next instruction',
          'The last computed result',
          'The clock frequency',
        ],
        optionsAr: [
          'عنوان التعليمة التالية',
          'آخر نتيجة محسوبة',
          'تردد الساعة',
        ],
        correctIndex: 0,
        explanationEn: 'PC points forward so fetch knows where to read next.',
        explanationAr: 'يشير PC للأمام ليعرف الجلب من أين يقرأ تالياً.',
      ),
    ],
  ),
  MachineLesson(
    id: 'instruction_cycle',
    titleEn: 'Fetch–decode–execute',
    titleAr: 'جلب–فك–تنفيذ',
    summaryEn: 'The heartbeat of the CPU: every program is this loop, billions of times per second.',
    summaryAr:
        'نبض المعالج: كل برنامج هو هذه الحلقة، مليارات المرات في الثانية.',
    icon: Icons.loop_rounded,
    sections: [
      MachineSection(
        headingEn: 'The three steps',
        headingAr: 'الخطوات الثلاث',
        bodyEn:
            'Fetch: copy the instruction at address PC from memory into IR, then '
            'advance PC. Decode: the control unit reads the opcode and operands. '
            'Execute: the ALU, registers or memory perform the action. Then the '
            'loop repeats forever until halt.',
        bodyAr:
            'الجلب: انسخ التعليمة عند العنوان PC من الذاكرة إلى IR ثم قدّم PC. '
            'فك التشفير: تقرأ وحدة التحكم رمز العملية ومعاملاتها. التنفيذ: تنفذ '
            'وحدة الحساب والمنطق أو المسجلات أو الذاكرة الإجراء. ثم تتكرر الحلقة '
            'إلى ما لا نهاية حتى التوقف.',
      ),
      MachineSection(
        headingEn: 'A tiny program, step by step',
        headingAr: 'برنامج صغير خطوة بخطوة',
        bodyEn:
            'Three instructions, three simplified cycles. Notice address 100 is '
            'read and written as data while the instructions themselves also come '
            'from memory: one address space for both.',
        bodyAr:
            'ثلاث تعليمات، ثلاث دورات مبسطة. لاحظ أن العنوان 100 يُقرأ ويُكتب '
            'كبيانات، بينما التعليمات نفسها تأتي من الذاكرة أيضاً: فضاء عنونة '
            'واحد للاثنين.',
        code:
            'LOAD R1, [100]   ; R1 <- memory[100]\n'
            'ADD  R1, 1       ; R1 <- R1 + 1\n'
            'STORE [100], R1  ; memory[100] <- R1',
      ),
      MachineSection(
        headingEn: 'Clock, cycles and GHz',
        headingAr: 'الساعة والدورات والتردد',
        bodyEn:
            'A clock tick drives each micro-step; a 3 GHz clock ticks 3 billion '
            'times per second. Modern CPUs pipeline several instructions and run '
            'more than one per cycle, but fetch–decode–execute remains the '
            'foundation underneath.',
        bodyAr:
            'نبضة الساعة تقود كل خطوة دقيقة؛ ساعة 3 GHz تنبض 3 مليارات مرة في '
            'الثانية. المعالجات الحديثة تمرّر عدة تعليمات في خط أنابيب وتنفذ أكثر '
            'من واحدة في الدورة، لكن جلب–فك–تنفيذ يبقى الأساس تحت ذلك.',
      ),
    ],
    terms: [
      MachineTerm(
        termEn: 'Fetch',
        termAr: 'الجلب',
        defEn: 'Reading the next instruction from memory into IR.',
        defAr: 'قراءة التعليمة التالية من الذاكرة إلى IR.',
      ),
      MachineTerm(
        termEn: 'Decode',
        termAr: 'فك التشفير',
        defEn: 'Figuring out which operation and operands the bits mean.',
        defAr: 'معرفة العملية والمعاملات التي تعنيها البتات.',
      ),
      MachineTerm(
        termEn: 'Execute',
        termAr: 'التنفيذ',
        defEn: 'Performing the operation and writing results back.',
        defAr: 'إجراء العملية وكتابة النتائج обратно.',
      ),
      MachineTerm(
        termEn: 'Pipeline',
        termAr: 'خط الأنابيب',
        defEn: 'Overlapping stages of several instructions at once.',
        defAr: 'تراكب مراحل عدة تعليمات في الوقت نفسه.',
      ),
    ],
    quiz: [
      MachineQuiz(
        questionEn: 'During FETCH the CPU...',
        questionAr: 'أثناء الجلب يقوم المعالج بـ...',
        optionsEn: [
          'Copying the instruction at PC into IR',
          'Adding two numbers',
          'Writing to disk',
        ],
        optionsAr: [
          'نسخ التعليمة عند PC إلى IR',
          'جمع عددين',
          'الكتابة على القرص',
        ],
        correctIndex: 0,
        explanationEn: 'Fetch is a memory read into the instruction register.',
        explanationAr: 'الجلب قراءة من الذاكرة إلى مسجل التعليمة.',
      ),
      MachineQuiz(
        questionEn: 'After fetching, the PC usually...',
        questionAr: 'بعد الجلب، عادةً ما يكون PC...',
        optionsEn: [
          'Pointing to the next instruction',
          'Reset to zero',
          'Stopped',
        ],
        optionsAr: ['مشيراً إلى التعليمة التالية', 'مصفّراً', 'متوقفاً'],
        correctIndex: 0,
        explanationEn: 'Advancing PC keeps the loop moving forward.',
        explanationAr: 'تقديم PC يبقي الحلقة تتحرك للأمام.',
      ),
    ],
  ),
  MachineLesson(
    id: 'memory_hierarchy',
    titleEn: 'The memory hierarchy',
    titleAr: 'هرمية الذاكرة',
    summaryEn:
        'Registers, cache, RAM, storage: faster means smaller and dearer.',
    summaryAr: 'مسجلات ومخبأ وRAM وتخزين: الأسرع أصغر وأغلى.',
    icon: Icons.layers_rounded,
    sections: [
      MachineSection(
        headingEn: 'Why layers?',
        headingAr: 'لماذا طبقات؟',
        bodyEn:
            'Fast memory is expensive per byte, so machines keep a little very '
            'fast memory close to the CPU and a lot of slow memory farther away. '
            'Locality — recently used things get used again — makes the trick '
            'work: most accesses hit the fast layers.',
        bodyAr:
            'الذاكرة السريعة غالية لكل بايت، لذا تحتفظ الآلات بقليل من الذاكرة '
            'فائقة السرعة قرب المعالج وكثير من الذاكرة البطيئة أبعد منه. '
            'والمحلية — ما استُخدم حديثاً يُستخدم مجدداً — تجعل الحيلة تنجح: '
            'معظم الوصولات تصيب الطبقات السريعة.',
      ),
      MachineSection(
        headingEn: 'The layers, top to bottom',
        headingAr: 'الطبقات من الأعلى للأسفل',
        bodyEn:
            'Registers (bytes, under 1 ns), L1/L2/L3 cache (KB to MB, a few ns), '
            'RAM (GB, around 100 ns, volatile), then SSD/HDD (TB, microseconds to '
            'milliseconds, persistent). Volatile means content disappears when '
            'power is off.',
        bodyAr:
            'مسجلات (بايتات، أقل من 1 نانوثانية)، مخبأ L1/L2/L3 (كيلوبايتات إلى '
            'ميغابايتات، نانوثوانٍ قليلة)، RAM (غيغابايتات، نحو 100 نانوثانية، '
            'متطايرة)، ثم SSD/HDD (تيرابايتات، ميكروثوانٍ إلى مليثوانٍ، دائمة). '
            'ومتطايرة تعني أن المحتوى يختفي عند انقطاع الطاقة.',
      ),
      MachineSection(
        headingEn: 'Feel it in code',
        headingAr: 'اشعر به في الكود',
        bodyEn:
            'Sequential access rides cache lines; jumping with a stride misses '
            'more. Same operation count, different real speed — this is why '
            'loop order matters in C and Python alike.',
        bodyAr:
            'الوصول المتسلسل يركب أسطر المخبأ؛ والقفز بخطوة ثابتة يخطئ أكثر. '
            'عدد العمليات نفسه لكن السرعة الفعلية مختلفة — لهذا يهم ترتيب '
            'الحلقات في C وPython معاً.',
        code:
            'int a[1000000];\n'
            'for (int i = 0; i < 1000000; i++) a[i] = i;       // sequential\n'
            'for (int i = 0; i < 1000000; i += 64) a[i] *= 2;  // strided',
      ),
    ],
    terms: [
      MachineTerm(
        termEn: 'Cache',
        termAr: 'الذاكرة المخبئية',
        defEn: 'Small fast memory keeping recently used data near the CPU.',
        defAr: 'ذاكرة صغيرة سريعة تبقي البيانات المستخدمة حديثاً قرب المعالج.',
      ),
      MachineTerm(
        termEn: 'RAM',
        termAr: 'ذاكرة الوصول العشوائي',
        defEn: 'Main working memory; volatile and byte-addressable.',
        defAr: 'ذاكرة العمل الرئيسية؛ متطايرة ومعنونة بالبايت.',
      ),
      MachineTerm(
        termEn: 'Volatile',
        termAr: 'متطايرة',
        defEn: 'Loses content when power is removed.',
        defAr: 'تفقد محتواها عند زوال الطاقة.',
      ),
      MachineTerm(
        termEn: 'Locality',
        termAr: 'المحلية',
        defEn: 'The tendency to reuse nearby or recent data.',
        defAr: 'ميل البرنامج لإعادة استخدام بيانات قريبة أو حديثة.',
      ),
    ],
    quiz: [
      MachineQuiz(
        questionEn: 'Which is fastest?',
        questionAr: 'أيها الأسرع؟',
        optionsEn: ['Registers', 'RAM', 'SSD'],
        optionsAr: ['المسجلات', 'RAM', 'SSD'],
        correctIndex: 0,
        explanationEn: 'Registers sit inside the core: about one cycle.',
        explanationAr: 'المسجلات داخل النواة نفسها: نحو دورة واحدة.',
      ),
      MachineQuiz(
        questionEn: 'Which loses its data when power is off?',
        questionAr: 'أيها يفقد بياناته عند انقطاع الطاقة؟',
        optionsEn: ['RAM', 'SSD', 'HDD'],
        optionsAr: ['RAM', 'SSD', 'HDD'],
        correctIndex: 0,
        explanationEn: 'RAM is volatile; disks keep data without power.',
        explanationAr: 'RAM متطايرة؛ والأقراص تحتفظ بالبيانات بلا طاقة.',
      ),
    ],
  ),
  MachineLesson(
    id: 'data_representation',
    titleEn: 'Bits, bytes & numbers',
    titleAr: 'بتات وبايتات وأرقام',
    summaryEn: 'Everything is binary: integers, text, images and your code.',
    summaryAr: 'كل شيء ثنائي: الأعداد والنصوص والصور وشيفرتك.',
    icon: Icons.tag_rounded,
    sections: [
      MachineSection(
        headingEn: 'Bits and bytes',
        headingAr: 'بتات وبايتات',
        bodyEn:
            'A bit is one 0/1 switch; 8 bits make a byte. n bits can represent '
            '2^n values. The number 13 is 1101 in binary because 8 + 4 + 1 = 13. '
            'Every value your program touches is ultimately such a pattern.',
        bodyAr:
            'البت مفتاح واحد 0/1؛ و8 بتات تصنع بايتاً. n بتاً تمثل 2^n قيمة. '
            'والعدد 13 هو 1101 ثنائياً لأن 8 + 4 + 1 = 13. كل قيمة يلمسها '
            'برنامجك هي في النهاية مثل هذا النمط.',
      ),
      MachineSection(
        headingEn: "Negative numbers: two's complement",
        headingAr: 'الأعداد السالبة: متمم الاثنين',
        bodyEn:
            'To negate: flip all bits and add one. In 4 bits, -3 is 1101. The '
            'beauty: the same addition circuit works for signed and unsigned '
            'numbers, which is why virtually all CPUs use this encoding.',
        bodyAr:
            'للنفي: اقلب كل البتات وأضف واحداً. في 4 بتات، -3 هو 1101. '
            'والجمال: دائرة الجمع نفسها تعمل للأعداد الموقعة وغير الموقعة، '
            'ولهذا تستخدم كل المعالجات تقريباً هذا الترميز.',
      ),
      MachineSection(
        headingEn: 'Text is numbers too',
        headingAr: 'النص أرقام أيضاً',
        bodyEn:
            "ASCII maps 'A' to 65; Unicode maps Arabic letters to larger numbers; "
            'UTF-8 encodes them into 1 to 4 bytes. Your source file is just bytes '
            'until a compiler or interpreter reads it.',
        bodyAr:
            'ASCII يعيّن \'A\' إلى 65؛ ويونيكود يعيّن الحروف العربية إلى أرقام '
            'أكبر؛ وUTF-8 يرمزها في 1 إلى 4 بايتات. ملف شيفرتك مجرد بايتات '
            'حتى يقرأه مترجم أو مفسر.',
        code:
            'printf("%d\\n", \'A\');    // 65\n'
            'printf("%d\\n", 0b1101);  // 13',
      ),
    ],
    terms: [
      MachineTerm(
        termEn: 'Bit',
        termAr: 'بت',
        defEn: 'One binary digit: 0 or 1.',
        defAr: 'رقم ثنائي واحد: 0 أو 1.',
      ),
      MachineTerm(
        termEn: 'Byte',
        termAr: 'بايت',
        defEn: '8 bits; the usual addressable memory unit.',
        defAr: '8 بتات؛ وحدة الذاكرة المعتادة للعنونة.',
      ),
      MachineTerm(
        termEn: "Two's complement",
        termAr: 'متمم الاثنين',
        defEn: 'Signed encoding: flip bits and add one to negate.',
        defAr: 'ترميز موقع: اقلب البتات وأضف واحداً للنفي.',
      ),
      MachineTerm(
        termEn: 'Encoding',
        termAr: 'ترميز',
        defEn: 'Agreed mapping from symbols to byte patterns.',
        defAr: 'اتفاق يعيّن الرموز إلى أنماط بايتات.',
      ),
    ],
    quiz: [
      MachineQuiz(
        questionEn: '13 in binary is...',
        questionAr: '13 ثنائياً هو...',
        optionsEn: ['1101', '1011', '1110'],
        optionsAr: ['1101', '1011', '1110'],
        correctIndex: 0,
        explanationEn: '8 + 4 + 1 = 13, so bits 8, 4 and 1 are set.',
        explanationAr: '8 + 4 + 1 = 13، لذا بتات 8 و4 و1 مرفوعة.',
      ),
      MachineQuiz(
        questionEn: 'How many values can 8 bits hold?',
        questionAr: 'كم قيمة تحمل 8 بتات؟',
        optionsEn: ['256', '8', '128'],
        optionsAr: ['256', '8', '128'],
        correctIndex: 0,
        explanationEn: '2^8 = 256 distinct patterns.',
        explanationAr: '2^8 = 256 نمطاً مختلفاً.',
      ),
    ],
  ),
  MachineLesson(
    id: 'buses_io',
    titleEn: 'Buses & input/output',
    titleAr: 'الناقلات والإدخال والإخراج',
    summaryEn: 'Data, address and control buses; how devices talk to the CPU.',
    summaryAr: 'ناقلات البيانات والعنوان والتحكم؛ وكيف تحادث الأجهزة المعالج.',
    icon: Icons.swap_horiz_rounded,
    sections: [
      MachineSection(
        headingEn: 'Three buses, three jobs',
        headingAr: 'ثلاثة ناقلات، ثلاث مهام',
        bodyEn:
            'The address bus carries "where" (CPU to memory/devices, one way), '
            'the data bus carries "what" (both ways), and the control bus carries '
            'read/write/interrupt signals. Width matters: a 32-bit address bus '
            'addresses 2^32 bytes = 4 GB.',
        bodyAr:
            'ناقل العنوان يحمل «أين» (من المعالج إلى الذاكرة/الأجهزة، باتجاه '
            'واحد)، وناقل البيانات يحمل «ماذا» (باتجاهين)، وناقل التحكم يحمل '
            'إشارات القراءة/الكتابة/المقاطعة. والعرض يهم: ناقل عنوان 32 بت '
            'يعنون 2^32 بايت = 4 غيغابايت.',
      ),
      MachineSection(
        headingEn: 'Talking to devices',
        headingAr: 'محادثة الأجهزة',
        bodyEn:
            'Polling means the CPU keeps asking "ready?"; interrupts mean the '
            'device raises a signal and the CPU pauses its current work to serve '
            'it. Interrupts keep the CPU free for your code instead of busy '
            'waiting.',
        bodyAr:
            'الاستطلاع يعني أن المعالج يظل يسأل «جاهز؟»؛ والمقاطعة تعني أن '
            'الجهاز يرفع إشارة فيوقف المعالج عمله الحالي ليخدمها. المقاطعات '
            'تبقي المعالج متفرغاً لشيفرتك بدل انشغاله بالانتظار.',
      ),
      MachineSection(
        headingEn: 'From keyboard to variable',
        headingAr: 'من لوحة المفاتيح إلى متغير',
        bodyEn:
            'A key press becomes: keyboard controller, interrupt, OS driver, '
            'then your scanf() or input() returns. Every "simple" input crosses '
            'all these layers — worth remembering when input feels slow.',
        bodyAr:
            'ضغطة المفتاح تصبح: متحكم لوحة المفاتيح، مقاطعة، برنامج تشغيل نظام '
            'التشغيل، ثم تعود scanf() أو input() عندك. كل إدخال «بسيط» يعبر '
            'كل هذه الطبقات — تذكر ذلك حين يبدو الإدخال بطيئاً.',
      ),
    ],
    terms: [
      MachineTerm(
        termEn: 'Data bus',
        termAr: 'ناقل البيانات',
        defEn: 'Bidirectional wires carrying the actual values.',
        defAr: 'أسلاك باتجاهين تحمل القيم الفعلية.',
      ),
      MachineTerm(
        termEn: 'Address bus',
        termAr: 'ناقل العنوان',
        defEn: 'One-way wires selecting which cell or device.',
        defAr: 'أسلاك باتجاه واحد تختار الخلية أو الجهاز.',
      ),
      MachineTerm(
        termEn: 'Control bus',
        termAr: 'ناقل التحكم',
        defEn: 'Signals like read, write and interrupt request.',
        defAr: 'إشارات مثل القراءة والكتابة وطلب المقاطعة.',
      ),
      MachineTerm(
        termEn: 'Interrupt',
        termAr: 'مقاطعة',
        defEn: 'A device signal that pauses the CPU to serve it.',
        defAr: 'إشارة جهاز توقف المعالج مؤقتاً لخدمته.',
      ),
    ],
    quiz: [
      MachineQuiz(
        questionEn: 'A 32-bit address bus can address...',
        questionAr: 'ناقل عنوان 32 بت يعنون...',
        optionsEn: ['4 GB', '32 GB', '2 GB'],
        optionsAr: ['4 غيغابايت', '32 غيغابايت', '2 غيغابايت'],
        correctIndex: 0,
        explanationEn: '2^32 bytes = 4 GiB of addressable memory.',
        explanationAr: '2^32 بايت = 4 غيبيبايت من الذاكرة المعنونة.',
      ),
      MachineQuiz(
        questionEn: 'Which lets the CPU work until a device needs it?',
        questionAr: 'أيها يترك المعالج يعمل حتى يحتاجه جهاز؟',
        optionsEn: ['Interrupts', 'Polling', 'Cache'],
        optionsAr: ['المقاطعات', 'الاستطلاع', 'المخبأ'],
        correctIndex: 0,
        explanationEn: 'Interrupts notify; polling wastes cycles asking.',
        explanationAr: 'المقاطعات تُشعر؛ والاستطلاع يهدر دورات في السؤال.',
      ),
    ],
  ),
];
