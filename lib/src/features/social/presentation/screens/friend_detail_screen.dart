import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/social_entities.dart';
import '../notifiers/social_notifier.dart';

class FriendDetailScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String? avatarUrl;

  const FriendDetailScreen({
    super.key,
    required this.friendId,
    required this.friendName,
    this.avatarUrl,
  });

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  FriendDetail? _detail;
  bool _loading = true;
  bool _nudging = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final detail = await context.read<SocialNotifier>().getFriendDetail(widget.friendId);
    if (mounted) setState(() { _detail = detail; _loading = false; });
  }

  Future<void> _nudge() async {
    setState(() => _nudging = true);
    final ok = await context.read<SocialNotifier>().nudgeFriend(widget.friendId);
    if (!mounted) return;
    setState(() => _nudging = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '¡Toque enviado a ${widget.friendName}!' : 'No se pudo enviar el toque.'),
      backgroundColor: ok ? const Color(0xFF00382B) : AppTheme.errorColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    final initials = parts.map((s) => s[0].toUpperCase()).join('');
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: Text(widget.friendName, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        actions: [
          if (_detail != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _nudging ? null : _nudge,
                icon: _nudging
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                    : const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryColor, size: 20),
                label: const Text('Toque', style: TextStyle(color: AppTheme.primaryColor, fontFamily: 'Inter')),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _detail == null
              ? _buildError()
              : _buildContent(_detail!),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.onSurfaceVariant),
          const SizedBox(height: 16),
          const Text('No se pudo cargar el perfil', style: TextStyle(color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextButton(onPressed: () { setState(() => _loading = true); _load(); }, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildContent(FriendDetail detail) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(detail),
          const SizedBox(height: 32),
          if (detail.publicHabits.isEmpty)
            _buildEmptyHabits()
          else ...[
            Text(
              'Hábitos Públicos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurface,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${detail.publicHabits.length} ${detail.publicHabits.length == 1 ? 'hábito compartido' : 'hábitos compartidos'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ...detail.publicHabits.map((h) => _buildHabitCard(h)),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileHeader(FriendDetail detail) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppTheme.primaryColor.withValues(alpha:0.15),
          backgroundImage: detail.avatarUrl != null ? NetworkImage(detail.avatarUrl!) : null,
          child: detail.avatarUrl == null
              ? Text(_initials(detail.fullName),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor))
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail.fullName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                      fontFamily: 'Inter')),
              if (detail.academicProgram != null) ...[
                const SizedBox(height: 4),
                Text(detail.academicProgram!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor, fontFamily: 'Inter')),
              ],
              if (detail.universityHeadquarters.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(detail.universityHeadquarters,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
                ]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHabitCard(FriendPublicHabit habit) {
    final color = _parseColor(habit.colorHex);
    final isActive = habit.currentStreak > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha:0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.star_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                        fontFamily: 'Inter',
                        fontSize: 15)),
                if (habit.description != null) ...[
                  const SizedBox(height: 2),
                  Text(habit.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12, fontFamily: 'Inter')),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                Text('🔥', style: TextStyle(fontSize: isActive ? 18 : 14)),
                const SizedBox(width: 4),
                Text('${habit.currentStreak}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isActive ? 18 : 14,
                        color: isActive ? color : AppTheme.onSurfaceVariant,
                        fontFamily: 'Inter')),
              ]),
              const SizedBox(height: 2),
              Text('mejor: ${habit.longestStreak}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant, fontFamily: 'Inter')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHabits() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.lock_outline_rounded, size: 40, color: AppTheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              '${widget.friendName} no tiene hábitos públicos aún.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontFamily: 'Inter'),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }
}
