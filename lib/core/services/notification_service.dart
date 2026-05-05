import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data'; // For Int64List (vibration pattern)
import 'shake_detector.dart';
import '../../data/local/database_helper.dart';

/// Service untuk mengelola notifikasi lokal
/// Menggunakan flutter_local_notifications untuk reminder minum obat
class NotificationService {
  // Singleton pattern
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isInitialized = false;

  // ══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════

  /// Initialize notification service
  /// Harus dipanggil di main() sebelum runApp()
  Future<void> initialize() async {
    if (_isInitialized) {
      print('✅ NotificationService already initialized');
      return;
    }

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      print('✅ Timezone initialized: Asia/Jakarta');

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
    }
  }

  /// Request notification permissions (Android 13+)
  Future<void> _requestPermissions() async {
    try {
      // Request notification permission
      final status = await Permission.notification.request();
      
      if (status.isGranted) {
        print('✅ Notification permission granted');
      } else if (status.isDenied) {
        print('⚠️ Notification permission denied');
      } else if (status.isPermanentlyDenied) {
        print('❌ Notification permission permanently denied');
        // User needs to enable from settings
        await openAppSettings();
      }

      // Request exact alarm permission (Android 12+)
      if (await Permission.scheduleExactAlarm.isDenied) {
        final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
        if (exactAlarmStatus.isGranted) {
          print('✅ Exact alarm permission granted');
        } else {
          print('⚠️ Exact alarm permission denied');
        }
      }
      
      // Request to ignore battery optimization (untuk notifikasi tetap jalan saat app force stop)
      final ignoringBatteryOptimizations = await Permission.ignoreBatteryOptimizations.isGranted;
      if (!ignoringBatteryOptimizations) {
        print('⚠️ Battery optimization is enabled, notifications may not work when app is force stopped');
        print('💡 Requesting battery optimization exemption...');
        
        final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
        if (batteryStatus.isGranted) {
          print('✅ Battery optimization exemption granted');
        } else {
          print('⚠️ Battery optimization exemption denied');
          print('💡 User can manually disable it in Settings > Apps > [App Name] > Battery > Unrestricted');
        }
      }
    } catch (e) {
      print('❌ Error requesting permissions: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    print('🔔 Action ID: ${response.actionId}');
    
    // Handle notification actions
    if (response.actionId == 'snooze') {
      // Snooze button tapped
      final scheduleId = int.tryParse(response.payload ?? '0');
      if (scheduleId != null && scheduleId > 0) {
        print('⏰ Snooze button tapped for schedule $scheduleId');
        snoozeNotification(scheduleId);
      }
    } else if (response.actionId == 'taken') {
      // Sudah Minum button tapped
      final scheduleId = int.tryParse(response.payload ?? '0');
      if (scheduleId != null && scheduleId > 0) {
        print('✅ Sudah Minum button tapped for schedule $scheduleId');
        // Stop shake detector
        ShakeDetector().stopListening();
        // TODO: Navigate to medication detail screen or mark as taken
      }
    } else {
      // Notification body tapped (no action)
      // TODO: Navigate to medication detail screen
      // Parse payload to get schedule_id
      // Navigator.push to MedicationDetailScreen
    }
  }

  // ══════════════════════════════════════════════════════════════
  // SCHEDULE MEDICATION REMINDER
  // ══════════════════════════════════════════════════════════════

  /// Schedule medication reminder notification
  /// 
  /// Parameters:
  /// - scheduleId: ID dari schedule di database
  /// - medicationName: Nama obat
  /// - timeIntake: Waktu minum (format HH:mm)
  /// - dosage: Jumlah dosis
  /// - dosageUnit: Satuan dosis (tablet/mg/ml)
  Future<void> scheduleMedicationReminder({
    required int scheduleId,
    required String medicationName,
    required String timeIntake, // Format: "08:00"
    required double dosage,
    required String dosageUnit,
  }) async {
    if (!_isInitialized) {
      print('⚠️ NotificationService not initialized');
      return;
    }

    try {
      // Parse time (HH:mm)
      final timeParts = timeIntake.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Get current time
      final now = tz.TZDateTime.now(tz.local);
      
      // Schedule for today if time hasn't passed, otherwise tomorrow
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Notification details
      final androidDetails = AndroidNotificationDetails(
        'medication_reminder', // channel id
        'Pengingat Minum Obat', // channel name
        channelDescription: 'Notifikasi untuk mengingatkan waktu minum obat',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500]), // Vibrate pattern: wait-vibrate-pause-vibrate
        playSound: true,
        icon: '@mipmap/ic_launcher',
        // Add notification actions (Snooze & Sudah Minum)
        actions: const [
          AndroidNotificationAction(
            'snooze',
            'Snooze 10 menit',
            showsUserInterface: false,
            cancelNotification: false,
          ),
          AndroidNotificationAction(
            'taken',
            'Sudah Minum',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule notification
      await _notifications.zonedSchedule(
        scheduleId, // notification id (unique per schedule)
        '⏰ Waktunya Minum Obat!',
        '$medicationName - ${dosage.toInt()} $dosageUnit',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily at same time
        payload: scheduleId.toString(), // Pass schedule_id for navigation
      );

      print('✅ Notification scheduled for $medicationName at $timeIntake (ID: $scheduleId)');
      print('   Next notification: $scheduledDate');
      
      // Start shake detector when notification is scheduled
      // Note: Shake detector will only work when app is in foreground/background
      // It won't work if app is force-stopped (Android limitation)
      print('🔔 Starting shake detector for schedule $scheduleId');
      ShakeDetector().startListening(
        scheduleId,
        () => snoozeNotification(scheduleId),
      );
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // SNOOZE NOTIFICATION
  // ══════════════════════════════════════════════════════════════

  /// Snooze notification for 10 minutes
  /// 
  /// Called when:
  /// - User shakes device (via ShakeDetector)
  /// - User taps "Snooze 10 menit" button on notification
  /// 
  /// Parameters:
  /// - scheduleId: ID dari schedule di database
  Future<void> snoozeNotification(int scheduleId) async {
    if (!_isInitialized) {
      print('⚠️ NotificationService not initialized');
      return;
    }

    try {
      print('⏰ Snoozing notification for schedule $scheduleId');

      // Get schedule data from database
      final schedule = await _dbHelper.getScheduleById(scheduleId);
      if (schedule == null) {
        print('❌ Schedule not found: $scheduleId');
        return;
      }

      // Cancel current notification
      await _notifications.cancel(scheduleId);

      // Calculate snooze time (+10 minutes from now)
      final snoozeTime = tz.TZDateTime.now(tz.local).add(
        const Duration(minutes: ShakeDetector.snoozeDurationMinutes),
      );

      // Get medication name
      final medication = await _dbHelper.getMedicationById(schedule['med_id']);
      final medicationName = medication?['name'] ?? 'Obat';

      // Notification details (same as original)
      final androidDetails = AndroidNotificationDetails(
        'medication_reminder',
        'Pengingat Minum Obat',
        channelDescription: 'Notifikasi untuk mengingatkan waktu minum obat',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500]), // Vibrate pattern
        playSound: true,
        icon: '@mipmap/ic_launcher',
        actions: const [
          AndroidNotificationAction(
            'snooze',
            'Snooze 10 menit',
            showsUserInterface: false,
            cancelNotification: false,
          ),
          AndroidNotificationAction(
            'taken',
            'Sudah Minum',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule snooze notification
      await _notifications.zonedSchedule(
        scheduleId,
        '⏰ Waktunya Minum Obat! (Snooze)',
        '$medicationName - ${schedule['dosage'].toInt()} ${schedule['dosage_unit']}',
        snoozeTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: scheduleId.toString(),
      );

      print('✅ Notification snoozed until ${snoozeTime.toString()}');
      print('   Snooze count: ${ShakeDetector().snoozeCount}/${ShakeDetector.maxSnoozeCount}');
    } catch (e) {
      print('❌ Error snoozing notification: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // CANCEL NOTIFICATION
  // ══════════════════════════════════════════════════════════════

  /// Cancel notification by schedule ID
  Future<void> cancelNotification(int scheduleId) async {
    if (!_isInitialized) {
      print('⚠️ NotificationService not initialized');
      return;
    }

    try {
      await _notifications.cancel(scheduleId);
      print('✅ Notification cancelled (ID: $scheduleId)');
    } catch (e) {
      print('❌ Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) {
      print('⚠️ NotificationService not initialized');
      return;
    }

    try {
      await _notifications.cancelAll();
      print('✅ All notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // LOW STOCK NOTIFICATION
  // ══════════════════════════════════════════════════════════════

  /// Show low stock notification (immediate)
  Future<void> showLowStockNotification({
    required String medicationName,
    required double remainingStock,
    required String dosageUnit,
  }) async {
    if (!_isInitialized) {
      print('⚠️ NotificationService not initialized');
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'low_stock_alert', // channel id
        'Peringatan Stok Obat', // channel name
        channelDescription: 'Notifikasi saat stok obat hampir habis',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use negative ID to avoid conflict with schedule IDs
      final notificationId = -DateTime.now().millisecondsSinceEpoch;

      await _notifications.show(
        notificationId,
        '⚠️ Stok Obat Hampir Habis!',
        '$medicationName - Sisa ${remainingStock.toInt()} $dosageUnit. Segera beli obat baru.',
        notificationDetails,
      );

      print('✅ Low stock notification shown for $medicationName');
    } catch (e) {
      print('❌ Error showing low stock notification: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // UTILITY
  // ══════════════════════════════════════════════════════════════

  /// Get list of pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) {
      print('⚠️ NotificationService not initialized');
      return [];
    }

    try {
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 Pending notifications: ${pending.length}');
      return pending;
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  /// Check if notification permission is granted
  Future<bool> isPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
}
