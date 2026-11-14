import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../theme/app_theme.dart';
import 'desktop_theme.dart';
import 'fx.dart';

/// A tiny, hand-built CPU emulator for the Structure Machine track.
///
/// Learners write a small assembly program and watch the fetch–decode–execute
/// cycle move through registers (R0–R3 + PC) and 16 memory cells. No external
/// packages: the assembler, the virtual machine and every animation are here.
class RegisterTracker extends StatefulWidget {
  const RegisterTracker({super.key});

  @override
  State<RegisterTracker> createState() => _RegisterTrackerState();
}

const int _registerCount = 4;
const int _memorySize = 16;
const int _maxSteps = 500;

class _Sample {
  const _Sample(this.nameEn, this.nameAr, this.code);
  final String nameEn;
  final String nameAr;
  final String code;
}

const List<_Sample> _samples = [
  _Sample('Arithmetic', 'حساب', '''
; Add two numbers, store the result
MOV R0, 5
MOV R1, 7
ADD R0, R1
STORE R0, [0]
LOAD R2, [0]
HALT
'''),
  _Sample('Memory copy', 'نسخ الذاكرة', '''
; Copy memory[0] into memory[1]
MOV R0, 42
STORE R0, [0]
LOAD R1, [0]
STORE R1, [1]
HALT
'''),
  _Sample('Countdown loop', 'حلقة عد تنازلي', '''
; Count R0 down to zero
MOV R0, 3
loop:
DEC R0
JZ R0, done
JMP loop
done:
HALT
'''),
];

class _Instr {
  const _Instr(this.op, this.args, this.text, this.srcLine);
  final String op;
  final List<String> args;
  final String text;
  final int srcLine;
}

class _Program {
  const _Program(this.code, this.labels, this.error);
  final List<_Instr> code;
  final Map<String, int> labels;
  final String? error;
}

class _Cpu {
  List<int> regs = List<int>.filled(_registerCount, 0);
  List<int> memory = List<int>.filled(_memorySize, 0);
  int pc = 0;
  int steps = 0;
  bool halted = false;
  String? error;
}

int? _regIndex(String token) {
  final match = RegExp(r'^[Rr]([0-3])$').firstMatch(token.trim());
  return match == null ? null : int.parse(match.group(1)!);
}

int? _memAddr(String token) {
  final match = RegExp(r'^\[\s*(\d+)\s*\]$').firstMatch(token.trim());
  if (match == null) return null;
  final addr = int.parse(match.group(1)!);
  return addr >= 0 && addr < _memorySize ? addr : null;
}

int? _immediate(String token) => int.tryParse(token.trim());

