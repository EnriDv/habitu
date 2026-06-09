

import 'dart:convert';
// import '../../../core/network/custom_http_client.dart';
// import '../../../core/constants/api_constants.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';
import '../../domain/repositories/habits_repository.dart';


class HabitsRemoteDataSource {
 
  Future<List<Habit>> getHabits({required String token}) async {
    
    return [];
  }

  
  Future<Habit> getHabitById({
    required String habitId,
    required String token,
  }) async {
   
    throw UnimplementedError();
  }

  
  Future<Habit> createHabit({
    required Habit habit,
    required String token,
  }) async {
    
    throw UnimplementedError();
  }

  Future<Habit> updateHabit({
    required String habitId,
    required Habit habit,
    required String token,
  }) async {
   
    throw UnimplementedError();
  }

  
  Future<void> deleteHabit({
    required String habitId,
    required String token,
  }) async {
   
  }

  Future<HabitLog> completeHabit({
    required String habitId,
    required String confidenceLevel,
    String? notes,
    required String token,
  }) async {

    throw UnimplementedError();
  }

  Future<List<HabitLog>> getHabitLogs({
    required String habitId,
    required String token,
    int limit = 30,
    int offset = 0,
  }) async {
 
    return [];
  }

  Future<String> uploadEvidencePhoto({
    required String habitLogId,
    required String photoPath,
    required String token,
  }) async {
    
    throw UnimplementedError();
  }

  
  Future<Map<String, dynamic>> syncHabits({
    required Map<String, dynamic> changes,
    required String token,
  }) async {

    return {};
  }
}