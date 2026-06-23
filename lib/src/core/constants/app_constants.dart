/// Constantes de la aplicación - Colores, strings e identificadores globales
class AppConstants {
  // ==================== APP INFO ====================
  static const String appName = 'Habitü';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Autogestión de hábitos con sincronización offline-first';

  // ==================== TIMEOUTS ====================
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 60);

  // ==================== DATABASE ====================
  static const String databaseFileName = 'habitu_local.db';
  static const int databaseVersion = 1;

  // ==================== FREQUENCY TYPES ====================
  static const String frequencyDaily = 'daily';
  static const String frequencyWeekly = 'weekly';
  static const String frequencyMonthly = 'monthly';
  static const String frequencyOnceOff = 'once_off';

  static const List<String> frequencyTypes = [
    frequencyDaily,
    frequencyWeekly,
    frequencyMonthly,
    frequencyOnceOff,
  ];

  // ==================== HABIT STATUS ====================
  static const String habitStatusActive = 'active';
  static const String habitStatusCompleted = 'completed';
  static const String habitStatusAbandoned = 'abandoned';
  static const String habitStatusPaused = 'paused';

  // ==================== SYNC STATUS ====================
  static const String syncStatusPending = 'pending';
  static const String syncStatusSyncing = 'syncing';
  static const String syncStatusSynced = 'synced';
  static const String syncStatusError = 'error';

  // ==================== USER ROLE ====================
  static const String roleStudent = 'student';
  static const String roleAdmin = 'admin';
  static const String roleModerator = 'moderator';

  // ==================== EMAIL DOMAIN ====================
  static const String universitEmailDomain = '@ucb.edu.bo';

  // ==================== VALIDATION ====================
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minHabitTitleLength = 3;
  static const int maxHabitTitleLength = 100;
  static const int minHabitDescriptionLength = 0;
  static const int maxHabitDescriptionLength = 500;

  // ==================== PAGINATION ====================
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // ==================== CACHE ====================
  static const Duration cacheDurationShort = Duration(minutes: 5);
  static const Duration cacheDurationMedium = Duration(minutes: 30);
  static const Duration cacheDurationLong = Duration(hours: 1);
}
