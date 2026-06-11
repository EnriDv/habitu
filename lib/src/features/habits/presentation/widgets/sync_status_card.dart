import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/repositories/habits_repository.dart';
import '../notifiers/habits_notifier.dart';

class SyncStatusCard extends StatefulWidget {
  const SyncStatusCard({super.key});

  @override
  State<SyncStatusCard> createState() => _SyncStatusCardState();
}

class _SyncStatusCardState extends State<SyncStatusCard> {
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPendingSync();
  }

  Future<void> _checkPendingSync() async {
    try {
      final repository = GetIt.instance<HabitsRepository>();
      final list = await repository.getPendingSyncHabits();
      if (mounted) {
        setState(() {
          _pendingCount = list.length;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Listen to habits changes to recheck queue status
    context.watch<HabitsNotifier>();
    _checkPendingSync();

    final isOffline = _pendingCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOffline 
            ? AppTheme.accentColor.withOpacity(0.12)
            : AppTheme.tertiaryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOffline 
              ? AppTheme.accentColor.withOpacity(0.25)
              : AppTheme.tertiaryColor.withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOffline ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
            size: 16,
            color: isOffline ? AppTheme.accentColor : AppTheme.tertiaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            isOffline ? 'Pendiente: $_pendingCount' : 'Sincronizado',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isOffline ? AppTheme.accentColor : AppTheme.tertiaryColor,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
