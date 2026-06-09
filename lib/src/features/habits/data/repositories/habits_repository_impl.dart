

import 'package:habitu/src/core/exceptions/app_exceptions.dart' hide AppException;
import '../datasources/habits_local_datasource.dart';
import '../datasources/habits_remote_datasource.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';
import '../../domain/repositories/habits_repository.dart' hide NetworkException;

class HabitsRepositoryImpl implements HabitsRepository {
  final HabitsLocalDataSource _localDataSource;
  final HabitsRemoteDataSource _remoteDataSource;

  HabitsRepositoryImpl({
    required HabitsLocalDataSource localDataSource,
    required HabitsRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;


  @override
  Future<List<Habit>> getHabits({required String token}) async {
    try {
      // Paso 1: Intenta obtener del backend
      final remoteHabits = await _remoteDataSource.getHabits(token: token);

      // Paso 2: Guarda en local para offline
      await _localDataSource.saveHabits(habits: remoteHabits);

      return remoteHabits;
    } on AppException {
      // Paso 3: Si falla, intenta local (Offline-First)
      return await _localDataSource.getHabits();
    }
  }

  @override
  Future<Habit> getHabitById({
    required String habitId,
    required String token,
  }) async {
    try {
      // Intenta remoto
      final remoteHabit = await _remoteDataSource.getHabitById(
        habitId: habitId,
        token: token,
      );
      // Guarda en local
      await _localDataSource.saveHabit(habit: remoteHabit);
      return remoteHabit;
    } on AppException {
      // Fallback a local
      final localHabit = await _localDataSource.getHabitById(habitId: habitId);
      if (localHabit != null) {
        return localHabit;
      }
      rethrow;
    }
  }

  @override
  Future<Habit> createHabit({
    required Habit habit,
    required String token,
  }) async {
    try {
      // Intenta crear en remoto
      final remoteHabit = await _remoteDataSource.createHabit(
        habit: habit,
        token: token,
      );

      // Guarda localmente
      await _localDataSource.saveHabit(habit: remoteHabit);

      return remoteHabit;
    } on NetworkException {
      // Si falla por red, guarda localmente y marca para sincronizar
      await _localDataSource.saveHabit(habit: habit);

      // Marca en cola de sincronización
      await _localDataSource.markHabitAsSyncPending(
        habitId: habit.id,
        operation: 'create',
        payload: habit.toJson(),
      );

      // Retorna el hábito local (sin remoteId aún)
      return habit;
    } on AppException {
      rethrow;
    }
  }

  @override
  Future<Habit> updateHabit({
    required String habitId,
    required Habit habit,
    required String token,
  }) async {
    try {
      // Intenta actualizar en remoto
      final remoteHabit = await _remoteDataSource.updateHabit(
        habitId: habitId,
        habit: habit,
        token: token,
      );

      // Guarda localmente
      await _localDataSource.saveHabit(habit: remoteHabit);

      return remoteHabit;
    } on NetworkException {
      // Si falla, guarda localmente y marca para sincronizar
      await _localDataSource.saveHabit(habit: habit);

      await _localDataSource.markHabitAsSyncPending(
        habitId: habitId,
        operation: 'update',
        payload: habit.toJson(),
      );

      return habit;
    } on AppException {
      rethrow;
    }
  }

  @override
  Future<void> deleteHabit({
    required String habitId,
    required String token,
  }) async {
    try {
      // Intenta eliminar en remoto
      await _remoteDataSource.deleteHabit(
        habitId: habitId,
        token: token,
      );

      // Elimina localmente
      await _localDataSource.deleteHabit(habitId: habitId);
    } on NetworkException {
      // Si falla, marca como eliminado localmente y sincronizar después
      await _localDataSource.deleteHabit(habitId: habitId);

      await _localDataSource.markHabitAsSyncPending(
        habitId: habitId,
        operation: 'delete',
        payload: {'habitId': habitId},
      );
    } on AppException {
      rethrow;
    }
  }

  @override
  Future<HabitLog> completeHabit({
    required String habitId,
    required String confidenceLevel,
    String? notes,
    required String token,
  }) async {
    // Paso 1: Crear HabitLog con timestamp actual
    final habitLog = HabitLog(
      id: _generateUuid(), // UUID local
      habitId: habitId,
      userId: '', // TODO: Obtener del usuario actual
      completedAt: DateTime.now(),
      notes: notes,
      evidencePhotoUrl: null, // Se cargará después si hay foto
      confidenceLevel: confidenceLevel,
      remoteId: null, // Se asignará al sincronizar
      createdAt: DateTime.now(),
      syncedAt: null,
    );

    // Paso 2: Guardar localmente (INSTANT OFFLINE-FIRST)
    await _localDataSource.insertHabitLog(log: habitLog);

    // Paso 3: Marcar como pendiente de sincronización
    await _localDataSource.markHabitLogAsSyncPending(
      habitLogId: habitLog.id,
      payload: habitLog.toJson(),
    );

    // Paso 4: Intenta enviar al backend (no bloqueante)
    try {
      final remoteLog = await _remoteDataSource.completeHabit(
        habitId: habitId,
        confidenceLevel: confidenceLevel,
        notes: notes,
        token: token,
      );

      // Si tiene éxito, actualiza con remoteId
      final updatedLog = habitLog.copyWith(remoteId: remoteLog.remoteId);
      await _localDataSource.updateHabitLog(log: updatedLog);
      await _localDataSource.markSyncAsComplete(syncId: habitLog.id);

      return updatedLog;
    } on AppException catch (e) {
      // Si falla, el HabitLog está guardado localmente y será sincronizado después
      print('Background sync scheduled: ${e.toString()}');
      return habitLog; // Retorna el log local (sin remoteId)
    }
  }

  @override
  Future<List<HabitLog>> getHabitLogs({
    required String habitId,
    required String token,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      // Intenta remoto
      final remoteLogs = await _remoteDataSource.getHabitLogs(
        habitId: habitId,
        token: token,
        limit: limit,
        offset: offset,
      );

      // Guarda en local
      for (final log in remoteLogs) {
        await _localDataSource.insertHabitLog(log: log);
      }

      return remoteLogs;
    } on AppException {
      // Fallback a local
      return await _localDataSource.getHabitLogs(habitId: habitId);
    }
  }

  @override
  Future<String> uploadEvidencePhoto({
    required String habitLogId,
    required String photoPath,
    required String token,
  }) async {
    try {
      final photoUrl = await _remoteDataSource.uploadEvidencePhoto(
        habitLogId: habitLogId,
        photoPath: photoPath,
        token: token,
      );

      // Actualiza el log con la URL
      // TODO: Obtener el log, actualizarlo, guardarlo
      // await _localDataSource.updateHabitLog(...)

      return photoUrl;
    } on AppException {
      throw AppException('Failed to upload photo. Please try again later.');
    }
  }

  @override
  Future<List<String>> getPendingSyncHabits() async {
    return await _localDataSource.getPendingSyncHabitIds();
  }

  @override
  Future<void> markHabitAsSynced({required String habitId}) async {
    await _localDataSource.markHabitAsSyncPending(
      habitId: habitId,
      operation: 'sync_complete',
      payload: {'habitId': habitId},
    );
  }

  /// Genera un UUID v4 simple (en producción, usar uuid package)
  String _generateUuid() {
    // TODO: Usar uuid package
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}