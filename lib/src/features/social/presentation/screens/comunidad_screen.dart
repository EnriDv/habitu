import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:habitu_ui/habitu_ui.dart';
import '../../../onboarding/presentation/notifiers/onboarding_notifier.dart';
import 'package:get_it/get_it.dart';
import '../../../habits/data/services/sync_manager.dart';

class ComunidadScreen extends StatefulWidget {
  const ComunidadScreen({super.key});

  @override
  State<ComunidadScreen> createState() => _ComunidadScreenState();
}

class _ComunidadScreenState extends State<ComunidadScreen> {
  bool _isConnecting = false;

  void _retryConnection() async {
    setState(() {
      _isConnecting = true;
    });

    // Simular intento de conexiÃ³n por 2 segundos
    try { await GetIt.instance<SyncManager>().sync(); } catch(e) {}

    if (mounted) {
      setState(() {
        _isConnecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexiÃ³n: El servidor no responde. IntÃ©ntalo mÃ¡s tarde.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingNotifier>();
    final user = onboarding.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            child: Text(
              user?.fullName.split(" ").map((s) => s[0]).join("").substring(0, 2) ?? 'U',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Beautiful animated / glowing icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Sin ConexiÃ³n a la Comunidad',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Para interactuar con tus compaÃ±eros, unirte a retos y ver la tabla de consistencia grupal, necesitas estar conectado al servidor.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 32),
              _isConnecting
                  ? const SizedBox(
                      width: 200,
                      height: 56,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : HabituButton(
                      label: 'Reintentar ConexiÃ³n',
                      onPressed: _retryConnection,
                      icon: Icons.refresh,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

