

import 'package:drift/drift.dart';
// import '../../../core/database/app_database.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';

class HabitsLocalDataSource {
  Future<List<Habit>> getHabits() async {
    return [];
  }

  Future<Habit?> getHabitById({required String habitId}) async {
    return null;
  }

  Future<void> saveHabit({required Habit habit}) async {
  }

  Future<void> saveHabits({required List<Habit> habits}) async {
  }

  Future<void> deleteHabit({required String habitId}) async {
  }


  Future<List<HabitLog>> getHabitLogs({
    required String habitId,
    int limit = 30,
    int offset = 0,
  }) async {
   
    return [];
  }

  Future<int> getCompletionCountLastDays({
    required String habitId,
    int days = 7,
  }) async {

    return 0;
  }

  Future<void> insertHabitLog({required HabitLog log}) async {

  }
  Future<void> updateHabitLog({required HabitLog log}) async {

  }


  Future<void> markHabitAsSyncPending({
    required String habitId,
    required String operation, // 'create', 'update', 'delete'
    required Map<String, dynamic> payload,
  }) async {

  }

  Future<void> markHabitLogAsSyncPending({
    required String habitLogId,
    required Map<String, dynamic> payload,
  }) async {
  }

  Future<List<String>> getPendingSyncHabitIds() async {

    return [];
  }

  Future<void> markSyncAsComplete({required String syncId}) async {

  }

  Future<void> cleanupOldSyncRecords({int olderThanDays = 30}) async {

  }


}