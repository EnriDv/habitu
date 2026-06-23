import 'package:flutter/material.dart';
import 'package:habitu_ui/habitu_ui.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../notifiers/session_onboarding_notifier.dart';

enum _AccessMode {
  signIn,
  register,
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  _AccessMode _mode = _AccessMode.signIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<OnboardingNotifier>(
          builder: (context, notifier, _) {
            return Stack(
              children: [
                _AccessBackground(),
                ListView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  children: [
                    const _AccessHeader(),
                    const SizedBox(height: 28),
                    AccessModeSwitch(
                      selectedIndex: _mode == _AccessMode.signIn ? 0 : 1,
                      labels: const ['Iniciar sesion', 'Crear cuenta'],
                      onChanged: (index) {
                        setState(() {
                          _mode = index == 0 ? _AccessMode.signIn : _AccessMode.register;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: _AccessForm(
                        mode: _mode,
                        notifier: notifier,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (notifier.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          notifier.errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontFamily: 'Inter',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    notifier.isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              HabituButton(
                                label: _mode == _AccessMode.signIn
                                    ? 'Entrar a mi cuenta'
                                    : 'Crear cuenta',
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    if (_mode == _AccessMode.signIn) {
                                      await notifier.signInWithEmail();
                                    } else {
                                      await notifier.registerAccount();
                                    }
                                  }
                                },
                                fullWidth: true,
                              ),
                              const SizedBox(height: 12),
                              HabituButton.outlined(
                                label: 'Usar solo en este dispositivo',
                                onPressed: () async {
                                  await notifier.registerAccount(anonymous: true);
                                },
                                fullWidth: true,
                              ),
                            ],
                          ),
                    if (notifier.localUsers.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const _LocalAccountsHeader(),
                      const SizedBox(height: 12),
                      ...notifier.localUsers.map(
                        (prevUser) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _LocalAccountTile(userId: prevUser.id),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AccessBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -120,
          right: -80,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.tertiaryColor.withOpacity(0.06),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccessHeader extends StatelessWidget {
  const _AccessHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceContainer,
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: const Icon(
            Icons.eco,
            color: AppTheme.primaryColor,
            size: 42,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Habitu',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -1.4,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'Gestiona habitos para salud, enfoque, bienestar y cualquier area de tu vida. Si ya tienes cuenta en la nube, entra aqui y cargaremos tus datos en este dispositivo.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}


class _AccessForm extends StatelessWidget {
  final _AccessMode mode;
  final OnboardingNotifier notifier;

  const _AccessForm({
    required this.mode,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (mode == _AccessMode.register) ...[
          TextFormField(
            initialValue: notifier.fullName,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Como quieres que te identifiquemos',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (val) {
              if (mode == _AccessMode.register && (val == null || val.trim().isEmpty)) {
                return 'Ingresa tu nombre';
              }
              return null;
            },
            onChanged: notifier.setFullName,
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          initialValue: notifier.email,
          decoration: const InputDecoration(
            labelText: 'Correo electronico',
            hintText: 'tu@correo.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Ingresa tu correo';
            }
            if (!val.contains('@') || !val.contains('.')) {
              return 'Ingresa un correo valido';
            }
            return null;
          },
          onChanged: notifier.setEmail,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: notifier.password,
          decoration: InputDecoration(
            labelText: 'Contrasena',
            hintText: mode == _AccessMode.signIn
                ? 'Tu contrasena de la nube'
                : 'Minimo 8 caracteres',
            prefixIcon: const Icon(Icons.lock_outline),
          ),
          obscureText: true,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Ingresa tu contrasena';
            }
            if (val.trim().length < 8) {
              return 'Debe tener al menos 8 caracteres';
            }
            return null;
          },
          onChanged: notifier.setPassword,
        ),
        if (mode == _AccessMode.register) ...[
          const SizedBox(height: 16),
          TextFormField(
            initialValue: notifier.confirmPassword,
            decoration: const InputDecoration(
              labelText: 'Confirmar contrasena',
              hintText: 'Repite tu contrasena',
              prefixIcon: Icon(Icons.verified_user_outlined),
            ),
            obscureText: true,
            validator: (val) {
              if (mode == _AccessMode.register && (val == null || val.trim().isEmpty)) {
                return 'Confirma tu contrasena';
              }
              if (mode == _AccessMode.register && val != notifier.password) {
                return 'Las contrasenas no coinciden';
              }
              return null;
            },
            onChanged: notifier.setConfirmPassword,
          ),
        ],
      ],
    );
  }
}

class _LocalAccountsHeader extends StatelessWidget {
  const _LocalAccountsHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Cuentas en este dispositivo',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Entra directo sin repetir el setup inicial.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppTheme.onSurfaceVariant.withOpacity(0.75),
          ),
        ),
      ],
    );
  }
}

class _LocalAccountTile extends StatelessWidget {
  final String userId;

  const _LocalAccountTile({required this.userId});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<OnboardingNotifier>();
    final user = notifier.localUsers.firstWhere((item) => item.id == userId);
    final isGuest = user.email.startsWith('guest_') && user.email.endsWith('@habitu.app');
    final displayEmail = isGuest ? 'Sesion como invitado' : user.email;

    return HabituCard(
      color: AppTheme.surfaceContainerLow,
      borderRadius: 16.0,
      borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            isGuest ? Icons.person_outline : Icons.email_outlined,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          isGuest ? displayEmail : '$displayEmail\nAcceso rapido en este dispositivo',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppTheme.onSurfaceVariant.withOpacity(0.8),
          ),
        ),
        isThreeLine: !isGuest,
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: notifier.isLoading
            ? null
            : () async {
                await notifier.loginWithExistingUser(user.id);
              },
      ),
    );
  }
}
