

import '../entities/habit.dart';
import '../entities/habit_log.dart';

abstract class RepositoryException implements Exception {
  final String message;
  RepositoryException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends RepositoryException {
  NetworkException(String message) : super(message);
}

class UnauthorizedException extends RepositoryException {
  UnauthorizedException(String message) : super(message);
}

class AppException extends RepositoryException {
  AppException(String message) : super(message);
}

abstract class HabitsRepository {
  Future<List<Habit>> getHabits({required String token});

  Future<Habit> getHabitById({
    required String habitId,
    required String token,
  });

  Future<Habit> createHabit({
    required Habit habit,
    required String token,
  });

  Future<Habit> updateHabit({
    required String habitId,
    required Habit habit,
    required String token,
  });

  Future<void> deleteHabit({
    required String habitId,
    required String token,
  });

  Future<HabitLog> completeHabit({
    required String habitId,
    required String confidenceLevel,
    String? notes,
    String? photoPath,
    DateTime? completedAt,
    required String token,
  });

  Future<List<HabitLog>> getHabitLogs({
    required String habitId,
    required String token,
    int limit = 30,
    int offset = 0,
  });

  Future<String> uploadEvidencePhoto({
    required String habitLogId,
    required String photoPath,
    required String token,
  });

  Future<List<String>> getPendingSyncHabits();

  Future<void> markHabitAsSynced({required String habitId});
}
