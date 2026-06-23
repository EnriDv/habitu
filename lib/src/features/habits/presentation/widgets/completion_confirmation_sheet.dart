import 'dart:io';

import 'package:flutter/material.dart';
import 'package:habitu_ui/habitu_ui.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/habit.dart';

class CompletionConfirmationSheet extends StatefulWidget {
  final Habit habit;

  const CompletionConfirmationSheet({super.key, required this.habit});

  @override
  State<CompletionConfirmationSheet> createState() => _CompletionConfirmationSheetState();
}

class _CompletionConfirmationSheetState extends State<CompletionConfirmationSheet> {
  final TextEditingController _notesController = TextEditingController();
  XFile? _imageFile;
  bool _isImageLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isImageLoading = true;
    });

    try {
      final granted = source == ImageSource.camera
          ? await NotificationService().requestCameraPermission(context)
          : await NotificationService().requestGalleryPermission(context);
      if (!granted) {
        return;
      }

      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _imageFile = photo;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos adjuntar la imagen. Intenta otra vez.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImageLoading = false;
        });
      }
    }
  }

  Future<void> _showImageSourcePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galeria'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
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
                '¿Cumpliste con este hábito?',
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
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Agrega una nota u observación opcional',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                style: const TextStyle(fontFamily: 'Inter'),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              if (_imageFile != null) ...[
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.tertiaryColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                    image: DecorationImage(
                      image: FileImage(File(_imageFile!.path)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: _isImageLoading ? null : _showImageSourcePicker,
                    icon: const Icon(Icons.refresh, color: AppTheme.tertiaryColor, size: 16),
                    label: const Text(
                      'Cambiar evidencia',
                      style: TextStyle(color: AppTheme.tertiaryColor, fontFamily: 'Inter'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_isImageLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(color: AppTheme.tertiaryColor),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                onPressed: _isImageLoading
                    ? null
                    : (_imageFile != null
                        ? () {
                            Navigator.pop(context, {
                              'complete': true,
                              'evidence': true,
                              'notes': _notesController.text.trim().isEmpty
                                  ? null
                                  : _notesController.text.trim(),
                              'photoPath': _imageFile!.path,
                            });
                          }
                        : _showImageSourcePicker),
                icon: Icon(_imageFile != null ? Icons.check : Icons.add_a_photo_outlined),
                label: Text(
                  _imageFile != null ? 'Completar con evidencia' : 'Adjuntar evidencia',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _imageFile != null ? AppTheme.primaryColor : AppTheme.tertiaryColor,
                  foregroundColor:
                      _imageFile != null ? Colors.white : AppTheme.onTertiary,
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
              const SizedBox(height: 12),
              if (_imageFile == null) ...[
                HabituButton.outlined(
                  label: 'Marcar sin evidencia',
                  onPressed: () {
                    Navigator.pop(context, {
                      'complete': true,
                      'evidence': false,
                      'notes': _notesController.text.trim().isEmpty
                          ? null
                          : _notesController.text.trim(),
                    });
                  },
                  icon: Icons.done_all,
                  fullWidth: true,
                ),
                const SizedBox(height: 16),
              ],
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
      ),
    );
  }
}
