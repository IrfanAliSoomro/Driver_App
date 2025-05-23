import 'dart:async';
import 'package:android_intent_plus/android_intent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/controller/location_handler.dart';
import 'package:driver_app/controller/notification_controller.dart';
import 'package:driver_app/utils/shared_pref.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocationBackgroundService {
  static const String _channelId = 'location_service_channel';
  static const String _channelName = 'Location Service';
  static const String _channelDescription = 'Tracking your location';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final SharedPreferencesHelper _sharedPrefs = SharedPreferencesHelper.instance;
  final NotificationController _notificationController =
      NotificationController();

  // Singleton pattern
  static final LocationBackgroundService _instance =
      LocationBackgroundService._internal();
  factory LocationBackgroundService() => _instance;
  LocationBackgroundService._internal();

  // Service control
  bool _isRunning = false;
  Timer? _locationTimer;
  Position? _lastPosition;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  Future<void> initialize() async {
    await _setupNotifications();
    final hasPermission = await _checkLocationPermissions();
    if (!hasPermission) {
      throw Exception('Location permissions not granted');
    }
  }

  //
  static const String pauseActionId = 'pause_action';

  Future<void> _setupNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'pause_action') {
          await stopService();
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: false,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<bool> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      return false;
    }

    if (permission != LocationPermission.always) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) {
        debugPrint('Background location permission not granted');
        return false;
      }
    }

    return true;
  }

  Future<void> startService() async {
    if (_isRunning) return;

    await initialize();
    _isRunning = true;

    // _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen(
    //   (status) {
    //     debugPrint('Location service status changed: $status');
    //     if (status == ServiceStatus.disabled) {
    //       _showForegroundNotification(
    //         title: 'Location Service',
    //         content: 'Please enable location services',
    //       );
    //     }
    //   },
    // );

    await _showForegroundNotification();

    _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      try {
        await _updateLocation();
      } catch (e) {
        debugPrint('Error in location update: $e');
      }
    });

    await _updateLocation();
  }

  Future<void> stopService() async {
    if (!_isRunning) return;

    _locationTimer?.cancel();
    _serviceStatusSubscription?.cancel();
    _isRunning = false;

    await _notificationsPlugin.cancel(0);
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 10),
      );

      _lastPosition = position;
      debugPrint(
          'Location updated: ${position.latitude}, ${position.longitude}');

      await _updateLocationStatus(position);
    } catch (e) {
      debugPrint('Error getting location: $e');
      await _showForegroundNotification(
        content: 'Error getting location',
      );
    }
  }

  Future<void> _updateLocationStatus(Position currentPosition) async {
    const double proximityThreshold = 500;
    final activeUsers = await LocationHandler().returnActiveUsers().first;

    bool isWithinLocation1 = activeUsers.location1Latlng != null &&
        _isWithinProximity(
            currentPosition, activeUsers.location1Latlng!, proximityThreshold);

    bool isWithinLocation2 = activeUsers.location2Latlng != null &&
        _isWithinProximity(
            currentPosition, activeUsers.location2Latlng!, proximityThreshold);

    final bool isWithinAnyLocation = isWithinLocation1 || isWithinLocation2;
    final int currentStatus = await _sharedPrefs.getLocationStatus();
    final GeoPoint? lastLocation = await _sharedPrefs.getLastLocation();

    GeoPoint? currentLocation;
    if (isWithinLocation1) currentLocation = activeUsers.location1Latlng;
    if (isWithinLocation2) currentLocation = activeUsers.location2Latlng;

    bool sameLocation = lastLocation != null &&
        currentLocation != null &&
        lastLocation.latitude == currentLocation.latitude &&
        lastLocation.longitude == currentLocation.longitude;

    if (isWithinAnyLocation) {
      if (currentStatus != 1) {
        await _handleEnteredLocation(currentLocation!);
      }
    } else {
      if (currentStatus != 0) {
        await _handleExitedLocation();
      }
    }

    if (activeUsers.totalActiveUsers >= activeUsers.maxUsersNotification) {
      await _handleActiveUserThreshold(activeUsers.totalActiveUsers);
    }
  }

  Future<void> _handleEnteredLocation(GeoPoint location) async {
    await updateActiveInactiveStatus(true);
    await _sharedPrefs.saveLocationStatus(1);
    await _sharedPrefs.saveLastLocation(location);

    await _notificationController.showNotificaiton(
      title: "Location Update",
      body: "You've entered the location radius",
    );
  }

  Future<void> _handleExitedLocation() async {
    await updateActiveInactiveStatus(false);
    await _sharedPrefs.saveLocationStatus(0);
    await _sharedPrefs.saveLastLocation(GeoPoint(0, 0));

    await _notificationController.showNotificaiton(
      title: "Location Update",
      body: "You've left the location radius",
    );
  }

  Future<void> _handleActiveUserThreshold(int activeUsersCount) async {
    await _notificationController.showNotificaiton(
      title: "Recommendation:",
      body: "Go offline now to maximize surge pricing.",
    );
  }

  bool _isWithinProximity(
      Position position, GeoPoint location, double threshold) {
    return Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          location.latitude,
          location.longitude,
        ) <=
        threshold;
  }

  Future<void> updateActiveInactiveStatus(bool isActive) async {
    final userDocRef =
        FirebaseFirestore.instance.collection("active_users").doc("totalusers");

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(userDocRef);
        if (!doc.exists) {
          transaction.set(userDocRef, {'active': isActive ? 1 : 0});
        } else {
          int count = doc['active'] ?? 0;
          transaction
              .update(userDocRef, {'active': isActive ? count + 1 : count - 1});
        }
      });
    } catch (e) {
      debugPrint('Error updating active count: $e');
      await Future.delayed(Duration(seconds: 2));
      await updateActiveInactiveStatus(isActive);
    }
  }

  Future<void> _showForegroundNotification({
    String title = 'Location Service',
    String content = 'Tracking your location',
  }) async {
    const pauseIntent = AndroidIntent(
      action: 'PAUSE_LOCATION_SERVICE',
    );

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      showWhen: false,
      visibility: NotificationVisibility.public,
      // actions: [
      //   AndroidNotificationAction(
      //     'pause_action',
      //     'Pause',
      //     icon: DrawableResourceAndroidBitmap('pause_icon'),
      //   ),
      // ],
    );

    final platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      0,
      title,
      content,
      platformChannelSpecifics,
    );
  }

  Position? get lastPosition => _lastPosition;
  bool get isRunning => _isRunning;

  Future<void> dispose() async {
    await stopService();
    _serviceStatusSubscription?.cancel();
  }
}

