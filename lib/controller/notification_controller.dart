import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:driver_app/views/screens/home_screen.dart';
import 'package:flutter/material.dart';

class NotificationController {
  //final timeZone = TimeZone();
  static final NotificationController _instance =
      NotificationController._internal();
  static NotificationController notificationController =
      NotificationController();

  factory NotificationController() {
    return _instance;
  }

  NotificationController._internal();
  static ReceivedAction? initialAction;

  ///     INITIALIZATIONS
  static Future<void> initializeLocalNotifications() async {
    await AwesomeNotifications().initialize(
        null, //'resource://drawable/res_app_icon',//
        [
          NotificationChannel(
              channelKey: 'alerts',
              channelName: 'Alerts',
              channelDescription: 'Notification tests as alerts',
              playSound: true,
              onlyAlertOnce: true,
              //groupAlertBehavior: GroupAlertBehavior.Children,
              importance: NotificationImportance.High,
              defaultPrivacy: NotificationPrivacy.Private,
              defaultColor: Colors.deepPurple,
              ledColor: Colors.deepPurple)
        ],
        debug: true);

    // Get initial notification action is optional
    initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
  }

  Future<void> showNotificaiton({
    required String title,
    required String body,
  }) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) isAllowed = await displayNotificationRationale();
    if (!isAllowed) return;
    String groupKey = 'default';
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 1212, // -1 is replaced by a random number
          channelKey: 'alerts',
          title: title,
          groupKey: groupKey,
          // bodyLocKey: "{json}",
          body: body,
          notificationLayout: NotificationLayout.BigPicture,
          //payload: {'notifiationJson': payload}
        ),
        actionButtons: [
          // NotificationActionButton(key: 'Accept', label: 'Accept'),
          // NotificationActionButton(key: 'Reject', label: 'Reject'),
          NotificationActionButton(
              key: 'DISMISS',
              label: 'Dismiss',
              actionType: ActionType.DismissAction,
              isDangerousOption: true)
        ]);
  }

  static Future<bool> displayNotificationRationale() async {
    bool userAuthorized = false;
    BuildContext context = HomeScreen.navigatorKey.currentContext!;
    await showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text("get_notified",
                style: Theme.of(context).textTheme.titleLarge),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                const Text(
                    "Allow Awesome Notifications to send you beautiful notifications!"),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    "Allow",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.red),
                  )),
              TextButton(
                  onPressed: () async {
                    userAuthorized = true;
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    "Allow",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.deepPurple),
                  )),
            ],
          );
        });
    return userAuthorized &&
        await AwesomeNotifications().requestPermissionToSendNotifications();
  }
}
