// shared_preferences_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  // Singleton instance
  SharedPreferencesHelper._();
  static final SharedPreferencesHelper _instance = SharedPreferencesHelper._();
  static SharedPreferencesHelper get instance => _instance;

  SharedPreferences? _sharedPreferences;

  // Initialize shared preferences
  Future<SharedPreferences> initPrefs() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    return _sharedPreferences!;
  }

  // String List operations
  dynamic getValue(String key) {
    final prefs = _sharedPreferences;
    return prefs?.getStringList(key);
  }

  Future<void> saveValue(String key, dynamic value) async {
    final prefs = _sharedPreferences;
    if (value is List<String>) {
      await prefs?.setStringList(key, value);
    }
  }

  // String operations
  dynamic getStrValue(String key) {
    final prefs = _sharedPreferences;
    return prefs?.getString(key) ?? '';
  }

  Future<void> saveStrValue(String key, String value) async {
    final prefs = _sharedPreferences;
    await prefs?.setString(key, value);
  }

  // Int operations
  Future<void> saveIntValue(String key, int value) async {
    final prefs = _sharedPreferences;
    await prefs?.setInt(key, value);
  }

  Future<int?> getIntValue(String key) async {
    final prefs = _sharedPreferences;
    return prefs?.getInt(key);
  }

  // Clear all
  Future<void> clearSharedPreferences() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }

  // Constants
  static const String _locationStatusKey = 'location_status';
  static const String _lastLocationKey = 'last_location';

  // Location status methods
  Future<void> saveLocationStatus(int status) async {
    await saveIntValue(_locationStatusKey, status);
  }

  Future<int> getLocationStatus() async {
    return (await getIntValue(_locationStatusKey)) ?? 0;
  }

  // Last location methods
  Future<void> saveLastLocation(GeoPoint location) async {
    await saveStrValue(
        _lastLocationKey, '${location.latitude},${location.longitude}');
  }

  Future<GeoPoint?> getLastLocation() async {
    final locationStr = await getStrValue(_lastLocationKey);
    if (locationStr.isEmpty) return null;
    final parts = locationStr.split(',');
    if (parts.length != 2) return null;
    return GeoPoint(double.parse(parts[0]), double.parse(parts[1]));
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class SharedPreferencesHelper {
//   // Private constructor to prevent instantiation
//   SharedPreferencesHelper._();

//   // Singleton instance
//   static final SharedPreferencesHelper _instance = SharedPreferencesHelper._();

//   // Getter for the singleton instance
//   static SharedPreferencesHelper get instance => _instance;

//   // Shared preferences instance
//   SharedPreferences? _sharedPreferences;

//   // Method to initialize shared preferences
//   Future<SharedPreferences> initPrefs() async {
//     _sharedPreferences ??= await SharedPreferences.getInstance();
//     return _sharedPreferences!;
//   }

//   dynamic getValue(String key) {
//     final SharedPreferences? prefs = _sharedPreferences;
//     return prefs!.getStringList(key);
//   }

//   dynamic getStrValue(String key) {
//     final SharedPreferences? prefs = _sharedPreferences;
//     dynamic va = prefs!.getString(key);
//     if (va == null) return '';
//     return va;
//   }

//   Future<void> saveStrValue(String key, String value) async {
//     try {
//       final SharedPreferences? prefs = _sharedPreferences;
//       await prefs!.setString(key, value);
//     } catch (e) {
//       print('Error saving string value: $e');
//     }
//   }

//   Future<void> saveValue(String key, dynamic value) async {
//     final SharedPreferences? prefs = _sharedPreferences;
//     if (value is List<String>) {
//       await prefs!.setStringList(key, value);
//     }
//   }

//   Future<void> clearSharedPreferences() async {
//     SharedPreferences preferences = await SharedPreferences.getInstance();
//     await preferences.clear();
//   }

//   //
//   //
//   // Add these to your SharedPreferencesHelper class
//   static const String _locationStatusKey = 'location_status';
//   static const String _lastLocationKey = 'last_location';

//   Future<void> saveLocationStatus(int status) async {
//     await saveIntValue(_locationStatusKey, status);
//   }

//   Future<int> getLocationStatus() async {
//     return getIntValue(_locationStatusKey) ?? 0;
//   }

//   Future<void> saveLastLocation(GeoPoint location) async {
//     await saveStrValue(
//         _lastLocationKey, '${location.latitude},${location.longitude}');
//   }

//   Future<GeoPoint?> getLastLocation() async {
//     final locationStr = await getStrValue(_lastLocationKey);
//     if (locationStr == null) return null;
//     final parts = locationStr.split(',');
//     return GeoPoint(double.parse(parts[0]), double.parse(parts[1]));
//   }
// }
