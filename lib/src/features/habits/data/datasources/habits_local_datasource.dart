import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:habitu/src/core/database/app_database.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';

class HabitsLocalDataSource {
  final AppDatabase _db;

  HabitsLocalDataSource({required AppDatabase db}) : _db = db;

  Future<String> getActiveUserId() async {
    final query = _db.select(_db.usersTable)..where((t) => t.isActive.equals(true));
    final r = await query.getSingleOrNull();
    return r?.id ?? 'anonymous_student';
  }

  Future<List<Habit>> getHabits() async {
    final activeUserId = await getActiveUserId();
    final query = _db.select(_db.habitsTable)..where((t) => t.isDeleted.equals(false) & t.userId.equals(activeUserId));
    final rows = await query.get();
    return rows.map((r) => Habit(
      id: r.id,
      userId: r.userId,
      title: r.title,
      description: r.description,
      frequencyType: r.frequencyType,
      colorHex: r.colorHex,
      icon: r.icon,
      isPublic: r.isPublic,
      isDeleted: r.isDeleted,
      remoteId: r.remoteId,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    )).toList();
  }

  Future<Habit?> getHabitById({required String habitId}) async {
    final query = _db.select(_db.habitsTable)..where((t) => t.id.equals(habitId));
    final r = await query.getSingleOrNull();
    if (r == null) return null;
    return Habit(
      id: r.id,
      userId: r.userId,
      title: r.title,
      description: r.description,
      frequencyType: r.frequencyType,
      colorHex: r.colorHex,
      icon: r.icon,
      isPublic: r.isPublic,
      isDeleted: r.isDeleted,
      remoteId: r.remoteId,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  Future<void> saveHabit({required Habit habit}) async {
    await _db.into(_db.habitsTable).insertOnConflictUpdate(
      HabitsTableCompanion(
        id: Value(habit.id),
        userId: Value(habit.userId),
        title: Value(habit.title),
        description: Value(habit.description),
        frequencyType: Value(habit.frequencyType),
        colorHex: Value(habit.colorHex),
        icon: Value(habit.icon),
        isPublic: Value(habit.isPublic),
        isDeleted: Value(habit.isDeleted),
        remoteId: Value(habit.remoteId),
        createdAt: Value(habit.createdAt),
        updatedAt: Value(habit.updatedAt),
      ),
    );
  }

  Future<void> saveHabits({required List<Habit> habits}) async {
    await _db.batch((batch) {
      for (final habit in habits) {
        batch.insert(
          _db.habitsTable,
          HabitsTableCompanion(
            id: Value(habit.id),
            userId: Value(habit.userId),
            title: Value(habit.title),
            description: Value(habit.description),
            frequencyType: Value(habit.frequencyType),
            colorHex: Value(habit.colorHex),
            icon: Value(habit.icon),
            isPublic: Value(habit.isPublic),
            isDeleted: Value(habit.isDeleted),
            remoteId: Value(habit.remoteId),
            createdAt: Value(habit.createdAt),
            updatedAt: Value(habit.updatedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> deleteHabit({required String habitId}) async {
    await (_db.update(_db.habitsTable)..where((t) => t.id.equals(habitId))).write(
      const HabitsTableCompanion(
        isDeleted: Value(true),
      ),
    );
  }

  Future<List<HabitLog>> getHabitLogs({
    required String habitId,
    int limit = 30,
    int offset = 0,
  }) async {
    final query = _db.select(_db.habitLogsTable)
      ..where((t) => t.habitId.equals(habitId))
      ..orderBy([(t) => OrderingTerm(expression: t.completedAt, mode: OrderingMode.desc)])
      ..limit(limit, offset: offset);
    final rows = await query.get();
    return rows.map((r) => HabitLog(
      id: r.id,
      habitId: r.habitId,
      userId: r.userId,
      completedAt: r.completedAt,
      notes: r.notes,
      evidencePhotoUrl: r.evidencePhotoUrl,
      confidenceLevel: r.confidenceLevel ?? 'trust_me',
      remoteId: r.remoteId,
      createdAt: r.createdAt,
      syncedAt: null,
    )).toList();
  }

  Future<int> getCompletionCountLastDays({
    required String habitId,
    int days = 7,
  }) async {
    final threshold = DateTime.now().subtract(Duration(days: days));
    final query = _db.select(_db.habitLogsTable)
      ..where((t) => t.habitId.equals(habitId) & t.completedAt.isBiggerOrEqualValue(threshold));
    final rows = await query.get();
    return rows.length;
  }

  Future<void> insertHabitLog({required HabitLog log}) async {
    await _db.into(_db.habitLogsTable).insertOnConflictUpdate(
      HabitLogsTableCompanion(
        id: Value(log.id),
        habitId: Value(log.habitId),
        userId: Value(log.userId),
        completedAt: Value(log.completedAt),
        notes: Value(log.notes),
        evidencePhotoUrl: Value(log.evidencePhotoUrl),
        confidenceLevel: Value(log.confidenceLevel),
        remoteId: Value(log.remoteId),
        createdAt: Value(log.createdAt),
      ),
    );
  }

  Future<void> updateHabitLog({required HabitLog log}) async {
    await _db.update(_db.habitLogsTable).replace(
      HabitLogsTableData(
        id: log.id,
        habitId: log.habitId,
        userId: log.userId,
        completedAt: log.completedAt,
        notes: log.notes,
        evidencePhotoUrl: log.evidencePhotoUrl,
        confidenceLevel: log.confidenceLevel,
        remoteId: log.remoteId,
        createdAt: log.createdAt,
      ),
    );
  }

  Future<void> markHabitAsSyncPending({
    required String habitId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    await _db.into(_db.syncQueueTable).insert(
      SyncQueueTableCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        operationType: operation,
        entityType: 'habit',
        entityId: habitId,
        payload: jsonEncode(payload),
        isDirty: const Value(true),
        status: const Value('pending'),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markHabitLogAsSyncPending({
    required String habitLogId,
    required Map<String, dynamic> payload,
  }) async {
    await _db.into(_db.syncQueueTable).insert(
      SyncQueueTableCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        operationType: 'create',
        entityType: 'habit_log',
        entityId: habitLogId,
        payload: jsonEncode(payload),
        isDirty: const Value(true),
        status: const Value('pending'),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<String>> getPendingSyncHabitIds() async {
    final query = _db.select(_db.syncQueueTable)
      ..where((t) => t.isDirty.equals(true) & t.entityType.equals('habit'));
    final rows = await query.get();
    return rows.map((r) => r.entityId).toList();
  }

  Future<void> markSyncAsComplete({required String syncId}) async {
    await (_db.update(_db.syncQueueTable)..where((t) => t.entityId.equals(syncId))).write(
      SyncQueueTableCompanion(
        isDirty: const Value(false),
        status: const Value('synced'),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> cleanupOldSyncRecords({int olderThanDays = 30}) async {
    final threshold = DateTime.now().subtract(Duration(days: olderThanDays));
    await (_db.delete(_db.syncQueueTable)
      ..where((t) => t.isDirty.equals(false) & t.createdAt.isSmallerThanValue(threshold)))
      .go();
  }
}
