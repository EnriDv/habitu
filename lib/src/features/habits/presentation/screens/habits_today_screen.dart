import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/android_widget_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/presentation/notifiers/session_onboarding_notifier.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_template_models.dart';
import '../../domain/entities/routine.dart';
import '../notifiers/habits_notifier.dart';
import '../notifiers/progress_hub_notifier.dart';
import '../widgets/completion_confirmation_sheet.dart';
import '../widgets/habit_creator_sheet.dart';
import '../widgets/habit_detail_sheet.dart';
import '../widgets/routine_editor_sheet.dart';
import '../widgets/sync_status_card.dart';
import 'focus_mode_screen.dart';
import 'recommendations_screen.dart';
import 'routine_detail_screen.dart';

class HabitsTodayScreen extends StatefulWidget {
  const HabitsTodayScreen({super.key});

  @override
  State<HabitsTodayScreen> createState() => _HabitsTodayScreenState();
}

class _HabitsTodayScreenState extends State<HabitsTodayScreen> {
  String? _lastWidgetSignature;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDashboardState(context);
    });
  }

  Future<void> _refreshDashboardState(BuildContext context) async {
    await context.read<HabitsNotifier>().loadHabits(token: 'offline_token');
    await context.read<ProgressHubNotifier>().initialize();
  }

  List<DateTime> _getCurrentWeekDays(DateTime selectedDate) {
    final monday = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  Future<void> _completeHabit(
    BuildContext context,
    Habit habit,
    HabitsNotifier notifier,
  ) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CompletionConfirmationSheet(habit: habit),
    );
    if (result == null || result['complete'] != true) return;

    final completed = await notifier.completeHabit(
      habitId: habit.id,
      confidenceLevel: result['evidence'] == true ? 'photo' : 'trust_me',
      notes: result['notes'] as String?,
      photoPath: result['photoPath'] as String?,
      token: 'offline_token',
    );
    if (!completed || !context.mounted) return;
    await context.read<ProgressHubNotifier>().initialize();
  }

  Future<void> _showCreateMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Qué quieres crear?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.checklist_rounded, color: AppTheme.onPrimary),
                ),
                title: const Text('Hábito'),
                subtitle: const Text('Crear una meta individual.'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const HabitCreatorSheet(),
                  );
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.tertiaryColor.withOpacity(0.2),
                  child: const Icon(Icons.layers_outlined, color: AppTheme.tertiaryColor),
                ),
                title: const Text('Rutina'),
                subtitle: const Text('Agrupar varios hábitos en un bloque.'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const RoutineEditorSheet(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncWidget({
    required List<Habit> habits,
    required HabitsNotifier habitsNotifier,
    required RoutineSummary? activeRoutine,
  }) {
    final selectedDate = habitsNotifier.selectedDate;
    final completedCount = habits
        .where((habit) => habitsNotifier.getCompletionLogForHabit(habit.id, selectedDate) != null)
        .length;
    final pendingHabits = habits
        .where((habit) => habitsNotifier.getCompletionLogForHabit(habit.id, selectedDate) == null)
        .toList();

    final widgetSignature = [
      completedCount,
      habits.length,
      activeRoutine?.id ?? '',
      pendingHabits.isEmpty ? '' : pendingHabits.first.id,
    ].join('|');

    if (_lastWidgetSignature == widgetSignature) return;
    _lastWidgetSignature = widgetSignature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AndroidWidgetService().updateTodaySummary(
        completedCount: completedCount,
        totalCount: habits.length,
        routineId: activeRoutine?.id,
        routineTitle: activeRoutine?.title,
        pendingHabitId: pendingHabits.isEmpty ? null : pendingHabits.first.id,
        pendingHabitTitle: pendingHabits.isEmpty ? null : pendingHabits.first.title,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final habitsNotifier = context.watch<HabitsNotifier>();
    final onboardingNotifier = context.watch<OnboardingNotifier>();
    final progressHubNotifier = context.watch<ProgressHubNotifier>();

    final selectedDate = habitsNotifier.selectedDate;
    final weekDays = _getCurrentWeekDays(selectedDate);
    final activeUser = onboardingNotifier.user;
    final activeRoutine = progressHubNotifier.getRoutineForNow(DateTime.now());
    final topRecommendation = progressHubNotifier.recommendations.isEmpty
        ? null
        : progressHubNotifier.recommendations.first;
    final routines = progressHubNotifier.routines;
    final templateHighlights = progressHubNotifier.templates.take(3).toList();
    final habits = habitsNotifier.habitsForSelectedDate;
    final totalHabits = habits.length;
    final completedCount = habits
        .where((habit) => habitsNotifier.getCompletionLogForHabit(habit.id, selectedDate) != null)
        .length;

    _syncWidget(
      habits: habits,
      habitsNotifier: habitsNotifier,
      activeRoutine: activeRoutine,
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refreshDashboardState(context),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${activeUser?.fullName.split(' ').first ?? 'Usuario'}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          totalHabits == 0
                              ? 'No tienes metas registradas hoy.'
                              : 'Hoy tienes $totalHabits ${totalHabits == 1 ? 'meta' : 'metas'}. $completedCount completadas.',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SyncStatusCard(),
                ],
              ),
              if (habitsNotifier.errorMessage != null) ...[
                const SizedBox(height: 16),
                _InlineNotice(
                  text:
                      'Tuvimos un problema al refrescar la vista, pero tus datos locales siguen seguros. ${habitsNotifier.errorMessage!}',
                ),
              ],
              const SizedBox(height: 20),
              if (totalHabits > 0) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const FocusModeScreen(),
                      ),
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
                          'Iniciar sesión de enfoque',
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
                const SizedBox(height: 14),
              ],
              if (activeRoutine != null) ...[
                _TodayInfoCard(
                  icon: Icons.layers_outlined,
                  accent: AppTheme.primaryColor,
                  title: 'Rutina activa',
                  subtitle:
                      '${activeRoutine.title} · ${activeRoutine.completedCount}/${activeRoutine.habitCount} completados',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RoutineDetailScreen(routineId: activeRoutine.id),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],
              if (topRecommendation != null) ...[
                _TodayInfoCard(
                  icon: Icons.auto_awesome_outlined,
                  accent: AppTheme.tertiaryColor,
                  title: 'Sugerencia para hoy',
                  subtitle: '${topRecommendation.title} · ${topRecommendation.reason}',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RecommendationsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],
              FutureBuilder<Map<String, TimeOfDay>>(
                future: NotificationService().getAllHabitReminders(),
                builder: (context, snapshot) {
                  final reminders = snapshot.data ?? const <String, TimeOfDay>{};
                  return _TodayInfoCard(
                    icon: Icons.notifications_active_outlined,
                    accent: const Color(0xFFFFB703),
                    title: 'Recordatorios',
                    subtitle: reminders.isEmpty
                        ? 'No tienes recordatorios activos.'
                        : '${reminders.length} hábitos con recordatorio activo.',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            reminders.isEmpty
                                ? 'Todavía no tienes recordatorios activos.'
                                : 'Puedes editar cada recordatorio entrando al hábito correspondiente.',
                          ),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 72,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: weekDays.map((day) {
                    final isSelected = day.year == selectedDate.year &&
                        day.month == selectedDate.month &&
                        day.day == selectedDate.day;
                    final now = DateTime.now();
                    final isToday =
                        day.year == now.year && day.month == now.month && day.day == now.day;
                    const weekDayLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => habitsNotifier.selectDate(day),
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
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                weekDayLetters[day.weekday - 1],
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.onSurfaceVariant,
                                      fontWeight:
                                          isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                day.day.toString(),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color:
                                          isSelected ? AppTheme.primaryColor : AppTheme.onSurface,
                                      fontWeight: FontWeight.bold,
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
              if (habitsNotifier.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                )
              else if (totalHabits == 0)
                _buildEmptyState(context)
              else
                ...habits.map((habit) {
                  final isCompleted =
                      habitsNotifier.getCompletionLogForHabit(habit.id, selectedDate) != null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildHabitCard(context, habit, isCompleted, habitsNotifier),
                  );
                }),
              const SizedBox(height: 8),
              _SectionHeader(
                title: 'Rutinas',
                actionLabel: 'Nueva',
                onAction: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const RoutineEditorSheet(),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (routines.isEmpty)
                const _EmptyPanel(
                  title: 'Todavía no tienes rutinas',
                  subtitle: 'Agrupa hábitos por momento del día para ejecutarlos con menos fricción.',
                )
              else
                SizedBox(
                  height: 164,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: routines.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _RoutineQuickCard(routine: routines[index]);
                    },
                  ),
                ),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Plantillas para empezar',
                actionLabel: 'Ver más',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RecommendationsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (templateHighlights.isEmpty)
                const _EmptyPanel(
                  title: 'Sin plantillas por ahora',
                  subtitle: 'Cuando carguemos más sugerencias aparecerán aquí.',
                )
              else
                ...templateHighlights.map(
                  (template) => _TemplateQuickCard(
                    template: template,
                    onApply: () async {
                      await progressHubNotifier.applyTemplate(template);
                      if (!context.mounted) return;
                      await _refreshDashboardState(context);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Se agregó "${template.title}" a tus hábitos.'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateMenu(context),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildHabitCard(
    BuildContext context,
    Habit habit,
    bool isCompleted,
    HabitsNotifier notifier,
  ) {
    final parsedColor = Color(int.parse(habit.colorHex.replaceAll('#', '0xFF')));
    final currentStreak = notifier.getHabitCurrentStreak(habit.id);

    return Dismissible(
      key: Key(habit.id),
      direction: isCompleted ? DismissDirection.none : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _completeHabit(context, habit, notifier);
        } else if (direction == DismissDirection.endToStart) {
          _showHabitOptions(context, habit, notifier);
        }
        return false;
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
              'Completar hábito',
              style: TextStyle(
                color: AppTheme.tertiaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
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
              'Opciones rápidas',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.more_horiz, color: AppTheme.errorColor, size: 28),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => HabitDetailSheet(habit: habit),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isCompleted
                ? AppTheme.surfaceContainerLow.withOpacity(0.5)
                : AppTheme.surfaceContainer,
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
              CircleAvatar(
                backgroundColor: parsedColor.withOpacity(0.12),
                radius: 26,
                child: Text(
                  habit.icon ?? '•',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                isCompleted ? AppTheme.onSurfaceVariant : AppTheme.onSurface,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          habit.frequencyType == 'daily' ? 'Diario' : 'Frecuente',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.onSurfaceVariant.withOpacity(0.7),
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
                        ],
                      ],
                    ),
                  ],
                ),
              ),
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

  void _showHabitOptions(BuildContext context, Habit habit, HabitsNotifier notifier) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                habit.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
                title: const Text('Editar hábito'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => HabitCreatorSheet(habit: habit),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorColor),
                title: const Text('Eliminar hábito'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      title: const Text('¿Eliminar hábito?'),
                      content: const Text(
                        'Esta acción detendrá su racha, pero mantendremos el historial guardado.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                            foregroundColor: AppTheme.onError,
                          ),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;
                  await notifier.deleteHabit(habitId: habit.id, token: 'offline_token');
                  if (!context.mounted) return;
                  await context.read<ProgressHubNotifier>().initialize();
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
            'Comienza tu disciplina',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'No tienes hábitos para este día. Usa el botón + para crear un hábito o una rutina.',
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

class _TodayInfoCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TodayInfoCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _RoutineQuickCard extends StatelessWidget {
  final RoutineSummary routine;

  const _RoutineQuickCard({required this.routine});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RoutineDetailScreen(routineId: routine.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              routine.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              (routine.description ?? '').isEmpty ? 'Sin descripción' : routine.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            LinearProgressIndicator(
              value: routine.completionRate,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
              backgroundColor: Colors.white.withOpacity(0.05),
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 10),
            Text(
              '${routine.completedCount}/${routine.habitCount} completados',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateQuickCard extends StatelessWidget {
  final HabitTemplateModel template;
  final VoidCallback onApply;

  const _TemplateQuickCard({
    required this.template,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(template.defaultIconKey ?? '✨', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  template.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            template.description ?? '',
            style: const TextStyle(color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onApply,
              child: const Text('Usar plantilla'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String text;

  const _InlineNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.16)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyPanel({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
