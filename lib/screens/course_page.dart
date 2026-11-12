import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/course.dart';
import '../models/level.dart';
import '../widgets/common.dart';
import '../widgets/course_visuals.dart';
import 'lesson_page.dart';

class CoursePage extends StatelessWidget {
  const CoursePage({super.key, required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final services = context.services;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: services.progress,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: courseColor(course),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        courseIcon(course.iconKey),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        course.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Text(
                    s.t('unlockHint'),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < course.levels.length; i++)
                  _levelCard(context, course.levels[i], i),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _levelCard(BuildContext context, Level level, int index) {
    final s = context.s;
    final services = context.services;
    final progress = services.progress;
    final unlocked = progress.isUnlocked(course.id, index);
    final stars = progress.starsFor(course.id, index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (!unlocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.t('lockedSnack'))),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LessonPage(course: course, levelIndex: index),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: unlocked ? Colors.white : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unlocked ? courseColor(course) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: unlocked ? courseColor(course) : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unlocked ? Icons.play_arrow_rounded : Icons.lock,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.titleFor(s.isArabic),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: unlocked ? Colors.black : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${level.subtitleFor(s.isArabic)}  •  '
                      '${level.questions.length} ${s.t('activities')}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              starRow(stars),
            ],
          ),
        ),
      ),
    );
  }
}
