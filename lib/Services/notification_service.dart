import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal({FlutterLocalNotificationsPlugin? plugin})
      : _notificationsPlugin = plugin ?? FlutterLocalNotificationsPlugin();

  @visibleForTesting
  factory NotificationService.withPlugin(FlutterLocalNotificationsPlugin plugin) {
    return NotificationService._internal(plugin: plugin);
  }

  @visibleForTesting
  static void setMockInstance(NotificationService service) {
    _instance = service;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = NotificationService._internal();
  }

  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize({bool isBackground = false}) async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Automatically detect background isolates (where lifecycleState is null) to prevent NullPointerException
    final bool isBackgroundIsolate =
        WidgetsBinding.instance.lifecycleState == null;

    if (!isBackground && !isBackgroundIsolate) {
      try {
        final androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          await androidImplementation.requestNotificationsPermission();
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[NotificationService] Permission prompt skipped: $e');
        }
      }
    }

    _isInitialized = true;
    if (kDebugMode) {
      debugPrint(
          '[NotificationService] Initialized successfully (isBackground: $isBackground)');
    }
  }

  Future<void> showPriceAlertNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'price_alerts_channel',
      'Price Alerts',
      channelDescription: 'Notifications sent when market assets reach target alert prices',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }
}
