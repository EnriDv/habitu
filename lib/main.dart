import 'package:flutter/material.dart';
import 'package:habitu_ui/habitu_ui.dart';
import 'package:provider/provider.dart';
import 'src/core/di/injection_container.dart' as di;
import 'src/core/services/app_sync_coordinator.dart';
import 'src/core/services/deep_link_service.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/constants/app_constants.dart';
import 'src/features/habits/presentation/notifiers/habits_notifier.dart';
import 'src/features/habits/presentation/notifiers/progress_hub_notifier.dart';
import 'src/features/onboarding/presentation/notifiers/session_onboarding_notifier.dart';
import 'src/features/onboarding/presentation/screens/access_screen.dart';
import 'src/features/onboarding/presentation/screens/initial_setup_screen.dart';
import 'src/features/habits/presentation/screens/habits_today_screen.dart';
import 'src/features/habits/presentation/screens/progress_screen.dart';
import 'src/features/social/presentation/screens/comunidad_screen.dart';
import 'src/features/profile/presentation/screens/profile_screen.dart';
import 'src/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<HabitsNotifier>(
          create: (_) => di.sl<HabitsNotifier>(),
        ),
        ChangeNotifierProvider<ProgressHubNotifier>(
          create: (_) => di.sl<ProgressHubNotifier>(),
        ),
        ChangeNotifierProvider<OnboardingNotifier>(
          create: (_) => di.sl<OnboardingNotifier>(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: di.sl<DeepLinkService>().navigatorKey,
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getLightTheme(),
        darkTheme: AppTheme.getDarkTheme(),
        themeMode: ThemeMode.dark, // Default to Dark as per Academic Ethereal brief
        home: const AppLifecycleSyncGate(
          child: HomeScreenStateWrapper(),
        ),
      ),
    );
  }
}

class AppLifecycleSyncGate extends StatefulWidget {
  final Widget child;

  const AppLifecycleSyncGate({super.key, required this.child});

  @override
  State<AppLifecycleSyncGate> createState() => _AppLifecycleSyncGateState();
}

class _AppLifecycleSyncGateState extends State<AppLifecycleSyncGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncAndRefresh(force: true);
      await NotificationService().consumePendingLaunchPayload();
      await _handlePlatformLaunchRoute();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncAndRefresh();
    }
  }

  Future<void> _syncAndRefresh({bool force = false}) async {
    if (!mounted) return;

    final onboardingNotifier = context.read<OnboardingNotifier>();
    final habitsNotifier = context.read<HabitsNotifier>();
    final progressHubNotifier = context.read<ProgressHubNotifier>();
    await di.sl<AppSyncCoordinator>().syncAndRefresh(
          onboardingNotifier: onboardingNotifier,
          habitsNotifier: habitsNotifier,
          force: force,
        );
    await progressHubNotifier.initialize();
  }

  Future<void> _handlePlatformLaunchRoute() async {
    final routeName = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (routeName.startsWith('habitu://')) {
      await di.sl<DeepLinkService>().handleLink(routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class HomeScreenStateWrapper extends StatelessWidget {
  const HomeScreenStateWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingNotifier>();

    if (!onboarding.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (onboarding.hasUser) {
      if (onboarding.shouldShowInitialSetup) {
        return const InitialSetupScreen();
      }
      return const MainDashboardScaffold();
    } else {
      return const OnboardingScreen();
    }
  }
}

class MainDashboardScaffold extends StatefulWidget {
  const MainDashboardScaffold({super.key});

  @override
  State<MainDashboardScaffold> createState() => _MainDashboardScaffoldState();
}

class _MainDashboardScaffoldState extends State<MainDashboardScaffold> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HabitsTodayScreen(),
    const ProgressScreen(),
    const ComunidadScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: HabituNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Hoy'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progreso'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Comunidad'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Mi Espacio'),
        ],
      ),
    );
  }
}
