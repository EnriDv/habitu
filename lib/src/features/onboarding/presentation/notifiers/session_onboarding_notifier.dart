import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../habits/data/services/sync_manager.dart';
import '../../domain/entities/user.dart' as ent;

class OnboardingNotifier extends ChangeNotifier {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ent.User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String _fullName = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _isInitialized = false;
  bool _hasCompletedInitialSetup = false;
  bool _isCurrentUserCloudLinked = false;
  List<String> _selectedFocusAreas = [];
  List<ent.User> _localUsers = [];

  OnboardingNotifier({required AppDatabase db}) : _db = db {
    checkActiveUser();
  }

  ent.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get fullName => _fullName;
  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  bool get isInitialized => _isInitialized;
  bool get hasUser => _user != null;
  bool get hasCompletedInitialSetup => _hasCompletedInitialSetup;
  bool get shouldShowInitialSetup => hasUser && !_hasCompletedInitialSetup;
  bool get isCurrentUserCloudLinked => _isCurrentUserCloudLinked;
  List<ent.User> get localUsers => _localUsers;
  List<String> get selectedFocusAreas => _selectedFocusAreas;

  void setFullName(String val) {
    _fullName = val;
    notifyListeners();
  }

  void setEmail(String val) {
    _email = val;
    notifyListeners();
  }

  void setPassword(String val) {
    _password = val;
    notifyListeners();
  }

  void setConfirmPassword(String val) {
    _confirmPassword = val;
    notifyListeners();
  }

  void toggleFocusArea(String areaId) {
    if (_selectedFocusAreas.contains(areaId)) {
      _selectedFocusAreas.remove(areaId);
    } else {
      _selectedFocusAreas.add(areaId);
    }
    notifyListeners();
  }

  Future<void> checkActiveUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final query = _db.select(_db.usersTable)..where((t) => t.isActive.equals(true));
      final rows = await query.get();
      if (rows.isNotEmpty) {
        _user = _mapUser(rows.first);
        await _loadSetupStateForCurrentUser();
        await _refreshCloudLinkStatus();
      } else {
        _user = null;
        _hasCompletedInitialSetup = false;
        _selectedFocusAreas = [];
        _isCurrentUserCloudLinked = false;
      }

