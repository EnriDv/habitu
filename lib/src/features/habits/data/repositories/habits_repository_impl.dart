import 'package:uuid/uuid.dart';
import 'package:habitu/src/core/exceptions/app_exceptions.dart' hide AppException;
import '../datasources/habits_local_datasource.dart';
import '../datasources/habits_remote_datasource.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';
import '../../domain/repositories/habits_repository.dart' hide NetworkException;

class HabitsRepositoryImpl implements HabitsRepository {
  final HabitsLocalDataSource _localDataSource;
  final HabitsRemoteDataSource _remoteDataSource;
  final _uuid = const Uuid();

  HabitsRepositoryImpl({
    required HabitsLocalDataSource localDataSource,
    required HabitsRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<List<Habit>> getHabits({required String token}) async {
    try {
      // Intenta obtener del remoto
      final remoteHabits = await _remoteDataSource.getHabits(token: token);
      await _localDataSource.saveHabits(habits: remoteHabits);
      return remoteHabits;
    } on NetworkException {
      // Offline-First fallback
      return await _localDataSource.getHabits();
    }
  }

  @override
  Future<Habit> getHabitById({
    required String habitId,
    required String token,
  }) async {
    try {
      final remoteHabit = await _remoteDataSource.getHabitById(
        habitId: habitId,
        token: token,
      );
      await _localDataSource.saveHabit(habit: remoteHabit);
      return remoteHabit;
    } on NetworkException {
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
    // Generar ID si no existe
    final habitWithId = habit.id.isEmpty
        ? habit.copyWith(id: _uuid.v4())
        : habit;

    try {
      final remoteHabit = await _remoteDataSource.createHabit(
        habit: habitWithId,
        token: token,
      );
      await _localDataSource.saveHabit(habit: remoteHabit);
      return remoteHabit;
    } on NetworkException {
      // Guardar localmente y registrar en cola de sincronización
      await _localDataSource.saveHabit(habit: habitWithId);
      await _localDataSource.markHabitAsSyncPending(
        habitId: habitWithId.id,
        operation: 'create',
        payload: habitWithId.toJson(),
      );
      return habitWithId;
    }
  }

  @override
  Future<Habit> updateHabit({
    required String habitId,
    required Habit habit,
    required String token,
  }) async {
    final updatedHabit = habit.copyWith(updatedAt: DateTime.now());
    try {
      final remoteHabit = await _remoteDataSource.updateHabit(
        habitId: habitId,
        habit: updatedHabit,
        token: token,
      );
      await _localDataSource.saveHabit(habit: remoteHabit);
      return remoteHabit;
    } on NetworkException {
      await _localDataSource.saveHabit(habit: updatedHabit);
      await _localDataSource.markHabitAsSyncPending(
        habitId: habitId,
        operation: 'update',
        payload: updatedHabit.toJson(),
      );
      return updatedHabit;
    }
  }

  @override
  Future<void> deleteHabit({
    required String habitId,
    required String token,
  }) async {
    try {
      await _remoteDataSource.deleteHabit(
        habitId: habitId,
        token: token,
      );
      await _localDataSource.deleteHabit(habitId: habitId);
    } on NetworkException {
      // Soft-delete local y marcar en cola
      await _localDataSource.deleteHabit(habitId: habitId);
      await _localDataSource.markHabitAsSyncPending(
        habitId: habitId,
        operation: 'delete',
        payload: {'habitId': habitId},
      );
    }
  }

  @override
  Future<HabitLog> completeHabit({
    required String habitId,
    required String confidenceLevel,
    String? notes,
    required String token,
  }) async {
    // Obtener usuario activo
    final userId = await _localDataSource.getActiveUserId();

    final habitLog = HabitLog(
      id: _uuid.v4(),
      habitId: habitId,
      userId: userId,
      completedAt: DateTime.now(),
      notes: notes,
      evidencePhotoUrl: null,
      confidenceLevel: confidenceLevel,
      remoteId: null,
      createdAt: DateTime.now(),
      syncedAt: null,
    );

    // Guardado local (Instant offline-first)
    await _localDataSource.insertHabitLog(log: habitLog);

    // Registrar en la cola de sincronización
    await _localDataSource.markHabitLogAsSyncPending(
      habitLogId: habitLog.id,
      payload: habitLog.toJson(),
    );

    try {
      final remoteLog = await _remoteDataSource.completeHabit(
        habitId: habitId,
        confidenceLevel: confidenceLevel,
        notes: notes,
        token: token,
      );

      final updatedLog = habitLog.copyWith(
        remoteId: remoteLog.remoteId,
        syncedAt: DateTime.now(),
      );
      await _localDataSource.updateHabitLog(log: updatedLog);
      await _localDataSource.markSyncAsComplete(syncId: habitLog.id);
      return updatedLog;
    } on NetworkException {
      return habitLog;
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
      final remoteLogs = await _remoteDataSource.getHabitLogs(
        habitId: habitId,
        token: token,
        limit: limit,
        offset: offset,
      );
      for (final log in remoteLogs) {
        await _localDataSource.insertHabitLog(log: log);
      }
      return remoteLogs;
    } on NetworkException {
      return await _localDataSource.getHabitLogs(
        habitId: habitId,
        limit: limit,
        offset: offset,
      );
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
      return photoUrl;
    } on NetworkException {
      // Como no hay backend, retornamos un path local temporal simulando la URL
      return 'local_assets://evidence_$habitLogId.jpg';
    }
  }

  @override
  Future<List<String>> getPendingSyncHabits() async {
    return await _localDataSource.getPendingSyncHabitIds();
  }

  @override
  Future<void> markHabitAsSynced({required String habitId}) async {
    await _localDataSource.markSyncAsComplete(syncId: habitId);
  }
}
