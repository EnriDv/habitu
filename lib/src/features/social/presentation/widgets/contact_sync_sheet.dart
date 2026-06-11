import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

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
    {'name': 'Luciana Mendez', 'career': 'Psicología', 'initials': 'LM'},
    {'name': 'Andres Torrez', 'career': 'Derecho', 'initials': 'AT'},
  ];

  final List<String> _following = [];

  void _startSync() {
    setState(() {
      _isSyncing = true;
    });
    // Simulate contact hashing and searching
    Future.delayed(const Duration(seconds: 2), () {
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
              'Sincronizaremos tus contactos de forma segura. Tus números telefónicos se encriptan con hash SHA-256 anónimo antes de subirse para total privacidad.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _startSync,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: const Text('Sincronizar y Buscar'),
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
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (isFollowing) {
                              _following.remove(name);
                            } else {
                              _following.add(name);
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing ? AppTheme.surfaceContainerHighest : AppTheme.primaryColor,
                          foregroundColor: isFollowing ? AppTheme.onSurface : AppTheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(60, 36),
                        ),
                        child: Text(isFollowing ? 'Siguiendo' : 'Seguir Racha'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
              child: const Text('Listo'),
            ),
          ],
        ],
      ),
    );
  }
}
