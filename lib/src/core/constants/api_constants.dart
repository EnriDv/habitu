/// Constantes de API - Endpoints del backend en .NET Core
class ApiConstants {

  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://pierre-players-atom-treaty.trycloudflare.com/api',
  );

  // ==================== AUTH ====================
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String refreshTokenEndpoint = '/auth/refresh-token';
  static const String logoutEndpoint = '/auth/logout';
  static const String validateEmailEndpoint = '/auth/validate-email';

  // ==================== HABITS ====================
  static const String habitsEndpoint = '/habits';
  static const String createHabitEndpoint = '/habits/create';
  static const String updateHabitEndpoint = '/habits/update';
  static const String deleteHabitEndpoint = '/habits/delete';
  static const String completeHabitEndpoint = '/habits/complete';
  static const String uploadEvidenceEndpoint = '/habits/upload-evidence';
  static const String getHabitLogsEndpoint = '/habits/logs';

  // ==================== SYNC ====================
  static const String syncEndpoint = '/sync';
  static const String syncQueueEndpoint = '/sync/queue';

  // ==================== ANALYTICS ====================
  static const String analyticsEndpoint = '/analytics';
  static const String analyticsSummaryEndpoint = '/analytics/summary';

  // ==================== ROUTINES ====================
  static const String routinesEndpoint = '/routines';

  // ==================== TEMPLATES ====================
  static const String templatesEndpoint = '/templates';
  static const String templateGoalsEndpoint = '/templates/goals';

  // ==================== RECOMMENDATIONS ====================
  static const String recommendationsEndpoint = '/recommendations';

  // ==================== FRIENDSHIPS ====================
  static const String friendshipsEndpoint = '/friendships';
  static const String friendshipsSearchEndpoint = '/friendships/search';
  static const String getFriendsEndpoint = '/friendships/list';
  static const String addFriendEndpoint = '/friendships/add';
  static const String removeFriendEndpoint = '/friendships/remove';
  static const String acceptFriendshipEndpoint = '/friendships/accept';
  static const String rejectFriendshipEndpoint = '/friendships/reject';
  static String friendHabitsEndpoint(String friendId) => '/friendships/$friendId/habits';
  static String nudgeFriendEndpoint(String friendId) => '/friendships/$friendId/nudge';
  static String acceptFriendByIdEndpoint(String id) => '/friendships/$id/accept';
  static String rejectFriendByIdEndpoint(String id) => '/friendships/$id/reject';
  static String removeFriendByIdEndpoint(String id) => '/friendships/$id';

  // ==================== SOCIAL ====================
  static const String rankingsEndpoint = '/social/rankings';
  static const String leaderboardEndpoint = '/social/leaderboard';
  static const String challengesEndpoint = '/social/challenges';
  static String joinChallengeEndpoint(String challengeId) => '/challenges/$challengeId/join';

  // ==================== PROFILE ====================
  static const String profileEndpoint = '/profile';
  static const String updateProfileEndpoint = '/profile/update';
  static const String uploadProfilePhotoEndpoint = '/profile/upload-photo';
  static const String getProfilePhotoEndpoint = '/profile/photo';

  // ==================== NOTIFICATIONS ====================
  static const String notificationsEndpoint = '/notifications';
  static const String registerDeviceEndpoint = '/notifications/register-device';
  static const String markNotificationAsReadEndpoint = '/notifications/mark-read';

  // ==================== HEALTH CHECK ====================
  static const String healthCheckEndpoint = '/health';
}

