import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:habitu_ui/habitu_ui.dart';
import '../../../onboarding/presentation/notifiers/onboarding_notifier.dart';
import '../../../habits/presentation/notifiers/habits_notifier.dart';
import '../../../habits/domain/repositories/habits_repository.dart';
import '../../../habits/data/services/sync_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _syncing = false;
  int _pendingCount = 0;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPendingSync();
    _checkNotificationPermissionStatus();
  }

  Future<void> _checkNotificationPermissionStatus() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _notificationsEnabled = status.isGranted;
      });
    }
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

  Future<void> _forceSync() async {
    setState(() {
      _syncing = true;
    });

    // Simular intento de conexiÃ³n por 1.5 segundos
    try { await GetIt.instance<SyncManager>().sync(); } catch(e) {}

    if (mounted) {
      setState(() {
        _syncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexiÃ³n: No se pudo establecer contacto con el servidor. Datos guardados de forma segura localmente.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showFaqDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerHigh,
        title: const Text('Preguntas Frecuentes', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: const [
              ExpansionTile(
                title: Text('Â¿La app gasta mis megas de internet?', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 13)),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'No. HabitÃ¼ funciona 100% sin conexiÃ³n. Tus datos se guardan en tu telÃ©fono y solo se sincronizan cuando estÃ¡s conectado a Wi-Fi o red mÃ³vil.',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    ),
                  )
                ],
              ),
              ExpansionTile(
                title: Text('Â¿CÃ³mo encuentro a mis amigos?', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 13)),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Al sincronizar contactos, la app encripta tus nÃºmeros telefÃ³nicos usando un hash SHA-256 anÃ³nimo. Solo comparamos los hashes en el servidor para proteger tu privacidad.',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    ),
                  )
                ],
              ),
              ExpansionTile(
                title: Text('Â¿QuÃ© pasa si olvido marcar un hÃ¡bito ayer?', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', fontSize: 13)),
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'Puedes seleccionar el dÃ­a anterior en el calendario de la pantalla de "Hoy" y marcar el hÃ¡bito retroactivamente para salvar tu consistencia.',
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          )
        ],
      ),
    );
  }

  void _handleLogout(OnboardingNotifier onboarding) async {
    await _checkPendingSync();

    if (!mounted) return;

    if (_pendingCount > 0) {
      // Guarded dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceContainerHigh,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.accentColor, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text('Â¡Espera! Tienes cambios', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
              ),
            ],
          ),
          content: Text(
            'Tienes $_pendingCount meta(s) o log(s) marcados que aÃºn no se han guardado en la nube por falta de conexiÃ³n. Si cierras sesiÃ³n ahora, perderÃ¡s permanentemente este progreso.',
            style: const TextStyle(color: AppTheme.onSurfaceVariant, fontFamily: 'Inter'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onboarding.logout();
                context.read<HabitsNotifier>().reset();
              },
              child: Text(
                'Cerrar sesiÃ³n de todos modos',
                style: TextStyle(color: AppTheme.errorColor.withOpacity(0.8), fontFamily: 'Inter'),
              ),
            ),
            HabituButton(
              label: 'Esperar a tener conexiÃ³n',
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      );
    } else {
      // Normal dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceContainerHigh,
          title: const Text('Â¿Cerrar SesiÃ³n?', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
          content: const Text(
            'Â¿EstÃ¡s seguro de que deseas cerrar sesiÃ³n en tu cuenta de HabitÃ¼?',
            style: TextStyle(color: AppTheme.onSurfaceVariant, fontFamily: 'Inter'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.outline)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: AppTheme.onError),
              child: const Text('Cerrar SesiÃ³n'),
            )
          ],
        ),
      );
      if (confirm == true) {
        onboarding.logout();
        context.read<HabitsNotifier>().reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingNotifier>();
    final user = onboarding.user;
    _checkPendingSync();

    final isOffline = _pendingCount > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Espacio', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          // Profile Details Card
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                      child: Text(
                        user?.fullName.split(" ").map((s) => s[0]).join("").substring(0, 2) ?? 'U',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.surfaceColor,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.primaryColor,
                          child: IconButton(
                            icon: const Icon(Icons.edit, size: 12, color: AppTheme.onPrimary),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('EdiciÃ³n de avatar deshabilitada temporalmente')),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'Usuario',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user?.academicProgram ?? "Carrera"} â€¢ Arquetipo: ${user?.persona ?? "Deep Thinker"}',
                  style: TextStyle(color: AppTheme.onSurfaceVariant.withOpacity(0.8), fontFamily: 'Inter', fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Sync status container card
          Text('Respaldo en la Nube', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isOffline ? AppTheme.accentColor.withOpacity(0.08) : AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isOffline ? AppTheme.accentColor.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isOffline ? AppTheme.accentColor.withOpacity(0.12) : AppTheme.primaryColor.withOpacity(0.12),
                  child: Icon(
                    isOffline ? Icons.cloud_off_outlined : Icons.cloud_queue_outlined,
                    color: isOffline ? AppTheme.accentColor : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOffline ? 'Cambios pendientes' : 'Modo local activo',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isOffline 
                            ? 'Tienes $_pendingCount cambios guardados localmente en este telÃ©fono.'
                            : 'Todos tus datos estÃ¡n seguros en este dispositivo.',
                        style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: _syncing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                      : const Icon(Icons.sync),
                  onPressed: _syncing ? null : _forceSync,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Settings Options
          Text('ConfiguraciÃ³n', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined, color: AppTheme.primaryColor),
                  title: const Text('Tema Oscuro', style: TextStyle(fontFamily: 'Inter')),
                  trailing: Switch(
                    value: true,
                    onChanged: (val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Modo oscuro predeterminado para Academic Ethereal')),
                      );
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryColor),
                  title: const Text('Notificaciones Activas', style: TextStyle(fontFamily: 'Inter')),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (val) async {
                      if (val) {
                        final status = await Permission.notification.status;
                        if (status.isGranted) {
                          setState(() {
                            _notificationsEnabled = true;
                          });
                        } else {
                          final result = await Permission.notification.request();
                          if (result.isGranted) {
                            setState(() {
                              _notificationsEnabled = true;
                            });
                          } else {
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  backgroundColor: AppTheme.surfaceContainerHigh,
                                  title: const Text(
                                    'Permiso de Notificaciones Requerido',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', color: Colors.white),
                                  ),
                                  content: const Text(
                                    'Para recibir tus recordatorios diarios de hÃ¡bitos, debes activar las notificaciones en la configuraciÃ³n del sistema.',
                                    style: TextStyle(color: AppTheme.onSurfaceVariant, fontFamily: 'Inter'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext),
                                      child: const Text('Cancelar', style: TextStyle(color: AppTheme.outline)),
                                    ),
                                    HabituButton(
                                      label: 'Ir a Ajustes',
                                      onPressed: () async {
                                        Navigator.pop(dialogContext);
                                        await openAppSettings();
                                      },
                                    )
                                  ],
                                ),
                              );
                            }
                            setState(() {
                              _notificationsEnabled = false;
                            });
                          }
                        }
                      } else {
                        await NotificationService().cancelAllNotifications();
                        setState(() {
                          _notificationsEnabled = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Recordatorios desactivados en esta aplicaciÃ³n.'),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                      }
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: AppTheme.primaryColor),
                  title: const Text('Preguntas Frecuentes', style: TextStyle(fontFamily: 'Inter')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showFaqDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout button
          ElevatedButton.icon(
            onPressed: () => _handleLogout(onboarding),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar SesiÃ³n'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorContainer.withOpacity(0.2),
              foregroundColor: AppTheme.errorColor,
              side: BorderSide(color: AppTheme.errorColor.withOpacity(0.2)),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}


