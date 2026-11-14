import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../theme/app_theme.dart';
import '../views/desktop_theme.dart';
import '../widgets/common.dart';
import 'machine_lesson_page.dart';
import 'machine_lessons.dart';

class MachineStructurePage extends StatelessWidget {
  const MachineStructurePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('machineTitle'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            s.t('machineSubtitle'),
            style: TextStyle(
              fontSize: 14,
              color: desktopPalette(context).subtle,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < machineLessons.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SectionCard(
                icon: machineLessons[i].icon,
                title: '${i + 1}. ${machineLessons[i].title(s.isArabic)}',
                subtitle: machineLessons[i].summary(s.isArabic),
                color: [blue, purple, darkGreen, amber, red, blue][i % 6],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MachineLessonPage(lesson: machineLessons[i]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
