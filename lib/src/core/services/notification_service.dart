import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/habits/domain/entities/habit.dart';
import 'deep_link_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _launchPayload;

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationResponse(response);
      },
    );

    final launchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchResponse != null) {
      final resolvedPayload =
          await _resolveNotificationNavigationTarget(launchResponse);
      if (resolvedPayload != null && resolvedPayload.isNotEmpty) {
        _launchPayload = resolvedPayload;
      }
    }
  }

  Future<void> consumePendingLaunchPayload() async {
    if (_launchPayload == null || _launchPayload!.isEmpty) return;
    final payload = _launchPayload;
    _launchPayload = null;
    await GetIt.instance<DeepLinkService>().handleLink(payload);
  }

  Future<void> _handleNotificationResponse(
    NotificationResponse response,
  ) async {
    final target = await _resolveNotificationNavigationTarget(response);
    if (target != null && target.isNotEmpty) {
      await GetIt.instance<DeepLinkService>().handleLink(target);
    }
  }

  Future<String?> _resolveNotificationNavigationTarget(
    NotificationResponse response,
  ) async {
    if (response.payload != null && response.payload!.isNotEmpty) {
      return response.payload;
    }

    final notificationId = response.id;
    if (notificationId == null) return null;

    final file = await _getRemindersFile();
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      final reminders = jsonDecode(content) as Map<String, dynamic>;
      for (final entry in reminders.entries) {
        final reminderValue = entry.value;
        final storedId = reminderValue is Map<String, dynamic>
            ? reminderValue['notificationId'] as int?
            : null;
        final fallbackId = _notificationIdForHabit(entry.key);
        if ((storedId ?? fallbackId) == notificationId) {
          return 'habitu://habit/${entry.key}';
        }
      }
    } catch (_) {}

    return null;
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
        return true;
      }
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return json['enabled'] as bool? ?? true;
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
        reminders = jsonDecode(content) as Map<String, dynamic>;
      }
      reminders[habitId] = {
        'time':
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        'notificationId': _notificationIdForHabit(habitId),
      };
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

  Future<Map<String, TimeOfDay>> getAllHabitReminders() async {
    final file = await _getRemindersFile();
    if (!await file.exists()) {
      return const {};
    }

    try {
      final content = await file.readAsString();
      final reminders = jsonDecode(content) as Map<String, dynamic>;
      final parsed = <String, TimeOfDay>{};
      for (final entry in reminders.entries) {
        final reminderEntry = entry.value;
        final timeStr = reminderEntry is String
            ? reminderEntry
            : (reminderEntry['time'] as String? ?? '08:00');
        final parts = timeStr.split(':');
        if (parts.length != 2) continue;
        parsed[entry.key] = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
      return parsed;
    } catch (_) {
      return const {};
    }
  }

  Future<TimeOfDay?> getHabitReminder(String habitId) async {
    final reminders = await getAllHabitReminders();
    return reminders[habitId];
  }

  Future<void> rescheduleAllNotifications(List<Habit> habits) async {
    try {
      final file = await _getRemindersFile();
      if (!await file.exists()) return;

      final content = await file.readAsString();
      final reminders = jsonDecode(content) as Map<String, dynamic>;

      for (final habit in habits) {
        if (!reminders.containsKey(habit.id)) continue;
        final reminderEntry = reminders[habit.id];
        final timeStr = reminderEntry is String
            ? reminderEntry
            : (reminderEntry['time'] as String? ?? '08:00');
        final parts = timeStr.split(':');
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts[1]) ?? 0;

        await scheduleDailyHabitNotification(
          habitId: habit.id,
          title: habit.title,
          time: TimeOfDay(hour: hour, minute: minute),
          force: true,
        );
      }
    } catch (e) {
      debugPrint('Error rescheduling notifications: $e');
    }
  }

  Future<bool> requestNotificationPermission(BuildContext context) async {
    if (Platform.isAndroid) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final pluginResult =
          await androidImplementation?.requestNotificationsPermission();
      if (pluginResult == true) {
        return true;
      }
    }

    final status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.notification.request();
    if (result.isGranted) {
      return true;
    }

    if (result.isPermanentlyDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDialog(
          context,
          'Permiso de notificaciones requerido',
          'Para recibir recordatorios de hábitos, activa las notificaciones en la configuración del sistema.',
        );
      }
    }

    return false;
  }

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
          'Permiso de cámara requerido',
          'Para subir fotos como evidencia, activa el permiso de cámara en la configuración del sistema.',
        );
      }
    }

    return false;
  }

  Future<bool> requestGalleryPermission(BuildContext context) async {
    Permission permission;
    if (Platform.isIOS) {
      permission = Permission.photos;
    } else if (Platform.isAndroid) {
      permission = Permission.photos;
    } else {
      permission = Permission.storage;
    }

    final status = await permission.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }

    final result = await permission.request();
    if (result.isGranted || result.isLimited) {
      return true;
    }

    if (Platform.isAndroid && permission == Permission.photos) {
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) {
        return true;
      }
      final storageResult = await Permission.storage.request();
      if (storageResult.isGranted) {
        return true;
      }
    }

    if (result.isPermanentlyDenied || status.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermissionDialog(
          context,
          'Permiso de galería requerido',
          'Para adjuntar evidencia desde tu galería, permite acceso a tus fotos en la configuración del sistema.',
        );
      }
    }

    return false;
  }

  void _showPermissionDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await openAppSettings();
            },
            child: const Text('Ir a ajustes'),
          ),
        ],
      ),
    );
  }

  Future<bool> scheduleDailyHabitNotification({
    required String habitId,
    required String title,
    required TimeOfDay time,
    bool force = false,
    String? payload,
  }) async {
    await saveHabitReminder(habitId, time);
    await setNotificationsEnabled(true);

    if (!force && !await areNotificationsEnabled()) {
      return false;
    }

    try {
      await cancelHabitNotification(habitId, onlyCancelNative: true);

      final notificationId = _notificationIdForHabit(habitId);
      final now = DateTime.now();
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestExactAlarmsPermission();
      }

      await _localNotifications.zonedSchedule(
        notificationId,
        'Es hora de tu habito',
        title,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habitu_alarms_channel',
            'Recordatorios de Habitos',
            channelDescription: 'Canal para recordatorios diarios de habitos',
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
        payload: payload ?? 'habitu://habit/$habitId',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (e) {
      debugPrint('Error scheduling habit notification: $e');
      return false;
    }
  }

  Future<void> cancelHabitNotification(
    String habitId, {
    bool onlyCancelNative = false,
  }) async {
    final notificationId = _notificationIdForHabit(habitId);
    await _localNotifications.cancel(notificationId);
    if (!onlyCancelNative) {
      await deleteHabitReminder(habitId);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    await setNotificationsEnabled(false);
  }

  int _notificationIdForHabit(String habitId) {
    return habitId.hashCode.abs();
  }
}
