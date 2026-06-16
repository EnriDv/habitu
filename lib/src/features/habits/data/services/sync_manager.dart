import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../../../../core/database/app_database.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/custom_http_client.dart';
import '../../../../core/constants/api_constants.dart';

class SyncManager {
  final AppDatabase _db;
  final CustomHttpClient _client;
  final ConnectivityService _connectivityService;
  final _uuid = const Uuid();
  bool _isSyncing = false;

  SyncManager({
    required AppDatabase db,
    required CustomHttpClient client,
    required ConnectivityService connectivityService,
  })  : _db = db,
        _client = client,
        _connectivityService = connectivityService {
    // Listen to connectivity shifts to automatically retry when back online
    _connectivityService.statusStream.listen((status) {
      if (status == ConnectionStateStatus.online) {
        sync();
      }
    });
  }

  bool get isSyncing => _isSyncing;

  Future<void> sync() async {
    if (_isSyncing) return;
    
    final connection = await _connectivityService.checkConnection();
    if (connection != ConnectionStateStatus.online) {
      print("Sync skipped: No connection to backend.");
      return;
    }

    _isSyncing = true;
    try {
      final activeUser = await (_db.select(_db.usersTable)
            ..where((t) => t.isActive.equals(true)))
          .getSingleOrNull();
      
      if (activeUser == null) {
        print("Sync skipped: No active user found.");
        return;
      }

      final token = await _getOrRefreshToken(activeUser);
      if (token == null) {
        print("Sync skipped: Could not authenticate user.");
        return;
      }

      final lastSyncedAt = activeUser.lastSyncedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      // Fetch unsynced local changes
      final pendingChanges = await (_db.select(_db.syncQueueTable)
            ..where((t) => t.isDirty.equals(true)))
          .get();

      final habitsToSend = <Map<String, dynamic>>[];
      final logsToSend = <Map<String, dynamic>>[];
      final friendshipsToSend = <Map<String, dynamic>>[];

      for (final change in pendingChanges) {
        try {
          final payload = jsonDecode(change.payload) as Map<String, dynamic>;
          
          if (change.entityType == 'habit') {
            habitsToSend.add({
              'id': change.entityId,
              'title': payload['title'] ?? '',
              'description': payload['description'],
              'frequencyType': payload['frequencyType'] ?? 'daily',
              'frequencyDays': payload['frequencyType'] == 'daily' ? [1, 2, 3, 4, 5, 6, 7] : [],
              'colorHex': payload['colorHex'] ?? '#6366F1',
              'isPublic': payload['isPublic'] ?? false,
              'isDeleted': change.operationType == 'delete' || (payload['isDeleted'] ?? false),
              'createdAt': payload['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
              'updatedAt': payload['updatedAt'] ?? DateTime.now().toUtc().toIso8601String(),
            });
          } else if (change.entityType == 'habit_log') {
            String execDate;
            if (payload['completedAt'] != null) {
              final dt = DateTime.parse(payload['completedAt']);
              execDate = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
            } else {
              final dt = DateTime.now();
              execDate = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
            }

            logsToSend.add({
              'id': change.entityId,
              'habitId': payload['habitId'] ?? '',
              'executionDate': execDate,
              'loggedAt': payload['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
              'evidenceUrl': payload['evidencePhotoUrl'],
              'isDeleted': change.operationType == 'delete',
            });
          }
        } catch (e) {
          print("Error parsing local sync change payload: $e");
        }
      }

      final deviceId = activeUser.id;
      final deviceName = Platform.operatingSystem;
      const appVersion = "1.0.0";

      final syncRequest = {
        'lastSyncedAt': lastSyncedAt.toUtc().toIso8601String(),
        'deviceId': deviceId,
        'deviceName': deviceName,
        'appVersion': appVersion,
        'habits': habitsToSend,
        'habitLogs': logsToSend,
        'friendships': friendshipsToSend,
      };

      final response = await _client.post(
        ApiConstants.syncEndpoint,
        body: syncRequest,
        token: token,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final newSyncTimestamp = DateTime.parse(responseData['newSyncTimestamp']);
        
        final serverHabits = responseData['habits'] as List<dynamic>;
        final serverLogs = responseData['habitLogs'] as List<dynamic>;

        // Apply habits winner (LWW)
        for (final sh in serverHabits) {
          final isDel = sh['isDeleted'] as bool? ?? false;
          if (isDel) {
            await (_db.delete(_db.habitsTable)..where((t) => t.id.equals(sh['id']))).go();
          } else {
            await _db.into(_db.habitsTable).insertOnConflictUpdate(
              HabitsTableCompanion.insert(
                id: sh['id'],
                userId: activeUser.id,
                title: sh['title'],
                description: Value(sh['description']),
                frequencyType: sh['frequencyType'],
                colorHex: Value(sh['colorHex'] ?? '#6366F1'),
                isPublic: Value(sh['isPublic'] ?? false),
                isDeleted: const Value(false),
                createdAt: Value(DateTime.parse(sh['createdAt'])),
                updatedAt: Value(DateTime.parse(sh['updatedAt'])),
                remoteId: Value(sh['id']),
              ),
            );
          }
        }

        // Apply logs winner (LWW)
        for (final sl in serverLogs) {
          final isDel = sl['isDeleted'] as bool? ?? false;
          if (isDel) {
            await (_db.delete(_db.habitLogsTable)..where((t) => t.id.equals(sl['id']))).go();
          } else {
            final loggedAt = DateTime.parse(sl['loggedAt']);
            await _db.into(_db.habitLogsTable).insertOnConflictUpdate(
              HabitLogsTableCompanion.insert(
                id: sl['id'],
                habitId: sl['habitId'],
                userId: activeUser.id,
                completedAt: Value(loggedAt),
                notes: Value(sl['notes']),
                evidencePhotoUrl: Value(sl['evidenceUrl']),
                createdAt: Value(loggedAt),
                remoteId: Value(sl['id']),
              ),
            );
          }
        }

        // Mark local queue items as clean/synced
        for (final change in pendingChanges) {
          await (_db.update(_db.syncQueueTable)
                ..where((t) => t.id.equals(change.id)))
              .write(
            SyncQueueTableCompanion(
              isDirty: const Value(false),
              status: const Value('synced'),
              syncedAt: Value(DateTime.now()),
            ),
          );
        }

        // Update active user's lastSyncedAt
        await (_db.update(_db.usersTable)
              ..where((t) => t.id.equals(activeUser.id)))
            .write(
          UsersTableCompanion(
            lastSyncedAt: Value(newSyncTimestamp),
          ),
        );

        print("Sync completed successfully at $newSyncTimestamp.");
      } else {
        print("Sync failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Sync encountered an error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Future<String?> _getOrRefreshToken(UsersTableData user) async {
    try {
      final session = await (_db.select(_db.userSessionsTable)
            ..where((t) => t.userId.equals(user.id))
            ..where((t) => t.isActive.equals(true))
            ..limit(1))
          .getSingleOrNull();

      if (session != null) {
        if (session.expiresAt.isAfter(DateTime.now().add(const Duration(minutes: 5)))) {
          return session.accessToken;
        }

        if (session.refreshToken != null) {
          final response = await http.post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshTokenEndpoint}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': session.refreshToken}),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final newAccess = data['accessToken'] as String;
            final newRefresh = data['refreshToken'] as String?;
            
            await (_db.update(_db.userSessionsTable)
                  ..where((t) => t.id.equals(session.id)))
                .write(
              UserSessionsTableCompanion(
                accessToken: Value(newAccess),
                refreshToken: Value(newRefresh),
                expiresAt: Value(DateTime.now().add(const Duration(days: 7))),
              ),
            );
            return newAccess;
          }
        }
      }

      final password = "${user.email}_Habitu2026!";
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': user.email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String?;

        await (_db.update(_db.userSessionsTable)
              ..where((t) => t.userId.equals(user.id)))
            .write(const UserSessionsTableCompanion(isActive: Value(false)));

        await _db.into(_db.userSessionsTable).insert(
          UserSessionsTableCompanion.insert(
            id: _uuid.v4(),
            userId: user.id,
            accessToken: accessToken,
            refreshToken: Value(refreshToken),
            expiresAt: DateTime.now().add(const Duration(days: 7)),
            isActive: const Value(true),
          ),
        );
        return accessToken;
      }

      // Automatically register user if not found/created on backend yet
      final regResponse = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': user.email,
          'password': password,
          'fullName': user.fullName,
          'universityHeadquarters': 'Sede Central',
          'academicProgram': 'Estudiante',
          'bio': '',
        }),
      );

      if (regResponse.statusCode == 200 || regResponse.statusCode == 201) {
        final data = jsonDecode(regResponse.body) as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String;
        final refreshToken = data['refreshToken'] as String?;

        await (_db.update(_db.userSessionsTable)
              ..where((t) => t.userId.equals(user.id)))
            .write(const UserSessionsTableCompanion(isActive: Value(false)));

        await _db.into(_db.userSessionsTable).insert(
          UserSessionsTableCompanion.insert(
            id: _uuid.v4(),
            userId: user.id,
            accessToken: accessToken,
            refreshToken: Value(refreshToken),
            expiresAt: DateTime.now().add(const Duration(days: 7)),
            isActive: const Value(true),
          ),
        );
        return accessToken;
      }
    } catch (e) {
      print("Authentication auto-login failed: $e");
    }
    return null;
  }
}
