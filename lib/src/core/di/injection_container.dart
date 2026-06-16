import 'package:get_it/get_it.dart';
import '../network/custom_http_client.dart';
import '../network/connectivity_service.dart';
import '../database/app_database.dart';
import '../../features/habits/data/datasources/habits_local_datasource.dart';
import '../../features/habits/data/datasources/habits_remote_datasource.dart';
import '../../features/habits/data/repositories/habits_repository_impl.dart';
import '../../features/habits/domain/repositories/habits_repository.dart';
import '../../features/habits/presentation/notifiers/habits_notifier.dart';
import '../../features/habits/data/services/sync_manager.dart';
import '../../features/onboarding/presentation/notifiers/onboarding_notifier.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  sl.registerLazySingleton<CustomHttpClient>(() => CustomHttpClient());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<SyncManager>(() => SyncManager(
        db: sl<AppDatabase>(),
        client: sl<CustomHttpClient>(),
        connectivityService: sl<ConnectivityService>(),
      ));

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

  sl.registerLazySingleton<HabitsNotifier>(
    () => HabitsNotifier(repository: sl<HabitsRepository>()),
  );
}

void cleanup() {
}
