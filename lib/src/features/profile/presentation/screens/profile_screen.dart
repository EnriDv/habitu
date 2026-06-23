import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/constants/habit_catalog.dart';
import '../../../../core/services/app_sync_coordinator.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:habitu_ui/habitu_ui.dart';
import '../../../onboarding/presentation/notifiers/session_onboarding_notifier.dart';
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
  int _pendingConflictCount = 0;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPendingSync();
    _checkPendingConflicts();
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

  Future<void> _checkPendingConflicts() async {
    try {
      final count = await GetIt.instance<SyncManager>().getPendingConflictCount();
      if (mounted) {
        setState(() {
          _pendingConflictCount = count;
        });
      }
    } catch (_) {}
  }

  Future<void> _forceSync() async {
    final onboarding = context.read<OnboardingNotifier>();
    if (!onboarding.isCurrentUserCloudLinked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Esta cuenta solo existe en este dispositivo. Primero guardala en la nube desde esta pantalla para poder sincronizarla.',
            ),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
      return;
    }

    setState(() {
      _syncing = true;
    });

    final synced = await GetIt.instance<AppSyncCoordinator>().syncAndRefresh(
      onboardingNotifier: context.read<OnboardingNotifier>(),
      habitsNotifier: context.read<HabitsNotifier>(),
      mode: SyncMode.full,
      force: true,
    );
    await _checkPendingSync();
    await _checkPendingConflicts();

    if (mounted) {
      setState(() {
        _syncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            synced
                ? 'Sincronizacion completada. Los cambios de este dispositivo ya quedaron enviados a la nube.'
                : 'No se pudo sincronizar en este momento. Tus cambios siguen guardados localmente en este dispositivo.',
          ),
          backgroundColor: synced ? AppTheme.primaryColor : AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _showLinkCloudSheet(OnboardingNotifier onboarding) async {
    final linked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CloudLinkSheet(onboarding: onboarding),
    );

    if (linked == true) {
      await _checkPendingSync();
      await _checkPendingConflicts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cuenta vinculada correctamente. Tus datos locales ya se guardaron en la nube.',
          ),
          backgroundColor: AppTheme.primaryColor,
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
    final selectedFocusAreaTitles = focusAreaOptions
        .where((area) => onboarding.selectedFocusAreas.contains(area.id))
        .map((area) => area.title)
        .toList();
    _checkPendingSync();

    final isCloudLinked = onboarding.isCurrentUserCloudLinked;
    final isOffline = _pendingCount > 0;
    final hasConflicts = _pendingConflictCount > 0;

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
                        (() { final name = user?.fullName ?? ''; if (name.isEmpty) return 'U'; final initials = name.trim().split(" ").where((s) => s.isNotEmpty).map((s) => s[0]).join('').toUpperCase(); return initials.length > 2 ? initials.substring(0, 2) : initials; })(),
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
                  selectedFocusAreaTitles.isEmpty
                      ? 'Construyendo consistencia a tu manera'
                      : 'Enfoques: ${selectedFocusAreaTitles.join(", ")}',
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
              color: !isCloudLinked
                  ? AppTheme.tertiaryColor.withOpacity(0.08)
                  : isOffline
                      ? AppTheme.accentColor.withOpacity(0.08)
                      : AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: !isCloudLinked
                    ? AppTheme.tertiaryColor.withOpacity(0.2)
                    : isOffline
                        ? AppTheme.accentColor.withOpacity(0.2)
                        : AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: !isCloudLinked
                          ? AppTheme.tertiaryColor.withOpacity(0.12)
                          : isOffline
                              ? AppTheme.accentColor.withOpacity(0.12)
                              : AppTheme.primaryColor.withOpacity(0.12),
                      child: Icon(
                        !isCloudLinked
                            ? Icons.cloud_upload_outlined
                            : isOffline
                                ? Icons.cloud_off_outlined
                                : Icons.cloud_done_outlined,
                        color: !isCloudLinked
                            ? AppTheme.tertiaryColor
                            : isOffline
                                ? AppTheme.accentColor
                                : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            !isCloudLinked
                                ? 'Cuenta solo local'
                                : hasConflicts
                                    ? 'Conflictos pendientes'
                                    : isOffline
                                        ? 'Cambios pendientes de subir'
                                        : 'Cuenta vinculada a la nube',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            !isCloudLinked
                                ? 'Esta cuenta existe solo en este dispositivo. Guardala en la nube para recuperarla y usarla en otros dispositivos.'
                                : hasConflicts
                                    ? 'Hay $_pendingConflictCount conflicto(s) de sincronizacion para revisar cuando el backend los devuelva.'
                                    : isOffline
                                        ? 'Tienes $_pendingCount cambio(s) guardados localmente. Presiona Sync para subirlos a la nube.'
                                        : 'Al entrar en la app descargamos tus datos de la nube a este dispositivo. Los cambios locales solo se suben cuando presionas Sync.',
                            style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: _syncing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor))
                          : const Icon(Icons.sync),
                      onPressed: _syncing || !isCloudLinked ? null : _forceSync,
                    ),
                  ],
                ),
                if (!isCloudLinked) ...[
                  const SizedBox(height: 16),
                  HabituButton(
                    label: 'Guardar mis datos en la nube',
                    onPressed: () => _showLinkCloudSheet(onboarding),
                    fullWidth: true,
                  ),
                ],
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

class _CloudLinkSheet extends StatefulWidget {
  final OnboardingNotifier onboarding;

  const _CloudLinkSheet({required this.onboarding});

  @override
  State<_CloudLinkSheet> createState() => _CloudLinkSheetState();
}

class _CloudLinkSheetState extends State<_CloudLinkSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.onboarding.user?.fullName ?? '');
    final userEmail = widget.onboarding.user?.email ?? '';
    final defaultEmail = userEmail.startsWith('guest_') && userEmail.endsWith('@habitu.app')
        ? ''
        : userEmail;
    _emailController = TextEditingController(text: defaultEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final linked = await widget.onboarding.linkCurrentAccountToCloud(
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmController.text,
      fullName: _nameController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });

    if (linked) {
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.onboarding.errorMessage ?? 'No se pudo vincular la cuenta en este momento.',
        ),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.82;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
        child: Material(
          color: AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guardar mis datos en la nube',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crearemos una cuenta en la nube y subiremos lo que ya tienes guardado en este dispositivo para que puedas recuperarlo en otros equipos.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo electronico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa tu correo';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Ingresa un correo valido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Contrasena',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa una contrasena';
                        }
                        if (value.trim().length < 8) {
                          return 'Debe tener al menos 8 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmController,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contrasena',
                        prefixIcon: Icon(Icons.verified_user_outlined),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Confirma tu contrasena';
                        }
                        if (value != _passwordController.text) {
                          return 'Las contrasenas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(height: 10),
                    HabituButton(
                      label: _saving ? 'Guardando...' : 'Guardar en la nube',
                      onPressed: _saving ? () {} : _submit,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



