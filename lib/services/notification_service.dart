import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null, // null means use default app icon
      [
        NotificationChannel(
          channelKey: 'friend_requests',
          channelName: 'Friend Requests',
          channelDescription: 'Notifications for friend requests',
          defaultColor: Colors.orange,
          ledColor: Colors.orange,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
        ),
        NotificationChannel(
          channelKey: 'watcher_requests',
          channelName: 'Watcher Requests',
          channelDescription: 'Notifications for watcher requests',
          defaultColor: Colors.blue,
          ledColor: Colors.blue,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
        ),
        NotificationChannel(
          channelKey: 'trip_updates',
          channelName: 'Trip Updates',
          channelDescription: 'Notifications for trip updates',
          defaultColor: Colors.green,
          ledColor: Colors.green,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
        ),
      ],
      debug: true,
    );

    // Listen to notification events
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onNotificationTap,
    );
  }

  Future<void> showFriendRequestNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'friend_requests',
        title: title,
        body: body,
        payload: {'data': payload ?? ''},
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<void> showWatcherNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'watcher_requests',
        title: title,
        body: body,
        payload: {'data': payload ?? ''},
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  Future<void> showTripUpdateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'trip_updates',
        title: title,
        body: body,
        payload: {'data': payload ?? ''},
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<void> _onNotificationTap(ReceivedAction receivedAction) async {
    debugPrint('Notification tapped: ${receivedAction.payload}');
    // TODO: Handle notification tap based on payload
  }

  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  Future<void> requestPermission() async {
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }
} 