import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/habit_catalog.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/network/custom_http_client.dart';
import '../../../../core/services/session_token_service.dart';
import '../../domain/entities/analytics_summary.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';
import '../../domain/entities/habit_template_models.dart';
import '../../domain/entities/routine.dart';

class ProgressHubRepository {
  final AppDatabase _db;
  final CustomHttpClient _client;
  final SessionTokenService _tokenService;

  ProgressHubRepository({
    required AppDatabase db,
    required CustomHttpClient client,
    required SessionTokenService tokenService,
  })  : _db = db,
        _client = client,
        _tokenService = tokenService;

  Future<String?> getActiveUserId() async {
    final user = await (_db.select(_db.usersTable)
          ..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();
    return user?.id;
  }

  Future<List<RoutineSummary>> getRoutines() async {
    final token = await _tokenService.getValidAccessToken();
    if (token != null) {
      try {
        final response = await _client.get(ApiConstants.routinesEndpoint, token: token);
        if (response.statusCode == 200) {
          final data = (jsonDecode(response.body) as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map(RoutineSummary.fromJson)
              .toList();
          await _saveRoutineSummaries(data);
          return data;
        }
      } catch (_) {}
    }

    return _getLocalRoutines();
  }

  Future<RoutineDetail?> getRoutineDetail(String routineId) async {
    final token = await _tokenService.getValidAccessToken();
    if (token != null) {
      try {
        final response = await _client.get('${ApiConstants.routinesEndpoint}/$routineId', token: token);
        if (response.statusCode == 200) {
          final data = RoutineDetail.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
          await _saveRoutineDetail(data);
          return data;
        }
      } catch (_) {}
    }

    return _getLocalRoutineDetail(routineId);
  }

  Future<RoutineDetail?> createRoutine({
    required String title,
    String? description,
    required String timeOfDay,
    String? anchorTime,
    required List<int> daysOfWeek,
  }) async {
    final userId = await getActiveUserId();
    if (userId == null) return null;

    final token = await _tokenService.getValidAccessToken();
    if (token != null) {
      try {
        final response = await _client.post(
          ApiConstants.routinesEndpoint,
          token: token,
          body: {
            'title': title,
            'description': description,
            'timeOfDay': timeOfDay,
            'anchorTime': anchorTime,
            'daysOfWeek': daysOfWeek,
          },
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          final detail = RoutineDetail.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
          await _saveRoutineDetail(detail);
          return detail;
        }
      } catch (_) {}
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final detail = RoutineDetail(
      id: id,
      title: title,
      description: description,
      timeOfDay: timeOfDay,
      anchorTime: anchorTime,
      daysOfWeek: daysOfWeek,
      habits: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _saveRoutineDetail(detail, userId: userId);
    return detail;
  }

  Future<RoutineDetail?> updateRoutine({
    required String routineId,
    required String title,
    String? description,
    required String timeOfDay,
    String? anchorTime,
    required List<int> daysOfWeek,
  }) async {
    final token = await _tokenService.getValidAccessToken();
    if (token != null) {
      try {
        final response = await _client.put(
          '${ApiConstants.routinesEndpoint}/$routineId',
          token: token,
          body: {
            'title': title,
            'description': description,
            'timeOfDay': timeOfDay,
            'anchorTime': anchorTime,
            'daysOfWeek': daysOfWeek,
          },
        );
        if (response.statusCode == 200) {
          final detail = RoutineDetail.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
          await _saveRoutineDetail(detail);
          return detail;
        }
      } catch (_) {}
    }

    final existing = await _getLocalRoutineDetail(routineId);
    if (existing == null) return null;
    final detail = RoutineDetail(
      id: existing.id,
      title: title,
      description: description,
      timeOfDay: timeOfDay,
      anchorTime: anchorTime,
      daysOfWeek: daysOfWeek,
      habits: existing.habits,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );
    await _saveRoutineDetail(detail);
    return detail;
  }

  Future<void> deleteRoutine(String routineId) async {
    final token = await _tokenService.getValidAccessToken();
    if (token != null) {
      try {
        await _client.delete('${ApiConstants.routinesEndpoint}/$routineId', token: token);
      } catch (_) {}
    }

    await (_db.update(_db.routinesTable)..where((t) => t.id.equals(routineId))).write(
      RoutinesTableCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<RoutineDetail?> assignHabitToRoutine({
    required String routineId,
    required String habitId,
    required int sortOrder,
  }) async {
    final token = await _tokenService.getValidAccessToken();
    if (token != null) {
      try {
        final response = await _client.post(
          '${ApiConstants.routinesEndpoint}/$routineId/habits',
          token: token,
          body: {
            'habitId': habitId,
            'sortOrder': sortOrder,
          },
        );
        if (response.statusCode == 200) {
          final detail = RoutineDetail.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
          await _saveRoutineDetail(detail);
          return detail;
        }
      } catch (_) {}
    }

    await _db.into(_db.routineHabitsTable).insertOnConflictUpdate(
      RoutineHabitsTableCompanion.insert(
        routineId: routineId,
        habitId: habitId,
        sortOrder: Value(sortOrder),
      ),
    );
    return _getLocalRoutineDetail(routineId);
  }

  Future<RoutineDetail?> removeHabitFromRoutine({
    required String routineId,
    required String habitId,
  }) async {
    final token = await _tokenService.getValidAccessToken();
    if (token != null) {
      try {
        final response = await _client.delete(
          '${ApiConstants.routinesEndpoint}/$routineId/habits/$habitId',
          token: token,
        );
        if (response.statusCode == 200) {
          final detail = RoutineDetail.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
          await _saveRoutineDetail(detail);
          return detail;
        }
      } catch (_) {}
    }

    await (_db.delete(_db.routineHabitsTable)
          ..where((t) => t.routineId.equals(routineId) & t.habitId.equals(habitId)))
        .go();
    return _getLocalRoutineDetail(routineId);
  }

  Future<AnalyticsSummary> getAnalyticsSummary() async {
    final token = await _tokenService.getValidAccessToken();
    if (token != null) {
      try {
        final response = await _client.get(ApiConstants.analyticsSummaryEndpoint, token: token);
        if (response.statusCode == 200) {
          return AnalyticsSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        }
      } catch (_) {}
    }

    return _buildLocalAnalyticsSummary();
  }

  Future<List<TemplateGoal>> getTemplateGoals() async {
    final token = await _tokenService.getValidAccessToken();
    if (token != null) {
      try {
        final response = await _client.get(ApiConstants.templateGoalsEndpoint, token: token);
        if (response.statusCode == 200) {
          return (jsonDecode(response.body) as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map(TemplateGoal.fromJson)
              .toList();
        }
      } catch (_) {}
    }

    return focusAreaOptions
        .map((area) => TemplateGoal(
              goalKey: area.id,
              title: area.title,
              description: area.description,
            ))
        .toList();
  }

  Future<List<HabitTemplateModel>> getTemplates({String? goalKey}) async {
    final token = await _tokenService.getValidAccessToken();
    if (token != null) {
      try {
        final endpoint = goalKey == null
            ? ApiConstants.templatesEndpoint
            : '${ApiConstants.templatesEndpoint}?goalKey=$goalKey';
        final response = await _client.get(endpoint, token: token);
        if (response.statusCode == 200) {
          return (jsonDecode(response.body) as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map(HabitTemplateModel.fromJson)
              .toList();
        }
      } catch (_) {}
    }

    final fallback = habitTemplateOptions.map((template) {
      final mappedGoal = _goalKeyForCategory(template.category);
      return HabitTemplateModel(
        id: '${mappedGoal}_${template.title}',
        title: template.title,
        description: template.description,
        goalKey: mappedGoal,
        category: template.category,
        lifestyleTags: const [],
        suggestedFrequencyType: 'daily',
        suggestedFrequencyDays: const [1, 2, 3, 4, 5, 6, 7],
        defaultColorHex: template.colorHex,
        defaultIconKey: template.emoji,
        isFeatured: true,
      );
    }).toList();

    return goalKey == null
        ? fallback
        : fallback.where((template) => template.goalKey == goalKey).toList();
  }

  Future<List<HabitRecommendation>> getRecommendations() async {
    final token = await _tokenService.getValidAccessToken();
    if (token != null) {
      try {
        final response = await _client.get(ApiConstants.recommendationsEndpoint, token: token);
        if (response.statusCode == 200) {
          return (jsonDecode(response.body) as List<dynamic>)
              .whereType<Map<String, dynamic>>()
              .map(HabitRecommendation.fromJson)
              .toList();
        }
      } catch (_) {}
    }

    final templates = await getTemplates();
    return templates.take(4).map((template) {
      return HabitRecommendation(
        id: template.id,
        type: 'template',
        title: template.title,
        description: template.description ?? '',
        reason: 'Sugerencia inicial basada en tus áreas y plantillas disponibles.',
        goalKey: template.goalKey,
        suggestedPayload: {
          'title': template.title,
          'description': template.description,
          'frequencyType': template.suggestedFrequencyType,
          'frequencyDays': template.suggestedFrequencyDays,
          'colorHex': template.defaultColorHex,
          'iconKey': template.defaultIconKey,
        },
      );
    }).toList();
  }

  Future<List<Habit>> getActiveHabitsSnapshot() async {
    final activeUserId = await getActiveUserId();
    if (activeUserId == null) return const [];

    final habits = await (_db.select(_db.habitsTable)
          ..where((t) => t.userId.equals(activeUserId) & t.isDeleted.equals(false)))
        .get();

    return habits
        .map((row) => Habit(
              id: row.id,
              userId: row.userId,
              title: row.title,
              description: row.description,
              frequencyType: row.frequencyType,
              colorHex: row.colorHex,
              icon: row.icon,
              isPublic: row.isPublic,
              isDeleted: row.isDeleted,
              remoteId: row.remoteId,
              createdAt: row.createdAt,
              updatedAt: row.updatedAt,
            ))
        .toList();
  }

  Future<void> _saveRoutineSummaries(List<RoutineSummary> routines) async {
    final userId = await getActiveUserId();
    if (userId == null) return;

    await _db.batch((batch) {
      for (final routine in routines) {
        batch.insert(
          _db.routinesTable,
          RoutinesTableCompanion.insert(
            id: routine.id,
            userId: userId,
            title: routine.title,
            description: Value(routine.description),
            timeOfDay: Value(routine.timeOfDay),
            anchorTime: Value(routine.anchorTime),
            daysOfWeek: Value(jsonEncode(routine.daysOfWeek)),
            isDeleted: const Value(false),
            createdAt: Value(routine.createdAt),
            updatedAt: Value(routine.updatedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> _saveRoutineDetail(RoutineDetail detail, {String? userId}) async {
    final resolvedUserId = userId ?? await getActiveUserId();
    if (resolvedUserId == null) return;

    await _db.into(_db.routinesTable).insertOnConflictUpdate(
      RoutinesTableCompanion.insert(
        id: detail.id,
        userId: resolvedUserId,
        title: detail.title,
        description: Value(detail.description),
        timeOfDay: Value(detail.timeOfDay),
        anchorTime: Value(detail.anchorTime),
        daysOfWeek: Value(jsonEncode(detail.daysOfWeek)),
        isDeleted: const Value(false),
        createdAt: Value(detail.createdAt),
        updatedAt: Value(detail.updatedAt),
      ),
    );

    await (_db.delete(_db.routineHabitsTable)..where((t) => t.routineId.equals(detail.id))).go();

    await _db.batch((batch) {
      for (final habit in detail.habits) {
        batch.insert(
          _db.routineHabitsTable,
          RoutineHabitsTableCompanion.insert(
            routineId: detail.id,
            habitId: habit.habitId,
            sortOrder: Value(habit.sortOrder),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<RoutineSummary>> _getLocalRoutines() async {
    final userId = await getActiveUserId();
    if (userId == null) return const [];

    final rows = await (_db.select(_db.routinesTable)
          ..where((t) => t.userId.equals(userId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .get();

    final links = await _db.select(_db.routineHabitsTable).get();
    final completionsToday = await _completionsToday();

    return rows.map((row) {
      final routineLinks = links.where((link) => link.routineId == row.id).toList();
      final completedCount = routineLinks.where((link) => completionsToday.contains(link.habitId)).length;
      return RoutineSummary(
        id: row.id,
        title: row.title,
        description: row.description,
        timeOfDay: row.timeOfDay,
        anchorTime: row.anchorTime,
        daysOfWeek: _decodeDays(row.daysOfWeek),
        habitCount: routineLinks.length,
        completedCount: completedCount,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
    }).toList();
  }

  Future<RoutineDetail?> _getLocalRoutineDetail(String routineId) async {
    final row = await (_db.select(_db.routinesTable)..where((t) => t.id.equals(routineId))).getSingleOrNull();
    if (row == null) return null;

    final links = await (_db.select(_db.routineHabitsTable)
          ..where((t) => t.routineId.equals(routineId))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
    final completionsToday = await _completionsToday();

    final habits = <RoutineHabitItem>[];
    for (final link in links) {
      final habitRow = await (_db.select(_db.habitsTable)..where((t) => t.id.equals(link.habitId))).getSingleOrNull();
      if (habitRow == null) continue;
      habits.add(RoutineHabitItem(
        habitId: habitRow.id,
        title: habitRow.title,
        description: habitRow.description,
        colorHex: habitRow.colorHex,
        sortOrder: link.sortOrder,
        isCompletedToday: completionsToday.contains(habitRow.id),
      ));
    }

    return RoutineDetail(
      id: row.id,
      title: row.title,
      description: row.description,
      timeOfDay: row.timeOfDay,
      anchorTime: row.anchorTime,
      daysOfWeek: _decodeDays(row.daysOfWeek),
      habits: habits,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<Set<String>> _completionsToday() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final logs = await (_db.select(_db.habitLogsTable)
          ..where((t) => t.completedAt.isBiggerOrEqualValue(start) & t.completedAt.isSmallerThanValue(end)))
        .get();
    return logs.map((log) => log.habitId).toSet();
  }

  List<int> _decodeDays(String raw) {
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => item as int).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<AnalyticsSummary> _buildLocalAnalyticsSummary() async {
    final habits = await getActiveHabitsSnapshot();
    final logsRows = await _db.select(_db.habitLogsTable).get();
    final logs = logsRows
        .map((row) => HabitLog(
              id: row.id,
              habitId: row.habitId,
              userId: row.userId,
              completedAt: row.completedAt,
              notes: row.notes,
              evidencePhotoUrl: row.evidencePhotoUrl,
              confidenceLevel: row.confidenceLevel ?? 'trust_me',
              remoteId: row.remoteId,
              createdAt: row.createdAt,
              syncedAt: null,
            ))
        .toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last7 = today.subtract(const Duration(days: 6));
    final last30 = today.subtract(const Duration(days: 29));
    final allLogs = logs;

    final topStats = habits.map((habit) {
      final habitLogs = allLogs.where((log) => log.habitId == habit.id).toList();
      return AnalyticsHabitStat(
        habitId: habit.id,
        title: habit.title,
        colorHex: habit.colorHex,
        completions: habitLogs.length,
        currentStreak: _currentStreak(habitLogs),
        longestStreak: _longestStreak(habitLogs),
      );
    }).toList();

    final sortedTop = List<AnalyticsHabitStat>.from(topStats)
      ..sort((a, b) {
        final byCompletions = b.completions.compareTo(a.completions);
        return byCompletions != 0 ? byCompletions : b.currentStreak.compareTo(a.currentStreak);
      });
    final needsAttention = List<AnalyticsHabitStat>.from(topStats)
      ..sort((a, b) {
        final byCompletions = a.completions.compareTo(b.completions);
        return byCompletions != 0 ? byCompletions : a.currentStreak.compareTo(b.currentStreak);
      });

    final heatmap = List.generate(120, (index) {
      final date = today.subtract(Duration(days: 119 - index));
      final count = allLogs.where((log) {
        final completed = DateTime(log.completedAt.year, log.completedAt.month, log.completedAt.day);
        return completed == date;
      }).length;
      return AnalyticsHeatmapPoint(date: date, count: count);
    });

    final timeBucketsMap = <String, int>{'Mañana': 0, 'Tarde': 0, 'Noche': 0};
    for (final log in allLogs) {
      final hour = log.completedAt.hour;
      if (hour < 12) {
        timeBucketsMap['Mañana'] = timeBucketsMap['Mañana']! + 1;
      } else if (hour < 18) {
        timeBucketsMap['Tarde'] = timeBucketsMap['Tarde']! + 1;
      } else {
        timeBucketsMap['Noche'] = timeBucketsMap['Noche']! + 1;
      }
    }

    final weekdayMap = <String, int>{};
    for (final log in allLogs) {
      const weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      final label = weekdays[log.completedAt.weekday - 1];
      weekdayMap[label] = (weekdayMap[label] ?? 0) + 1;
    }

    final totalCompletedLast7Days = allLogs.where((log) => !log.completedAt.isBefore(last7)).length;
    final totalCompletedLast30Days = allLogs.where((log) => !log.completedAt.isBefore(last30)).length;
    final maxActiveStreak = topStats.isEmpty ? 0 : topStats.map((item) => item.currentStreak).reduce((a, b) => a > b ? a : b);

    return AnalyticsSummary(
      totalActiveHabits: habits.length,
      totalCompletedLast7Days: totalCompletedLast7Days,
      totalCompletedLast30Days: totalCompletedLast30Days,
      weeklySuccessRate: habits.isEmpty ? 0 : totalCompletedLast7Days / (habits.length * 7),
      monthlySuccessRate: habits.isEmpty ? 0 : totalCompletedLast30Days / (habits.length * 30),
      maxActiveStreak: maxActiveStreak,
      mostProductiveWeekday: weekdayMap.entries.isEmpty
          ? 'Sin datos'
          : (weekdayMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key,
      bestCompletionWindow: (timeBucketsMap.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .first
          .key,
      topHabits: sortedTop.take(3).toList(),
      needsAttentionHabits: needsAttention.take(3).toList(),
      heatmap: heatmap,
      timeBuckets: timeBucketsMap.entries
          .map((entry) => AnalyticsTimeBucket(label: entry.key, count: entry.value))
          .toList(),
    );
  }

  int _currentStreak(List<HabitLog> logs) {
    if (logs.isEmpty) return 0;
    final dates = logs
        .map((log) => DateTime(log.completedAt.year, log.completedAt.month, log.completedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final yesterday = normalizedToday.subtract(const Duration(days: 1));
    if (dates.first != normalizedToday && dates.first != yesterday) {
      return 0;
    }
    var streak = 1;
    for (var i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        break;
      }
    }
    return streak;
  }

  int _longestStreak(List<HabitLog> logs) {
    if (logs.isEmpty) return 0;
    final dates = logs
        .map((log) => DateTime(log.completedAt.year, log.completedAt.month, log.completedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    var longest = 1;
    var current = 1;
    for (var i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        current++;
      } else if (diff > 1) {
        if (current > longest) longest = current;
        current = 1;
      }
    }
    return current > longest ? current : longest;
  }

  String _goalKeyForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'salud':
        return 'health';
      case 'productividad':
        return 'productivity';
      case 'bienestar':
        return 'wellbeing';
      case 'relaciones':
        return 'relationships';
      case 'aprendizaje':
        return 'learning';
      case 'hogar':
        return 'home';
      case 'finanzas':
        return 'finance';
      default:
        return 'general';
    }
  }
}
