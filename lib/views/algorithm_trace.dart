import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../theme/app_theme.dart';
import 'algorithm_trace_data.dart';
import 'desktop_theme.dart';

class AlgorithmTrace extends StatefulWidget {
  const AlgorithmTrace({super.key});

  @override
  State<AlgorithmTrace> createState() => _AlgorithmTraceState();
}

class _AlgorithmTraceState extends State<AlgorithmTrace> {
  TracePreset _preset = TracePreset.arraySum;
  AlgorithmTraceData _data = AlgorithmTraceData.forPreset(TracePreset.arraySum);
  final ScrollController _codeScroll = ScrollController();
  Timer? _timer;
  int _position = 0;

  TraceFrame get _frame => _data.frames[_position];
  bool get _running => _timer?.isActive ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!TickerMode.valuesOf(context).enabled) _stop();
  }

  @override
  void dispose() {
    _stop();
    _codeScroll.dispose();
    super.dispose();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _reset([TracePreset? preset]) {
    setState(() {
      _stop();
      if (preset != null) {
        _preset = preset;
        _data = AlgorithmTraceData.forPreset(preset);
      }
      _position = 0;
    });
    if (_codeScroll.hasClients) _codeScroll.jumpTo(0);
  }

  void _step() {
    if (_frame.complete) return;
    setState(() {
      _position++;
      if (_frame.complete) _stop();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_codeScroll.hasClients || _frame.line == null) return;
      final lineHeight = 30 * MediaQuery.textScalerOf(context).scale(1);
      final offset = ((_frame.line! - 3) * lineHeight).clamp(
        0.0,
        _codeScroll.position.maxScrollExtent,
      );
      _codeScroll.animateTo(
        offset,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
      );
    });
  }

  void _toggleRun() {
    if (_running) {
      setState(_stop);
      return;
    }
    if (_frame.complete) return;
    _step();
    if (!_frame.complete) {
      setState(() {
        _timer = Timer.periodic(
          const Duration(milliseconds: 650),
          (_) => _step(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.s.isArabic;
    final palette = desktopPalette(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final header = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ar
                  ? 'تتبّع تنفيذ خوارزميات C'
                  : 'Algorithm & C Execution Visualizer',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              ar
                  ? 'محاكاة أمثلة جاهزة • القيم بعد تنفيذ السطر المظلل، وليست ذاكرة عملية حقيقية.'
                  : 'Preset simulation • Values after the highlighted line, not live process memory.',
              style: TextStyle(color: palette.subtle, fontSize: 12),
            ),
            const SizedBox(height: 14),
            _controls(ar, constraints.maxWidth),
          ],
        );
        if (constraints.maxWidth < 760 ||
            constraints.maxHeight < 420 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.4) {
          return ListView(
            key: const ValueKey('trace-stacked-layout'),
            children: [
              header,
              const SizedBox(height: 14),
              SizedBox(height: 350, child: _codePanel(ar, palette)),
              const SizedBox(height: 14),
              _statePanel(ar, palette),
              const SizedBox(height: 14),
              _explanation(ar, palette),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 14),
            Expanded(
              child: Row(
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 6, child: _codePanel(ar, palette)),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: _statePanel(ar, palette),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _explanation(ar, palette),
          ],
        );
      },
    );
  }

  Widget _controls(bool ar, double width) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: math.min(320, width),
          child: DropdownButtonFormField<TracePreset>(
            key: const ValueKey('trace-preset'),
            initialValue: _preset,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: ar ? 'مثال C' : 'C preset',
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final preset in TracePreset.values)
                DropdownMenuItem(value: preset, child: Text(preset.label(ar))),
            ],
            onChanged: (preset) {
              if (preset != null) _reset(preset);
            },
          ),
        ),
        Tooltip(
          message: ar
              ? 'تنفيذ تعليمة C واحدة وفحص أثرها'
              : 'Execute one C statement and inspect its effect',
          child: OutlinedButton.icon(
            key: const ValueKey('trace-step'),
            onPressed: _running || _frame.complete ? null : _step,
            icon: const Icon(Icons.skip_next_rounded, size: 18),
            label: Text(ar ? 'خطوة' : 'Step'),
          ),
        ),
        Tooltip(
          message: _running
              ? (ar
                    ? 'إيقاف التتبع مؤقتاً لفحص القيم'
                    : 'Pause the trace to inspect the current state')
              : (ar
                    ? 'تنفيذ الخطوات تلقائياً حتى نهاية المثال'
                    : 'Run the preset automatically to completion'),
          child: FilledButton.icon(
            key: const ValueKey('trace-run'),
            onPressed: _frame.complete ? null : _toggleRun,
            icon: Icon(
              _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 18,
            ),
            label: Text(
              _running ? (ar ? 'إيقاف مؤقت' : 'Pause') : (ar ? 'تشغيل' : 'Run'),
            ),
          ),
        ),
        Tooltip(
          message: ar
              ? 'إيقاف التنفيذ وإعادة المثال الحالي إلى بدايته'
              : 'Stop execution and reset the current preset',
          child: OutlinedButton.icon(
            key: const ValueKey('trace-reset'),
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: Text(ar ? 'إعادة' : 'Reset'),
          ),
        ),
      ],
    );
  }

  BoxDecoration _decoration(DesktopPalette palette) => BoxDecoration(
    color: palette.card,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: palette.cardBorder),
  );

  Widget _codePanel(bool ar, DesktopPalette palette) {
    final lineHeight = 30 * MediaQuery.textScalerOf(context).scale(1);
    return Container(
      decoration: _decoration(palette),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.code_rounded, color: blue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ar ? 'كود C • للقراءة فقط' : 'C source • read-only',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (_frame.line != null)
                  Text(
                    ar ? 'السطر ${_frame.line}' : 'Line ${_frame.line}',
                    key: const ValueKey('trace-current-line'),
                    style: const TextStyle(color: blue, fontSize: 12),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: palette.cardBorder),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final codeWidth = math.max(
                    constraints.maxWidth,
                    510 * MediaQuery.textScalerOf(context).scale(1),
                  );
                  return Scrollbar(
                    controller: _codeScroll,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _codeScroll,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: codeWidth,
                          child: Column(
                            children: [
                              for (
                                var index = 0;
                                index < _data.lines.length;
                                index++
                              )
                                Semantics(
                                  selected: _frame.line == index + 1,
                                  label: _frame.line == index + 1
                                      ? 'Current C line ${index + 1}'
                                      : null,
                                  child: Container(
                                    key: ValueKey('trace-line-${index + 1}'),
                                    height: lineHeight,
                                    color: _frame.line == index + 1
                                        ? blue.withValues(alpha: 0.15)
                                        : null,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 3,
                                          color: _frame.line == index + 1
                                              ? blue
                                              : Colors.transparent,
                                        ),
                                        SizedBox(
                                          width: 40,
                                          child: Text(
                                            '${index + 1}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                              color: _frame.line == index + 1
                                                  ? blue
                                                  : palette.subtle,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _data.lines[index],
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 13,
                                            color: _frame.line == index + 1
                                                ? Colors.white
                                                : palette.subtle,
                                            fontWeight: _frame.line == index + 1
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statePanel(bool ar, DesktopPalette palette) {
    final previous = _position > 0 ? _data.frames[_position - 1] : null;
    return Container(
      decoration: _decoration(palette),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ar ? 'مراقبة المتغيرات' : 'Variables Watch',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in _frame.variables.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: palette.sidebar,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: entry.value != previous?.variables[entry.key]
                            ? amber
                            : palette.cardBorder,
                      ),
                    ),
                    child: Text(
                      '${entry.key} = ${entry.value ?? '—'}',
                      key: ValueKey('watch-${entry.key}'),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ar
                ? '— قبل التهيئة • إطار ذهبي للقيمة المتغيرة'
                : '— before initialization • gold border = changed value',
            style: TextStyle(fontSize: 11, color: palette.subtle),
          ),
          Divider(height: 28, color: palette.cardBorder),
          Text(
            ar ? 'حالة المصفوفة' : 'Array State',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_frame.array.isEmpty)
            Text(
              ar
                  ? 'لم تُهيأ المصفوفة a بعد.'
                  : 'Array a is not initialized yet.',
              style: TextStyle(color: palette.subtle, fontSize: 13),
            )
          else
            Directionality(
              textDirection: TextDirection.ltr,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < _frame.array.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Column(
                          children: [
                            Text(
                              _frame.pointers[i] ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: blue,
                              ),
                            ),
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 14,
                              color: _frame.pointers.containsKey(i)
                                  ? blue
                                  : Colors.transparent,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              key: ValueKey('array-cell-$i'),
                              width: 54,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                color:
                                    (_frame.written.contains(i)
                                            ? amber
                                            : _frame.pointers.containsKey(i)
                                            ? blue
                                            : palette.sidebar)
                                        .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  width: 1.5,
                                  color: _frame.written.contains(i)
                                      ? amber
                                      : _frame.pointers.containsKey(i)
                                      ? blue
                                      : palette.cardBorder,
                                ),
                              ),
                              child: Text(
                                '${_frame.array[i]}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'a[$i]',
                              style: TextStyle(
                                color: palette.subtle,
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              Text(
                ar ? 'أزرق: قراءة / مقارنة' : 'Blue: read / compare',
                style: const TextStyle(color: blue, fontSize: 11),
              ),
              Text(
                ar ? 'ذهبي: كتابة في هذه الخطوة' : 'Gold: written this step',
                style: const TextStyle(color: amber, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _explanation(bool ar, DesktopPalette palette) {
    final status = _frame.complete
        ? (ar ? 'مكتمل' : 'Complete')
        : _running
        ? (ar ? 'قيد التشغيل' : 'Running')
        : _position == 0
        ? (ar ? 'جاهز' : 'Ready')
        : (ar ? 'متوقف' : 'Paused');
    return Container(
      decoration: _decoration(palette),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _frame.complete
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: _frame.complete ? green : blue,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$status · ${ar ? 'خطوة' : 'Step'} $_position / ${_data.frames.length - 1}',
                  key: const ValueKey('trace-status'),
                  style: TextStyle(
                    color: _frame.complete ? green : blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _frame.note(ar),
                  key: const ValueKey('trace-explanation'),
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
