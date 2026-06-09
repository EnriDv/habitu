

import 'package:flutter/foundation.dart';
// import 'package:get_it/get_it.dart';
import '../../domain/repositories/habits_repository.dart';
import '../../domain/entities//habit.dart';
import '../../domain/entities//habit_log.dart';

/// Estados de carga posibles
enum LoadingState {
  idle,
  loading,
  success,
  error,
}

class HabitsNotifier extends ChangeNotifier {
  final HabitsRepository _repository;

  List<Habit> _habits = [];
  List<HabitLog> _currentHabitLogs = [];
  LoadingState _loadingState = LoadingState.idle;
  String? _errorMessage;
  String? _selectedHabitId; // Para mostrar logs del hábito actual

  HabitsNotifier({required HabitsRepository repository})
      : _repository = repository;


  List<Habit> get habits => _habits;
  List<Habit> get activeHabits => _habits.where((h) => !h.isDeleted).toList();
  bool get isLoading => _loadingState == LoadingState.loading;
  String? get errorMessage => _errorMessage;
  LoadingState get loadingState => _loadingState;

  List<HabitLog> get currentHabitLogs => _currentHabitLogs;
  String? get selectedHabitId => _selectedHabitId;

  /// Retorna el hábito seleccionado actualmente
  Habit? get selectedHabit {
    if (_selectedHabitId == null) return null;
    try {
      return _habits.firstWhere((h) => h.id == _selectedHabitId);
    } catch (_) {
      return null;
    }
  }


  Future<void> loadHabits({required String token}) async {
    _setLoading(true);
    try {

    } on Exception catch (e) {
      _setError('Failed to load habits: ${e.toString()}');
    }
  }

  Future<bool> createHabit({
    required Habit habit,
    required String token,
  }) async {
    try {
      return false;
    } on Exception catch (e) {
      _setError('Failed to create habit: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateHabit({
    required Habit habit,
    required String token,
  }) async {
    try {
      return false;
    } on Exception catch (e) {
      _setError('Failed to update habit: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteHabit({
    required String habitId,
    required String token,
  }) async {
    try {
      return false;
    } on Exception catch (e) {
      _setError('Failed to delete habit: ${e.toString()}');
      return false;
    }
  }

  Future<bool> completeHabit({
    required String habitId,
    required String confidenceLevel,
    String? notes,
    required String token,
  }) async {
    try {
      return false;
    } on Exception catch (e) {
      _setError('Failed to complete habit: ${e.toString()}');
      return false;
    }
  }

  Future<void> loadHabitLogs({
    required String habitId,
    required String token,
  }) async {
    _selectedHabitId = habitId;
    _setLoading(true);

    try {
    } on Exception catch (e) {
      _setError('Failed to load habit logs: ${e.toString()}');
    }
  }

  void clearSelectedHabit() {
    _selectedHabitId = null;
    _currentHabitLogs = [];
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _loadingState = loading ? LoadingState.loading : LoadingState.success;
    if (loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _setError(String message) {
    _loadingState = LoadingState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _loadingState = LoadingState.idle;
    notifyListeners();
  }

  void reset() {
    _habits = [];
    _currentHabitLogs = [];
    _loadingState = LoadingState.idle;
    _errorMessage = null;
    _selectedHabitId = null;
    notifyListeners();
  }
}