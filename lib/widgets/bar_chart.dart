import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../views/desktop_theme.dart';

class TopicBar extends StatelessWidget {
  const TopicBar({
    super.key,
    required this.label,
    required this.accuracy,
    required this.trailing,
  });

  final String label;
  final double accuracy;
  final String trailing;

  Color get _color {
    if (accuracy >= 0.75) return green;
    if (accuracy >= 0.5) return amber;
    return red;
  }

  @override
  Widget build(BuildContext context) {
    final palette = desktopPalette(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                trailing,
                style: TextStyle(fontSize: 12, color: palette.subtle),
              ),
              const SizedBox(width: 8),
              Text(
                '${(accuracy * 100).round()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: accuracy.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: palette.track,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

class MiniStat extends StatelessWidget {
  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = desktopPalette(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
        color: Color.alphaBlend(color.withValues(alpha: 0.07), palette.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: palette.subtle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