//




//





//




//







//





//




//

//


//



// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:driver_app/controller/location_handler.dart';
// import 'package:driver_app/controller/notification_controller.dart';
// import 'package:driver_app/main.dart';
// import 'package:driver_app/utils/shared_pref.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class LocationBackgroundService {
//   static const String _channelId = 'location_service_channel';
//   static const String _channelName = 'Location Service';
//   static const String _channelDescription = 'Tracking your location';

//   final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   final sharedPreferencesHelper = SharedPreferencesHelper.instance;

//   // Singleton pattern
//   static final LocationBackgroundService _instance =
//       LocationBackgroundService._internal();
//   factory LocationBackgroundService() => _instance;
//   LocationBackgroundService._internal();

//   // Service control
//   bool _isRunning = false;
//   Timer? _locationTimer;
//   Position? _lastPosition;

//   Future<void> initialize() async {
//     await _setupNotifications();
//     await _checkLocationPermission();
//     await _checkBackgroundLocationPermission();
//   }

//   Future<void> _setupNotifications() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const InitializationSettings initializationSettings =
//         InitializationSettings(
//       android: initializationSettingsAndroid,
//     );

//     await _notificationsPlugin.initialize(initializationSettings);

//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       _channelId,
//       _channelName,
//       description: _channelDescription,
//       importance: Importance.high,
//     );

//     await _notificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//   }

//   Future<bool> _checkLocationPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       debugPrint('Location services are disabled.');
//       return false;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         debugPrint('Location permissions are denied');
//         return false;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       debugPrint('Location permissions are permanently denied');
//       return false;
//     }

//     return true;
//   }

