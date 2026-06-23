import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/presentation/notifiers/session_onboarding_notifier.dart';
import '../../domain/entities/habit.dart';
import '../notifiers/habits_notifier.dart';

class HabitCreatorSheet extends StatefulWidget {
  final Habit? habit;

  const HabitCreatorSheet({super.key, this.habit});

  @override
  State<HabitCreatorSheet> createState() => _HabitCreatorSheetState();
}

class _HabitCreatorSheetState extends State<HabitCreatorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  String _selectedEmoji = '📚';
  String _selectedColorHex = AppTheme.habitColorHexes.first;
  List<int> _selectedDays = [1, 2, 3, 4, 5];
  bool _isPublic = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  final List<Map<String, String>> _categories = const [
    {'name': 'Aprendizaje', 'emoji': '📚'},
    {'name': 'Bienestar', 'emoji': '🧘'},
    {'name': 'Movimiento', 'emoji': '🏃'},
    {'name': 'Descanso', 'emoji': '🛌'},
    {'name': 'Meta', 'emoji': '🎯'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?.title ?? '');
    _descController = TextEditingController(text: widget.habit?.description ?? '');

    if (widget.habit != null) {
      _selectedEmoji = widget.habit!.icon ?? '📚';
      _selectedColorHex = widget.habit!.colorHex;
      _isPublic = widget.habit!.isPublic;
      _loadStoredReminder();
    }
  }

  Future<void> _loadStoredReminder() async {
    final existing = await NotificationService().getHabitReminder(widget.habit!.id);
    if (existing != null && mounted) {
      setState(() {
        _reminderTime = existing;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final habitsNotifier = context.read<HabitsNotifier>();
    final onboardingNotifier = context.read<OnboardingNotifier>();
    final notificationService = NotificationService();
    final userId = onboardingNotifier.user?.id ?? 'anonymous_student';

    final notificationsAllowed =
        await notificationService.requestNotificationPermission(context);
    if (notificationsAllowed) {
      await notificationService.setNotificationsEnabled(true);
    }

    bool reminderScheduled = false;

    if (widget.habit != null) {
      final updated = widget.habit!.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        icon: _selectedEmoji,
        colorHex: _selectedColorHex,
        isPublic: _isPublic,
        updatedAt: DateTime.now(),
      );
      await habitsNotifier.updateHabit(habit: updated, token: 'offline_token');
      reminderScheduled = notificationsAllowed
          ? await notificationService.scheduleDailyHabitNotification(
              habitId: updated.id,
              title: updated.title,
              time: _reminderTime,
            )
          : false;
    } else {
      final habitId = const Uuid().v4();
      final habit = Habit(
        id: habitId,
        userId: userId,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        frequencyType: 'daily',
        colorHex: _selectedColorHex,
        icon: _selectedEmoji,
        isPublic: _isPublic,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await habitsNotifier.createHabit(habit: habit, token: 'offline_token');
      reminderScheduled = notificationsAllowed
          ? await notificationService.scheduleDailyHabitNotification(
              habitId: habitId,
              title: habit.title,
              time: _reminderTime,
            )
          : false;
    }

    if (!mounted) {
      return;
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
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.habit != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            isEdit ? 'Editar hábito' : 'Crear hábito',
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _save,
              child: const Text(
                'Guardar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: true,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                decoration: const InputDecoration(
                  hintText: '¿Qué quieres construir hoy?',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Agrega una descripción opcional...',
                  filled: true,
                ),
                style: const TextStyle(fontFamily: 'Inter'),
              ),
              const SizedBox(height: 24),
              Text('Categoría:', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = _categories[idx];
                    final isSelected = _selectedEmoji == cat['emoji'];
                    return ChoiceChip(
                      label: Text('${cat['emoji']} ${cat['name']}'),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white.withOpacity(0.05),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedEmoji = cat['emoji']!;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text('Color de tarjeta:', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppTheme.habitColorHexes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, idx) {
                    final hex = AppTheme.habitColorHexes[idx];
                    final color = Color(int.parse(hex.replaceAll('#', '0xFF')));
                    final isSelected = _selectedColorHex == hex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColorHex = hex;
                        });
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Frecuencia (días de la semana):',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final dayNum = index + 1;
                  final isSelected = _selectedDays.contains(dayNum);
                  const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            if (_selectedDays.length > 1) {
                              _selectedDays.remove(dayNum);
                            }
                          } else {
                            _selectedDays.add(dayNum);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          dayNames[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.onSurfaceVariant,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppTheme.primaryColor,
                ),
                title: const Text('Recordatorio', style: TextStyle(fontFamily: 'Inter')),
                subtitle: Text(
                  _reminderTime.format(context),
                  style: const TextStyle(fontFamily: 'Inter'),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: _selectTime,
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Hacer público para amigos',
                  style: TextStyle(fontFamily: 'Inter'),
                ),
                subtitle: Text(
                  _isPublic
                      ? 'Tus amigos verán tu racha y progreso.'
                      : 'Hábito privado. Solo tú podrás verlo.',
                  style: const TextStyle(fontSize: 12, fontFamily: 'Inter'),
                ),
                value: _isPublic,
                onChanged: (val) {
                  setState(() {
                    _isPublic = val;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
              if (isEdit) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: AppTheme.surfaceContainerHigh,
                        title: const Text(
                          '¿Eliminar hábito?',
                          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                        ),
                        content: const Text(
                          'Esta acción detendrá tu racha de este hábito, pero conservaremos tu progreso histórico.',
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontFamily: 'Inter',
                          ),
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
                    if (confirm == true && context.mounted) {
                      await context.read<HabitsNotifier>().deleteHabit(
                            habitId: widget.habit!.id,
                            token: 'offline_token',
                          );
                      await NotificationService()
                          .cancelHabitNotification(widget.habit!.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar hábito'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorContainer.withOpacity(0.2),
                    foregroundColor: AppTheme.errorColor,
                    side: BorderSide(color: AppTheme.errorColor.withOpacity(0.2)),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
