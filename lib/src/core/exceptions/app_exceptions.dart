
abstract class AppException implements Exception {
  final String message;
  final Exception? originalException;

  AppException({
    required this.message,
    this.originalException,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({
    required String message,
    Exception? originalException,
  }) : super(
    message: message,
    originalException: originalException,
  );

  factory NetworkException.noInternet() {
    return NetworkException(
      message: 'No hay conexión a internet',
    );
  }

  factory NetworkException.timeout() {
    return NetworkException(
      message: 'La solicitud tardó demasiado tiempo',
    );
  }

  factory NetworkException.connectionError(String details) {
    return NetworkException(
      message: 'Error de conexión: $details',
    );
  }
}

class UnauthorizedException extends AppException {
  UnauthorizedException({
    required String message,
    Exception? originalException,
  }) : super(
    message: message,
    originalException: originalException,
  );

  factory UnauthorizedException.tokenExpired() {
    return UnauthorizedException(
      message: 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente',
    );
  }

  factory UnauthorizedException.invalidCredentials() {
    return UnauthorizedException(
      message: 'Usuario o contraseña incorrectos',
    );
  }

  factory UnauthorizedException.forbidden() {
    return UnauthorizedException(
      message: 'No tienes permisos para acceder a este recurso',
    );
  }
}
class ValidationException extends AppException {
  final Map<String, String>? errors; // Mapa de campo -> error

  ValidationException({
    required String message,
    this.errors,
    Exception? originalException,
  }) : super(
    message: message,
    originalException: originalException,
  );

  factory ValidationException.fromErrorMap(Map<String, dynamic> errorMap) {
    final errors = <String, String>{};
    errorMap.forEach((key, value) {
      errors[key] = value.toString();
    });

    return ValidationException(
      message: 'Validación fallida',
      errors: errors,
    );
  }
}

class ServerException extends AppException {
  final int? statusCode;

  ServerException({
    required String message,
    this.statusCode,
    Exception? originalException,
  }) : super(
    message: message,
    originalException: originalException,
  );

  factory ServerException.internalError() {
    return ServerException(
      message: 'Error interno del servidor',
      statusCode: 500,
    );
  }

  factory ServerException.serviceUnavailable() {
    return ServerException(
      message: 'El servicio no está disponible en este momento',
      statusCode: 503,
    );
  }
}

class NotFoundException extends AppException {
  final String resourceType; // 'Habit', 'User', etc.
  final String resourceId;

  NotFoundException({
    required String message,
    required this.resourceType,
    required this.resourceId,
    Exception? originalException,
  }) : super(
    message: message,
    originalException: originalException,
  );

  factory NotFoundException.habit(String habitId) {
    return NotFoundException(
      message: 'El hábito "$habitId" no existe o fue eliminado',
      resourceType: 'Habit',
      resourceId: habitId,
    );
  }

  factory NotFoundException.user(String userId) {
    return NotFoundException(
      message: 'El usuario "$userId" no existe',
      resourceType: 'User',
      resourceId: userId,
    );
  }
}

class StateException extends AppException {
  StateException({
    required String message,
    Exception? originalException,
  }) : super(
    message: message,
    originalException: originalException,
  );

  factory StateException.habitAlreadyCompleted() {
    return StateException(
      message: 'El hábito ya fue completado hoy',
    );
  }

  factory StateException.invalidState(String entityType, String currentState) {
    return StateException(
      message: '$entityType no puede operar en estado "$currentState"',
    );
  }
}

class SyncException extends AppException {
  final String conflictType; // 'update_conflict', 'delete_conflict', etc.

  SyncException({
    required String message,
    required this.conflictType,
    Exception? originalException,
  }) : super(
    message: message,
    originalException: originalException,
  );

  factory SyncException.updateConflict(String entityType, String entityId) {
    return SyncException(
      message: 'Conflicto: $entityType "$entityId" fue modificado en otro dispositivo',
      conflictType: 'update_conflict',
    );
  }

  factory SyncException.deleteConflict(String entityType, String entityId) {
    return SyncException(
      message: 'Conflicto: $entityType "$entityId" fue eliminado en otro dispositivo',
      conflictType: 'delete_conflict',
    );
  }
}

/// Lanzada cuando hay problemas con Drift/SQLite
class DatabaseException extends AppException {
  DatabaseException({
    required String message,
    Exception? originalException,
  }) : super(
    message: message,
    originalException: originalException,
  );

  factory DatabaseException.corruptDatabase() {
    return DatabaseException(
      message: 'La base de datos local está corrompida',
    );
  }

  factory DatabaseException.diskFull() {
    return DatabaseException(
      message: 'Espacio insuficiente en el dispositivo',
    );
  }
}

/// Fallback para errores inesperados
class UnknownException extends AppException {
  UnknownException({
    required String message,
    Exception? originalException,
  }) : super(
    message: message,
    originalException: originalException,
  );

  factory UnknownException.fromException(dynamic error) {
    return UnknownException(
      message: 'Error desconocido: ${error.toString()}',
      originalException: error is Exception ? error : null,
    );
  }
}