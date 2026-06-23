import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../features/habits/domain/entities/habit.dart';
import '../../features/habits/presentation/notifiers/habits_notifier.dart';
import '../../features/habits/presentation/screens/recommendations_screen.dart';
import '../../features/habits/presentation/screens/routine_detail_screen.dart';
import '../../features/habits/presentation/widgets/habit_detail_sheet.dart';
import '../../features/social/presentation/screens/challenge_detail_screen.dart';

class DeepLinkService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> handleLink(String? rawLink) async {
    if (rawLink == null || rawLink.trim().isEmpty) return;

    final uri = Uri.tryParse(rawLink.trim());
    if (uri == null) return;

    final firstSegment = uri.host.isNotEmpty
        ? uri.host
        : (uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '');
    final pathSegments = uri.host.isNotEmpty
        ? uri.pathSegments
        : (uri.pathSegments.length > 1 ? uri.pathSegments.sublist(1) : <String>[]);

    switch (firstSegment) {
      case 'today':
        openToday();
        break;
      case 'habit':
        if (pathSegments.isNotEmpty) {
          await openHabitDetail(pathSegments.first);
        }
        break;
      case 'routine':
        if (pathSegments.isNotEmpty) {
          openRoutineDetail(pathSegments.first);
        }
        break;
      case 'recommendations':
        openRecommendations();
        break;
      case 'challenge':
        if (pathSegments.isNotEmpty) {
          final challengeId = pathSegments.first;
          final shouldAutoJoin = pathSegments.length > 1 && pathSegments[1] == 'join';
          openChallengeDetail(challengeId, autoJoin: shouldAutoJoin);
        }
        break;
      case 'invite':
        if (pathSegments.isNotEmpty) {
          openChallengeDetail(pathSegments.first, autoJoin: true, isInviteCode: true);
        }
        break;
    }
  }

  Future<void> openHabitDetail(String habitId) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final habitsNotifier = GetIt.instance<HabitsNotifier>();
    if (habitsNotifier.habits.isEmpty) {
      await habitsNotifier.loadHabits(token: 'offline_token');
    }

    Habit? selectedHabit;
    for (final habit in habitsNotifier.habits) {
      if (habit.id == habitId) {
        selectedHabit = habit;
        break;
      }
    }

    if (selectedHabit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos encontrar ese habito.')),
      );
      return;
    }

    final resolvedHabit = selectedHabit;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitDetailSheet(habit: resolvedHabit),
    );
  }

  void openChallengeDetail(
    String challengeId, {
    bool autoJoin = false,
    bool isInviteCode = false,
  }) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ChallengeDetailScreen(
          challengeId: challengeId,
          autoJoin: autoJoin,
          isInviteCode: isInviteCode,
        ),
      ),
    );
  }

  void openToday() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.popUntil((route) => route.isFirst);
  }

  void openRoutineDetail(String routineId) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => RoutineDetailScreen(routineId: routineId),
      ),
    );
  }

  void openRecommendations() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const RecommendationsScreen(),
      ),
    );
  }
}
