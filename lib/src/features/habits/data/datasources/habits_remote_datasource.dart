import 'dart:convert';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';
import 'package:habitu/src/core/exceptions/app_exceptions.dart';
import 'package:habitu/src/core/network/custom_http_client.dart';
import 'package:habitu/src/core/constants/api_constants.dart';

class HabitsRemoteDataSource {
  final CustomHttpClient _client;

  HabitsRemoteDataSource(this._client);

  Future<List<Habit>> getHabits({required String token}) async {
    try {
      final response = await _client.get(ApiConstants.habitsEndpoint, token: token);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Habit.fromJson(json)).toList();
      }
      throw NetworkException(message: 'Error al obtener hábitos del servidor: ${response.statusCode}');
    } catch (e) {
      throw NetworkException(message: 'Error de red al obtener hábitos: $e');
    }
  }

  Future<Habit> getHabitById({
    required String habitId,
    required String token,
  }) async {
    try {
      final response = await _client.get('${ApiConstants.habitsEndpoint}/$habitId', token: token);
      if (response.statusCode == 200) {
        return Habit.fromJson(jsonDecode(response.body));
      }
      throw NetworkException(message: 'Error al obtener hábito: ${response.statusCode}');
    } catch (e) {
      throw NetworkException(message: 'Error de red al obtener el hábito: $e');
    }
  }

  Future<Habit> createHabit({
    required Habit habit,
    required String token,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.createHabitEndpoint,
        body: habit.toJson(),
        token: token,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Habit.fromJson(jsonDecode(response.body));
      }
      throw NetworkException(message: 'Error al crear hábito en servidor: ${response.statusCode}');
    } catch (e) {
      throw NetworkException(message: 'Error de red al crear hábito: $e');
    }
  }

  Future<Habit> updateHabit({
    required String habitId,
    required Habit habit,
    required String token,
  }) async {
    // Se delega al sync cycle
    throw NetworkException(message: 'Sincronizando a través de SyncManager.');
  }

  Future<void> deleteHabit({
    required String habitId,
    required String token,
  }) async {
    // Se delega al sync cycle
    throw NetworkException(message: 'Sincronizando a través de SyncManager.');
  }

  Future<HabitLog> completeHabit({
    required String habitId,
    required String confidenceLevel,
    String? notes,
    required String token,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.completeHabitEndpoint,
        body: {
          'habitId': habitId,
          'confidenceLevel': confidenceLevel,
          'notes': notes,
        },
        token: token,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return HabitLog.fromJson(jsonDecode(response.body));
      }
      throw NetworkException(message: 'Error al completar hábito en servidor: ${response.statusCode}');
    } catch (e) {
      throw NetworkException(message: 'Error de red al completar hábito: $e');
    }
  }

  Future<List<HabitLog>> getHabitLogs({
    required String habitId,
    required String token,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final response = await _client.get(
        '${ApiConstants.getHabitLogsEndpoint}/$habitId?limit=$limit&offset=$offset',
        token: token,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => HabitLog.fromJson(json)).toList();
      }
      throw NetworkException(message: 'Error al obtener logs: ${response.statusCode}');
    } catch (e) {
      throw NetworkException(message: 'Error de red al obtener logs: $e');
    }
  }

  Future<String> uploadEvidencePhoto({
    required String habitLogId,
    required String photoPath,
    required String token,
  }) async {
    throw NetworkException(message: 'Sube de fotos no disponible individualmente.');
  }

  Future<Map<String, dynamic>> syncHabits({
    required Map<String, dynamic> changes,
    required String token,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.syncEndpoint,
        body: changes,
        token: token,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw NetworkException(message: 'Error al sincronizar con servidor: ${response.statusCode}');
    } catch (e) {
      throw NetworkException(message: 'Error de red durante sincronización: $e');
    }
  }
}
