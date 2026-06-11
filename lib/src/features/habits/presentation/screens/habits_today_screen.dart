import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/habit.dart';
import '../notifiers/habits_notifier.dart';
import 'package:habitu/src/features/onboarding/presentation/notifiers/onboarding_notifier.dart';
import '../widgets/habit_creator_sheet.dart';
import '../widgets/habit_detail_sheet.dart';
import '../widgets/completion_confirmation_sheet.dart';
import '../widgets/sync_status_card.dart';
import 'focus_mode_screen.dart';

class HabitsTodayScreen extends StatefulWidget {
  const HabitsTodayScreen({super.key});

  @override
  State<HabitsTodayScreen> createState() => _HabitsTodayScreenState();
}

class _HabitsTodayScreenState extends State<HabitsTodayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitsNotifier>().loadHabits(token: 'offline_token');
    });
  }

  // Helper to get 7 days of the current week centered around selectedDate
  List<DateTime> _getCurrentWeekDays(DateTime selectedDate) {
    // Find Monday of this week
    final int currentWeekday = selectedDate.weekday;
    final DateTime monday = selectedDate.subtract(Duration(days: currentWeekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final habitsNotifier = context.watch<HabitsNotifier>();
    final onboardingNotifier = context.watch<OnboardingNotifier>();
    
    final selectedDate = habitsNotifier.selectedDate;
    final weekDays = _getCurrentWeekDays(selectedDate);
    final activeUser = onboardingNotifier.user;
    
    final habits = habitsNotifier.habitsForSelectedDate;
    final totalHabits = habits.length;
    final completedCount = habits.where((h) => habitsNotifier.getCompletionLogForHabit(h.id, selectedDate) != null).length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Greeting + User Identity + Sync Status)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${activeUser?.fullName.split(" ").first ?? "Estudiante"}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalHabits == 0 
                              ? 'No tienes metas registradas hoy.'
                              : 'Hoy tienes $totalHabits ${totalHabits == 1 ? "meta" : "metas"}. $completedCount completadas.',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Sync card in header
                  const SyncStatusCard(),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Focus Mode Quick Link
              if (totalHabits > 0) ...[
                GestureDetector(
                  onTap: () {
                    // Navigate to Focus Mode Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FocusModeScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.12),
                          AppTheme.tertiaryColor.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Iniciar sesión de Deep Focus',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: AppTheme.primaryColor, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 3. Horizontal Calendar Weekly Picker
              SizedBox(
                height: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: weekDays.map((day) {
                    final isSelected = day.day == selectedDate.day &&
                        day.month == selectedDate.month &&
                        day.year == selectedDate.year;
                    final isToday = day.day == DateTime.now().day &&
                        day.month == DateTime.now().month &&
                        day.year == DateTime.now().year;

                    final List<String> weekDayLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                    final dayLetter = weekDayLetters[day.weekday - 1];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          habitsNotifier.selectDate(day);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppTheme.primaryColor.withOpacity(0.15) 
                                : isToday 
                                    ? AppTheme.surfaceContainerHighest.withOpacity(0.5)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                  ? AppTheme.primaryColor 
                                  : isToday 
                                      ? AppTheme.outline.withOpacity(0.5)
                                      : Colors.white.withOpacity(0.05),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayLetter,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isSelected ? AppTheme.primaryColor : AppTheme.onSurfaceVariant,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                day.day.toString(),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppTheme.primaryColor : AppTheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Habits List
              Expanded(
                child: habitsNotifier.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    : totalHabits == 0
                        ? _buildEmptyState(context)
                        : ListView.separated(
                            itemCount: habits.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, idx) {
                              final habit = habits[idx];
                              final isCompleted = habitsNotifier.getCompletionLogForHabit(habit.id, selectedDate) != null;
                              return _buildHabitCard(context, habit, isCompleted, habitsNotifier);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Sheet A: Habit Creator
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const HabitCreatorSheet(),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  // Habit Item Card with swipe actions
  Widget _buildHabitCard(BuildContext context, Habit habit, bool isCompleted, HabitsNotifier notifier) {
    final parsedColor = Color(int.parse(habit.colorHex.replaceAll('#', '0xFF')));
    final currentStreak = notifier.getHabitCurrentStreak(habit.id);

    return Dismissible(
      key: Key(habit.id),
      direction: isCompleted ? DismissDirection.none : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right to complete -> Open Sheet D (Completion Confirmation)
          final result = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => CompletionConfirmationSheet(habit: habit),
          );
          if (result != null && result['complete'] == true) {
            await notifier.completeHabit(
              habitId: habit.id,
              confidenceLevel: result['evidence'] == true ? 'photo' : 'trust_me',
              notes: result['notes'],
              token: 'offline_token',
            );
            return false; // Return false so the card snaps back and rebuilds as completed
          }
        } else if (direction == DismissDirection.endToStart) {
          // Swipe left to edit/delete
          _showHabitOptions(context, habit, notifier);
        }
        return false; // Don't dismiss instantly
      },
      background: Container(
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: AppTheme.tertiaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.tertiaryColor.withOpacity(0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.tertiaryColor, size: 28),
            SizedBox(width: 12),
            Text(
              'Completar Hábito...',
              style: TextStyle(
                color: AppTheme.tertiaryColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            )
          ],
        ),
      ),
      secondaryBackground: Container(
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Opciones rápidas...',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.more_horiz, color: AppTheme.errorColor, size: 28),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          // Sheet B: Habit Detail & Streak
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => HabitDetailSheet(habit: habit),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isCompleted ? AppTheme.surfaceContainerLow.withOpacity(0.5) : AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isCompleted 
                  ? AppTheme.tertiaryColor.withOpacity(0.3) 
                  : Colors.white.withOpacity(0.04),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Icon Circle
              CircleAvatar(
                backgroundColor: parsedColor.withOpacity(0.12),
                radius: 26,
                child: Text(
                  habit.icon ?? '🎯',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppTheme.onSurfaceVariant : AppTheme.onSurface,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          habit.frequencyType == 'daily' ? 'Diario' : 'Frecuente',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                        ),
                        if (currentStreak > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '🔥 $currentStreak días',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              // Completion Checkmark Indicator
              if (isCompleted)
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppTheme.tertiaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: AppTheme.onTertiary, size: 18),
                )
              else
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.outline.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Quick edit/delete bottom sheet
  void _showHabitOptions(BuildContext context, Habit habit, HabitsNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                habit.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
                title: const Text('Editar Hábito', style: TextStyle(fontFamily: 'Inter')),
                onTap: () {
                  Navigator.pop(context);
                  // Open edit view
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => HabitCreatorSheet(habit: habit),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                title: const Text('Eliminar Hábito', style: TextStyle(fontFamily: 'Inter')),
                onTap: () async {
                  Navigator.pop(context);
                  // Trigger delete confirmation dialogue
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      title: const Text('¿Eliminar Hábito?', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                      content: Text(
                        'Esta acción detendrá tu racha de este hábito, pero conservaremos tu progreso histórico.',
                        style: TextStyle(color: AppTheme.onSurfaceVariant, fontFamily: 'Inter'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar', style: TextStyle(color: AppTheme.outline)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: AppTheme.onError),
                          child: const Text('Eliminar'),
                        )
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await notifier.deleteHabit(habitId: habit.id, token: 'offline_token');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceContainerLow,
            ),
            child: Icon(
              Icons.assignment_turned_in_outlined,
              size: 64,
              color: AppTheme.outline.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Comienza tu Disciplina',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'No tienes hábitos para el día de hoy. Agrega uno pulsando el botón +.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
