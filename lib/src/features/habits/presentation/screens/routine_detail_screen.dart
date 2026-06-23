import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/android_widget_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/routine.dart';
import '../notifiers/habits_notifier.dart';
import '../notifiers/progress_hub_notifier.dart';
import '../widgets/routine_editor_sheet.dart';

class RoutineDetailScreen extends StatefulWidget {
  final String routineId;

  const RoutineDetailScreen({
    super.key,
    required this.routineId,
  });

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  Future<void> _refreshRoutineState() async {
    await context.read<HabitsNotifier>().loadHabits(token: 'offline_token');
    await context.read<ProgressHubNotifier>().initialize();
    await context.read<ProgressHubNotifier>().loadRoutineDetail(widget.routineId);

    final habitsNotifier = context.read<HabitsNotifier>();
    final progressNotifier = context.read<ProgressHubNotifier>();
    final habits = habitsNotifier.habitsForSelectedDate;
    final completedCount = habits
        .where((habit) => habitsNotifier.getCompletionLogForHabit(habit.id, habitsNotifier.selectedDate) != null)
        .length;
    final pendingHabits = habits
        .where((habit) => habitsNotifier.getCompletionLogForHabit(habit.id, habitsNotifier.selectedDate) == null)
        .toList();
    final activeRoutine = progressNotifier.getRoutineForNow(DateTime.now());

    await AndroidWidgetService().updateTodaySummary(
      completedCount: completedCount,
      totalCount: habits.length,
      routineId: activeRoutine?.id,
      routineTitle: activeRoutine?.title,
      pendingHabitId: pendingHabits.isEmpty ? null : pendingHabits.first.id,
      pendingHabitTitle: pendingHabits.isEmpty ? null : pendingHabits.first.title,
    );
  }

  Future<void> _toggleRoutineHabitCompletion(RoutineDetail routine, String habitId) async {
    final habitsNotifier = context.read<HabitsNotifier>();
    final progressNotifier = context.read<ProgressHubNotifier>();
    final routineHabit = routine.habits.firstWhere((item) => item.habitId == habitId);

    if (routineHabit.isCompletedToday) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este hábito ya está marcado hoy. Para editar el detalle entra al hábito.'),
        ),
      );
      return;
    }

    await habitsNotifier.completeHabit(
      habitId: habitId,
      confidenceLevel: 'trust_me',
      notes: 'Completado desde la rutina "${routine.title}".',
      token: 'offline_token',
    );
    await progressNotifier.loadRoutineDetail(widget.routineId);
    await _refreshRoutineState();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProgressHubNotifier>().loadRoutineDetail(widget.routineId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProgressHubNotifier>();
    final routine = notifier.selectedRoutine;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de rutina'),
        actions: [
          IconButton(
            onPressed: routine == null
                ? null
                : () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => RoutineEditorSheet(
                        routineId: routine.id,
                        initialTitle: routine.title,
                        initialDescription: routine.description,
                        initialTimeOfDay: routine.timeOfDay,
                        initialAnchorTime: routine.anchorTime,
                        initialDaysOfWeek: routine.daysOfWeek,
                      ),
                    );
                    if (context.mounted) await _refreshRoutineState();
                  },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: routine == null
                ? null
                : () async {
                    await notifier.deleteRoutine(routine.id);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: routine == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if ((routine.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          routine.description!,
                          style: const TextStyle(color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'Momento: ${routine.timeOfDay} · Días: ${routine.daysOfWeek.join(', ')}',
                        style: const TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      'Hábitos de la rutina',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _openAssignHabitSheet(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (routine.habits.isEmpty)
                  const _RoutineEmptyState()
                else
                  ...routine.habits.map((habit) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 42,
                            decoration: BoxDecoration(
                              color:
                                  Color(int.parse(habit.colorHex.replaceAll('#', '0xFF'))),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(habit.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                if ((habit.description ?? '').isNotEmpty)
                                  Text(
                                    habit.description!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _toggleRoutineHabitCompletion(routine, habit.habitId),
                            icon: Icon(
                              habit.isCompletedToday
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: habit.isCompletedToday
                                  ? Colors.greenAccent
                                  : AppTheme.onSurfaceVariant,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await notifier.removeHabitFromRoutine(
                                routineId: routine.id,
                                habitId: habit.habitId,
                              );
                              await _refreshRoutineState();
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }

  Future<void> _openAssignHabitSheet(BuildContext context) async {
    final notifier = context.read<ProgressHubNotifier>();
    final habits = await notifier.getActiveHabitsSnapshot();
    final routine = notifier.selectedRoutine;
    if (!context.mounted || routine == null) return;

    final existingHabitIds = routine.habits.map((habit) => habit.habitId).toSet();
    final available = habits.where((habit) => !existingHabitIds.contains(habit.id)).toList();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignHabitSheet(
        routineId: routine.id,
        availableHabits: available,
      ),
    );
    if (!context.mounted) return;
    await _refreshRoutineState();
  }
}

class _AssignHabitSheet extends StatelessWidget {
  final String routineId;
  final List<Habit> availableHabits;

  const _AssignHabitSheet({
    required this.routineId,
    required this.availableHabits,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<ProgressHubNotifier>();
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: availableHabits.isEmpty
            ? const _RoutineEmptyState()
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Agregar hábito',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: availableHabits.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final habit = availableHabits[index];
                        return ListTile(
                          tileColor: AppTheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(habit.title),
                          subtitle: Text(habit.description ?? 'Sin descripción'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () async {
                              await notifier.assignHabitToRoutine(
                                routineId: routineId,
                                habitId: habit.id,
                                sortOrder: index,
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _RoutineEmptyState extends StatelessWidget {
  const _RoutineEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text(
        'No hay hábitos en esta rutina todavía. Agrégales algunos para convertirla en un bloque útil.',
        style: TextStyle(color: AppTheme.onSurfaceVariant),
      ),
    );
  }
}
