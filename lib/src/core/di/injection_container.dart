import 'package:get_it/get_it.dart';
import '../network/custom_http_client.dart';
import '../network/connectivity_service.dart';
import '../database/app_database.dart';
import '../services/app_sync_coordinator.dart';
import '../services/session_token_service.dart';
import '../services/deep_link_service.dart';
import '../services/device_installation_service.dart';
import '../../features/habits/data/datasources/habits_local_datasource.dart';
import '../../features/habits/data/datasources/habits_remote_datasource.dart';
import '../../features/habits/data/repositories/progress_hub_repository.dart';
import '../../features/habits/data/repositories/habits_repository_impl.dart';
import '../../features/habits/domain/repositories/habits_repository.dart';
import '../../features/habits/presentation/notifiers/habits_notifier.dart';
import '../../features/habits/presentation/notifiers/progress_hub_notifier.dart';
import '../../features/habits/data/services/sync_manager.dart';
import '../../features/onboarding/presentation/notifiers/session_onboarding_notifier.dart';
import '../../features/social/data/datasources/social_remote_datasource.dart';
import '../../features/social/presentation/notifiers/social_notifier.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  sl.registerLazySingleton<CustomHttpClient>(() => CustomHttpClient());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<DeviceInstallationService>(() => DeviceInstallationService());
  sl.registerLazySingleton<DeepLinkService>(() => DeepLinkService());
  sl.registerLazySingleton<SessionTokenService>(
    () => SessionTokenService(db: sl<AppDatabase>()),
  );
  sl.registerLazySingleton<SyncManager>(() => SyncManager(
        db: sl<AppDatabase>(),
        client: sl<CustomHttpClient>(),
        connectivityService: sl<ConnectivityService>(),
        deviceInstallationService: sl<DeviceInstallationService>(),
      ));
  sl.registerLazySingleton<AppSyncCoordinator>(
    () => AppSyncCoordinator(syncManager: sl<SyncManager>()),
  );

  sl.registerLazySingleton<OnboardingNotifier>(
    () => OnboardingNotifier(db: sl<AppDatabase>()),
  );

  sl.registerLazySingleton<HabitsRemoteDataSource>(
    () => HabitsRemoteDataSource(sl<CustomHttpClient>()),
  );

  sl.registerLazySingleton<HabitsLocalDataSource>(
    () => HabitsLocalDataSource(db: sl<AppDatabase>()),
  );

  sl.registerLazySingleton<HabitsRepository>(
    () => HabitsRepositoryImpl(
      localDataSource: sl<HabitsLocalDataSource>(),
      remoteDataSource: sl<HabitsRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<ProgressHubRepository>(
    () => ProgressHubRepository(
      db: sl<AppDatabase>(),
      client: sl<CustomHttpClient>(),
      tokenService: sl<SessionTokenService>(),
    ),
  );

  sl.registerLazySingleton<HabitsNotifier>(
    () => HabitsNotifier(repository: sl<HabitsRepository>()),
  );

  sl.registerLazySingleton<ProgressHubNotifier>(
    () => ProgressHubNotifier(
      repository: sl<ProgressHubRepository>(),
      habitsRepository: sl<HabitsRepository>(),
      db: sl<AppDatabase>(),
    ),
  );

  sl.registerLazySingleton<SocialRemoteDatasource>(
    () => SocialRemoteDatasource(sl<CustomHttpClient>()),
  );

  sl.registerLazySingleton<SocialNotifier>(
    () => SocialNotifier(
      datasource: sl<SocialRemoteDatasource>(),
      tokenService: sl<SessionTokenService>(),
    ),
  );
}

void cleanup() {
}
