import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../i18n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/course_visuals.dart';
import 'home_page.dart';
import 'placement_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const totalSteps = 4;
  static const experiences = [
    ('exp_beginner', 'exp_beginner_desc'),
    ('exp_basics', 'exp_basics_desc'),
    ('exp_comfortable', 'exp_comfortable_desc'),
    ('exp_experienced', 'exp_experienced_desc'),
  ];
  static const goals = [
    ('goal_uni', 'goal_uni_desc'),
    ('goal_career', 'goal_career_desc'),
    ('goal_apps', 'goal_apps_desc'),
    ('goal_fun', 'goal_fun_desc'),
  ];

  int step = 0;
  final nameCtrl = TextEditingController();
  String exp = '';
  String goalPick = '';
  String favPick = '';

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  bool get canContinue {
    return switch (step) {
      0 => nameCtrl.text.trim().isNotEmpty,
      1 => exp.isNotEmpty,
      2 => goalPick.isNotEmpty,
      _ => favPick.isNotEmpty,
    };
  }

  bool get isBeginner => exp == 'exp_beginner';

  Future<void> _next() async {
    if (step < totalSteps - 1) {
      setState(() => step++);
      return;
    }

    final services = context.services;
    if (isBeginner) {
      await services.profile.completeOnboarding(
        name: nameCtrl.text,
        experience: exp,
        goal: goalPick,
        favoriteCourse: favPick,
        placementScore: 0,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlacementPage(
          questions: services.repository.placementQuestions,
          name: nameCtrl.text.trim(),
          experience: exp,
          goal: goalPick,
          favoriteCourse: favPick,
        ),
      ),
    );
  }

  Widget _stepBody(AppStrings s) {
    switch (step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.t('onboardingWelcome'),
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              s.t('onboardingIntro'),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: s.t('nameHint'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.t('howMuch'),
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            for (final item in experiences)
              ChoiceCard(
                title: s.t(item.$1),
                subtitle: s.t(item.$2),
                selected: exp == item.$1,
                onTap: () => setState(() => exp = item.$1),
              ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.t('whyLearning'),
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            for (final item in goals)
              ChoiceCard(
                title: s.t(item.$1),
                subtitle: s.t(item.$2),
                selected: goalPick == item.$1,
                onTap: () => setState(() => goalPick = item.$1),
              ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.t('whichLanguage'),
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            for (final course in context.services.repository.courses)
              ChoiceCard(
                title: course.name,
                subtitle: course.subtitleFor(s.isArabic),
                icon: courseIcon(course.iconKey),
                color: courseColor(course),
                selected: favPick == course.id,
                onTap: () => setState(() => favPick = course.id),
              ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lastLabel = isBeginner ? s.t('finish') : s.t('takeQuickTest');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 12, 24, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: step == 0
                              ? Colors.transparent
                              : Colors.grey.shade600,
                        ),
                        onPressed: step == 0
                            ? null
                            : () => setState(() => step--),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (step + 1) / totalSteps,
                            minHeight: 14,
                            backgroundColor: Colors.grey.shade300,
                            color: green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _stepBody(s),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: BigButton(
                    label: step == totalSteps - 1 ? lastLabel : s.t('continue'),
                    onPressed: canContinue ? _next : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
