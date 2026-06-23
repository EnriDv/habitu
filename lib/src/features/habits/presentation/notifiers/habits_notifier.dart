import 'package:flutter/foundation.dart';
import '../../domain/repositories/habits_repository.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';

enum LoadingState {
  idle,
  loading,
  success,
  error,
}

class HabitsNotifier extends ChangeNotifier {
  final HabitsRepository _repository;

  List<Habit> _habits = [];
  List<HabitLog> _allLogs = [];
  List<HabitLog> _currentHabitLogs = [];
  LoadingState _loadingState = LoadingState.idle;
  String? _errorMessage;
  String? _selectedHabitId;

  // Selected date for "Hoy" calendar view
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  HabitsNotifier({required HabitsRepository repository})
      : _repository = repository;

  List<Habit> get habits => _habits;
  List<Habit> get activeHabits => _habits.where((h) => !h.isDeleted).toList();
  bool get isLoading => _loadingState == LoadingState.loading;
  String? get errorMessage => _errorMessage;
  LoadingState get loadingState => _loadingState;

  List<HabitLog> get currentHabitLogs => _currentHabitLogs;
  String? get selectedHabitId => _selectedHabitId;
  DateTime get selectedDate => _selectedDate;

  /// Retorna el hÃ¡bito seleccionado actualmente
  Habit? get selectedHabit {
    if (_selectedHabitId == null) return null;
    try {
      return _habits.firstWhere((h) => h.id == _selectedHabitId);
    } catch (_) {
      return null;
    }
  }

  /// Filtra hÃ¡bitos para el dÃ­a seleccionado
  List<Habit> get habitsForSelectedDate {
    // Para simplificar, mostramos todos los hÃ¡bitos activos.
    // En el futuro, podrÃ­amos filtrar segÃºn la frecuencia y el dÃ­a de la semana.
    return activeHabits;
  }

  /// Verifica si un hÃ¡bito se completÃ³ en la fecha seleccionada
  HabitLog? getCompletionLogForHabit(String habitId, DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    try {
      return _allLogs.firstWhere((log) {
        final logDate = DateTime(log.completedAt.year, log.completedAt.month, log.completedAt.day);
        return log.habitId == habitId && logDate == targetDate;
      });
    } catch (_) {
      return null;
    }
  }

  /// Cambia el dÃ­a seleccionado en el carrusel
  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  Future<void> loadHabits({required String token}) async {
    _setLoading(true);
    try {
      _habits = await _repository.getHabits(token: token);
      
      // Cargar logs de todos los hÃ¡bitos para calcular rachas e historial
      final List<HabitLog> loadedLogs = [];
      final habitsCopy = List<Habit>.from(_habits);
      for (final habit in habitsCopy) {
        try {
          final logs = await _repository.getHabitLogs(habitId: habit.id, token: token, limit: 100);
          loadedLogs.addAll(logs);
        } catch (e) {
          debugPrint('No se pudieron cargar los logs para ${habit.title}: $e');
        }
      }
      _allLogs = loadedLogs;
      _loadingState = LoadingState.success;
      notifyListeners();
    } on Exception catch (_) {
      _setError('No pudimos cargar tus hábitos en este momento.');
    }
  }

  Future<bool> createHabit({
    required Habit habit,
    required String token,
  }) async {
    _setLoading(true);
    try {
      final created = await _repository.createHabit(habit: habit, token: token);
      _habits.add(created);
      _loadingState = LoadingState.success;
      notifyListeners();
      return true;
    } on Exception catch (_) {
      _setError('No pudimos crear el hábito en este momento.');
      return false;
    }
  }

