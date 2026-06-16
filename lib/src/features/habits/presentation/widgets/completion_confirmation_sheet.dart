import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:habitu_ui/habitu_ui.dart';
import '../../domain/entities/habit.dart';
import '../../../../core/services/notification_service.dart';

class CompletionConfirmationSheet extends StatefulWidget {
  final Habit habit;

  const CompletionConfirmationSheet({super.key, required this.habit});

  @override
  State<CompletionConfirmationSheet> createState() => _CompletionConfirmationSheetState();
}

class _CompletionConfirmationSheetState extends State<CompletionConfirmationSheet> {
  final TextEditingController _notesController = TextEditingController();
  XFile? _imageFile;
  bool _isCameraLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    setState(() {
      _isCameraLoading = true;
    });

    try {
      final granted = await NotificationService().requestCameraPermission(context);
      if (granted) {
        final picker = ImagePicker();
        final XFile? photo = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (photo != null) {
          setState(() {
            _imageFile = photo;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {
      setState(() {
        _isCameraLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            const CircleAvatar(
              backgroundColor: AppTheme.tertiaryColor,
              radius: 28,
              child: Icon(Icons.check, color: AppTheme.onTertiary, size: 32),
            ),
            const SizedBox(height: 16),
            
            Text(
              '¿Cumpliste con tu hábito?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.habit.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Notes input field
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Agrega una nota u observación... (Opcional)',
                prefixIcon: Icon(Icons.edit_note),
              ),
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            const SizedBox(height: 20),

            if (_imageFile != null) ...[
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.tertiaryColor.withOpacity(0.5), width: 1.5),
                  image: DecorationImage(
                    image: FileImage(File(_imageFile!.path)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _isCameraLoading ? null : _takePhoto,
                  icon: const Icon(Icons.refresh, color: AppTheme.tertiaryColor, size: 16),
                  label: const Text('Tomar otra foto', style: TextStyle(color: AppTheme.tertiaryColor, fontFamily: 'Inter')),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_isCameraLoading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularProgressIndicator(color: AppTheme.tertiaryColor),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action 1: Upload Evidence or Complete
            ElevatedButton.icon(
              onPressed: _isCameraLoading 
                  ? null 
                  : (_imageFile != null 
                      ? () {
                          Navigator.pop(context, {
                            'complete': true,
                            'evidence': true,
                            'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                            'photoPath': _imageFile!.path,
                          });
                        }
                      : _takePhoto),
              icon: Icon(_imageFile != null ? Icons.check : Icons.camera_alt),
              label: Text(_imageFile != null ? 'Completar Hábito con Evidencia' : 'Subir Evidencia (Foto)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _imageFile != null ? AppTheme.primaryColor : AppTheme.tertiaryColor,
                foregroundColor: _imageFile != null ? Colors.white : AppTheme.onTertiary,
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 12),

            // Action 2: Trust me
            if (_imageFile == null) ...[
              HabituButton.outlined(
                label: 'Confía en Mí (Honestidad)',
                onPressed: () {
                  Navigator.pop(context, {
                    'complete': true,
                    'evidence': false,
                    'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                  });
                },
                icon: Icons.done_all,
                fullWidth: true,
              ),
              const SizedBox(height: 16),
            ],

            // Cancel text button
            TextButton(
              onPressed: () {
                Navigator.pop(context, {'complete': false});
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withOpacity(0.8),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
