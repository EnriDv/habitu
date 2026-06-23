import 'package:flutter/foundation.dart';

import '../../../../core/database/app_database.dart';
import '../../data/repositories/progress_hub_repository.dart';
import '../../domain/entities/analytics_summary.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_template_models.dart';
import '../../domain/entities/routine.dart';
import '../../domain/repositories/habits_repository.dart';

class ProgressHubNotifier extends ChangeNotifier {
  final ProgressHubRepository _repository;
  final HabitsRepository _habitsRepository;
  final AppDatabase _db;

  ProgressHubNotifier({
    required ProgressHubRepository repository,
    required HabitsRepository habitsRepository,
    required AppDatabase db,
  })  : _repository = repository,
        _habitsRepository = habitsRepository,
        _db = db;

  bool _isLoading = false;
  String? _errorMessage;
  AnalyticsSummary? _analytics;
  List<RoutineSummary> _routines = [];
  RoutineDetail? _selectedRoutine;
  List<TemplateGoal> _goals = [];
  List<HabitTemplateModel> _templates = [];
  List<HabitRecommendation> _recommendations = [];
  String? _selectedGoalKey;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AnalyticsSummary? get analytics => _analytics;
  List<RoutineSummary> get routines => _routines;
  RoutineDetail? get selectedRoutine => _selectedRoutine;
  List<TemplateGoal> get goals => _goals;
  List<HabitTemplateModel> get templates => _templates;
  List<HabitRecommendation> get recommendations => _recommendations;
  String? get selectedGoalKey => _selectedGoalKey;

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await Future.wait([
        refreshAnalytics(),
        refreshRoutines(),
        loadGoals(),
        loadRecommendations(),
      ]);
      await loadTemplates(goalKey: _selectedGoalKey);
    } catch (e) {
      _errorMessage = 'No pudimos actualizar todo el panel ahora mismo. Seguimos mostrando lo disponible localmente.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshAnalytics() async {
    _analytics = await _repository.getAnalyticsSummary();
    notifyListeners();
  }

  Future<void> refreshRoutines() async {
    _routines = await _repository.getRoutines();
    notifyListeners();
  }

  Future<void> loadRoutineDetail(String routineId) async {
    _selectedRoutine = await _repository.getRoutineDetail(routineId);
    notifyListeners();
  }

  Future<void> createRoutine({
    required String title,
    String? description,
    required String timeOfDay,
    String? anchorTime,
    required List<int> daysOfWeek,
  }) async {
    final detail = await _repository.createRoutine(
      title: title,
      description: description,
      timeOfDay: timeOfDay,
      anchorTime: anchorTime,
      daysOfWeek: daysOfWeek,
    );
    if (detail != null) {
      _selectedRoutine = detail;
      await refreshRoutines();
    }
  }

  Future<void> updateRoutine({
    required String routineId,
    required String title,
    String? description,
    required String timeOfDay,
    String? anchorTime,
    required List<int> daysOfWeek,
  }) async {
    final detail = await _repository.updateRoutine(
      routineId: routineId,
      title: title,
      description: description,
      timeOfDay: timeOfDay,
      anchorTime: anchorTime,
      daysOfWeek: daysOfWeek,
    );
    if (detail != null) {
      _selectedRoutine = detail;
      await refreshRoutines();
    }
  }

  Future<void> deleteRoutine(String routineId) async {
    await _repository.deleteRoutine(routineId);
    if (_selectedRoutine?.id == routineId) {
      _selectedRoutine = null;
    }
    await refreshRoutines();
  }

  Future<void> assignHabitToRoutine({
    required String routineId,
    required String habitId,
    required int sortOrder,
  }) async {
    final detail = await _repository.assignHabitToRoutine(
      routineId: routineId,
      habitId: habitId,
      sortOrder: sortOrder,
    );
    if (detail != null) {
      _selectedRoutine = detail;
      await refreshRoutines();
    }
  }

  Future<void> removeHabitFromRoutine({
    required String routineId,
    required String habitId,
  }) async {
    final detail = await _repository.removeHabitFromRoutine(
      routineId: routineId,
      habitId: habitId,
    );
    if (detail != null) {
      _selectedRoutine = detail;
      await refreshRoutines();
    }
  }

  Future<void> loadGoals() async {
    _goals = await _repository.getTemplateGoals();
    _selectedGoalKey ??= _goals.isEmpty ? null : _goals.first.goalKey;
    notifyListeners();
  }

  Future<void> loadTemplates({String? goalKey}) async {
    _selectedGoalKey = goalKey ?? _selectedGoalKey;
    _templates = await _repository.getTemplates(goalKey: _selectedGoalKey);
    notifyListeners();
  }

  Future<void> loadRecommendations() async {
    _recommendations = await _repository.getRecommendations();
    notifyListeners();
  }

  Future<void> applyTemplate(HabitTemplateModel template) async {
    final user = await (_db.select(_db.usersTable)
          ..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();
    if (user == null) {
      return;
    }

    final habit = Habit(
      id: '',
      userId: user.id,
      title: template.title,
      description: template.description,
      frequencyType: template.suggestedFrequencyType,
      colorHex: template.defaultColorHex,
      icon: template.defaultIconKey,
      isPublic: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _habitsRepository.createHabit(habit: habit, token: 'offline_token');
    await Future.wait([
      refreshAnalytics(),
      loadRecommendations(),
    ]);
  }

  Future<List<Habit>> getActiveHabitsSnapshot() {
    return _repository.getActiveHabitsSnapshot();
  }

  RoutineSummary? getRoutineForNow(DateTime now) {
    final weekday = now.weekday;
    final currentHour = now.hour;
    final currentTag = currentHour < 12
        ? 'morning'
        : currentHour < 18
            ? 'afternoon'
            : 'evening';

    final matching = _routines.where((routine) {
      final dayMatch = routine.daysOfWeek.isEmpty || routine.daysOfWeek.contains(weekday);
      final timeMatch = routine.timeOfDay == currentTag || routine.timeOfDay == 'custom';
      return dayMatch && timeMatch;
    }).toList();

    if (matching.isEmpty) return null;
    matching.sort((a, b) => b.completionRate.compareTo(a.completionRate));
    return matching.first;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
