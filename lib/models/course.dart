import 'level.dart';

class Course {
  const Course({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.subtitleAr,
    required this.iconKey,
    required this.colorHex,
    required this.levels,
  });

  final String id;
  final String name;
  final String subtitle;
  final String subtitleAr;
  final String iconKey;
  final String colorHex;
  final List<Level> levels;

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      subtitleAr: json['subtitleAr'] as String? ?? json['subtitle'] as String? ?? '',
      iconKey: json['icon'] as String? ?? 'code',
      colorHex: json['color'] as String? ?? '1CB0F6',
      levels: ((json['levels'] as List?) ?? const [])
          .map((l) => Level.fromJson(l as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  String subtitleFor(bool arabic) =>
      arabic && subtitleAr.isNotEmpty ? subtitleAr : subtitle;
}
