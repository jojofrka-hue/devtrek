import 'package:coding_quest/services/storage_service.dart';

/// In-memory [KeyValueStore] so unit tests never touch SharedPreferences.
class MemoryStore implements KeyValueStore {
  final Map<String, Object?> data = {};

  @override
  String? getString(String key) => data[key] as String?;

  @override
  int? getInt(String key) => data[key] as int?;

  @override
  bool? getBool(String key) => data[key] as bool?;

  @override
  List<String>? getStringList(String key) {
    final value = data[key];
    if (value == null) return null;
    return List<String>.of(value as Iterable<String>);
  }

  @override
  Future<void> setString(String key, String value) async => data[key] = value;

  @override
  Future<void> setInt(String key, int value) async => data[key] = value;

  @override
  Future<void> setBool(String key, bool value) async => data[key] = value;

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      data[key] = List<String>.of(value);

  @override
  Future<void> remove(String key) async => data.remove(key);

  @override
  Future<void> clear() async => data.clear();
}
