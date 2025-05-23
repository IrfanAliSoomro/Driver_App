// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class LocalNotificationController {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Initialize the local notifications
//   Future<void> initialize() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('app_icon');

//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);

//     await flutterLocalNotificationsPlugin.initialize(initializationSettings);
//   }

//   // Method to show the notification
//   Future<void> showNotification(
//       {required String title, required String body}) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'your_channel_id',
//       'your_channel_name',
//       channelDescription: 'your_channel_description',
//       importance: Importance.high,
//       priority: Priority.high,
//       showWhen: false,
//     );
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);

//     await flutterLocalNotificationsPlugin.show(
//       0,
//       title,
//       body,
//       platformChannelSpecifics,
//       payload: 'item x',
//     );
//   }

//   // Method to show custom dialog
//   void showCustomDialog(BuildContext context, String title, String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(title),
//           content: Text(message),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Method to fetch active users and trigger notification if limit reached
//   Future<void> checkActiveUsersAndTriggerNotification(
//       BuildContext context, int maxActiveUsers) async {
//     try {
//       final snapshot = await _firestore.collection('users').get();
//       final int activeUsersCount = snapshot.docs.length;

//       if (activeUsersCount >= maxActiveUsers) {
//         // Trigger the local notification
//         showNotification(
//           title: 'Max Users Reached!',
//           body: 'The number of active users has reached the limit.',
//         );

//         // Show the custom dialog
//         showCustomDialog(
//           context,
//           'Max Users Reached',
//           'The number of active users has reached the maximum limit.',
//         );
//       }
//     } catch (e) {
//       print("Error fetching active users: $e");
//     }
//   }
// }
