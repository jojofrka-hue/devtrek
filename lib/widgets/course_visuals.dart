import 'package:flutter/material.dart';

import '../models/course.dart';
import '../theme/app_theme.dart';

Color courseColor(Course course) {
  final parsed = int.tryParse('FF${course.colorHex}', radix: 16);
  return parsed == null ? blue : Color(parsed);
}

IconData courseIcon(String key) {
  return switch (key) {
    'terminal' => Icons.terminal,
    'data_object' => Icons.data_object,
    'coffee' => Icons.coffee,
    'web' => Icons.web,
    _ => Icons.code,
  };
}
