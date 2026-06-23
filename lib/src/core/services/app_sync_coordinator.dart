import '../../features/habits/presentation/notifiers/habits_notifier.dart';
import '../../features/onboarding/presentation/notifiers/session_onboarding_notifier.dart';
import '../../features/habits/data/services/sync_manager.dart';

class AppSyncCoordinator {
  final SyncManager _syncManager;
  DateTime? _lastRunAt;

  AppSyncCoordinator({required SyncManager syncManager}) : _syncManager = syncManager;

  Future<bool> syncAndRefresh({
    required OnboardingNotifier onboardingNotifier,
    required HabitsNotifier habitsNotifier,
    SyncMode mode = SyncMode.pullOnly,
    bool force = false,
  }) async {
    if (!onboardingNotifier.hasUser || onboardingNotifier.shouldShowInitialSetup) {
      return false;
    }

    final now = DateTime.now();
    if (!force &&
        _lastRunAt != null &&
        now.difference(_lastRunAt!) < const Duration(seconds: 10)) {
      return false;
    }

    _lastRunAt = now;
    final synced = await _syncManager.sync(mode: mode);
    await habitsNotifier.loadHabits(token: 'offline_token');
    return synced;
  }
}
