import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/course_repository.dart';
import 'services/app_services.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final repository = await CourseRepository.loadFromAssets();
  final services = await AppServices.create(
    store: PrefsStore(prefs),
    repository: repository,
  );
  runApp(CodingQuestApp(services: services));
}
