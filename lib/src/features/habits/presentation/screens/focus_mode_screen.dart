import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/habit.dart';
import '../notifiers/habits_notifier.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> with TickerProviderStateMixin {
  Habit? _selectedHabit;
  bool _isRunning = false;
  int _secondsLeft = 1500; // 25 minutes by default
  Timer? _timer;
  
  late AnimationController _pulsingController;

  @override
  void initState() {
    super.initState();
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

  void _toggleTimer() {
    setState(() {
      if (_isRunning) {
        _timer?.cancel();
        _pulsingController.stop();
        _isRunning = false;
      } else {
        _isRunning = true;
        _pulsingController.repeat(reverse: true);
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (_secondsLeft > 0) {
              _secondsLeft--;
            } else {
              _timer?.cancel();
              _pulsingController.stop();
              _isRunning = false;
              _showCompletionDialog();
            }
          });
        });
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _pulsingController.stop();
    setState(() {
      _isRunning = false;
      _secondsLeft = 1500;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        title: const Text('¡Sesión Completada!', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        content: Text(
          _selectedHabit != null 
              ? 'Felicidades, completaste tu sesión de enfoque para "${_selectedHabit!.title}".'
              : 'Felicidades, completaste tu sesión de enfoque.',
          style: const TextStyle(color: AppTheme.onSurfaceVariant, fontFamily: 'Inter'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_selectedHabit != null) {
                // Complete habit
                context.read<HabitsNotifier>().completeHabit(
                  habitId: _selectedHabit!.id,
                  confidenceLevel: 'trust_me',
                  notes: 'Completado mediante sesión de enfoque.',
                  token: 'offline_token',
                );
              }
              Navigator.pop(context); // Close focus screen
            },
            child: const Text('Registrar Hábito'),
          )
        ],
      ),
    );
  }

  String _formatTime() {
    final int minutes = _secondsLeft ~/ 60;
    final int seconds = _secondsLeft % 60;
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
        title: const Text('Enfoque Habitü', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background ambient elements
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: MediaQuery.of(context).size.width * 0.2,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                CurvedAnimation(parent: _pulsingController, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.04),
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Habit dropdown selector
                if (activeHabits.isNotEmpty) ...[
                  DropdownButtonFormField<Habit>(
                    value: _selectedHabit,
                    decoration: const InputDecoration(
                      labelText: 'Enfocar en Hábito',
                      filled: true,
                    ),
                    dropdownColor: AppTheme.surfaceContainerHigh,
                    items: activeHabits.map((h) {
                      return DropdownMenuItem(
                        value: h,
                        child: Text('${h.icon ?? "🎯"} ${h.title}', style: const TextStyle(fontFamily: 'Inter')),
                      );
                    }).toList(),
                    onChanged: _isRunning ? null : (val) {
                      setState(() {
                        _selectedHabit = val;
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                ],

                const Spacer(),

                // Pulsing timer ring
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ring
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: _secondsLeft / 1500,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.04),
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      // Time Text
                      Column(
                        children: [
                          Text(
                            _formatTime(),
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 54,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isRunning ? 'SESIÓN ACTIVA' : 'PAUSADO',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.5,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Action Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Reset Button
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 28),
                      onPressed: _resetTimer,
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: AppTheme.surfaceContainer,
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Play/Pause Button
                    GestureDetector(
                      onTap: _toggleTimer,
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
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
