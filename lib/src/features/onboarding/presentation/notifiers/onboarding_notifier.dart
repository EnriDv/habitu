import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/user.dart' as ent;

class OnboardingNotifier extends ChangeNotifier {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ent.User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 0;

  // Form selections
  String? _persona;
  String? _academicProgram;
  String _fullName = '';
  String _email = '';
  bool _isInitialized = false;

  List<ent.User> _localUsers = [];
  List<ent.User> get localUsers => _localUsers;

  OnboardingNotifier({required AppDatabase db}) : _db = db {
    checkActiveUser();
  }

  ent.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  String? get persona => _persona;
  String? get academicProgram => _academicProgram;
  String get fullName => _fullName;
  String get email => _email;
  bool get isInitialized => _isInitialized;
  bool get hasUser => _user != null;

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  void selectPersona(String? val) {
    _persona = val;
    notifyListeners();
  }

  void selectAcademicProgram(String? val) {
    _academicProgram = val;
    notifyListeners();
  }

  void setFullName(String val) {
    _fullName = val;
    notifyListeners();
  }

  void setEmail(String val) {
    _email = val;
    notifyListeners();
  }

  /// Verifica si ya existe un usuario activo en la base de datos local y carga cuentas anteriores
  Future<void> checkActiveUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final query = _db.select(_db.usersTable)..where((t) => t.isActive.equals(true));
      final rows = await query.get();
      if (rows.isNotEmpty) {
        final r = rows.first;
        _user = ent.User(
          id: r.id,
          email: r.email,
          fullName: r.fullName,
          profilePictureUrl: r.profilePictureUrl,
          role: r.role,
          ucbId: r.ucbId,
          isActive: r.isActive,
          createdAt: r.createdAt,
        );
      } else {
        _user = null;
      }

      await _loadLocalUsersList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Carga la lista de todos los usuarios registrados localmente en el dispositivo
  Future<void> _loadLocalUsersList() async {
    try {
      final allUsersQuery = _db.select(_db.usersTable);
      final allRows = await allUsersQuery.get();
      _localUsers = allRows.map((r) => ent.User(
        id: r.id,
        email: r.email,
        fullName: r.fullName,
        profilePictureUrl: r.profilePictureUrl,
        role: r.role,
        ucbId: r.ucbId,
        isActive: r.isActive,
        createdAt: r.createdAt,
      )).toList();
    } catch (e) {
      debugPrint('Error loading local users: $e');
    }
  }

  /// Inicia sesión con una cuenta local existente
  Future<bool> loginWithExistingUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Marcar todos los usuarios como inactivos
      await _db.update(_db.usersTable).write(const UsersTableCompanion(isActive: Value(false)));

      // 2. Activar el usuario seleccionado
      await (_db.update(_db.usersTable)..where((t) => t.id.equals(userId))).write(
        UsersTableCompanion(
          isActive: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // 3. Cargar el usuario actual
      final query = _db.select(_db.usersTable)..where((t) => t.id.equals(userId));
      final rows = await query.get();
      if (rows.isNotEmpty) {
        final r = rows.first;
        _user = ent.User(
          id: r.id,
          email: r.email,
          fullName: r.fullName,
          profilePictureUrl: r.profilePictureUrl,
          role: r.role,
          ucbId: r.ucbId,
          isActive: r.isActive,
          createdAt: r.createdAt,
        );
      }

      await _loadLocalUsersList();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Crea la identidad local (registro offline o correo institucional)
  Future<bool> completeOnboarding({bool anonymous = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = _uuid.v4();
      final userEmail = anonymous ? 'anonimo_$userId@habitu.app' : _email.trim();
      final userName = anonymous 
          ? (_fullName.trim().isNotEmpty ? _fullName.trim() : 'Estudiante Anónimo') 
          : _fullName.trim();
      final userPersona = _persona ?? 'Deep Thinker';

      if (!anonymous && (!userEmail.contains('@') || !userEmail.contains('.'))) {
        throw Exception('Por favor ingresa un correo electrónico válido');
      }

      if (!anonymous && userName.isEmpty) {
        throw Exception('El nombre completo es obligatorio');
      }

      // Verificar si ya existe el usuario localmente
      final existingQuery = _db.select(_db.usersTable)..where((t) => t.email.equals(userEmail));
      final existingUsers = await existingQuery.get();

      String finalUserId = userId;
      if (existingUsers.isNotEmpty) {
        final existingUser = existingUsers.first;
        finalUserId = existingUser.id;

        await (_db.update(_db.usersTable)..where((t) => t.id.equals(finalUserId))).write(
          UsersTableCompanion(
            isActive: const Value(true),
            fullName: Value(userName),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await _db.into(_db.usersTable).insert(
          UsersTableCompanion.insert(
            id: finalUserId,
            email: userEmail,
            fullName: userName,
            role: const Value('student'),
            isActive: const Value(true),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }

      _user = ent.User(
        id: finalUserId,
        email: userEmail,
        fullName: userName,
        role: 'student',
        isActive: true,
        academicProgram: _academicProgram,
        persona: userPersona,
        createdAt: DateTime.now(),
      );

      await _loadLocalUsersList();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cierra sesión
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Marcamos los usuarios locales como inactivos
      await _db.update(_db.usersTable).write(const UsersTableCompanion(isActive: Value(false)));
      _user = null;
      _currentPage = 0;
      _persona = null;
      _academicProgram = null;
      _fullName = '';
      _email = '';
      
      await _loadLocalUsersList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
