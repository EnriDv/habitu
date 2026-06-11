import 'package:get_it/get_it.dart';
import '../network/custom_http_client.dart';
import '../database/app_database.dart';
import '../../features/habits/data/datasources/habits_local_datasource.dart';
import '../../features/habits/data/datasources/habits_remote_datasource.dart';
import '../../features/habits/data/repositories/habits_repository_impl.dart';
import '../../features/habits/domain/repositories/habits_repository.dart';
import '../../features/habits/presentation/notifiers/habits_notifier.dart';
import '../../features/onboarding/presentation/notifiers/onboarding_notifier.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Database
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // Network
  sl.registerLazySingleton<CustomHttpClient>(() => CustomHttpClient());

  // Onboarding Feature
  sl.registerLazySingleton<OnboardingNotifier>(
    () => OnboardingNotifier(db: sl<AppDatabase>()),
  );

  // Habits Feature DataSources
  sl.registerLazySingleton<HabitsRemoteDataSource>(
    () => HabitsRemoteDataSource(),
  );

  sl.registerLazySingleton<HabitsLocalDataSource>(
    () => HabitsLocalDataSource(db: sl<AppDatabase>()),
  );

  // Habits Feature Repository
  sl.registerLazySingleton<HabitsRepository>(
    () => HabitsRepositoryImpl(
      localDataSource: sl<HabitsLocalDataSource>(),
      remoteDataSource: sl<HabitsRemoteDataSource>(),
    ),
  );

  // Habits Feature Notifiers
  sl.registerLazySingleton<HabitsNotifier>(
    () => HabitsNotifier(repository: sl<HabitsRepository>()),
  );

  print('✅ Dependencias inicializadas correctamente');
}

void cleanup() {
  GetIt.instance.reset();
}
