import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:habitu_ui/habitu_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/android_widget_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/presentation/notifiers/session_onboarding_notifier.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';
import '../../domain/entities/habit_template_models.dart';
import '../../domain/entities/routine.dart';
import '../../domain/repositories/habits_repository.dart';
import '../notifiers/habits_notifier.dart';
import '../notifiers/progress_hub_notifier.dart';
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
  static const List<HabitEditorCategoryOption> _habitCategories = [
    HabitEditorCategoryOption(label: 'Aprendizaje', emoji: 'book'),
    HabitEditorCategoryOption(label: 'Bienestar', emoji: 'well'),
    HabitEditorCategoryOption(label: 'Movimiento', emoji: 'move'),
    HabitEditorCategoryOption(label: 'Descanso', emoji: 'rest'),
    HabitEditorCategoryOption(label: 'Meta', emoji: 'goal'),
  ];

  Future<bool> _requestEvidencePermission(HabitEvidenceSource source) {
    final notificationService = NotificationService();
    return source == HabitEvidenceSource.camera
        ? notificationService.requestCameraPermission(context)
        : notificationService.requestGalleryPermission(context);
  }

  Future<Map<String, dynamic>?> showCompletionConfirmationSheet(
    BuildContext context, {
    required Habit habit,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => CompletionConfirmationSheet(
        habitTitle: habit.title,
        onRequestEvidence: (source) async {
          final granted = await _requestEvidencePermission(source);
          if (!granted) {
            return null;
          }

          final picker = ImagePicker();
          final photo = await picker.pickImage(
            source: source == HabitEvidenceSource.camera
                ? ImageSource.camera
                : ImageSource.gallery,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 85,
          );
          return photo?.path;
        },
        onSubmit: (result) {
          Navigator.pop(sheetContext, {
            'complete': true,
            'evidence': result.hasEvidence,
            'notes': result.notes,
            'photoPath': result.photoPath,
          });
        },
        onCancel: () => Navigator.pop(sheetContext, {'complete': false}),
      ),
    );
  }

  Future<void> showHabitEditorSheet(
    BuildContext context, {
    Habit? habit,
  }) {
    final habitsNotifier = context.read<HabitsNotifier>();
    final onboardingNotifier = context.read<OnboardingNotifier>();
    final notificationService = NotificationService();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitEditorSheet(
        title: habit != null ? 'Editar hábito' : 'Crear hábito',
        initialTitle: habit?.title,
        initialDescription: habit?.description,
        initialIcon: habit?.icon ?? 'book',
        initialColorHex: habit?.colorHex ?? AppTheme.habitColorHexes.first,
        initialDaysOfWeek: const [1, 2, 3, 4, 5],
        initialIsPublic: habit?.isPublic ?? false,
        initialReminderTime: const TimeOfDay(hour: 8, minute: 0),
        categories: _habitCategories,
        availableColorHexes: AppTheme.habitColorHexes,
        onSubmit: (result) async {
          final userId = onboardingNotifier.user?.id ?? 'anonymous_student';
          final notificationsAllowed =
              await notificationService.requestNotificationPermission(context);
          if (notificationsAllowed) {
            await notificationService.setNotificationsEnabled(true);
          }

          bool saved;
          bool reminderScheduled = false;

          if (habit != null) {
            final updated = habit.copyWith(
              title: result.title,
              description: result.description,
              icon: result.icon,
              colorHex: result.colorHex,
              isPublic: result.isPublic,
              updatedAt: DateTime.now(),
            );
            saved = await habitsNotifier.updateHabit(habit: updated, token: 'offline_token');
            if (saved && notificationsAllowed) {
              reminderScheduled = await notificationService.scheduleDailyHabitNotification(
                habitId: updated.id,
                title: updated.title,
                time: result.reminderTime,
              );
            }
          } else {
            final habitId = const Uuid().v4();
            final created = Habit(
              id: habitId,
              userId: userId,
              title: result.title,
              description: result.description,
              frequencyType: 'daily',
              colorHex: result.colorHex,
              icon: result.icon,
              isPublic: result.isPublic,
              isDeleted: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            saved = await habitsNotifier.createHabit(habit: created, token: 'offline_token');
            if (saved && notificationsAllowed) {
              reminderScheduled = await notificationService.scheduleDailyHabitNotification(
                habitId: habitId,
                title: created.title,
                time: result.reminderTime,
              );
            }
          }

          if (!context.mounted) {
            return saved;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                !notificationsAllowed
                    ? 'Hábito guardado. El recordatorio no se activó porque faltan permisos de notificación.'
                    : reminderScheduled
                        ? 'Hábito guardado. Recordatorio programado correctamente.'
                        : 'Hábito guardado, pero no pudimos programar el recordatorio en este dispositivo.',
              ),
              backgroundColor:
                  reminderScheduled ? AppTheme.primaryColor : AppTheme.accentColor,
            ),
          );

          return saved;
        },
        onDelete: habit == null
            ? null
            : () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    title: const Text('¿Eliminar hábito?'),
                    content: const Text(
                      'Esta acción detendrá tu racha de este hábito, pero conservaremos tu progreso histórico.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: AppTheme.onError,
                        ),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (confirm != true) {
                  return false;
                }

                final deleted = await habitsNotifier.deleteHabit(
                  habitId: habit.id,
                  token: 'offline_token',
                );
                if (deleted) {
                  await notificationService.cancelHabitNotification(habit.id);
                }
                return deleted;
              },
      ),
    );
  }

  Future<void> showHabitDetailSheet(
    BuildContext context, {
    required Habit habit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HabitDetailSheetBridge(
        initialHabit: habit,
        onEditRequested: (selectedHabit) async {
          await showHabitEditorSheet(context, habit: selectedHabit);
        },
        onDeleted: () async {
          await context.read<ProgressHubNotifier>().initialize();
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDashboardState(context);
    });
  }

  Future<void> _refreshDashboardState(BuildContext context) async {
    final habitsNotifier = context.read<HabitsNotifier>();
    final progressHubNotifier = context.read<ProgressHubNotifier>();
    await habitsNotifier.loadHabits(token: 'offline_token');
    await progressHubNotifier.initialize();
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
    final progressHubNotifier = context.read<ProgressHubNotifier>();
    final result = await showCompletionConfirmationSheet(
      context,
      habit: habit,
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
    await progressHubNotifier.initialize();
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
                  showHabitEditorSheet(context);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.tertiaryColor.withValues(alpha: 0.2),
                  child: const Icon(Icons.layers_outlined, color: AppTheme.tertiaryColor),
                ),
                title: const Text('Rutina'),
                subtitle: const Text('Agrupar varios hábitos en un bloque.'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showRoutineEditorSheet(context);
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


  Future<int> _loadPendingSyncCount() async {
    try {
      final repository = GetIt.instance<HabitsRepository>();
      final pendingHabits = await repository.getPendingSyncHabits();
      return pendingHabits.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _showRoutineEditorSheet(
    BuildContext context, {
    String? routineId,
    String? initialTitle,
    String? initialDescription,
    String initialTimeOfDay = 'morning',
    String? initialAnchorTime,
    List<int> initialDaysOfWeek = const [],
  }) {
    final notifier = context.read<ProgressHubNotifier>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoutineEditorSheet(
        routineId: routineId,
        initialTitle: initialTitle,
        initialDescription: initialDescription,
        initialTimeOfDay: initialTimeOfDay,
        initialAnchorTime: initialAnchorTime,
        initialDaysOfWeek: initialDaysOfWeek,
        onSubmit: (result) async {
          if (routineId == null) {
            await notifier.createRoutine(
              title: result.title,
              description: result.description,
              timeOfDay: result.timeOfDay,
              daysOfWeek: result.daysOfWeek,
              anchorTime: result.anchorTime,
            );
            return;
          }

          await notifier.updateRoutine(
            routineId: routineId,
            title: result.title,
            description: result.description,
            timeOfDay: result.timeOfDay,
            daysOfWeek: result.daysOfWeek,
            anchorTime: result.anchorTime,
          );
        },
      ),
    );
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
                  FutureBuilder<int>(
                    future: _loadPendingSyncCount(),
                    builder: (context, snapshot) {
                      return SyncStatusCard(pendingCount: snapshot.data ?? 0);
                    },
                  ),
                ],
              ),
              if (habitsNotifier.errorMessage != null) ...[
                const SizedBox(height: 16),
                InlineNotice(
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
                          AppTheme.primaryColor.withValues(alpha: 0.12),
                          AppTheme.tertiaryColor.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
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
                                ? AppTheme.primaryColor.withValues(alpha: 0.15)
                                : isToday
                                    ? AppTheme.surfaceContainerHighest.withValues(alpha: 0.5)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : isToday
                                      ? AppTheme.outline.withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.05),
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
              SectionHeader(
                title: 'Rutinas',
                actionLabel: 'Nueva',
                onAction: () {
                  _showRoutineEditorSheet(context);
                },
              ),
              const SizedBox(height: 12),
              if (routines.isEmpty)
                const EmptyPanel(
                  title: 'Todavía no tienes rutinas',
                  subtitle: 'Agrupa hábitos por momento del día para ejecutarlos con menos fricción.',
                )
              else
                SizedBox(
                  height: 164,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: routines.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return RoutineQuickCard(
                        routine: RoutineQuickCardViewModel(
                          title: routines[index].title,
                          description: routines[index].description,
                          completionRate: routines[index].completionRate,
                          completedCount: routines[index].completedCount,
                          habitCount: routines[index].habitCount,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => RoutineDetailScreen(routineId: routines[index].id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              SectionHeader(
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
                const EmptyPanel(
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
          color: AppTheme.tertiaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.tertiaryColor.withValues(alpha: 0.4)),
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
          color: AppTheme.errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
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
          showHabitDetailSheet(context, habit: habit);
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isCompleted
                ? AppTheme.surfaceContainerLow.withValues(alpha: 0.5)
                : AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isCompleted
                  ? AppTheme.tertiaryColor.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.04),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: parsedColor.withValues(alpha: 0.12),
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
                                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
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
                      color: AppTheme.outline.withValues(alpha: 0.4),
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
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await showHabitEditorSheet(context, habit: habit);
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
              color: AppTheme.outline.withValues(alpha: 0.5),
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
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
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







class _HabitDetailSheetBridge extends StatefulWidget {
  final Habit initialHabit;
  final Future<void> Function(Habit habit) onEditRequested;
  final Future<void> Function() onDeleted;

  const _HabitDetailSheetBridge({
    required this.initialHabit,
    required this.onEditRequested,
    required this.onDeleted,
  });

  @override
  State<_HabitDetailSheetBridge> createState() => _HabitDetailSheetBridgeState();
}

class _HabitDetailSheetBridgeState extends State<_HabitDetailSheetBridge> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitsNotifier>().loadHabitLogs(
            habitId: widget.initialHabit.id,
            token: 'offline_token',
          );
    });
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  HabitDetailLogViewModel _mapLog(HabitLog log) {
    return HabitDetailLogViewModel(
      completedAt: log.completedAt,
      notes: log.notes,
      evidencePath: log.evidencePhotoUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitsNotifier = context.watch<HabitsNotifier>();
    final habit = habitsNotifier.habits.firstWhere(
      (entry) => entry.id == widget.initialHabit.id,
      orElse: () => widget.initialHabit,
    );

    return HabitDetailSheet(
      habit: HabitDetailViewModel(
        title: habit.title,
        currentStreak: habitsNotifier.getHabitCurrentStreak(habit.id),
        longestStreak: habitsNotifier.getHabitLongestStreak(habit.id),
        logs: habitsNotifier.currentHabitLogs.map(_mapLog).toList(),
        accentColor: _parseColor(habit.colorHex),
      ),
      onEdit: () async {
        Navigator.pop(context);
        await widget.onEditRequested(habit);
      },
      onDelete: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppTheme.surfaceContainerHigh,
            title: const Text('¿Eliminar hábito?'),
            content: const Text(
              'Esta acción detendrá tu racha de este hábito, pero conservaremos tu progreso histórico.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: AppTheme.onError,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
        if (confirm != true) {
          return false;
        }

        final deleted = await habitsNotifier.deleteHabit(
              habitId: habit.id,
              token: 'offline_token',
            );
        if (deleted) {
          await NotificationService().cancelHabitNotification(habit.id);
          await widget.onDeleted();
        }
        return deleted;
      },
    );
  }
}

