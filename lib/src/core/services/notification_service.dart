import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/habits/domain/entities/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
  }

  Future<File> _getSettingsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/notification_settings.json');
  }

  Future<File> _getRemindersFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/notification_reminders.json');
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      final file = await _getSettingsFile();
      if (!await file.exists()) {
        return true; // Enabled by default
      }
      final content = await file.readAsString();
      final json = jsonDecode(content);
      return json['enabled'] ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final file = await _getSettingsFile();
      await file.writeAsString(jsonEncode({'enabled': enabled}));
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  Future<void> saveHabitReminder(String habitId, TimeOfDay time) async {
    try {
      final file = await _getRemindersFile();
      Map<String, dynamic> reminders = {};
      if (await file.exists()) {
        final content = await file.readAsString();
        reminders = jsonDecode(content);
      }
      reminders[habitId] = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      await file.writeAsString(jsonEncode(reminders));
    } catch (e) {
      debugPrint('Error saving habit reminder: $e');
    }
  }

  Future<void> deleteHabitReminder(String habitId) async {
    try {
      final file = await _getRemindersFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final reminders = jsonDecode(content) as Map<String, dynamic>;
        reminders.remove(habitId);
        await file.writeAsString(jsonEncode(reminders));
      }
    } catch (e) {
      debugPrint('Error deleting habit reminder: $e');
    }
  }

  Future<void> rescheduleAllNotifications(List<Habit> habits) async {
    try {
      final file = await _getRemindersFile();
      if (!await file.exists()) return;

      final content = await file.readAsString();
      final reminders = jsonDecode(content) as Map<String, dynamic>;

      for (final habit in habits) {
        if (reminders.containsKey(habit.id)) {
          final timeStr = reminders[habit.id] as String;
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          
          await scheduleDailyHabitNotification(
            habitId: habit.id,
            title: habit.title,
            time: TimeOfDay(hour: hour, minute: minute),
            force: true, // Bypass in-app enabled check
          );
        }
      }
    } catch (e) {
      debugPrint('Error rescheduling notifications: $e');
    }
  }

  /// Solicitar permisos de notificación con fallback a ajustes si es rechazado varias veces
  Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.notification.request();
    if (result.isGranted) {
      return true;
    }

    // Si está denegado permanentemente (o bloqueado)
    if (result.isPermanentlyDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDialog(
          context,
          'Permiso de Notificaciones Requerido',
          'Para recibir tus recordatorios diarios de hábitos, debes activar las notificaciones en la configuración del sistema.',
        );
      }
      return false;
    }

    return false;
  }

  /// Solicitar permisos de cámara con fallback a ajustes si es rechazado varias veces
  Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.camera.request();
    if (result.isGranted) {
      return true;
    }

    if (result.isPermanentlyDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDialog(
          context,
          'Permiso de Cámara Requerido',
          'Para subir fotos como evidencia de cumplimiento, debes activar el permiso de cámara en la configuración del sistema.',
        );
      }
      return false;
    }

    return false;
  }

  void _showPermissionDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E), // AppTheme.surfaceContainerHigh
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', color: Colors.white)),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF9499B8), fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF7A80A3))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1), // AppTheme.primaryColor
              foregroundColor: Colors.white,
            ),
            child: const Text('Ir a Ajustes'),
          )
        ],
      ),
    );
  }

  /// Programa una alarma/notificación exacta diaria para un hábito
  Future<void> scheduleDailyHabitNotification({
    required String habitId,
    required String title,
    required TimeOfDay time,
    bool force = false,
  }) async {
    // Guardar recordatorio localmente
    await saveHabitReminder(habitId, time);

    // Si las notificaciones están desactivadas in-app, no programar a nivel de sistema operativo
    if (!force && !await areNotificationsEnabled()) {
      return;
    }

    // Cancelar cualquier notificación previa de este hábito para evitar duplicados
    await cancelHabitNotification(habitId, onlyCancelNative: true);

    // Generar un ID entero a partir del hash del habitId para el plugin
    final int notificationId = habitId.hashCode.abs();

    final now = DateTime.now();
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Si la hora ya pasó hoy, programar para mañana
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Solicitar permiso de alarmas exactas en Android si corresponde
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestExactAlarmsPermission();
    }

    await _localNotifications.zonedSchedule(
      notificationId,
      '¡Es hora de tu hábito! 🎯',
      title,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'habitu_alarms_channel',
          'Recordatorios de Hábitos',
          channelDescription: 'Canal para alertas y recordatorios diarios de hábitos',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repetir cada día a la misma hora
    );
  }

  /// Cancela la notificación de un hábito
  Future<void> cancelHabitNotification(String habitId, {bool onlyCancelNative = false}) async {
    final int notificationId = habitId.hashCode.abs();
    await _localNotifications.cancel(notificationId);
    if (!onlyCancelNative) {
      await deleteHabitReminder(habitId);
    }
  }

  /// Cancela todas las notificaciones programadas
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    await setNotificationsEnabled(false);
  }
}
