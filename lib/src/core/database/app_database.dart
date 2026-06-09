import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../constants/app_constants.dart';

class UsersTable extends Table {
  TextColumn get id => text()(); // UUID del usuario
  TextColumn get email => text().unique()(); // Email @ucb.edu.bo
  TextColumn get fullName => text()(); // Nombre completo del usuario
  TextColumn get profilePictureUrl => text().nullable()(); // URL de foto de perfil
  TextColumn get role => text().withDefault(const Constant('student'))(); // Rol: student, admin, moderator
  TextColumn get ucbId => text().nullable()(); // ID interno de la UCB
  BoolColumn get isActive => boolean().withDefault(const Constant(true))(); // Usuario activo
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de hábitos locales
class HabitsTable extends Table {
  TextColumn get id => text()(); // UUID del hábito (generado en Flutter)
  TextColumn get userId => text()(); // Referencia al usuario propietario
  TextColumn get title => text().withLength(min: 1, max: 100)(); // Nombre del hábito
  TextColumn get description => text().nullable()(); // Descripción opcional
  TextColumn get frequencyType => text()(); // daily, weekly, monthly, once_off
  TextColumn get colorHex =>
      text().withDefault(const Constant('#6366F1'))(); // Color en formato hex
  TextColumn get icon => text().nullable()(); // Emoji o nombre del icono
  BoolColumn get isPublic =>
      boolean().withDefault(const Constant(false))(); // Compartido con amigos
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))(); // Marcado como eliminado
  TextColumn get remoteId => text().nullable()(); // ID remoto en backend
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {userId, title}, // Un usuario no puede tener dos hábitos con el mismo nombre
  ];
}

/// Tabla de logs de hábitos completados (cada vez que completa un hábito)
class HabitLogsTable extends Table {
  TextColumn get id => text()(); // UUID del log
  TextColumn get habitId => text()(); // Referencia al hábito
  TextColumn get userId => text()(); // Usuario que completó
  DateTimeColumn get completedAt =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().nullable()(); // Notas opcionales
  TextColumn get evidencePhotoUrl => text().nullable()(); // URL de foto de evidencia
  TextColumn get confidenceLevel =>
      text().nullable()(); // 'trust_me', 'photo', 'auto_detected', etc.
  TextColumn get remoteId => text().nullable()(); // ID remoto en backend
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {habitId, completedAt}, // No puede completar el mismo hábito dos veces en el mismo día
  ];
}

/// Tabla de cola de sincronización (para registrar cambios pendientes de sincronizar)
class SyncQueueTable extends Table {
  TextColumn get id => text()(); // UUID del registro en la cola
  TextColumn get operationType => text()(); // 'create', 'update', 'delete'
  TextColumn get entityType => text()(); // 'habit', 'habit_log', 'friendship', etc.
  TextColumn get entityId => text()(); // ID de la entidad afectada
  TextColumn get payload => text()(); // JSON serializado del payload a enviar
  BoolColumn get isDirty =>
      boolean().withDefault(const Constant(true))(); // Pendiente de sincronizar
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, syncing, synced, error
  TextColumn get errorMessage => text().nullable()(); // Mensaje de error si falló
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de amigos (contactos agregados)
class FriendshipsTable extends Table {
  TextColumn get id => text()(); // UUID de la amistad
  TextColumn get userId => text()(); // Usuario actual
  TextColumn get friendUserId => text()(); // Usuario amigo
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending, accepted, blocked
  TextColumn get contactHash => text().nullable()(); // Hash SHA-256 del contacto para privacidad
  BoolColumn get canSeeHabits =>
      boolean().withDefault(const Constant(true))(); // Puede ver hábitos del amigo
  TextColumn get remoteId => text().nullable()(); // ID remoto en backend
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {userId, friendUserId}, // Un usuario no puede agregar dos veces el mismo amigo
  ];
}

/// Tabla de sesiones de usuario (tokens y información de autenticación)
class UserSessionsTable extends Table {
  TextColumn get id => text()(); // UUID de la sesión
  TextColumn get userId => text()(); // Referencia al usuario
  TextColumn get accessToken => text()(); // JWT token de acceso
  TextColumn get refreshToken => text().nullable()(); // JWT token de refresco
  DateTimeColumn get expiresAt => dateTime()(); // Fecha de expiración del token
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))(); // Sesión activa
  TextColumn get deviceId => text().nullable()(); // ID del dispositivo
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastActivityAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de notificaciones recibidas
class NotificationsTable extends Table {
  TextColumn get id => text()(); // UUID de la notificación
  TextColumn get userId => text()(); // Usuario receptor
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get payload => text().nullable()(); // JSON adicional
  BoolColumn get isRead =>
      boolean().withDefault(const Constant(false))(); // Leída por el usuario
  TextColumn get type => text().nullable()(); // 'streak_reached', 'friend_joined', etc.
  TextColumn get remoteId => text().nullable()(); // ID remoto en backend
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get readAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de rankings locales en caché (se actualiza en cada sincronización)
class RankingsTable extends Table {
  TextColumn get id => text()(); // UUID del ranking
  TextColumn get challengeId => text()(); // Referencia al desafío/categoría
  TextColumn get userId => text()(); // Usuario en el ranking
  IntColumn get position => integer()(); // Posición en el ranking
  IntColumn get totalPoints => integer()(); // Puntos totales
  IntColumn get currentStreak => integer()(); // Racha actual
  TextColumn get userName => text()(); // Nombre del usuario (cacheado)
  TextColumn get profilePictureUrl => text().nullable()(); // Foto (cacheada)
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {challengeId, userId}, // Un usuario solo aparece una vez por desafío
  ];
}

// ==================== BASE DE DATOS DRIFT ====================

// @DriftDatabase(tables: [
//   UsersTable,
//   HabitsTable,
//   HabitLogsTable,
//   SyncQueueTable,
//   FriendshipsTable,
//   UserSessionsTable,
//   NotificationsTable,
//   RankingsTable,
// ])
// class AppDatabase extends _$AppDatabase {
//   AppDatabase() : super(_openConnection());
//
//   @override
//   int get schemaVersion => 1;
//
//   // Migrations aquí si es necesario en versiones futuras
// }

/// Inicialización de la conexión a SQLite nativa
/// 
/// Abre la base de datos en la carpeta de documentos de la aplicación
/// de forma asíncrona (no bloquea el hilo principal)
QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseFileName));

    // Crear conexión nativa a SQLite
    return NativeDatabase.createInBackground(file);
  });
}
