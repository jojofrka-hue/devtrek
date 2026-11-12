import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class Mascot extends StatelessWidget {
  const Mascot({
    super.key,
    this.mood = 'idle',
    this.message,
    this.size = 62,
  });

  final String mood;
  final String? message;
  final double size;

  String get _face => switch (mood) {
    'happy' => '🤩',
    'sad' => '😅',
    'party' => '🥳',
    _ => '🤖',
  };

  @override
  Widget build(BuildContext context) {
    final face = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE7F8D4), Color(0xFFDDF4FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: green.withValues(alpha: 0.5), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(_face, style: TextStyle(fontSize: size * 0.5)),
    );

    if (message == null) return face;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        face,
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              message!,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ),
        ),
      ],
    );
  }
}
