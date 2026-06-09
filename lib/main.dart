import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/core/di/injection_container.dart' as di;
import 'src/core/theme/app_theme.dart';
import 'src/core/constants/app_constants.dart';
import 'src/features/habits/presentation/notifiers/habits_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: ThemeMode.system,
      
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<HabitsNotifier>(
            create: (_) => di.sl<HabitsNotifier>(),
          ),
          // TODO: Registrar otros ChangeNotifiers a medida que se creen
          // === Feature: Onboarding ===
          // ChangeNotifierProvider<OnboardingNotifier>(
          //   create: (_) => OnboardingNotifier(),
          // ),
          // === Feature: Social ===
          // ChangeNotifierProvider<SocialNotifier>(
          //   create: (_) => SocialNotifier(),
          // ),
          // === Feature: Sync ===
          // ChangeNotifierProvider<SyncNotifier>(
          //   create: (_) => SyncNotifier(),
          // ),
          // === Feature: Profile ===
          // ChangeNotifierProvider<ProfileNotifier>(
          //   create: (_) => ProfileNotifier(),
          // ),
        ],
        child: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habitü'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_box_outlined,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              AppConstants.appDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navegar a OnboardingScreen (login)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ir a Login')),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Iniciar Sesión'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Navegar a RegisterScreen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ir a Registro')),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Crear Cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
