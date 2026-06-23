import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';
import '../notifiers/habits_notifier.dart';
import 'habit_creator_sheet.dart';

class HabitDetailSheet extends StatefulWidget {
  final Habit habit;

  const HabitDetailSheet({super.key, required this.habit});

  @override
  State<HabitDetailSheet> createState() => _HabitDetailSheetState();
}

class _HabitDetailSheetState extends State<HabitDetailSheet> {
  DateTime? _selectedDate;

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

  int _daysInMonth(DateTime date) {
    final firstDayNextMonth = DateTime(date.year, date.month + 1, 1);
    return firstDayNextMonth.subtract(const Duration(days: 1)).day;
  }

  HabitLog? _selectedLog(List<HabitLog> logs) {
    if (logs.isEmpty) {
      return null;
    }

    if (_selectedDate != null) {
      for (final log in logs) {
        final completedAt = DateTime(
          log.completedAt.year,
          log.completedAt.month,
          log.completedAt.day,
        );
        if (completedAt == _selectedDate) {
          return log;
        }
      }
    }

    return logs.first;
  }

  Widget _buildEvidencePreview(HabitLog log) {
    final evidencePath = log.evidencePhotoUrl;
    if (evidencePath == null || evidencePath.isEmpty) {
      return const SizedBox.shrink();
    }

    final uri = Uri.tryParse(evidencePath);
    final isRemote = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    final localFile = File(evidencePath);
    final hasLocalFile = !isRemote && localFile.existsSync();

    if (!isRemote && !hasLocalFile) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: const Text(
          'La evidencia quedó registrada, pero esta imagen ya no está disponible en este dispositivo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: isRemote
            ? Image.network(
                evidencePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.surfaceContainer,
                  alignment: Alignment.center,
                  child: const Text('No pudimos cargar la evidencia.'),
                ),
              )
            : Image.file(
                localFile,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitsNotifier = context.watch<HabitsNotifier>();
    final habit = habitsNotifier.habits.firstWhere(
      (h) => h.id == widget.habit.id,
      orElse: () => widget.habit,
    );

    final currentStreak = habitsNotifier.getHabitCurrentStreak(habit.id);
    final longestStreak = habitsNotifier.getHabitLongestStreak(habit.id);
    final logs = List<HabitLog>.from(habitsNotifier.currentHabitLogs)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final selectedLog = _selectedLog(logs);
    final totalSessions = logs.length;

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final totalDays = _daysInMonth(now);
    final startOffset = firstDay.weekday - 1;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            habit.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
          ),
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
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Racha activa',
                    value: '$currentStreak días',
                    icon: Icons.local_fire_department_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Racha máxima',
                    value: '$longestStreak días',
                    icon: Icons.workspace_premium_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Consistencia este mes',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.03)),
              ),
              child: Column(
                children: [
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
                      final log = habitsNotifier.getCompletionLogForHabit(habit.id, dayDate);
                      final isCompleted = log != null;
                      final isSelected = _selectedDate != null && dayDate == _selectedDate;

                      return InkWell(
                        borderRadius: BorderRadius.circular(99),
                        onTap: isCompleted
                            ? () {
                                setState(() {
                                  _selectedDate = dayDate;
                                });
                              }
                            : null,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppTheme.primaryColor.withOpacity(0.18)
                                : isCompleted
                                    ? AppTheme.tertiaryColor.withOpacity(0.2)
                                    : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : isCompleted
                                      ? AppTheme.tertiaryColor
                                      : Colors.white.withOpacity(0.05),
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            dayNum.toString(),
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : isCompleted
                                      ? AppTheme.tertiaryColor
                                      : AppTheme.onSurface,
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
            Text(
              'Detalle del registro',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (selectedLog == null)
              const _EmptyStateCard(
                title: 'Todavía no hay registros',
                subtitle: 'Cuando completes este hábito, aquí podrás ver hora, nota y evidencia.',
              )
            else
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
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _InfoPill(
                          icon: Icons.calendar_today_outlined,
                          text:
                              '${selectedLog.completedAt.day}/${selectedLog.completedAt.month}/${selectedLog.completedAt.year}',
                        ),
                        _InfoPill(
                          icon: Icons.schedule_outlined,
                          text:
                              '${selectedLog.completedAt.hour.toString().padLeft(2, '0')}:${selectedLog.completedAt.minute.toString().padLeft(2, '0')}',
                        ),
                        _InfoPill(
                          icon: selectedLog.evidencePhotoUrl == null
                              ? Icons.notes_outlined
                              : Icons.image_outlined,
                          text: selectedLog.evidencePhotoUrl == null
                              ? 'Sin evidencia'
                              : 'Con evidencia',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if ((selectedLog.notes ?? '').isNotEmpty) ...[
                      const Text(
                        'Nota',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedLog.notes!,
                        style: const TextStyle(color: AppTheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (selectedLog.evidencePhotoUrl != null &&
                        selectedLog.evidencePhotoUrl!.isNotEmpty) ...[
                      const Text(
                        'Evidencia',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildEvidencePreview(selectedLog),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Historial reciente',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              const _EmptyStateCard(
                title: 'Sin historial todavía',
                subtitle: 'Tus últimas completadas aparecerán aquí.',
              )
            else
              ...logs.take(8).map(
                    (log) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () {
                          setState(() {
                            _selectedDate = DateTime(
                              log.completedAt.year,
                              log.completedAt.month,
                              log.completedAt.day,
                            );
                          });
                        },
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                          child: Icon(
                            log.evidencePhotoUrl == null
                                ? Icons.check_circle_outline
                                : Icons.image_outlined,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        title: Text(
                          '${log.completedAt.day}/${log.completedAt.month} · ${log.completedAt.hour.toString().padLeft(2, '0')}:${log.completedAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          (log.notes ?? '').isEmpty
                              ? 'Sin nota'
                              : log.notes!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ),
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
                      style: TextStyle(color: AppTheme.onSurfaceVariant, fontFamily: 'Inter'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancelar', style: TextStyle(color: AppTheme.outline)),
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
                        habitId: habit.id,
                        token: 'offline_token',
                      );
                  await NotificationService().cancelHabitNotification(habit.id);
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.onSurfaceVariant,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
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