//   Future<bool> _checkBackgroundLocationPermission() async {
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission != LocationPermission.always) {
//       permission = await Geolocator.requestPermission();
//       if (permission != LocationPermission.always) {
//         debugPrint('Background location permission not granted');
//         return false;
//       }
//     }
//     return true;
//   }

//   Future<void> startService() async {
//     if (_isRunning) return;

//     await initialize();
//     _isRunning = true;

//     // Start foreground service on Android
//     await _showForegroundNotification();

//     // Start location updates
//     _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
//       await _updateLocation();
//       if (_isMapActive) {
//         _validateLocationStatus();
//       }
//     });

//     // Get initial location
//     await _updateLocation();
//   }

//   Future<void> stopService() async {
//     if (!_isRunning) return;

//     _locationTimer?.cancel();
//     _isRunning = false;

//     // Remove foreground notification
//     await _notificationsPlugin.cancel(0);
//   }

//   Future<void> _updateLocation() async {
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.bestForNavigation,
//       );

//       _lastPosition = position;
//       debugPrint(
//           'Location updated: ${position.latitude}, ${position.longitude}');

//       await _checkAndUpdateActiveCount(position);

//       final activeUsers = await LocationHandler().returnActiveUsers().first;
//       if (activeUsers.totalActiveUsers >= activeUsers.maxUsersNotification) {
//         await NotificationController().showNotificaiton(
//           title: "Maximum Users Reached!",
//           body: "The maximum number of users has been reached!",
//         );
//       }
//     } catch (e) {
//       debugPrint('Error getting location: $e');
//       await _showForegroundNotification(
//         content: 'Error getting location',
//       );
//     }
//   }

//   Future<void> _checkAndUpdateActiveCount(Position currentPosition) async {
//     const double proximityThreshold = 500; // meters
//     final activeUsers = await LocationHandler().returnActiveUsers().first;

//     bool isWithinLocation1 = activeUsers.location1Latlng != null &&
//         LocationUtils.isWithinProximity(
//             currentPosition, activeUsers.location1Latlng!, proximityThreshold);

//     bool isWithinLocation2 = activeUsers.location2Latlng != null &&
//         LocationUtils.isWithinProximity(
//             currentPosition, activeUsers.location2Latlng!, proximityThreshold);

//     final bool isWithinAnyLocation = isWithinLocation1 || isWithinLocation2;
//     final int currentStatus = await sharedPreferencesHelper.getLocationStatus();
//     final GeoPoint? lastLocation =
//         await sharedPreferencesHelper.getLastLocation();

//     GeoPoint? currentLocation;
//     if (isWithinLocation1) currentLocation = activeUsers.location1Latlng;
//     if (isWithinLocation2) currentLocation = activeUsers.location2Latlng;

//     bool sameLocation = lastLocation != null &&
//         currentLocation != null &&
//         lastLocation.latitude == currentLocation.latitude &&
//         lastLocation.longitude == currentLocation.longitude;

//     if (isWithinAnyLocation) {
//       if (currentStatus != 1 || !sameLocation) {
//         await updateActiveInactiveStatus(true);
//         await sharedPreferencesHelper.saveLocationStatus(1);
//         await sharedPreferencesHelper.saveLastLocation(currentLocation!);
//       }
//     } else {
//       if (currentStatus != 0) {
//         await updateActiveInactiveStatus(false);
//         await sharedPreferencesHelper.saveLocationStatus(0);
//         await sharedPreferencesHelper.saveLastLocation(GeoPoint(0, 0));
//       }
//     }
//   }

//   Future<void> updateActiveInactiveStatus(bool isActive) async {
//     final userDocRef =
//         FirebaseFirestore.instance.collection("active_users").doc("totalusers");

//     try {
//       await FirebaseFirestore.instance.runTransaction((transaction) async {
//         final doc = await transaction.get(userDocRef);
//         if (!doc.exists) {
//           transaction.set(userDocRef, {'active': isActive ? 1 : 0});
//         } else {
//           int count = doc['active'] ?? 0;
//           transaction
//               .update(userDocRef, {'active': isActive ? count + 1 : count - 1});
//         }
//       });
//     } catch (e) {
//       debugPrint('Error updating active count: $e');
//     }
//   }

//   Future<void> _showForegroundNotification({
//     String title = 'Location Service',
//     String content = 'Tracking your location',
//   }) async {
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       _channelId,
//       _channelName,
//       channelDescription: _channelDescription,
//       importance: Importance.high,
//       priority: Priority.high,
//       ongoing: true,
//       showWhen: false,
//     );

//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);

//     await _notificationsPlugin.show(
//       0, // Notification ID
//       title,
//       content,
//       platformChannelSpecifics,
//     );
//   }

//   Position? get lastPosition => _lastPosition;
//   bool get isRunning => _isRunning;
// }