  Future<bool> updateHabit({
    required Habit habit,
    required String token,
  }) async {
    _setLoading(true);
    try {
      final updated = await _repository.updateHabit(habitId: habit.id, habit: habit, token: token);
      final index = _habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        _habits[index] = updated;
      }
      _loadingState = LoadingState.success;
      notifyListeners();
      return true;
    } on Exception catch (_) {
      _setError('No pudimos actualizar el hábito en este momento.');
      return false;
    }
  }

  Future<bool> deleteHabit({
    required String habitId,
    required String token,
  }) async {
    _setLoading(true);
    try {
      await _repository.deleteHabit(habitId: habitId, token: token);
      // Soft-delete local
      final index = _habits.indexWhere((h) => h.id == habitId);
      if (index != -1) {
        _habits[index] = _habits[index].copyWith(isDeleted: true);
      }
      _loadingState = LoadingState.success;
      notifyListeners();
      return true;
    } on Exception catch (_) {
      _setError('No pudimos eliminar el hábito en este momento.');
      return false;
    }
  }

  Future<bool> completeHabit({
    required String habitId,
    required String confidenceLevel,
    String? notes,
    String? photoPath,
    required String token,
  }) async {
    final targetCompletedAt = _selectedDate == DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
        ? DateTime.now()
        : _selectedDate;

    // Optimista offline-first: agregamos un log temporal en memoria
    final tempLog = HabitLog(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      habitId: habitId,
      userId: '',
      completedAt: targetCompletedAt,
      confidenceLevel: confidenceLevel,
      notes: notes,
      evidencePhotoUrl: photoPath,
      createdAt: DateTime.now(),
    );
    
    _allLogs.add(tempLog);
    notifyListeners();

    try {
      final savedLog = await _repository.completeHabit(
        habitId: habitId,
        confidenceLevel: confidenceLevel,
        notes: notes,
        photoPath: photoPath,
        completedAt: targetCompletedAt,
        token: token,
      );

      // Reemplazar el log temporal con el guardado
      _allLogs.remove(tempLog);
      _allLogs.add(savedLog);
      
      // Si el hÃ¡bito detallado seleccionado es este, actualizar su vista
      if (_selectedHabitId == habitId) {
        await loadHabitLogs(habitId: habitId, token: token);
      }
      
      notifyListeners();
      return true;
    } on Exception catch (_) {
      _allLogs.remove(tempLog);
      _setError('No pudimos guardar la completada en este momento.');
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
      _currentHabitLogs = await _repository.getHabitLogs(habitId: habitId, token: token);
      _loadingState = LoadingState.success;
      notifyListeners();
    } on Exception catch (_) {
      _setError('No pudimos cargar el historial de este hábito.');
    }
  }

  /// Calcula la racha actual del hÃ¡bito
  int getHabitCurrentStreak(String habitId) {
    final logs = _allLogs.where((l) => l.habitId == habitId).toList();
    if (logs.isEmpty) return 0;
    
    final dates = logs.map((l) => DateTime(l.completedAt.year, l.completedAt.month, l.completedAt.day))
                      .toSet()
                      .toList()
                      ..sort((a, b) => b.compareTo(a));
                      
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (dates.first != today && dates.first != yesterday) {
      return 0;
    }
    
    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i+1]).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        break;
      }
    }
    return streak;
  }

  /// Calcula la racha mÃ¡s larga del hÃ¡bito
  int getHabitLongestStreak(String habitId) {
    final logs = _allLogs.where((l) => l.habitId == habitId).toList();
    if (logs.isEmpty) return 0;
    
    final dates = logs.map((l) => DateTime(l.completedAt.year, l.completedAt.month, l.completedAt.day))
                      .toSet()
                      .toList()
                      ..sort((a, b) => b.compareTo(a));
                      
    int longest = 1;
    int current = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i+1]).inDays;
      if (diff == 1) {
        current++;
      } else if (diff > 1) {
        if (current > longest) {
          longest = current;
        }
        current = 1;
      }
    }
    return current > longest ? current : longest;
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
    _allLogs = [];
    _currentHabitLogs = [];
    _loadingState = LoadingState.idle;
    _errorMessage = null;
    _selectedHabitId = null;
    notifyListeners();
  }
}

