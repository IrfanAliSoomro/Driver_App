// ignore: depend_on_referenced_packages
// ignore_for_file: depend_on_referenced_packages

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';

class LocationHandler {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeoFlutterFire geo = GeoFlutterFire();

  Future<List<DocumentSnapshot>> getNearbyUsers() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    GeoFirePoint myLocation = geo.point(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    // Query users collection
    var collectionRef = _firestore.collection('location');

    // Search for users within 500 meters
    var stream = geo.collection(collectionRef: collectionRef).within(
          center: myLocation,
          radius: 0.5, // 0.5 km = 500 meters
          field: 'position',
          strictMode: true,
        );

    List<DocumentSnapshot> nearbyUsers = await stream.first;
    return nearbyUsers;
  }

  Stream<ActiveUsersModel> returnActiveUsers() {
    var collectionRef = FirebaseFirestore.instance.collection('active_users');

    return collectionRef.snapshots().map((querySnapshot) {
      int totalActiveUsers = 0;
      GeoPoint? location1Latlng;
      GeoPoint? location2Latlng;
      int maxUsersNotification = 0;

      if (querySnapshot.docs.isNotEmpty) {
        for (var doc in querySnapshot.docs) {
          Map<String, dynamic> data = doc.data();

          if (doc.id == 'totalusers') {
            totalActiveUsers = data['active'] ?? 0;
          } else if (doc.id == 'location1') {
            double? lat = double.tryParse(data['lat'].toString());
            double? lng = double.tryParse(data['lng'].toString());
            if (lat != null && lng != null) {
              location1Latlng = GeoPoint(lat, lng);
            }
          } else if (doc.id == 'location2') {
            double? lat = double.tryParse(data['lat'].toString());
            double? lng = double.tryParse(data['lng'].toString());
            if (lat != null && lng != null) {
              location2Latlng = GeoPoint(lat, lng);
            }
          } else if (doc.id == 'max_users') {
            maxUsersNotification = data['max_users_notifi'] ?? 0;
          }
        }
      }

      return ActiveUsersModel(
        totalActiveUsers: totalActiveUsers,
        location1Latlng: location1Latlng,
        location2Latlng: location2Latlng,
        maxUsersNotification: maxUsersNotification,
      );
    });
  }

  Future<Position?> getCurrentPositionWrapper() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
            'Location permissions are permanently denied, we cannot request permissions.');
        return null;
      }

      // When we reach here, permissions are granted and we can
      // continue accessing the position of the device.
      try {
        Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 10))
            .timeout(const Duration(seconds: 10), onTimeout: () {
          debugPrint('Timeout getting location.');
          return Future.value(null); // Return null on timeout
        });
        return position;
      } catch (e) {
        debugPrint('Error getting location: $e');
        return null;
      }
    } catch (e) {
      debugPrint('Error in getCurrentPositionWrapper: $e');
      return null;
    }
  }
}

class ActiveUsersModel {
  final int totalActiveUsers;
  final GeoPoint? location1Latlng;
  final GeoPoint? location2Latlng;
  final int maxUsersNotification;

  ActiveUsersModel({
    required this.totalActiveUsers,
    this.location1Latlng,
    this.location2Latlng,
    required this.maxUsersNotification,
  });
}
