import '../data/course_repository.dart';
import 'achievement_service.dart';
import 'ai_tutor_service.dart';
import 'bug_hunt_progress_service.dart';
import 'profile_service.dart';
import 'progress_service.dart';
import 'review_service.dart';
import 'settings_service.dart';
import 'sound_service.dart';
import 'storage_service.dart';
import 'streak_service.dart';

/// Composition root: builds and loads every service once at startup.
class AppServices {
  AppServices._({
    required this.store,
    required this.repository,
    required this.profile,
    required this.progress,
    required this.streak,
    required this.review,
    required this.achievements,
    required this.bugHunt,
    required this.settings,
  }) : ai = AiTutorService(settings: settings),
       sound = SoundService(settings);

  final KeyValueStore store;
  final CourseRepository repository;
  final ProfileService profile;
  final ProgressService progress;
  final StreakService streak;
  final ReviewService review;
  final AchievementService achievements;
  final BugHuntProgressService bugHunt;
  final SettingsService settings;
  final AiTutorService ai;
  final SoundService sound;

  static Future<AppServices> create({
    required KeyValueStore store,
    required CourseRepository repository,
    DateTime Function()? clock,
  }) async {
    final settings = SettingsService(store);
    final profile = ProfileService(store);
    final progress = ProgressService(store);
    final streak = StreakService(store, clock: clock);
    final review = ReviewService(store, repository, clock: clock);
    final achievements = AchievementService(store, repository);
    final bugHunt = BugHuntProgressService(store);

    await Future.wait([
      settings.load(),
      profile.load(),
      progress.load(),
      streak.load(),
      review.load(),
      achievements.load(),
      bugHunt.load(),
    ]);

    return AppServices._(
      store: store,
      repository: repository,
      profile: profile,
      progress: progress,
      streak: streak,
      review: review,
      achievements: achievements,
      bugHunt: bugHunt,
      settings: settings,
    );
  }

  Future<void> evaluateAchievements() async {
    await achievements.evaluate(
      progress: progress,
      streak: streak,
      review: review,
      fixedBugs: bugHunt.solvedCount,
    );
  }

  Future<void> resetAll() async {
    await profile.reset(clearStore: false);
    progress.reset();
    await progress.save();
    await streak.reset();
    await review.reset();
    await achievements.reset();
    await bugHunt.reset();
  }
}