      await _loadLocalUsersList();
    } catch (e) {
      _errorMessage = _toUserMessage(e);
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedEmail = _email.trim().toLowerCase();
      if (!normalizedEmail.contains('@') || !normalizedEmail.contains('.')) {
        throw Exception('Ingresa un correo electronico valido');
      }
      _validatePassword(_password, message: 'Ingresa tu contrasena para iniciar sesion');

      final auth = await _loginAgainstCloud(
        email: normalizedEmail,
        password: _password.trim(),
      );
      final localUser = await _upsertCloudUser(auth);
      await _activateUser(localUser.id);
      _user = localUser.copyWith(isActive: true);
      _password = '';
      _confirmPassword = '';
      await _loadSetupStateForCurrentUser();
      await _refreshCloudLinkStatus();
      await _loadLocalUsersList();
      await _triggerPullSync();
      return true;
    } catch (e) {
      _errorMessage = _toUserMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerAccount({bool anonymous = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = _uuid.v4();
      final now = DateTime.now();
      final userEmail = anonymous
          ? 'guest_$userId@habitu.app'
          : _email.trim().toLowerCase();
      final userName = anonymous
          ? (_fullName.trim().isNotEmpty ? _fullName.trim() : 'Invitado Habitu')
          : _fullName.trim();

      if (!anonymous && (!userEmail.contains('@') || !userEmail.contains('.'))) {
        throw Exception('Ingresa un correo electronico valido');
      }

      if (!anonymous && userName.isEmpty) {
        throw Exception('El nombre es obligatorio para crear una cuenta');
      }

      if (!anonymous) {
        _validatePassword(_password);
        if (_password != _confirmPassword) {
          throw Exception('Las contrasenas no coinciden');
        }
      }

      await _activateUser(null);

      if (anonymous) {
        final existingQuery = _db.select(_db.usersTable)..where((t) => t.email.equals(userEmail));
        final existingUsers = await existingQuery.get();
        if (existingUsers.isNotEmpty) {
          throw Exception('Ya existe una cuenta local con ese correo. Usa iniciar sesion.');
        }

        await _db.into(_db.usersTable).insert(
          UsersTableCompanion.insert(
            id: userId,
            email: userEmail,
            fullName: userName,
            role: const Value('member'),
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        _user = ent.User(
          id: userId,
          email: userEmail,
          fullName: userName,
          role: 'member',
          isActive: true,
          createdAt: now,
        );
      } else {
        final auth = await _registerAgainstCloud(
          email: userEmail,
          fullName: userName,
          password: _password.trim(),
        );
        final localUser = await _upsertCloudUser(auth);
        await _activateUser(localUser.id);
        _user = localUser.copyWith(isActive: true);
        _password = '';
        _confirmPassword = '';
      }

      _selectedFocusAreas = [];
      _hasCompletedInitialSetup = false;
      await _saveSetupState(userId: _user!.id, isComplete: false, focusAreas: const []);
      await _refreshCloudLinkStatus();
      await _loadLocalUsersList();
      return true;
    } catch (e) {
      _errorMessage = _toUserMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithExistingUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _activateUser(userId);
      final query = _db.select(_db.usersTable)..where((t) => t.id.equals(userId));
      final rows = await query.get();
      if (rows.isNotEmpty) {
        _user = _mapUser(rows.first);
      }

      await _loadSetupStateForCurrentUser();
      await _refreshCloudLinkStatus();
      await _loadLocalUsersList();
      await _triggerPullSync();
      return true;
    } catch (e) {
      _errorMessage = _toUserMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> completeInitialSetup({required List<String> focusAreas}) async {
    if (_user == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedFocusAreas = List<String>.from(focusAreas);
      _hasCompletedInitialSetup = true;
      await _saveSetupState(
        userId: _user!.id,
        isComplete: true,
        focusAreas: _selectedFocusAreas,
      );
      return true;
    } catch (e) {
      _errorMessage = _toUserMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _db.update(_db.usersTable).write(const UsersTableCompanion(isActive: Value(false)));
      _user = null;
      _hasCompletedInitialSetup = false;
      _selectedFocusAreas = [];
      _fullName = '';
      _email = '';
      _password = '';
      _confirmPassword = '';
      _isCurrentUserCloudLinked = false;
      await _loadLocalUsersList();
    } catch (e) {
      _errorMessage = _toUserMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLocalUsersList() async {
    try {
      final allUsersQuery = _db.select(_db.usersTable);
      final allRows = await allUsersQuery.get();
      _localUsers = allRows.map(_mapUser).toList();
    } catch (e) {
      debugPrint('Error loading local users: $e');
    }
  }

  ent.User _mapUser(UsersTableData row) {
    return ent.User(
      id: row.id,
      email: row.email,
      fullName: row.fullName,
      profilePictureUrl: row.profilePictureUrl,
      role: row.role,
      ucbId: row.ucbId,
      isActive: row.isActive,
      createdAt: row.createdAt,
    );
  }

  Future<void> _activateUser(String? userId) async {
    await _db.update(_db.usersTable).write(const UsersTableCompanion(isActive: Value(false)));

    if (userId != null) {
      await (_db.update(_db.usersTable)..where((t) => t.id.equals(userId))).write(
        UsersTableCompanion(
          isActive: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<File> _getSetupStateFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/onboarding_state.json');
  }

  Future<Map<String, dynamic>> _readSetupState() async {
    final file = await _getSetupStateFile();
    if (!await file.exists()) {
      return {};
    }

    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {};
  }

  Future<void> _saveSetupState({
    required String userId,
    required bool isComplete,
    required List<String> focusAreas,
  }) async {
    final file = await _getSetupStateFile();
    final state = await _readSetupState();
    state[userId] = {
      'completed': isComplete,
      'focusAreas': focusAreas,
    };
    await file.writeAsString(jsonEncode(state));
  }

  Future<void> _loadSetupStateForCurrentUser() async {
    if (_user == null) {
      _hasCompletedInitialSetup = false;
      _selectedFocusAreas = [];
      return;
    }

    final state = await _readSetupState();
    final currentUserState = state[_user!.id];

    if (currentUserState is Map<String, dynamic>) {
      _hasCompletedInitialSetup = currentUserState['completed'] as bool? ?? false;
      final storedAreas = currentUserState['focusAreas'] as List<dynamic>? ?? const [];
      _selectedFocusAreas = storedAreas.map((area) => area.toString()).toList();
      return;
    }

    _hasCompletedInitialSetup = true;
    _selectedFocusAreas = [];
  }

  Future<bool> linkCurrentAccountToCloud({
    required String email,
    required String password,
    required String confirmPassword,
    String? fullName,
  }) async {
    if (_user == null) {
      _errorMessage = 'No hay una cuenta local activa para vincular.';
      notifyListeners();
      return false;
    }
    if (_isCurrentUserCloudLinked) {
      _errorMessage = 'Esta cuenta ya esta vinculada a la nube.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (!normalizedEmail.contains('@') || !normalizedEmail.contains('.')) {
        throw Exception('Ingresa un correo electronico valido');
      }

      _validatePassword(password);
      if (password != confirmPassword) {
        throw Exception('Las contrasenas no coinciden');
      }

      final auth = await _registerAgainstCloud(
        email: normalizedEmail,
        fullName: (fullName?.trim().isNotEmpty ?? false)
            ? fullName!.trim()
            : _user!.fullName,
        password: password.trim(),
      );
      final localUser = await _upsertCloudUser(
        auth,
        migrateFromUserId: _user!.id,
      );
      await _activateUser(localUser.id);
      _user = localUser.copyWith(isActive: true);
      _email = normalizedEmail;
      _password = '';
      _confirmPassword = '';
      await _loadSetupStateForCurrentUser();
      await _refreshCloudLinkStatus();
      await _loadLocalUsersList();
      await GetIt.instance<SyncManager>().sync(mode: SyncMode.full);
      return true;
    } catch (e) {
      _errorMessage = _toUserMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _triggerPullSync() async {
    try {
      await GetIt.instance<SyncManager>().sync(mode: SyncMode.pullOnly);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _loginAgainstCloud({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('No pudimos iniciar sesion con la cuenta registrada en la nube.');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _registerAgainstCloud({
    required String email,
    required String fullName,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'fullName': fullName,
        'universityHeadquarters': 'General',
        'academicProgram': 'Personal',
        'bio': '',
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('No pudimos registrar la cuenta en la nube.');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<ent.User> _upsertCloudUser(
    Map<String, dynamic> auth, {
    String? migrateFromUserId,
  }) async {
    final remoteUserId = auth['userId'].toString();
    final email = auth['email'] as String;
    final fullName = auth['fullName'] as String? ?? _fullName.trim();
    final role = auth['role'] as String? ?? 'member';
    final avatarUrl = auth['avatarUrl'] as String?;
    final now = DateTime.now();

    final sameIdRow = await (_db.select(_db.usersTable)..where((t) => t.id.equals(remoteUserId))).getSingleOrNull();
    final idsToMigrate = <String>{};
    if (sameIdRow == null) {
      final sameEmailRow = await (_db.select(_db.usersTable)..where((t) => t.email.equals(email))).getSingleOrNull();
      if (sameEmailRow != null && sameEmailRow.id != remoteUserId) {
        idsToMigrate.add(sameEmailRow.id);
      }
    }
    if (migrateFromUserId != null && migrateFromUserId != remoteUserId) {
      idsToMigrate.add(migrateFromUserId);
    }

    for (final sourceUserId in idsToMigrate) {
      await _migrateUserReferences(
        fromUserId: sourceUserId,
        toUserId: remoteUserId,
      );
      await _migrateSetupState(
        fromUserId: sourceUserId,
        toUserId: remoteUserId,
      );
      await (_db.delete(_db.usersTable)..where((t) => t.id.equals(sourceUserId))).go();
    }

    await _db.into(_db.usersTable).insertOnConflictUpdate(
      UsersTableCompanion.insert(
        id: remoteUserId,
        email: email,
        fullName: fullName,
        profilePictureUrl: Value(avatarUrl),
        role: Value(role),
        isActive: const Value(true),
        createdAt: Value(sameIdRow?.createdAt ?? now),
        updatedAt: Value(now),
      ),
    );

    await (_db.update(_db.userSessionsTable)..where((t) => t.userId.equals(remoteUserId))).write(
      const UserSessionsTableCompanion(isActive: Value(false)),
    );

    await _db.into(_db.userSessionsTable).insert(
      UserSessionsTableCompanion.insert(
        id: _uuid.v4(),
        userId: remoteUserId,
        accessToken: auth['accessToken'] as String,
        refreshToken: Value(auth['refreshToken'] as String?),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        isActive: const Value(true),
      ),
    );

    return ent.User(
      id: remoteUserId,
      email: email,
      fullName: fullName,
      profilePictureUrl: avatarUrl,
      role: role,
      isActive: true,
      createdAt: sameIdRow?.createdAt ?? now,
    );
  }

  Future<void> _migrateUserReferences({
    required String fromUserId,
    required String toUserId,
  }) async {
    await (_db.update(_db.habitsTable)..where((t) => t.userId.equals(fromUserId))).write(
      HabitsTableCompanion(userId: Value(toUserId)),
    );
    await (_db.update(_db.habitLogsTable)..where((t) => t.userId.equals(fromUserId))).write(
      HabitLogsTableCompanion(userId: Value(toUserId)),
    );
    await (_db.update(_db.friendshipsTable)..where((t) => t.userId.equals(fromUserId))).write(
      FriendshipsTableCompanion(userId: Value(toUserId)),
    );
    await (_db.update(_db.userSessionsTable)..where((t) => t.userId.equals(fromUserId))).write(
      UserSessionsTableCompanion(userId: Value(toUserId)),
    );
    await (_db.update(_db.notificationsTable)..where((t) => t.userId.equals(fromUserId))).write(
      NotificationsTableCompanion(userId: Value(toUserId)),
    );
    await (_db.update(_db.rankingsTable)..where((t) => t.userId.equals(fromUserId))).write(
      RankingsTableCompanion(userId: Value(toUserId)),
    );
    await (_db.update(_db.routinesTable)..where((t) => t.userId.equals(fromUserId))).write(
      RoutinesTableCompanion(userId: Value(toUserId)),
    );
  }

  Future<void> _migrateSetupState({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) {
      return;
    }

    final file = await _getSetupStateFile();
    if (!await file.exists()) {
      return;
    }

    final state = await _readSetupState();
    final previousState = state[fromUserId];
    if (previousState != null) {
      state[toUserId] = previousState;
      state.remove(fromUserId);
      await file.writeAsString(jsonEncode(state));
    }
  }

  Future<void> _refreshCloudLinkStatus() async {
    if (_user == null) {
      _isCurrentUserCloudLinked = false;
      return;
    }

    final session = await (_db.select(_db.userSessionsTable)
          ..where((t) => t.userId.equals(_user!.id))
          ..limit(1))
        .getSingleOrNull();
    _isCurrentUserCloudLinked = session != null;
  }

  void _validatePassword(
    String password, {
    String message = 'Ingresa una contrasena',
  }) {
    final normalized = password.trim();
    if (normalized.isEmpty) {
      throw Exception(message);
    }
    if (normalized.length < 8) {
      throw Exception('La contrasena debe tener al menos 8 caracteres');
    }
  }

  String _toUserMessage(Object error) {
    if (error is SocketException || error is http.ClientException) {
      return 'No pudimos conectarnos a la nube en este momento. Revisa tu conexión o intenta más tarde. Tus datos locales siguen seguros.';
    }

    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.contains('Failed host lookup') || raw.contains('SocketException')) {
      return 'No pudimos conectarnos a la nube en este momento. Revisa tu conexión o intenta más tarde. Tus datos locales siguen seguros.';
    }

    return raw;
  }
}
