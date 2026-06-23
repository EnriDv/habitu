import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import '../../../../core/database/app_database.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/custom_http_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/device_installation_service.dart';
import 'package:path_provider/path_provider.dart';

enum SyncMode {
  pullOnly,
  full,
}

class SyncManager {
  final AppDatabase _db;
  final CustomHttpClient _client;
  final ConnectivityService _connectivityService;
  final DeviceInstallationService _deviceInstallationService;
  bool _isSyncing = false;

  SyncManager({
    required AppDatabase db,
    required CustomHttpClient client,
    required ConnectivityService connectivityService,
    required DeviceInstallationService deviceInstallationService,
  })  : _db = db,
        _client = client,
        _connectivityService = connectivityService,
        _deviceInstallationService = deviceInstallationService;

  bool get isSyncing => _isSyncing;

  Future<bool> sync({SyncMode mode = SyncMode.full}) async {
    if (_isSyncing) return false;
    
    final connection = await _connectivityService.checkConnection();
    if (connection != ConnectionStateStatus.online) {
      print("Sync skipped: No connection to backend.");
      return false;
    }

    _isSyncing = true;
    try {
      final activeUser = await (_db.select(_db.usersTable)
            ..where((t) => t.isActive.equals(true)))
          .getSingleOrNull();
      
      if (activeUser == null) {
        print("Sync skipped: No active user found.");
        return false;
      }

      final token = await _getOrRefreshToken(activeUser);
      if (token == null) {
        print("Sync skipped: Could not authenticate user.");
        return false;
      }

      final lastSyncedAt = activeUser.lastSyncedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      final pendingChanges = mode == SyncMode.full
          ? await (_db.select(_db.syncQueueTable)
                ..where((t) => t.isDirty.equals(true)))
              .get()
          : <SyncQueueTableData>[];

      final habitsToSend = <Map<String, dynamic>>[];
      final logsToSend = <Map<String, dynamic>>[];
      final friendshipsToSend = <Map<String, dynamic>>[];

      final activeUserId = activeUser.id;
      for (final change in pendingChanges) {
        try {
          final payload = jsonDecode(change.payload) as Map<String, dynamic>;
          final payloadUserId = payload['userId'];
          if (payloadUserId != null && payloadUserId != activeUserId) {
            continue;
          }
          
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

      final deviceId = await _deviceInstallationService.getOrCreateDeviceId();
      final deviceName = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
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
        await _persistConflicts(responseData['conflicts'] as List<dynamic>? ?? const []);
        
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
        if (mode == SyncMode.full) {
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
        return true;
      } else {
        await _persistConflicts(const []);
        print("Sync failed with status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Sync encountered an error: $e");
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  Future<int> getPendingConflictCount() async {
    final conflicts = await getPendingConflicts();
    return conflicts.length;
  }

  Future<List<Map<String, dynamic>>> getPendingConflicts() async {
    final file = await _getConflictsFile();
    if (!await file.exists()) {
      return const [];
    }

    try {
      final content = await file.readAsString();
      final decoded = jsonDecode(content) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> clearPendingConflicts() async {
    await _persistConflicts(const []);
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
    } catch (e) {
      print("Authentication refresh failed: $e");
    }
    return null;
  }

  Future<File> _getConflictsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/sync_conflicts.json');
  }

  Future<void> _persistConflicts(List<dynamic> conflicts) async {
    final file = await _getConflictsFile();
    await file.writeAsString(jsonEncode(conflicts));
  }
}

