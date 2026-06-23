

class HabitLog {
  final String id; // UUID único del registro
  final String habitId; // Referencia al hábito
  final String userId; // Usuario que completó
  final DateTime completedAt; // Fecha y hora de completado
  final String? notes; // Notas opcionales del usuario
  final String? evidencePhotoUrl; // URL de la foto de evidencia (en Supabase Storage)
  final String confidenceLevel; // 'trust_me', 'photo', 'auto_detected'
  final String? remoteId; // ID en backend (para sincronización)
  final DateTime createdAt; // Cuándo se registró localmente
  final DateTime? syncedAt; // Cuándo se sincronizó al backend

  HabitLog({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    this.notes,
    this.evidencePhotoUrl,
    required this.confidenceLevel,
    this.remoteId,
    required this.createdAt,
    this.syncedAt,
  });

  /// Crea una copia con valores modificados
  HabitLog copyWith({
    String? id,
    String? habitId,
    String? userId,
    DateTime? completedAt,
    String? notes,
    String? evidencePhotoUrl,
    String? confidenceLevel,
    String? remoteId,
    DateTime? createdAt,
    DateTime? syncedAt,
  }) {
    return HabitLog(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      userId: userId ?? this.userId,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      evidencePhotoUrl: evidencePhotoUrl ?? this.evidencePhotoUrl,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'userId': userId,
      'completedAt': completedAt.toIso8601String(),
      'notes': notes,
      'evidencePhotoUrl': evidencePhotoUrl,
      'confidenceLevel': confidenceLevel,
      'remoteId': remoteId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Crea un HabitLog desde JSON
  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      userId: json['userId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      notes: json['notes'] as String?,
      evidencePhotoUrl: json['evidencePhotoUrl'] as String?,
      confidenceLevel: json['confidenceLevel'] as String? ?? 'trust_me',
      remoteId: json['remoteId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      syncedAt: json['syncedAt'] != null 
          ? DateTime.parse(json['syncedAt'] as String) 
          : null,
    );
  }

  @override
  String toString() => 'HabitLog(id: $id, habitId: $habitId, completedAt: ${completedAt.toLocal()})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          habitId == other.habitId &&
          completedAt == other.completedAt;

  @override
  int get hashCode => id.hashCode ^ habitId.hashCode ^ completedAt.hashCode;
}