_Program _assemble(String source) {
  final code = <_Instr>[];
  final labels = <String, int>{};
  final lines = source.split('\n');
  for (var li = 0; li < lines.length; li++) {
    var line = lines[li];
    final commentAt = line.indexOf(RegExp(r'[;#]'));
    if (commentAt >= 0) line = line.substring(0, commentAt);
    line = line.trim();
    if (line.isEmpty) continue;

    final colon = line.indexOf(':');
    if (colon >= 0) {
      final label = line.substring(0, colon).trim();
      if (!RegExp(r'^[A-Za-z_]\w*$').hasMatch(label)) {
        return _Program(const [], const {}, 'Invalid label on line ${li + 1}');
      }
      if (labels.containsKey(label)) {
        return _Program(const [], const {}, 'Duplicate label "$label"');
      }
      labels[label] = code.length;
      line = line.substring(colon + 1).trim();
      if (line.isEmpty) continue;
    }

    final tokens = line
        .split(RegExp(r'[\s,]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final op = tokens.first.toUpperCase();
    final args = tokens.sublist(1);
    code.add(_Instr(op, args, ([op, ...args]).join(' '), li + 1));
  }

  for (final instr in code) {
    final problem = _validate(instr, labels, code.length);
    if (problem != null) {
      return _Program(
        const [],
        const {},
        'Line ${instr.srcLine}: ${instr.op} $problem',
      );
    }
  }
  return _Program(code, labels, null);
}

String? _validate(_Instr instr, Map<String, int> labels, int n) {
  bool isReg(String t) => _regIndex(t) != null;
  bool isVal(String t) => isReg(t) || _immediate(t) != null;
  bool isMem(String t) => _memAddr(t) != null;
  bool isTarget(String t) {
    if (labels.containsKey(t)) return true;
    final v = _immediate(t);
    return v != null && v >= 0 && v <= n;
  }

  switch (instr.op) {
    case 'MOV':
    case 'ADD':
    case 'SUB':
      if (instr.args.length != 2) return 'expects 2 operands';
      if (!isReg(instr.args[0])) return 'first operand must be a register';
      if (!isVal(instr.args[1])) return 'second operand must be a register or number';
      return null;
    case 'LOAD':
    case 'STORE':
      if (instr.args.length != 2) return 'expects 2 operands';
      if (!isReg(instr.args[0])) return 'first operand must be a register';
      if (!isMem(instr.args[1])) return 'second operand must be memory like [0]';
      return null;
    case 'INC':
    case 'DEC':
      if (instr.args.length != 1) return 'expects 1 register';
      if (!isReg(instr.args[0])) return 'operand must be a register';
      return null;
    case 'JMP':
      if (instr.args.length != 1) return 'expects a label or line';
      if (!isTarget(instr.args[0])) return 'unknown jump target';
      return null;
    case 'JZ':
      if (instr.args.length != 2) return 'expects a register and a target';
      if (!isReg(instr.args[0])) return 'first operand must be a register';
      if (!isTarget(instr.args[1])) return 'unknown jump target';
      return null;
    case 'HALT':
      if (instr.args.isNotEmpty) return 'expects no operands';
      return null;
    default:
      return 'is not a known instruction';
  }
}

class _RegisterTrackerState extends State<RegisterTracker> {
  late final TextEditingController _src = TextEditingController(
    text: _samples.first.code,
  );
  _Program _program = const _Program([], {}, null);
  final _Cpu _cpu = _Cpu();
  final List<String> _log = [];
  Timer? _runner;
  int? _flashReg;
  int? _flashMem;
  int _sampleIndex = 0;

  @override
  void initState() {
    super.initState();
    _program = _assemble(_src.text);
  }

  @override
  void dispose() {
    _runner?.cancel();
    _src.dispose();
    super.dispose();
  }

  bool get _running => _runner != null;
  bool get _canStep =>
      !_running &&
      _program.error == null &&
      _program.code.isNotEmpty &&
      !_cpu.halted &&
      _cpu.error == null;

  void _resetVm() {
    _runner?.cancel();
    _runner = null;
    _cpu
      ..regs = List<int>.filled(_registerCount, 0)
      ..memory = List<int>.filled(_memorySize, 0)
      ..pc = 0
      ..steps = 0
      ..halted = false
      ..error = null;
    _log.clear();
    _flashReg = null;
    _flashMem = null;
  }

  void _reparse() {
    setState(() {
      _program = _assemble(_src.text);
      _resetVm();
    });
  }

  void _loadSample(int index) {
    setState(() {
      _sampleIndex = index;
      _src.text = _samples[index].code;
      _program = _assemble(_src.text);
      _resetVm();
    });
  }

  void _reset() {
    setState(_resetVm);
  }

  int _valueOf(String token) {
    final reg = _regIndex(token);
    return reg != null ? _cpu.regs[reg] : _immediate(token)!;
  }

  int _targetOf(String token) {
    final byLabel = _program.labels[token];
    return byLabel ?? _immediate(token)!;
  }

  /// Executes a single instruction, mutating [_cpu] and appending a trace line.
  void _stepOnce() {
    if (_cpu.halted || _cpu.error != null) return;
    if (_cpu.pc < 0 || _cpu.pc >= _program.code.length) {
      _cpu.halted = true;
      _log.insert(0, 'PC=${_cpu.pc}  end of program → HALT');
      return;
    }
    final instr = _program.code[_cpu.pc];
    final fetch = 'PC=${_cpu.pc}  ${instr.text}';
    _cpu.steps++;
    _flashReg = null;
    _flashMem = null;
    var nextPc = _cpu.pc + 1;
    String effect;

    switch (instr.op) {
      case 'MOV':
        final r = _regIndex(instr.args[0])!;
        _cpu.regs[r] = _valueOf(instr.args[1]);
        _flashReg = r;
        effect = 'R$r = ${_cpu.regs[r]}';
      case 'LOAD':
        final r = _regIndex(instr.args[0])!;
        final addr = _memAddr(instr.args[1])!;
        _cpu.regs[r] = _cpu.memory[addr];
        _flashReg = r;
        _flashMem = addr;
        effect = 'R$r = mem[$addr] = ${_cpu.regs[r]}';
      case 'STORE':
        final r = _regIndex(instr.args[0])!;
        final addr = _memAddr(instr.args[1])!;
        _cpu.memory[addr] = _cpu.regs[r];
        _flashMem = addr;
        effect = 'mem[$addr] = R$r = ${_cpu.regs[r]}';
      case 'ADD':
        final r = _regIndex(instr.args[0])!;
        final v = _valueOf(instr.args[1]);
        _cpu.regs[r] += v;
        _flashReg = r;
        effect = 'R$r = ${_cpu.regs[r]}';
      case 'SUB':
        final r = _regIndex(instr.args[0])!;
        final v = _valueOf(instr.args[1]);
        _cpu.regs[r] -= v;
        _flashReg = r;
        effect = 'R$r = ${_cpu.regs[r]}';
      case 'INC':
        final r = _regIndex(instr.args[0])!;
        _cpu.regs[r]++;
        _flashReg = r;
        effect = 'R$r = ${_cpu.regs[r]}';
      case 'DEC':
        final r = _regIndex(instr.args[0])!;
        _cpu.regs[r]--;
        _flashReg = r;
        effect = 'R$r = ${_cpu.regs[r]}';
      case 'JMP':
        nextPc = _targetOf(instr.args[0]);
        effect = 'jump → PC=$nextPc';
      case 'JZ':
        final r = _regIndex(instr.args[0])!;
        if (_cpu.regs[r] == 0) {
          nextPc = _targetOf(instr.args[1]);
          effect = 'R$r == 0 → jump PC=$nextPc';
        } else {
          effect = 'R$r = ${_cpu.regs[r]} ≠ 0 → no jump';
        }
      case 'HALT':
        _cpu.halted = true;
        effect = 'HALT';
      default:
        _cpu.error = 'Unknown instruction ${instr.op}';
        effect = _cpu.error!;
    }

    _cpu.pc = nextPc;
    _log.insert(0, '$fetch   →   $effect');
    if (_cpu.steps >= _maxSteps && !_cpu.halted && _cpu.error == null) {
      _cpu.error = 'Stopped after $_maxSteps steps (possible infinite loop)';
    }
    if (!_cpu.halted && _cpu.pc >= _program.code.length && _cpu.error == null) {
      _cpu.halted = true;
    }
  }

  void _step() {
    if (!_canStep) return;
    setState(_stepOnce);
  }

  void _run() {
    if (_running || _program.error != null || _cpu.halted || _cpu.error != null) {
      return;
    }
    setState(() {
      _runner = Timer.periodic(const Duration(milliseconds: 340), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_cpu.halted || _cpu.error != null || _cpu.steps >= _maxSteps) {
          timer.cancel();
          setState(() => _runner = null);
          return;
        }
        setState(_stepOnce);
      });
    });
  }

  void _stop() {
    _runner?.cancel();
    setState(() => _runner = null);
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.s.isArabic;
    final palette = desktopPalette(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(ar, palette),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: _editorColumn(ar, palette)),
              const SizedBox(width: 16),
              Expanded(flex: 6, child: _stateColumn(ar, palette)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _logPanel(ar, palette),
      ],
    );
  }

  Widget _header(bool ar, DesktopPalette palette) {
    return Row(
      children: [
        Icon(Icons.memory_rounded, color: blue, size: 22),
        const SizedBox(width: 10),
        Text(
          ar ? 'محاكي المعالج وتتبع المسجلات' : 'CPU Emulator & Register Tracker',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 12),
        _statusChip(ar, palette),
        const Spacer(),
        IconButton(
          tooltip: ar ? 'تعليمات' : 'Instruction set',
          onPressed: () => _showHelp(ar),
          icon: Icon(Icons.help_outline_rounded, color: palette.subtle),
        ),
      ],
    );
  }

  Widget _statusChip(bool ar, DesktopPalette palette) {
    String label;
    Color color;
    if (_program.error != null || _cpu.error != null) {
      label = ar ? 'خطأ' : 'ERROR';
      color = red;
    } else if (_running) {
      label = ar ? 'يعمل' : 'RUNNING';
      color = green;
    } else if (_cpu.halted) {
      label = ar ? 'توقف' : 'HALTED';
      color = amber;
    } else {
      label = ar ? 'جاهز' : 'READY';
      color = blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 6),
          Text(
            '$label · ${_cpu.steps} ${ar ? 'خطوة' : 'steps'}',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _editorColumn(bool ar, DesktopPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _samples.length; i++)
              _sampleChip(i, ar, palette),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: palette.sidebar,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.cardBorder, width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              controller: _src,
              onChanged: (_) => _reparse(),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13.5,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
        ),
        if (_program.error != null) ...[
          const SizedBox(height: 8),
          _errorBanner(_program.error!),
        ],
        const SizedBox(height: 10),
        _controls(ar, palette),
      ],
    );
  }

  Widget _sampleChip(int index, bool ar, DesktopPalette palette) {
    final selected = index == _sampleIndex;
    return HoverScale(
      hoverScale: 1.05,
      glow: blue,
      radius: 10,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _loadSample(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? blue.withValues(alpha: 0.16) : palette.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? blue : palette.cardBorder,
              width: 1.5,
            ),
          ),
          child: Text(
            ar ? _samples[index].nameAr : _samples[index].nameEn,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? blue : palette.subtle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls(bool ar, DesktopPalette palette) {
    return Row(
      children: [
        Expanded(
          child: _controlButton(
            label: ar ? 'خطوة' : 'Step',
            icon: Icons.skip_next_rounded,
            color: blue,
            onPressed: _canStep ? _step : null,
            palette: palette,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _running
              ? _controlButton(
                  label: ar ? 'إيقاف' : 'Stop',
                  icon: Icons.stop_rounded,
                  color: amber,
                  onPressed: _stop,
                  palette: palette,
                )
              : _controlButton(
                  label: ar ? 'تشغيل' : 'Run',
                  icon: Icons.play_arrow_rounded,
                  color: green,
                  onPressed: _canStep ? _run : null,
                  palette: palette,
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _controlButton(
            label: ar ? 'تصفير' : 'Reset',
            icon: Icons.restart_alt_rounded,
            color: palette.subtle,
            onPressed: _reset,
            palette: palette,
          ),
        ),
      ],
    );
  }

  Widget _controlButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required DesktopPalette palette,
  }) {
    return SizedBox(
      height: 44,
      child: HoverScale(
        hoverScale: 1.03,
        glow: onPressed == null ? null : color,
        radius: 12,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            disabledBackgroundColor: palette.track,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 18, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _stateColumn(bool ar, DesktopPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(ar ? 'المسجلات' : 'REGISTERS', palette),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var r = 0; r < _registerCount; r++)
              _regCell('R$r', _cpu.regs[r], _flashReg == r, blue, palette),
            _regCell('PC', _cpu.pc, false, purple, palette),
          ],
        ),
        const SizedBox(height: 14),
        _sectionLabel(ar ? 'الذاكرة (16 خلية)' : 'MEMORY (16 cells)', palette),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var a = 0; a < _memorySize; a++)
              _memCell(a, _cpu.memory[a], _flashMem == a, palette),
          ],
        ),
        const SizedBox(height: 14),
        _sectionLabel(ar ? 'البرنامج' : 'PROGRAM', palette),
        const SizedBox(height: 8),
        Expanded(child: _programListing(palette)),
      ],
    );
  }

  Widget _sectionLabel(String text, DesktopPalette palette) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: palette.subtle,
      ),
    );
  }

  Widget _regCell(
    String name,
    int value,
    bool flash,
    Color color,
    DesktopPalette palette,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 66,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: flash ? color.withValues(alpha: 0.20) : palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: flash ? color : palette.cardBorder,
          width: flash ? 2 : 1.5,
        ),
        boxShadow: flash
            ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16)]
            : const [],
      ),
      child: Column(
        children: [
          Text(
            name,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _memCell(int addr, int value, bool flash, DesktopPalette palette) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: flash ? green.withValues(alpha: 0.20) : palette.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: flash ? green : palette.cardBorder,
          width: flash ? 2 : 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            '[$addr]',
            style: TextStyle(fontSize: 9.5, color: palette.subtle),
          ),
          const SizedBox(height: 1),
          Text(
            '$value',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _programListing(DesktopPalette palette) {
    if (_program.code.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: palette.sidebar,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.cardBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          _program.error ?? '—',
          style: TextStyle(color: palette.subtle, fontSize: 12),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: palette.sidebar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _program.code.length,
        itemBuilder: (context, i) {
          final active = i == _cpu.pc && !_cpu.halted && _cpu.error == null;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            color: active ? green.withValues(alpha: 0.16) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: active
                      ? const Icon(Icons.play_arrow_rounded, size: 15, color: green)
                      : Text(
                          '$i',
                          style: TextStyle(fontSize: 11, color: palette.subtle),
                        ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _program.code[i].text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      color: active ? green : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _logPanel(bool ar, DesktopPalette palette) {
    return Container(
      height: 132,
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.sidebar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 14, color: palette.subtle),
              const SizedBox(width: 6),
              Text(
                ar ? 'سجل الجلب والفك والتنفيذ' : 'FETCH · DECODE · EXECUTE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: palette.subtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _log.isEmpty
                ? Center(
                    child: Text(
                      ar ? 'اضغط «خطوة» للبدء' : 'Press Step to begin',
                      style: TextStyle(fontSize: 12, color: palette.subtle),
                    ),
                  )
                : ListView.builder(
                    itemCount: _log.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        _log[i],
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: i == 0 ? green : palette.subtle,
                          fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: red.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: red, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp(bool ar) {
    final palette = desktopPalette(context);
    final rows = <List<String>>[
      ['MOV R0, 5', ar ? 'ضع قيمة في مسجل' : 'Set a register to a value'],
      ['MOV R0, R1', ar ? 'انسخ مسجلاً إلى آخر' : 'Copy one register to another'],
      ['LOAD R0, [3]', ar ? 'اقرأ الذاكرة إلى مسجل' : 'Read memory into a register'],
      ['STORE R0, [3]', ar ? 'اكتب المسجل في الذاكرة' : 'Write a register to memory'],
      ['ADD R0, R1', ar ? 'اجمع إلى المسجل' : 'Add into a register'],
      ['SUB R0, 2', ar ? 'اطرح من المسجل' : 'Subtract from a register'],
      ['INC R0 / DEC R0', ar ? 'زد / أنقص بواحد' : 'Increment / decrement by one'],
      ['JMP loop', ar ? 'اقفز إلى عنوان' : 'Jump to a label or line'],
      ['JZ R0, done', ar ? 'اقفز إذا كان المسجل صفراً' : 'Jump if the register is zero'],
      ['HALT', ar ? 'أوقف التنفيذ' : 'Stop execution'],
    ];
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.card,
        title: Text(ar ? 'مجموعة التعليمات' : 'Instruction set'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(
                            row[0],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row[1],
                            style: TextStyle(fontSize: 12.5, color: palette.subtle),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ar ? 'حسناً' : 'Got it'),
          ),
        ],
      ),
    );
  }
}