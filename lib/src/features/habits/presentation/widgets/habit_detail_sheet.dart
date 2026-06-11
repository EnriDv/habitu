import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/habit.dart';
import '../notifiers/habits_notifier.dart';
import 'habit_creator_sheet.dart';
import '../../../../core/services/notification_service.dart';

class HabitDetailSheet extends StatefulWidget {
  final Habit habit;

  const HabitDetailSheet({super.key, required this.habit});

  @override
  State<HabitDetailSheet> createState() => _HabitDetailSheetState();
}

class _HabitDetailSheetState extends State<HabitDetailSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitsNotifier>().loadHabitLogs(
        habitId: widget.habit.id,
        token: 'offline_token',
      );
    });
  }

  // Helper to calculate days in the current month
  int _daysInMonth(DateTime date) {
    var firstDayNextMonth = DateTime(date.year, date.month + 1, 1);
    return firstDayNextMonth.subtract(const Duration(days: 1)).day;
  }

  @override
  Widget build(BuildContext context) {
    final habitsNotifier = context.watch<HabitsNotifier>();
    final habit = habitsNotifier.habits.firstWhere((h) => h.id == widget.habit.id, orElse: () => widget.habit);
    
    final currentStreak = habitsNotifier.getHabitCurrentStreak(habit.id);
    final longestStreak = habitsNotifier.getHabitLongestStreak(habit.id);
    final totalSessions = habitsNotifier.currentHabitLogs.length;

    // Monthly calendar generation
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final totalDays = _daysInMonth(now);
    final startOffset = firstDay.weekday - 1; // 0 for Monday, 6 for Sunday

    final color = Color(int.parse(habit.colorHex.replaceAll('#', '0xFF')));

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(habit.title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => HabitCreatorSheet(habit: habit),
                );
              },
            )
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header stats
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.03)),
                    ),
                    child: Column(
                      children: [
                        const Text('🔥 Racha Activa', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, fontFamily: 'Inter')),
                        const SizedBox(height: 6),
                        Text('$currentStreak días', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.03)),
                    ),
                    child: Column(
                      children: [
                        const Text('👑 Racha Máxima', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant, fontFamily: 'Inter')),
                        const SizedBox(height: 6),
                        Text('$longestStreak días', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Monthly grid calendar title
            Text(
              'Consistencia este mes',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Calendar Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.03)),
              ),
              child: Column(
                children: [
                  // Week day labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['L', 'M', 'M', 'J', 'V', 'S', 'D'].map((label) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Grid View of Month Days
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: totalDays + startOffset,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemBuilder: (context, idx) {
                      if (idx < startOffset) {
                        return const SizedBox.shrink();
                      }
                      
                      final dayNum = idx - startOffset + 1;
                      final dayDate = DateTime(now.year, now.month, dayNum);
                      final isCompleted = habitsNotifier.getCompletionLogForHabit(habit.id, dayDate) != null;
                      
                      return Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppTheme.tertiaryColor.withOpacity(0.2)
                                : Colors.transparent,
                            border: Border.all(
                              color: isCompleted
                                  ? AppTheme.tertiaryColor
                                  : Colors.white.withOpacity(0.05),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            dayNum.toString(),
                            style: TextStyle(
                              color: isCompleted ? AppTheme.tertiaryColor : AppTheme.onSurface,
                              fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Evidence photo gallery (Mock/Ethereal visual)
            Text(
              'Evidencia fotográfica',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              height: 120,
              child: totalSessions == 0
                  ? Center(
                      child: Text(
                        'Sin fotos registradas aún.',
                        style: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.5), fontFamily: 'Inter'),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: totalSessions,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, idx) {
                        final log = habitsNotifier.currentHabitLogs[idx];
                        final hasPhoto = log.confidenceLevel == 'photo';
                        
                        return Container(
                          width: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                            image: hasPhoto 
                                ? const DecorationImage(
                                    image: NetworkImage('https://images.unsplash.com/photo-1506784983877-45594efa4cbe?auto=format&fit=crop&q=80&w=200'),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${log.completedAt.day}/${log.completedAt.month}',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'Inter'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    title: const Text('¿Eliminar Hábito?', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                    content: const Text(
                      'Esta acción detendrá tu racha de este hábito, pero conservaremos tu progreso histórico.',
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontFamily: 'Inter'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancelar', style: TextStyle(color: AppTheme.outline)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: AppTheme.onError),
                        child: const Text('Eliminar'),
                      )
                    ],
                  ),
                );
                if (confirm == true) {
                  if (context.mounted) {
                    await context.read<HabitsNotifier>().deleteHabit(habitId: habit.id, token: 'offline_token');
                    await NotificationService().cancelHabitNotification(habit.id);
                    Navigator.pop(context);
                  }
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar Hábito'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorContainer.withOpacity(0.2),
                foregroundColor: AppTheme.errorColor,
                side: BorderSide(color: AppTheme.errorColor.withOpacity(0.2)),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
