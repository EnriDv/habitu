import 'package:flutter/material.dart';
import 'package:habitu_ui/habitu_ui.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../onboarding/presentation/notifiers/session_onboarding_notifier.dart';
import '../notifiers/social_notifier.dart';
import '../../domain/entities/social_entities.dart';
import 'friend_detail_screen.dart';

String _initials(String name) {
  final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return 'U';
  final value = parts.map((s) => s[0].toUpperCase()).join('');
  return value.length > 2 ? value.substring(0, 2) : value;
}

Color _parseColor(String hex) {
  try {
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  } catch (_) {
    return AppTheme.primaryColor;
  }
}

class ComunidadScreen extends StatefulWidget {
  const ComunidadScreen({super.key});

  @override
  State<ComunidadScreen> createState() => _ComunidadScreenState();
}

class _ComunidadScreenState extends State<ComunidadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadCurrentTab();
    });
  }

  void _loadAll() {
    final n = context.read<SocialNotifier>();
    n.loadRankings();
    n.loadFriends();
    n.loadChallenges();
  }

  void _loadCurrentTab() {
    final n = context.read<SocialNotifier>();
    switch (_tabController.index) {
      case 0: n.loadRankings(); break;
      case 1: n.loadFriends(); break;
      case 2: n.loadChallenges(); break;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<OnboardingNotifier>().user;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: const Text('Comunidad',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            child: Text(
              _initials(user?.fullName ?? ''),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor),
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.onSurfaceVariant,
          labelStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events_outlined, size: 20), text: 'Ranking'),
            Tab(icon: Icon(Icons.group_outlined, size: 20), text: 'Amigos'),
            Tab(icon: Icon(Icons.flag_outlined, size: 20), text: 'Retos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RankingsTab(),
          _FriendsTab(),
          _ChallengesTab(),
        ],
      ),
    );
  }
}

// ─── Rankings Tab ────────────────────────────────────────────────────────────

class _RankingsTab extends StatelessWidget {
  const _RankingsTab();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SocialNotifier>();

    if (notifier.rankingsState == SocialLoadingState.loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (notifier.rankingsState == SocialLoadingState.error || notifier.rankings.isEmpty) {
      return EmptyStatePanel(
        icon: Icons.emoji_events_outlined,
        title: notifier.rankingsState == SocialLoadingState.error
            ? 'No se pudo cargar el ranking'
            : 'Sin rachas públicas aún',
        subtitle: 'Comparte tus hábitos en público para aparecer aquí.',
        actionLabel: 'Reintentar',
        onAction: () => notifier.loadRankings(),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: notifier.loadRankings,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: notifier.rankings.length,
        itemBuilder: (_, i) => RankingCard(
          entry: RankingCardViewModel(
            rank: notifier.rankings[i].rank,
            fullName: notifier.rankings[i].fullName,
            habitTitle: notifier.rankings[i].habitTitle,
            currentStreak: notifier.rankings[i].currentStreak,
            longestStreak: notifier.rankings[i].longestStreak,
            avatarUrl: notifier.rankings[i].avatarUrl,
            accentColor: _parseColor(notifier.rankings[i].colorHex),
            initials: _initials(notifier.rankings[i].fullName),
          ),
        ),
      ),
    );
  }
}

// ─── Friends Tab ─────────────────────────────────────────────────────────────

