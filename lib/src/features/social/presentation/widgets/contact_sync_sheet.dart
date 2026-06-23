import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:habitu_ui/habitu_ui.dart';
import 'package:get_it/get_it.dart';
import '../../../../features/habits/data/services/sync_manager.dart';

class ContactSyncSheet extends StatefulWidget {
  const ContactSyncSheet({super.key});

  @override
  State<ContactSyncSheet> createState() => _ContactSyncSheetState();
}

class _ContactSyncSheetState extends State<ContactSyncSheet> {
  bool _isSyncing = false;
  bool _synced = false;

  final List<Map<String, String>> _foundPeers = [
    {'name': 'Daniel Castro', 'career': 'Ing. Sistemas', 'initials': 'DC'},
    {'name': 'Luciana Mendez', 'career': 'PsicologÃ­a', 'initials': 'LM'},
    {'name': 'Andres Torrez', 'career': 'Derecho', 'initials': 'AT'},
  ];

  final List<String> _following = [];

  void _startSync() {
    setState(() {
      _isSyncing = true;
    });
    // Simulate contact hashing and searching
    GetIt.instance<SyncManager>().sync(mode: SyncMode.full).then((_) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _synced = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          if (!_synced && !_isSyncing) ...[
            const CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              radius: 28,
              child: Icon(Icons.people_outline, color: AppTheme.onPrimary, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Encuentra a tus amigos',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Sincronizaremos tus contactos de forma segura. Tus nÃºmeros telefÃ³nicos se encriptan con hash SHA-256 anÃ³nimo antes de subirse para total privacidad.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            HabituButton(
              label: 'Sincronizar y Buscar',
              onPressed: _startSync,
              fullWidth: true,
            ),
          ] else if (_isSyncing) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    SizedBox(height: 20),
                    Text(
                      'Encriptando y buscando coincidencias...',
                      style: TextStyle(fontFamily: 'Inter', color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Text(
              'Amigos Encontrados',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              itemCount: _foundPeers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final peer = _foundPeers[idx];
                final name = peer['name']!;
                final isFollowing = _following.contains(name);
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                        child: Text(
                          peer['initials']!,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                            Text(peer['career']!, style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant, fontFamily: 'Inter')),
                          ],
                        ),
                      ),
                      isFollowing
                            ? HabituButton.outlined(
                                label: 'Siguiendo',
                                onPressed: () {
                                  setState(() {
                                    _following.remove(name);
                                  });
                                },
                              )
                            : HabituButton(
                                label: 'Seguir Racha',
                                onPressed: () {
                                  setState(() {
                                    _following.add(name);
                                  });
                                },
                              ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            HabituButton.outlined(
              label: 'Listo',
              onPressed: () => Navigator.pop(context),
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }
}

