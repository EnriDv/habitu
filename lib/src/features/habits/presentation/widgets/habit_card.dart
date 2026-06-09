/// Widget: Tarjeta de Hábito
/// 
/// Muestra la información de un hábito y permite al usuario:
/// - Ver el nombre, descripción, frecuencia
/// - Ver el color/icono del hábito
/// - Completar el hábito (swipe detection)
/// - Editar/eliminar (acciones adicionales)

import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../notifiers/habits_notifier.dart';
import '../../domain/entities/habit.dart';

/// Tarjeta reusable para mostrar un hábito
/// 
/// Uso:
/// ```dart
/// HabitCard(
///   habit: habit,
///   onComplete: () => _completeHabit(habit.id),
///   onTap: () => _openHabitDetail(habit.id),
/// )
/// ```
class HabitCard extends StatefulWidget {
  final Habit habit;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HabitCard({
    Key? key,
    required this.habit,
    this.onComplete,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  late Offset _tapDownPosition;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _tapDownPosition = details.globalPosition,
      onTap: widget.onTap,
      onLongPress: () => _showContextMenu(context),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ======================== HEADER ========================
              Row(
                children: [
                  // Icono del hábito
                  _buildHabitIcon(),
                  const SizedBox(width: 12),
                  // Título y descripción
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.habit.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.habit.description != null &&
                            widget.habit.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              widget.habit.description!,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Botón de menú
                  PopupMenuButton(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          widget.onEdit?.call();
                          break;
                        case 'delete':
                          _confirmDelete(context);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ======================== INFO ========================
              Row(
                children: [
                  // Frecuencia
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.repeat,
                      label: _frequencyLabel(widget.habit.frequencyType),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Privacidad
                  if (widget.habit.isPublic)
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.public,
                        label: 'Público',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // ======================== COMPLETE BUTTON ========================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onComplete,
                  icon: const Icon(Icons.check),
                  label: const Text('Marcar Completado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getColorFromHex(widget.habit.colorHex),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el icono del hábito
  Widget _buildHabitIcon() {
    final color = _getColorFromHex(widget.habit.colorHex);
    final icon = widget.habit.icon != null
        ? _getIconFromString(widget.habit.icon!)
        : Icons.task_alt;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 28,
      ),
    );
  }

  /// Construye un chip de información
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }

  /// Muestra el menú contextual (edit/delete)
  void _showContextMenu(BuildContext context) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        _tapDownPosition.dx,
        _tapDownPosition.dy,
        _tapDownPosition.dx,
        _tapDownPosition.dy,
      ),
      items: [
        PopupMenuItem(
          onTap: widget.onEdit,
          child: const Row(
            children: [
              Icon(Icons.edit),
              SizedBox(width: 8),
              Text('Editar'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => _confirmDelete(context),
          child: const Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Eliminar', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  /// Confirma eliminación con diálogo
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar hábito?'),
        content: Text('¿Estás seguro de que deseas eliminar "${widget.habit.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Convierte código hexadecimal a Color
  Color _getColorFromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.indigo; // Color por defecto
    }
  }

  /// Convierte string a IconData
  IconData _getIconFromString(String iconString) {
    // TODO: Mapear strings a IconData (ej: 'fitness' -> Icons.fitness_center)
    // Por ahora, retornar icono por defecto
    return Icons.task_alt;
  }

  /// Etiqueta legible para el tipo de frecuencia
  String _frequencyLabel(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Diario';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensual';
      case 'weekdays':
        return 'Entre semana';
      default:
        return frequency;
    }
  }
}