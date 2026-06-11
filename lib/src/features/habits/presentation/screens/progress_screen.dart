import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/habit.dart';
import '../notifiers/habits_notifier.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  // Helper to check completions count for a specific date across all habits
  int _getCompletionsForDate(HabitsNotifier notifier, DateTime date) {
    int count = 0;
    for (final habit in notifier.activeHabits) {
      if (notifier.getCompletionLogForHabit(habit.id, date) != null) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final habitsNotifier = context.watch<HabitsNotifier>();
    final activeHabits = habitsNotifier.activeHabits;

    // 1. Calculate Maximum Active Streak across all habits
    int maxActiveStreak = 0;
    for (final h in activeHabits) {
      final streak = habitsNotifier.getHabitCurrentStreak(h.id);
      if (streak > maxActiveStreak) {
        maxActiveStreak = streak;
      }
    }

    // 2. Calculate Weekly Success Rate
    // completions in the last 7 days vs potential completions (total habits * 7)
    double weeklySuccessRate = 0.0;
    int totalCompletionsLastWeek = 0;
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      totalCompletionsLastWeek += _getCompletionsForDate(habitsNotifier, date);
    }
    final int maxPotential = activeHabits.length * 7;
    if (maxPotential > 0) {
      weeklySuccessRate = totalCompletionsLastWeek / maxPotential;
    }

    // 3. Find Strongest Habit (the one with the most completions in memory)
    Habit? strongestHabit;
    int maxCompletions = 0;
    // We can infer completions counts from habitsNotifier logs if available
    // For now we count logs in notifier.
    for (final h in activeHabits) {
      // Since notifier has logs of selected habit, we can fallback or query
      // but let's count from the local logs in habitsNotifier if available,
      // or compute it based on streaks. Let's find the one with longest streak!
      final streak = habitsNotifier.getHabitLongestStreak(h.id);
      if (streak > maxCompletions) {
        maxCompletions = streak;
        strongestHabit = h;
      }
    }

    // 4. Most Productive Day (Mock/Calculated)
    // In production, we'd group logs by weekday. For now we use Wednesday as classic brief.
    const String productiveDay = 'Miércoles';

    // 5. Heatmap Dates (5 rows x 24 columns = 120 cells representing last 120 days)
    final List<DateTime> heatmapDates = [];
    final today = DateTime(now.year, now.month, now.day);
    // Grid: 24 columns, 5 rows. We generate dates backwards.
    for (int col = 23; col >= 0; col--) {
      for (int row = 4; row >= 0; row--) {
        final daysAgo = col * 5 + row;
        heatmapDates.add(today.subtract(Duration(days: daysAgo)));
      }
    }
    // Sort chronological for left-to-right rendering
    heatmapDates.sort((a, b) => a.compareTo(b));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progreso Analítico', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          // Header description
          Text(
            'Tu evolución académica en datos',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Bento Grid items
          // Focal Streak Card
          Container(
            padding: const EdgeInsets.all(24),
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryContainer.withOpacity(0.9),
                  AppTheme.surfaceColor.withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.06),
                  blurRadius: 32,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔥 RACHA MÁXIMA ACTIVA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        letterSpacing: 1.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$maxActiveStreak',
                          style: const TextStyle(
                            fontSize: 54,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Días',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  maxActiveStreak == 0 
                      ? 'Inicia y completa hábitos hoy para comenzar tu racha.'
                      : '¡Excelente ritmo! Sigue así para romper tu récord semestral.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weekly rate card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: Row(
              children: [
                // Circular success rate
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 76,
                      height: 76,
                      child: CircularProgressIndicator(
                        value: weeklySuccessRate,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        color: AppTheme.tertiaryColor,
                      ),
                    ),
                    Text(
                      '${(weeklySuccessRate * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.tertiaryColor,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tasa de Éxito Semanal',
                        style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completaste $totalCompletionsLastWeek de $maxPotential metas posibles esta semana.',
                        style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Consistency Heatmap Card
          Text(
            'Mapa de Consistencia',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Últimos 120 días', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, fontFamily: 'Inter')),
                    Row(
                      children: [
                        const Text('Menos ', style: TextStyle(fontSize: 10, color: AppTheme.outline, fontFamily: 'Inter')),
                        ...List.generate(5, (idx) {
                          Color cellColor = AppTheme.surfaceContainerLow;
                          if (idx == 1) cellColor = AppTheme.primaryColor.withOpacity(0.2);
                          if (idx == 2) cellColor = AppTheme.primaryColor.withOpacity(0.5);
                          if (idx == 3) cellColor = AppTheme.primaryColor.withOpacity(0.8);
                          if (idx == 4) cellColor = AppTheme.primaryColor;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                        const Text(' Más', style: TextStyle(fontSize: 10, color: AppTheme.outline, fontFamily: 'Inter')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Grid render
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: heatmapDates.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 24, // 24 columns
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (context, idx) {
                    final date = heatmapDates[idx];
                    final comps = _getCompletionsForDate(habitsNotifier, date);
                    
                    Color cellColor = AppTheme.surfaceContainerLow;
                    if (comps == 1) cellColor = AppTheme.primaryColor.withOpacity(0.2);
                    if (comps == 2) cellColor = AppTheme.primaryColor.withOpacity(0.5);
                    if (comps == 3) cellColor = AppTheme.primaryColor.withOpacity(0.8);
                    if (comps >= 4) cellColor = AppTheme.primaryColor;

                    return Tooltip(
                      message: '${date.day}/${date.month}: $comps completado(s)',
                      child: Container(
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats list
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.03)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star_outline, color: AppTheme.primaryColor),
                      const SizedBox(height: 12),
                      const Text(
                        'HÁBITO FUERTE',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.0, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        strongestHabit?.title ?? 'Ninguno',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strongestHabit != null ? 'Racha: $maxCompletions d' : 'Sin datos',
                        style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.03)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppTheme.secondaryColor),
                      const SizedBox(height: 12),
                      const Text(
                        'DÍA PRODUCTIVO',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant, letterSpacing: 1.0, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        productiveDay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Pico 18:00 - 20:00',
                        style: TextStyle(fontSize: 11, color: AppTheme.secondaryColor, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
