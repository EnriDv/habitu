import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/habit.dart';
import '../notifiers/habits_notifier.dart';
import '../notifiers/progress_hub_notifier.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen>
    with TickerProviderStateMixin {
  static const List<int> _presetDurations = [15, 25, 45, 60];

  Habit? _selectedHabit;
  bool _isRunning = false;
  int _durationMinutes = 25;
  late int _secondsLeft;
  Timer? _timer;
  late final AnimationController _pulsingController;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _durationMinutes * 60;
    _pulsingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulsingController.dispose();
    super.dispose();
  }

  double get _progress {
    final totalSeconds = _durationMinutes * 60;
    if (totalSeconds <= 0) return 0;
    return _secondsLeft / totalSeconds;
  }

  Future<void> _showDurationPicker() async {
    if (_isRunning) return;

    double draftMinutes = _durationMinutes.toDouble();
    final selectedMinutes = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Duración del enfoque',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${draftMinutes.round()} minutos',
                      style: const TextStyle(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Slider(
                      min: 5,
                      max: 120,
                      divisions: 23,
                      value: draftMinutes,
                      onChanged: (value) {
                        setSheetState(() {
                          draftMinutes = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(draftMinutes.round()),
                        child: const Text('Usar este tiempo'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selectedMinutes == null) return;
    _applyDuration(selectedMinutes);
  }

  void _applyDuration(int minutes) {
    _timer?.cancel();
    _pulsingController.stop();
    setState(() {
      _durationMinutes = minutes;
      _secondsLeft = minutes * 60;
      _isRunning = false;
    });
  }

  void _toggleTimer() {
    if (_selectedHabit == null) return;

    setState(() {
      if (_isRunning) {
        _timer?.cancel();
        _pulsingController.stop();
        _isRunning = false;
        return;
      }

      _isRunning = true;
      _pulsingController.repeat(reverse: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_secondsLeft > 0) {
            _secondsLeft--;
            return;
          }

          _timer?.cancel();
          _pulsingController.stop();
          _isRunning = false;
          _showCompletionDialog();
        });
      });
    });
  }

  void _resetTimer() {
    _applyDuration(_durationMinutes);
  }

  Future<void> _showCompletionDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        title: const Text(
          'Sesión completada',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          _selectedHabit != null
              ? 'Terminaste tu bloque de enfoque para "${_selectedHabit!.title}". ¿Quieres registrarlo como completado?'
              : 'Terminaste tu bloque de enfoque.',
          style: const TextStyle(color: AppTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (_selectedHabit == null) return;

              await context.read<HabitsNotifier>().completeHabit(
                    habitId: _selectedHabit!.id,
                    confidenceLevel: 'trust_me',
                    notes: 'Completado mediante sesión de enfoque.',
                    token: 'offline_token',
                  );
              await context.read<ProgressHubNotifier>().initialize();

              if (!mounted) return;
              Navigator.of(context).pop();
            },
            child: const Text('Registrar hábito'),
          ),
        ],
      ),
    );
  }

  String _formatTime() {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final habitsNotifier = context.watch<HabitsNotifier>();
    final activeHabits = habitsNotifier.activeHabits;

    if (_selectedHabit == null && activeHabits.isNotEmpty) {
      _selectedHabit = activeHabits.first;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Enfoque Habitu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          children: [
            if (activeHabits.isNotEmpty) ...[
              DropdownButtonFormField<Habit>(
                value: _selectedHabit,
                decoration: const InputDecoration(
                  labelText: 'Enfocar en hábito',
                  filled: true,
                ),
                dropdownColor: AppTheme.surfaceContainerHigh,
                items: activeHabits.map((habit) {
                  return DropdownMenuItem<Habit>(
                    value: habit,
                    child: Text('${habit.icon ?? '🎯'} ${habit.title}'),
                  );
                }).toList(),
                onChanged: _isRunning
                    ? null
                    : (habit) {
                        setState(() {
                          _selectedHabit = habit;
                        });
                      },
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _presetDurations.map((minutes) {
                      return ChoiceChip(
                        label: Text('$minutes min'),
                        selected: _durationMinutes == minutes,
                        onSelected: _isRunning
                            ? null
                            : (_) => _applyDuration(minutes),
                      );
                    }).toList(),
                  ),
                ),
                TextButton.icon(
                  onPressed: _showDurationPicker,
                  icon: const Icon(Icons.tune),
                  label: const Text('Configurar'),
                ),
              ],
            ),
            const Spacer(),
            Expanded(
              flex: 4,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(begin: 1, end: 1.08).animate(
                          CurvedAnimation(
                            parent: _pulsingController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: 0.88,
                          heightFactor: 0.88,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor.withOpacity(0.05),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 10,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(),
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  fontSize: 54,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isRunning ? 'SESION ACTIVA' : 'PAUSADO',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  letterSpacing: 1.5,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh, size: 28),
                  onPressed: _resetTimer,
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: AppTheme.surfaceContainer,
                  ),
                ),
                const SizedBox(width: 32),
                GestureDetector(
                  onTap: activeHabits.isEmpty ? null : _toggleTimer,
                  child: Opacity(
                    opacity: activeHabits.isEmpty ? 0.5 : 1,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause : Icons.play_arrow,
                        color: AppTheme.onPrimary,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (activeHabits.isEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Crea al menos un hábito para iniciar una sesión de enfoque.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