class _FriendsTab extends StatelessWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SocialNotifier>();

    if (notifier.friendsState == SocialLoadingState.loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: const Color(0xFF003061),
        onPressed: () => _showAddFriendSheet(context),
        child: const Icon(Icons.person_add_outlined),
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: notifier.loadFriends,
        child: notifier.friends.isEmpty
            ? EmptyStatePanel(
                icon: Icons.group_outlined,
                title: 'Sin amigos aún',
                subtitle: 'Usa el botón + para buscar amigos por nombre.',
                actionLabel: 'Reintentar',
                onAction: notifier.loadFriends,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  if (notifier.pendingFriends.isNotEmpty) ...[
                    SectionHeader(
                        title: 'Solicitudes pendientes',
                        count: notifier.pendingFriends.length),
                    const SizedBox(height: 8),
                    ...notifier.pendingFriends.map((f) => _PendingFriendCard(friend: f)),
                    const SizedBox(height: 20),
                  ],
                  if (notifier.acceptedFriends.isNotEmpty) ...[
                    SectionHeader(
                        title: 'Mis amigos',
                        count: notifier.acceptedFriends.length),
                    const SizedBox(height: 8),
                    ...notifier.acceptedFriends.map(
                      (f) => FriendCard(
                        friend: FriendCardViewModel(
                          fullName: f.fullName,
                          subtitle: f.academicProgram,
                          avatarUrl: f.avatarUrl,
                          initials: _initials(f.fullName),
                        ),
                        actionLabel: 'Ver rachas',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: context.read<SocialNotifier>(),
                              child: FriendDetailScreen(
                                friendId: f.friendId,
                                friendName: f.fullName,
                                avatarUrl: f.avatarUrl,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  void _showAddFriendSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SocialNotifier>(),
        child: const _AddFriendSheet(),
      ),
    );
  }
}

class _PendingFriendCard extends StatelessWidget {
  final Friend friend;
  const _PendingFriendCard({required this.friend});

  String _initials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    final i = parts.map((s) => s[0].toUpperCase()).join('');
    return i.length > 2 ? i.substring(0, 2) : i;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            backgroundImage: friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
            child: friend.avatarUrl == null
                ? Text(_initials(friend.fullName),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                        fontFamily: 'Inter',
                        fontSize: 14)),
                const Text('Solicitud pendiente',
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 11,
                        fontFamily: 'Inter')),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionIconButton(
                icon: Icons.check,
                color: const Color(0xFF96D3BD),
                onTap: () async {
                  final ok = await context.read<SocialNotifier>().acceptFriendRequest(friend.friendshipId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? '¡Ahora son amigos!' : 'Error al aceptar'),
                    backgroundColor: ok ? const Color(0xFF003B2D) : AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                  ));
                },
              ),
              const SizedBox(width: 8),
              _ActionIconButton(
                icon: Icons.close,
                color: AppTheme.errorColor,
                onTap: () => context.read<SocialNotifier>().rejectFriendRequest(friend.friendshipId),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _AddFriendSheet extends StatefulWidget {
  const _AddFriendSheet();

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SocialNotifier>();
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1C1B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Agregar amigo',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                          fontFamily: 'Inter')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: (q) => notifier.searchUsers(q),
                    style: const TextStyle(color: AppTheme.onSurface, fontFamily: 'Inter'),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
                      hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant, fontFamily: 'Inter'),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant),
                      suffixIcon: notifier.isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)))
                          : null,
                      filled: true,
                      fillColor: AppTheme.surfaceContainerHigh,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: notifier.searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _controller.text.length >= 2
                            ? 'Sin resultados para "${_controller.text}"'
                            : 'Escribe al menos 2 caracteres para buscar',
                        style: const TextStyle(color: AppTheme.onSurfaceVariant, fontFamily: 'Inter'),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: notifier.searchResults.length,
                      itemBuilder: (_, i) => _SearchResultTile(result: notifier.searchResults[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatefulWidget {
  final UserSearchResult result;
  const _SearchResultTile({required this.result});

  @override
  State<_SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends State<_SearchResultTile> {
  bool _sending = false;
  bool _sent = false;

  String _initials(String name) {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    final i = parts.map((s) => s[0].toUpperCase()).join('');
    return i.length > 2 ? i.substring(0, 2) : i;
  }

  @override
  Widget build(BuildContext context) {
    final alreadyFriend = widget.result.alreadyFriend || _sent;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        backgroundImage: widget.result.avatarUrl != null ? NetworkImage(widget.result.avatarUrl!) : null,
        child: widget.result.avatarUrl == null
            ? Text(_initials(widget.result.fullName),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor))
            : null,
      ),
      title: Text(widget.result.fullName,
          style: const TextStyle(color: AppTheme.onSurface, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
      subtitle: widget.result.academicProgram != null
          ? Text(widget.result.academicProgram!,
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontFamily: 'Inter', fontSize: 12))
          : null,
      trailing: alreadyFriend
          ? const Icon(Icons.check_circle, color: Color(0xFF96D3BD), size: 22)
          : SizedBox(
              width: 36,
              height: 36,
              child: _sending
                  ? const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)
                  : IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.person_add_outlined, color: AppTheme.primaryColor),
                      onPressed: () async {
                        setState(() => _sending = true);
                        final ok = await context.read<SocialNotifier>().sendFriendRequest(widget.result.userId);
                        if (!context.mounted) return;
                        setState(() { _sending = false; _sent = ok; });
                        if (ok) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Solicitud enviada'),
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                    ),
            ),
    );
  }
}

// ─── Challenges Tab ───────────────────────────────────────────────────────────

class _ChallengesTab extends StatelessWidget {
  const _ChallengesTab();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SocialNotifier>();

    if (notifier.challengesState == SocialLoadingState.loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    if (notifier.challengesState == SocialLoadingState.error || notifier.challenges.isEmpty) {
      return EmptyStatePanel(
        icon: Icons.flag_outlined,
        title: notifier.challengesState == SocialLoadingState.error
            ? 'No se pudieron cargar los retos'
            : 'Sin retos disponibles',
        subtitle: 'Los retos universitarios aparecerán aquí cuando estén disponibles.',
        actionLabel: 'Reintentar',
        onAction: () => notifier.loadChallenges(),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: notifier.loadChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: notifier.challenges.length,
        itemBuilder: (_, i) => _ChallengeCard(challenge: notifier.challenges[i]),
      ),
    );
  }
}

class _ChallengeCard extends StatefulWidget {
  final SocialChallenge challenge;
  const _ChallengeCard({required this.challenge});

  @override
  State<_ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends State<_ChallengeCard> {
  bool _joining = false;

  @override
  Widget build(BuildContext context) {
    final ch = widget.challenge;
    return ChallengeCard(
      challenge: ChallengeCardViewModel(
        title: ch.title,
        description: ch.description,
        category: ch.category,
        dateRangeLabel: '${ch.startDate} – ${ch.endDate}',
        participantsLabel: ch.maxParticipants != null
            ? '${ch.participantCount}/${ch.maxParticipants}'
            : '${ch.participantCount}',
        isJoined: ch.isJoined,
        isFull: ch.isFull,
      ),
      isJoining: _joining,
      onJoin: () async {
        setState(() => _joining = true);
        final ok = await context.read<SocialNotifier>().joinChallenge(ch.id);
        if (!context.mounted) return;
        setState(() => _joining = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? '¡Te uniste al reto!' : 'No se pudo unirse al reto.'),
          backgroundColor: ok ? const Color(0xFF003B2D) : AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
      },
    );
  }
}
