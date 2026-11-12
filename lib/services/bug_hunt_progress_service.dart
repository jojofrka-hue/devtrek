import 'package:flutter/foundation.dart';

import '../models/bug_task.dart';
import 'bug_validation.dart';
import 'storage_service.dart';

class BugHuntProgressService extends ChangeNotifier {
  BugHuntProgressService(this._store);

  final KeyValueStore _store;
  final Set<String> _solved = {};

  Set<String> get solved => Set.unmodifiable(_solved);

  int get solvedCount => _solved.length;

  bool isSolved(String id) => _solved.contains(id);

  Future<void> load() async {
    _solved
      ..clear()
      ..addAll(_store.getStringList('bugs.solved') ?? const []);
    notifyListeners();
  }

  Future<BugValidationResult> submit(BugTask task, String code) async {
    final result = validateBugFix(task, code);
    if (result.isSolved && !_solved.contains(task.id)) {
      _solved.add(task.id);
      await _store.setStringList('bugs.solved', _solved.toList());
      notifyListeners();
    }
    return result;
  }

  Future<void> reset() async {
    _solved.clear();
    await _store.remove('bugs.solved');
    notifyListeners();
  }
}
