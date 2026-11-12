import 'package:flutter/material.dart';

const green = Color(0xFF58CC02);
const darkGreen = Color(0xFF58A700);
const red = Color(0xFFFF4B4B);
const blue = Color(0xFF1CB0F6);
const amber = Color(0xFFFFB020);
const purple = Color(0xFF7A5CFF);

const pairColors = [
  Color(0xFF1CB0F6),
  Color(0xFFFF9600),
  Color(0xFF7A5CFF),
  Color(0xFFFF4B8B),
  Color(0xFF00B894),
];

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: green,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
