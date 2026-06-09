
class Habit {
  final String id; // UUID generado en Flutter
  final String userId; // Usuario propietario
  final String title; // Nombre del hábito
  final String? description; // Descripción opcional
  final String frequencyType; // 'daily', 'weekly', 'monthly', 'once_off'
  final String colorHex; // Formato: '#6366F1'
  final String? icon; // Emoji o nombre de icono
  final bool isPublic; // Visible para amigos
  final bool isDeleted; // Borrado lógico
  final String? remoteId; // ID en el backend (sincronización)
  final DateTime createdAt;
  final DateTime updatedAt;

  int get currentStreak => 0; // TODO: Calcular desde HabitLogs
  DateTime? get lastCompletedDate => null; // TODO: Desde HabitLogs

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.frequencyType,
    required this.colorHex,
    this.icon,
    required this.isPublic,
    required this.isDeleted,
    this.remoteId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crea una copia del hábito con valores modificados
  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? frequencyType,
    String? colorHex,
    String? icon,
    bool? isPublic,
    bool? isDeleted,
    String? remoteId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      frequencyType: frequencyType ?? this.frequencyType,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      isPublic: isPublic ?? this.isPublic,
      isDeleted: isDeleted ?? this.isDeleted,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'frequencyType': frequencyType,
      'colorHex': colorHex,
      'icon': icon,
      'isPublic': isPublic,
      'remoteId': remoteId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Crea un Habit desde JSON (backend o local)
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      frequencyType: json['frequencyType'] as String,
      colorHex: json['colorHex'] as String? ?? '#6366F1',
      icon: json['icon'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      remoteId: json['remoteId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  String toString() => 'Habit(id: $id, title: $title, frequencyType: $frequencyType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Habit &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ userId.hashCode ^ title.hashCode;
}