

import 'package:flutter/material.dart';
class ConfirmHabitSheet extends StatefulWidget {
  final String habitTitle;
  final Function(String confidenceLevel, String? notes) onConfirm;
  final VoidCallback? onCancel;

  const ConfirmHabitSheet({
    Key? key,
    required this.habitTitle,
    required this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String habitTitle,
    required Function(String, String?) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ConfirmHabitSheet(
        habitTitle: habitTitle,
        onConfirm: (confidence, notes) {
          Navigator.pop(context);
          onConfirm(confidence, notes);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  @override
  State<ConfirmHabitSheet> createState() => _ConfirmHabitSheetState();
}

class _ConfirmHabitSheetState extends State<ConfirmHabitSheet> {
  String? _selectedOption; // 'trust_me', 'photo'
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ======================== HEADER ========================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, size: 48, color: Colors.green),
                  const SizedBox(height: 12),
                  Text(
                    '¿Completaste "${widget.habitTitle}"?',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cuéntanos cómo lo hiciste',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ======================== OPTIONS ========================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Opción 1: Trust Me
                  _buildOptionTile(
                    value: 'trust_me',
                    title: '✓ Confía en mí',
                    subtitle: 'Solo registro que lo completé',
                    icon: Icons.done,
                  ),
                  const SizedBox(height: 12),
                  // Opción 2: Foto
                  _buildOptionTile(
                    value: 'photo',
                    title: '📷 Subir Foto',
                    subtitle: 'Evidencia con foto',
                    icon: Icons.camera_alt,
                  ),
                ],
              ),
            ),
            // ======================== NOTES (si está seleccionada una opción) ========================
            if (_selectedOption != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notas (opcional)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        hintText: 'Cómo te fue, dificultades, etc...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.1),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ],
            // ======================== ACTIONS ========================
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        widget.onCancel?.call();
                        Navigator.pop(context);
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedOption == null
                          ? null
                          : () => _confirmCompletion(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un tile seleccionable para cada opción
  Widget _buildOptionTile({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedOption == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedOption = value),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.indigo.withOpacity(0.1) : Colors.transparent,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icono
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.indigo.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.indigo : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.indigo : null,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ),
            // Checkbox
            Radio<String>(
              value: value,
              groupValue: _selectedOption,
              onChanged: (val) => setState(() => _selectedOption = val),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirma la finalización del hábito
  void _confirmCompletion(BuildContext context) {
    if (_selectedOption == null) return;

    final notes = _notesController.text.isNotEmpty ? _notesController.text : null;
    widget.onConfirm(_selectedOption!, notes);
  }
}