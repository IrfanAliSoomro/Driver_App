import 'dart:async';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/controller/location_background_service.dart';
import 'package:driver_app/controller/location_handler.dart';
import 'package:driver_app/controller/notification_controller.dart';
import 'package:driver_app/utils/persistent_notification_service.dart';
import 'package:driver_app/utils/size_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:driver_app/controller/shared_prefs_controller.dart';
import 'package:driver_app/firebaseoptions.dart';
import 'package:driver_app/theme/app_theme.dart';
import 'package:driver_app/utils/shared_pref.dart';
import 'package:driver_app/views/screens/home_screen.dart';
import 'package:driver_app/views/screens/signin_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences first
  await Future.wait([
    NotificationController.initializeLocalNotifications(),
  ]);
  await initializeSharePref();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialized successfully.");
  } catch (e) {
    debugPrint("❌ Firebase initialization error: $e");
  }

  // Initialize background service after other critical initializations
  await initializeService();

  await PersistentNotificationService.initialize();
  bool isLoggedIn = await PrefsController().getLoginStatus();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({required this.isLoggedIn, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return MaterialApp(
      title: 'UBER, REPLICA',
      theme: AppTheme.theme,
      home: isLoggedIn ? HomeScreen() : SigninScreen(),
      routes: {
        '/signin': (context) => SigninScreen(),
        '/home': (context) => HomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<void> initializeSharePref() async {
  try {
    await SharedPreferencesHelper.instance.initPrefs();
  } catch (e) {
    debugPrint("❌ SharedPreferences initialization error: $e");
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'driver_app_channel',
      initialNotificationTitle: 'Driver App Service',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 1,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: null,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize Firebase within the background service isolate
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialized in background service.");
  } catch (e) {
    debugPrint("❌ Firebase initialization error in background service: $e");
  }

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Driver App Service",
      content: "Service is running",
    );
  }

  // Listen for stop service command
  service.on('stopService').listen((event) {
    if (event == true) {
      service.stopSelf();
    }
  });

  // Main service loop
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    try {
      // NotificationController()
      //     .showNotificaiton(title: "Test Timer", body: "Test Description");

      // Check if toggle is ON in SharedPreferences
      final isToggleOn = await SharedPreferencesHelper.instance
              .getStrValue("isActiveToggleStr") ==
          '1';
      //if (!isToggleOn) return;

      // Get current location
      // Position? position = await LocationHandler().getCurrentPositionWrapper();

      final currentPosition = LocationBackgroundService().lastPosition;
      if (currentPosition != null) {
        print(
            '`Last` known position: ${currentPosition.latitude}, ${currentPosition.longitude}');
      }

      // Check proximity and update status
      //await _checkAndUpdateActiveCount(position!);

      // Check for max users notification

      // ✅ Just print message (no toast)
      debugPrint("Location updated successfully");
    } catch (e) {
      debugPrint('Background service error: $e');
    }
  });
}

class LocationUtils {
  static bool isWithinProximity(
      Position currentPosition, GeoPoint location, double threshold) {
    double distance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      location.latitude,
      location.longitude,
    );
    return distance <= threshold;
  }
}
