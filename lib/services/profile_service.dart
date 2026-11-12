import 'package:flutter/foundation.dart';

import 'storage_service.dart';

class ProfileService extends ChangeNotifier {
  ProfileService(this._store);

  final KeyValueStore _store;

  bool onboarded = false;
  String name = '';
  String experience = '';
  String goal = '';
  String favoriteCourse = '';
  int placementScore = -1;

  Future<void> load() {
    onboarded = _store.getBool('onboarded') ?? false;
    name = _store.getString('userName') ?? '';
    experience = _store.getString('experience') ?? '';
    goal = _store.getString('goal') ?? '';
    favoriteCourse = _store.getString('favoriteCourse') ?? '';
    placementScore = _store.getInt('placementScore') ?? -1;
    notifyListeners();
    return Future.value();
  }

  Future<void> save() async {
    await _store.setBool('onboarded', onboarded);
    await _store.setString('userName', name);
    await _store.setString('experience', experience);
    await _store.setString('goal', goal);
    await _store.setString('favoriteCourse', favoriteCourse);
    await _store.setInt('placementScore', placementScore);
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required String name,
    required String experience,
    required String goal,
    required String favoriteCourse,
    required int placementScore,
  }) async {
    this.name = name.trim();
    this.experience = experience;
    this.goal = goal;
    this.favoriteCourse = favoriteCourse;
    this.placementScore = placementScore;
    onboarded = true;
    await save();
  }

  Future<void> reset({bool clearStore = true}) async {
    onboarded = false;
    name = '';
    experience = '';
    goal = '';
    favoriteCourse = '';
    placementScore = -1;
    if (clearStore) {
      await _store.clear();
    } else {
      await save();
    }
    notifyListeners();
  }
}
