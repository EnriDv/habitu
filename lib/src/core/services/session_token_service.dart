import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../database/app_database.dart';

class SessionTokenService {
  final AppDatabase _db;

  SessionTokenService({required AppDatabase db}) : _db = db;

  Future<String?> getValidAccessToken() async {
    final activeUser = await (_db.select(_db.usersTable)
          ..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();

    if (activeUser == null) {
      return null;
    }

    final session = await (_db.select(_db.userSessionsTable)
          ..where((t) => t.userId.equals(activeUser.id))
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

    return null;
  }
}
