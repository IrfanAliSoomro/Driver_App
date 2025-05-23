import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class PersistentNotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isPermissionRequestInProgress =
      false; // Track permission request state

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<bool> isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      final bool granted = await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
      return granted;
    }
    return false;
  }

  static Future<bool> requestPermissions() async {
    if (_isPermissionRequestInProgress) {
      debugPrint('Permission request already in progress');
      return false;
    }

    try {
      _isPermissionRequestInProgress = true;

      if (Platform.isIOS || Platform.isMacOS) {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        return true;
      } else if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

        final bool? grantedNotificationPermission =
            await androidImplementation?.requestNotificationsPermission();
        return grantedNotificationPermission ?? false;
      }
      return false;
    } finally {
      _isPermissionRequestInProgress = false;
    }
  }

  static Future<bool> show() async {
    try {
      // Check permissions first
      bool hasPermission = await isAndroidPermissionGranted();
      if (!hasPermission) {
        hasPermission = await requestPermissions();
        if (!hasPermission) return false;
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'persistent_channel',
        'Persistent Notifications',
        channelDescription: 'Keeps notification visible while app runs',
        importance: Importance.max,
        priority: Priority.max,
        ongoing: true,
        autoCancel: false,
        visibility: NotificationVisibility.public,
        colorized: true,
        color: Colors.blue,
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        0,
        'App Running',
        'Tap to return to the application',
        notificationDetails,
      );
      return true;
    } catch (e) {
      debugPrint('Error showing notification: $e');
      return false;
    }
  }

  static Future<bool> cancel() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(0);
      return true;
    } catch (e) {
      debugPrint('Error canceling notification: $e');
      return false;
    }
  }

  static Future<bool> isActive() async {
    try {
      final List<PendingNotificationRequest> pendingNotifications =
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      return pendingNotifications.any((notification) => notification.id == 0);
    } catch (e) {
      debugPrint('Error checking notification status: $e');
      return false;
    }
  }
}
