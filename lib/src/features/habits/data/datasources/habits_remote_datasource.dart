import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';
import 'package:habitu/src/core/exceptions/app_exceptions.dart';

class HabitsRemoteDataSource {
  Future<List<Habit>> getHabits({required String token}) async {
    throw NetworkException(message: 'El backend no está disponible en este momento');
  }

  Future<Habit> getHabitById({
    required String habitId,
    required String token,
  }) async {
    throw NetworkException(message: 'El backend no está disponible en este momento');
  }

  Future<Habit> createHabit({
    required Habit habit,
    required String token,
  }) async {
    throw NetworkException(message: 'El backend no está disponible en este momento');
  }

  Future<Habit> updateHabit({
    required String habitId,
    required Habit habit,
    required String token,
  }) async {
    throw NetworkException(message: 'El backend no está disponible en este momento');
  }

  Future<void> deleteHabit({
    required String habitId,
    required String token,
  }) async {
    throw NetworkException(message: 'El backend no está disponible en este momento');
  }

  Future<HabitLog> completeHabit({
    required String habitId,
    required String confidenceLevel,
    String? notes,
    required String token,
  }) async {
    throw NetworkException(message: 'El backend no está disponible en este momento');
  }

  Future<List<HabitLog>> getHabitLogs({
    required String habitId,
    required String token,
    int limit = 30,
    int offset = 0,
  }) async {
    throw NetworkException(message: 'El backend no está disponible en este momento');
  }

  Future<String> uploadEvidencePhoto({
    required String habitLogId,
    required String photoPath,
    required String token,
  }) async {
    throw NetworkException(message: 'El backend no está disponible en este momento');
  }

  Future<Map<String, dynamic>> syncHabits({
    required Map<String, dynamic> changes,
    required String token,
  }) async {
    throw NetworkException(message: 'El backend no está disponible en este momento');
  }
}
