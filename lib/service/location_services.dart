import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background/flutter_background.dart' as fb;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';

class LocationService {
  bool isBackgroundServiceRunning1 = false;
  final geo = GeoFlutterFire();

  Future<void> checkPermissions1() async {
    await Permission.location.request();
    await Permission.activityRecognition.request();
  }

  Future<bool> startDriverTrackingBackgroundService() async {
    final androidConfig = fb.FlutterBackgroundAndroidConfig(
      notificationTitle: 'Background Service',
      notificationText: 'Fetching location in the background',
      notificationImportance: fb.AndroidNotificationImportance.max,
      notificationIcon: fb.AndroidResource(
        name:
            'background_icon', // The name of the icon file without the extension
        defType: 'drawable', // The resource type
      ),
    );

    bool hasPermissions = await fb.FlutterBackground.hasPermissions;
    if (!hasPermissions && await checkLocationPermissionsOneTime()) {
      await checkPermissions();
    }

    final isInitialized =
        await fb.FlutterBackground.initialize(androidConfig: androidConfig);
    bool isRunning = false;
    if (isInitialized) {
      isRunning = await fb.FlutterBackground.enableBackgroundExecution();
      if (isRunning) {
        //isBackgroundServiceRunning = true;
        _fetchLocationPeriodically();
      }
    }
    return isRunning;
  }

  Future<void> startTrackingBackgroundService() async {
    bool hasPermissions = await fb.FlutterBackground.hasPermissions;

    final androidConfig = fb.FlutterBackgroundAndroidConfig(
      notificationTitle: 'Background Service',
      notificationText: 'Fetching location in the background',
      notificationImportance: fb.AndroidNotificationImportance.normal, //
      notificationIcon: fb.AndroidResource(
        name:
            'background_icon', // The name of the icon file without the extension
        defType: 'drawable', // The resource type
      ),
    );

    if (!hasPermissions) {
      hasPermissions = await checkPermissions();
    }

    final isInitialized =
        await fb.FlutterBackground.initialize(androidConfig: androidConfig);
    if (isInitialized) {
      await fb.FlutterBackground.enableBackgroundExecution();
    } else {
      print('Background execution could not be started.');
    }
  }

  Future<bool> checkLocationPermissionsOneTime() async {
    // Request foreground location permissions
    PermissionStatus locationStatus = await Permission.location.request();
    if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
      return true;
    }
    return false;
  }

  Future<bool> isLocationPermissionEnabled() async {
    // Request foreground location permissions
    PermissionStatus locationStatus = await Permission.location.request();
    if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
      return false;
    }
    return true;
  }

  Future<bool> checkPermissions() async {
    // Request foreground location permissions
    PermissionStatus locationStatus = await Permission.location.request();
    if (locationStatus.isDenied || locationStatus.isPermanentlyDenied) {
      return false;
    }

    // Request background location permissions
    PermissionStatus backgroundLocationStatus =
        await Permission.locationAlways.request();
    if (backgroundLocationStatus.isDenied ||
        backgroundLocationStatus.isPermanentlyDenied) {
      return false;
    }

    return locationStatus.isGranted && backgroundLocationStatus.isGranted;
  }

  Future<bool> checkLocationPermissions() async {
    final androidConfig = fb.FlutterBackgroundAndroidConfig(
      notificationTitle: 'Background Service',
      notificationText: 'Fetching location in the background',
      notificationImportance: fb.AndroidNotificationImportance.normal,
      notificationIcon: fb.AndroidResource(
        name:
            'background_icon', // The name of the icon file without the extension
        defType: 'drawable', // The resource type
      ),
    );

    bool hasPermissions = await fb.FlutterBackground.hasPermissions;
    PermissionStatus locationStatus = await Permission.location.request();
    if (!hasPermissions || !locationStatus.isGranted) {
      return await checkPermissions();
    }
    return true;
  }

  bool isBackgroundServiceRunning() {
    return fb.FlutterBackground.isBackgroundExecutionEnabled;
  }

  Future<void> stopBackgroundService() async {
    try {
      if (isBackgroundServiceRunning()) {
        await fb.FlutterBackground.disableBackgroundExecution();
        // isBackgroundServiceRunning = false; // Update local state if necessary
      }
    } catch (e) {
      print('Error stopping background service: $e');
    }
  }

  void _fetchUpdateLocation() {
    Future.doWhile(() async {
      if (!isBackgroundServiceRunning()) return false;

      getCurrentLocation().then((position) async {});

      await Future.delayed(
          Duration(seconds: 10)); // Adjust the interval as needed
      return true;
    });
  }

  void _fetchLocationPeriodically() {
    Future.doWhile(() async {
      if (!isBackgroundServiceRunning()) return false;
      try {
        updateCurrentLocationOnFirestore();
      } catch (e) {
        print(e);
      }

      await Future.delayed(
          Duration(seconds: 10)); // Adjust the interval as needed
      return true;
    });
  }

  void updateCurrentLocationOnFirestore() async {
    getCurrentLocation().then((position) async {
      if (FirebaseAuth.instance.currentUser == null) {
        stopBackgroundService();
        return;
      }
      String? userId = FirebaseAuth.instance.currentUser!.uid;
      updateLocation(userId, position);
    });
  }

  void updateLocation(String userId, Position position) async {
    GeoFirePoint myLocation =
        geo.point(latitude: position.latitude, longitude: position.longitude);
    final userDocRef =
        FirebaseFirestore.instance.collection("location").doc(userId);
    final docSnapshot = await userDocRef.get();
    if (docSnapshot.exists) {
      await userDocRef.update({'position': myLocation.data});
    } else {
      await userDocRef.set({'position': myLocation.data});
    }
  }

  Future<Position> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print("Current Position: ${position.latitude}, ${position.longitude}");
    return position;
  }

  Future<LatLng?> getCurrentLocationOnButtonClick() async {
    try {
      Position position = await getCurrentLocation();
      LatLng location = LatLng(position.latitude, position.longitude);
      return location;
    } catch (e) {
      print('Error getting current location on button click: $e');
    }
    return null;
  }
}
