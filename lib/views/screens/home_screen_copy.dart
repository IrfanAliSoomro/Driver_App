// import 'dart:async';
// import 'dart:io';
// import 'dart:math';
// import 'package:driver_app/controller/location_background_service.dart';
// import 'package:driver_app/controller/notification_controller.dart';
// import 'package:driver_app/utils/persistent_notification_service.dart';
// import 'package:driver_app/utils/shared_pref.dart';
// import 'package:driver_app/views/widgets/label/default_label.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../../controller/auth_controller.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geoflutterfire2/geoflutterfire2.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import '../../controller/location_handler.dart';

// class HomeScreen extends StatefulWidget {
//   static final GlobalKey<NavigatorState> navigatorKey =
//       GlobalKey<NavigatorState>();

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final NotificationController notificationController =
//       NotificationController();
//   final geo = GeoFlutterFire();
//   final SharedPreferencesHelper sharedPreferencesHelper =
//       SharedPreferencesHelper.instance;
//   final AuthController _authController = AuthController();

//   GoogleMapController? _mapController;
//   LatLng? _currentLocation;
//   bool _isMapActive = false;
//   bool _isLoading = false;
//   int locStatus = 0; // 0: out of range, 1: within radius

//   ActiveUsersModel activeUsersModel =
//       ActiveUsersModel(totalActiveUsers: 0, maxUsersNotification: 0);
//   BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
//   final Set<Marker> markers = {};
//   bool _isDialogShowing = false;
//   StreamSubscription? _activeUsersSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }

//   Future<void> _initializeApp() async {
//     await _loadInitialStatus();
//     await _checkLocationPermission();
//     await _checkNotificationStatus();

//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (_isMapActive) {
//         await _startLocationServices();
//       }
//     });
//   }

//   Future<void> _startLocationServices() async {
//     await LocationBackgroundService().startService();
//     await _startLiveLocation();

//     Timer.periodic(Duration(seconds: 5), (timer) {
//       if (_isMapActive) {
//         _validateLocationStatus();
//       } else {
//         timer.cancel();
//       }
//     });
//   }

//   Future<void> _loadInitialStatus() async {
//     final status = await sharedPreferencesHelper.getLocationStatus();
//     if (mounted) {
//       setState(() => locStatus = status);
//     }
//   }

//   Future<void> _checkNotificationStatus() async {
//     final isActive = await PersistentNotificationService.isActive();
//     if (mounted) {
//       setState(() => _isMapActive = isActive);
//     }
//   }

//   Future<void> _initializeAfterPermission() async {
//     await loadActiveUsers();
//     initData();
//     setCustomMarkerIcon();
//   }

//   Future<void> _checkLocationPermission() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showLocationServiceDisabledDialog(context);
//       return;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showLocationPermissionDeniedDialog(context);
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showLocationPermissionDeniedForeverDialog(context);
//       return;
//     }

//     await _initializeAfterPermission();
//   }

//   @override
//   void dispose() {
//     _activeUsersSubscription?.cancel();
//     super.dispose();
//   }

//   Future<void> loadActiveUsers() async {
//     setState(() => _isLoading = true);
//     _activeUsersSubscription?.cancel();

//     try {
//       final currentUsers = await LocationHandler().returnActiveUsers().first;
//       if (mounted) {
//         setState(() {
//           activeUsersModel = currentUsers;
//           _isLoading = false;
//         });
//         if (_isMapActive) {
//           _handleActiveUserNotifications(currentUsers);
//         }
//       }
//     } catch (e) {
//       print("Error loading active users: $e");
//       if (mounted) setState(() => _isLoading = false);
//     }

//     _activeUsersSubscription = LocationHandler().returnActiveUsers().listen(
//       (activeUsers) {
//         if (mounted) {
//           setState(() {
//             activeUsersModel = activeUsers;
//             _isLoading = false;
//           });
//           if (_isMapActive) {
//             _handleActiveUserNotifications(activeUsers);
//           }
//         }
//       },
//       onError: (error) {
//         print("Error in active users stream: $error");
//         if (mounted) setState(() => _isLoading = false);
//       },
//     );
//   }

//   void initData() {
//     String isToggleActive =
//         sharedPreferencesHelper.getStrValue("isActiveToggleStr");
//     _toggleMap(isToggleActive == '1');
//   }

//   Future<void> _toggleMap(bool value) async {
//     setState(() => _isLoading = true);
//     final locationService = LocationBackgroundService();

//     if (value) {
//       if (!await _ensureLocationPermissions()) {
//         setState(() => _isLoading = false);
//         return;
//       }

//       _startLocationServices();
//       // await sharedPreferencesHelper.saveLocationStatus(0);
//       // await locationService.startService();
//       // await _startLiveLocation();
//       await PersistentNotificationService.show();
//       await loadActiveUsers();
//     } else {
//       if (locStatus == 1) {
//         await updateActiveInactiveStatus(false);
//         await sharedPreferencesHelper.saveLocationStatus(0);
//         if (mounted) setState(() => locStatus = 0);
//       }

//       await locationService.stopService();
//       await PersistentNotificationService.cancel();
//     }

//     if (mounted) {
//       setState(() => _isMapActive = value);
//     }
//     await sharedPreferencesHelper.saveStrValue(
//         "isActiveToggleStr", value ? '1' : '0');
//     if (mounted) setState(() => _isLoading = false);
//   }

//   Future<bool> _ensureLocationPermissions() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showLocationServiceDisabledDialog(context);
//       return false;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       await _checkLocationPermission();
//       return false;
//     }

//     return true;
//   }

//   Future<void> _validateLocationStatus() async {
//     if (!_isMapActive) return;

//     try {
//       Position position = await getCurrentLocation();
//       await _checkAndUpdateActiveCount(position);
//     } catch (e) {
//       print("Error validating location: $e");
//       // Only update status if we're sure we're not in the radius
//       if (mounted) setState(() => locStatus = 0);
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
//           if (isActive) {
//             transaction.update(userDocRef, {'active': count + 1});
//           } else {
//             // Prevent negative count
//             transaction
//                 .update(userDocRef, {'active': count > 0 ? count - 1 : 0});
//           }
//         }
//       });
//     } catch (e) {
//       debugPrint('Error updating active count: $e');
//       await Future.delayed(Duration(seconds: 2));
//       await updateActiveInactiveStatus(isActive);
//     }
//   }

//   Future<void> _startLiveLocation() async {
//     try {
//       Position position = await getCurrentLocation();

//       setState(() {
//         _currentLocation = LatLng(position.latitude, position.longitude);
//         _isLoading = false;
//       });

//       if (FirebaseAuth.instance.currentUser?.uid != null) {
//         await _checkAndUpdateActiveCount(position);
//       }

//       if (_mapController != null && _currentLocation != null && mounted) {
//         Future.delayed(Duration(milliseconds: 300), () {
//           _mapController?.animateCamera(
//             CameraUpdate.newLatLngZoom(_currentLocation!, 20),
//           );
//         });
//       }
//     } catch (e) {
//       print("Error getting location: $e");
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _checkAndUpdateActiveCount(Position currentPosition) async {
//     try {
//       const double proximityThreshold = 500; // meters
//       final activeUsers = await LocationHandler().returnActiveUsers().first;

//       bool isWithinLocation1 = activeUsers.location1Latlng != null &&
//           _isWithinProximity(currentPosition, activeUsers.location1Latlng!,
//               proximityThreshold);

//       bool isWithinLocation2 = activeUsers.location2Latlng != null &&
//           _isWithinProximity(currentPosition, activeUsers.location2Latlng!,
//               proximityThreshold);

//       final bool isWithinAnyLocation = isWithinLocation1 || isWithinLocation2;
//       final int currentStatus =
//           await sharedPreferencesHelper.getLocationStatus();

//       if (isWithinAnyLocation) {
//         if (currentStatus != 1) {
//           // sharedPreferencesHelper.saveLocationStatus(1);
//           // Only update if status is changing
//           await _handleLocationStatusChange(
//             newStatus: 1,
//             isActive: true,
//             notificationTitle: "Location Update",
//             notificationBody: "You've entered the location radius",
//           );
//         }
//       } else {
//         if (currentStatus != 0) {
//           // Only update if status is changing
//           // sharedPreferencesHelper.saveLocationStatus(0);
//           await _handleLocationStatusChange(
//             newStatus: 0,
//             isActive: false,
//             notificationTitle: "Location Update",
//             notificationBody: "You've left the location radius",
//           );
//         }
//       }

//       if (mounted) {
//         setState(() {
//           activeUsersModel = activeUsers;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       print("Error in active count check: $e");
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _handleLocationStatusChange({
//     required int newStatus,
//     required bool isActive,
//     required String notificationTitle,
//     required String notificationBody,
//   }) async {
//     // First update the status locally
//     if (mounted) {
//       setState(() => locStatus = newStatus);
//     }

//     // Then save to shared preferences
//     await sharedPreferencesHelper.saveLocationStatus(newStatus);

//     // Then update Firebase
//     await updateActiveInactiveStatus(isActive);

//     // Finally show notification
//     notificationController.showNotificaiton(
//       title: notificationTitle,
//       body: notificationBody,
//     );
//   }

//   void _showThresholdDialog(ActiveUsersModel activeUsers) {
//     if (_isDialogShowing) return;
//     _isDialogShowing = true;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: DefaultLabel(
//           text: "Recommendation:",
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//         ),
//         content: DefaultLabel(
//           text: "Go offline now to maximize surge pricing.",
//           fontSize: 16,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               _isDialogShowing = false;
//               Navigator.pop(context);
//             },
//             child: DefaultLabel(
//               text: "OK",
//               fontSize: 16,
//               color: Colors.black,
//             ),
//           ),
//         ],
//       ),
//     ).then((_) => _isDialogShowing = false);
//   }

//   void _handleActiveUserNotifications(ActiveUsersModel activeUsers) async {
//     if (activeUsers.totalActiveUsers >= activeUsers.maxUsersNotification) {
//       await notificationController.showNotificaiton(
//         title: "Recommendation:",
//         body: "Go offline now to maximize surge pricing.",
//       );

//       if (_isMapActive &&
//           mounted &&
//           ModalRoute.of(context)?.isCurrent == true) {
//         _showThresholdDialog(activeUsers);
//       }
//     } else {
//       _isDialogShowing = false;
//     }
//   }

//   bool _isWithinProximity(
//       Position currentPosition, GeoPoint location, double threshold) {
//     return Geolocator.distanceBetween(
//           currentPosition.latitude,
//           currentPosition.longitude,
//           location.latitude,
//           location.longitude,
//         ) <=
//         threshold;
//   }

//   Future<Position> getCurrentLocation() async {
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: Duration(seconds: 10),
//       );

//       // Validate that we got a real position
//       if (position.latitude == 0.0 && position.longitude == 0.0) {
//         throw Exception("Invalid position received");
//       }

//       return position;
//     } catch (e) {
//       print("Error getting location: $e");
//       // Try to get last known position if current fails
//       Position? lastPosition = await Geolocator.getLastKnownPosition();
//       if (lastPosition != null) {
//         return lastPosition;
//       }
//       // If all fails, rethrow the exception
//       rethrow;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.teal,
//         title: DefaultLabel(
//           text: 'Drivers Coordination',
//           color: Colors.white,
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.logout, color: Colors.white),
//             onPressed: () => _showLogoutDialog(context),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           if (_isLoading)
//             LinearProgressIndicator(
//               backgroundColor: Colors.teal.withOpacity(0.2),
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
//             ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     DefaultLabel(
//                       text: "Active",
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     Transform.scale(
//                       scale: 0.8,
//                       child: Switch(
//                         value: _isMapActive,
//                         onChanged: (value) => _toggleMap(value),
//                         activeColor: Colors.teal,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 10),
//                 Row(
//                   children: [
//                     Expanded(
//                       flex: 1,
//                       child: _buildStatusCard(
//                         icon: Icons.person,
//                         color: Color(0xFF7BC0FA),
//                         title: "Active Users",
//                         value: '${activeUsersModel.totalActiveUsers}',
//                       ),
//                     ),
//                     SizedBox(width: 10),
//                     Expanded(
//                       flex: 1,
//                       child: _buildRefreshCard(),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 6),
//                 Center(
//                   child: DefaultLabel(
//                     text: _getLocationStatusText(),
//                     fontSize: 12,
//                     color: _getLocationStatusColor(),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             flex: 10,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(15),
//                 child: _isMapActive
//                     ? GoogleMap(
//                         initialCameraPosition: CameraPosition(
//                           target: _currentLocation ?? LatLng(0, 0),
//                           zoom: 20.0,
//                         ),
//                         onMapCreated: (controller) {
//                           _mapController = controller;
//                           if (_currentLocation != null && mounted) {
//                             Future.delayed(Duration(milliseconds: 300), () {
//                               _mapController?.animateCamera(
//                                 CameraUpdate.newLatLngZoom(
//                                     _currentLocation!, 20),
//                               );
//                             });
//                           }
//                         },
//                         markers: {
//                           if (_currentLocation != null)
//                             Marker(
//                               markerId: MarkerId("My Location"),
//                               icon: currentLocationIcon,
//                               position: _currentLocation!,
//                             ),
//                         },
//                         myLocationEnabled: true,
//                         zoomControlsEnabled: true,
//                         zoomGesturesEnabled: true,
//                       )
//                     : Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.map, size: 50, color: Colors.grey),
//                             SizedBox(height: 10),
//                             DefaultLabel(
//                               text: "Enable the switch to activate map",
//                               color: Colors.grey,
//                               fontSize: 16,
//                             ),
//                           ],
//                         ),
//                       ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatusCard({
//     required IconData icon,
//     required Color color,
//     required String title,
//     required String value,
//   }) {
//     return Expanded(
//       child: Container(
//         height: 70,
//         padding: EdgeInsets.all(10),
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: Colors.white, size: 30),
//             SizedBox(width: 10),
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   DefaultLabel(
//                     text: title,
//                     fontSize: 14,
//                     color: Colors.white,
//                   ),
//                   SizedBox(height: 2),
//                   DefaultLabel(
//                     text: value,
//                     fontSize: 16,
//                     color: Colors.white,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildRefreshCard() {
//     return Expanded(
//       child: GestureDetector(
//         onTap: loadActiveUsers,
//         child: Container(
//           height: 70,
//           padding: EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: Color(0xFFABF6BA),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Center(
//             child: _isLoading
//                 ? Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       SizedBox(
//                         height: 16,
//                         width: 16,
//                         child: CircularProgressIndicator(
//                           color: Colors.black,
//                           strokeWidth: 2,
//                         ),
//                       ),
//                       // SizedBox(width: 8),
//                       // DefaultLabel(
//                       //   text: "Updating...",
//                       //   fontSize: 14,
//                       //   fontWeight: FontWeight.bold,
//                       //   color: Colors.black,
//                       // ),
//                     ],
//                   )
//                 : Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.refresh, color: Colors.black, size: 26),
//                       SizedBox(width: 8),
//                       Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           DefaultLabel(
//                             text: "Login Update",
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                           ),
//                           DefaultLabel(
//                             text: "1 min ago",
//                             fontSize: 14,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//           ),
//         ),
//       ),
//     );
//   }

//   String _getLocationStatusText() {
//     if (!_isMapActive) return "Location tracking is disabled";

//     switch (locStatus) {
//       case 1:
//         return "You are in the surge zone.";
//       case 0:
//         return "You are not in the surge zone.";
//       default:
//         return _currentLocation == null
//             ? "Acquiring location..."
//             : "Location acquired";
//     }
//   }

//   Color _getLocationStatusColor() {
//     if (!_isMapActive) return Colors.orange;
//     return locStatus == 1 ? Colors.green : Colors.red;
//   }

//   void setCustomMarkerIcon() {
//     BitmapDescriptor.fromAssetImage(
//       ImageConfiguration(size: Size(48, 48)),
//       "assets/marker_loc.png",
//     ).then((icon) {
//       if (mounted) setState(() => currentLocationIcon = icon);
//     });
//   }

//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: DefaultLabel(
//           text: 'Logout',
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//         ),
//         content: DefaultLabel(
//           text: 'Are you sure you want to log out?',
//           fontSize: 16,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: DefaultLabel(text: 'Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _authController.signOut(context);
//             },
//             child: DefaultLabel(
//               text: 'Logout',
//               color: Colors.red,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ... (Keep your existing dialog methods like _showLocationPermissionDeniedDialog etc.)

//   //
//   void _showLocationServiceDisabledDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: DefaultLabel(text: 'Location Services Disabled'),
//           content: DefaultLabel(
//               text: 'Please enable location services to use this feature.'),
//           actions: [
//             TextButton(
//               child: DefaultLabel(text: 'Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: DefaultLabel(text: 'Enable Location'),
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 // Open device location settings
//                 if (Platform.isAndroid) {
//                   await Geolocator.openLocationSettings();
//                 } else if (Platform.isIOS) {
//                   await openAppSettings(); //permission_handler package
//                 }
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   //
//   void _showLocationPermissionDeniedDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: DefaultLabel(text: 'Location Permission Denied'),
//           content: DefaultLabel(
//               text:
//                   'Location permission is required to use this feature. Please enable it.'),
//           actions: [
//             TextButton(
//               child: DefaultLabel(text: 'Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: DefaultLabel(text: 'Request Permission'),
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 await _checkLocationPermission(); // Re-request permission
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   //
//   void _showLocationPermissionDeniedForeverDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           title: DefaultLabel(
//             text: 'Location Permission Denied Forever',
//             fontWeight: FontWeight.bold,
//           ),
//           content: DefaultLabel(
//             text:
//                 'Location permission is required to use this feature. Please enable it in app settings.',
//             color: Colors.black,
//           ),
//           actions: [
//             TextButton(
//               child: DefaultLabel(
//                 text: 'Cancel',
//                 color: Colors.grey,
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: DefaultLabel(
//                 text: 'Open Settings',
//                 color: Colors.black,
//               ),
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 await openAppSettings(); // uses permission_handler package
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
// }


// This is NEW backup Code

// import 'dart:async';
// import 'dart:io';
// import 'package:driver_app/controller/location_background_service.dart';
// import 'package:driver_app/controller/notification_controller.dart';
// import 'package:driver_app/main.dart';
// import 'package:driver_app/utils/persistent_notification_service.dart';
// import 'package:driver_app/utils/shared_pref.dart';
// import 'package:driver_app/views/widgets/label/default_label.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../../controller/auth_controller.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geoflutterfire2/geoflutterfire2.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter/services.dart';

// import '../../controller/location_handler.dart';

// class HomeScreen extends StatefulWidget {
//   static final GlobalKey<NavigatorState> navigatorKey =
//       GlobalKey<NavigatorState>();
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   NotificationController notificationController = NotificationController();
//   final geo = GeoFlutterFire();
//   SharedPreferencesHelper sharedPreferencesHelper =
//       SharedPreferencesHelper.instance;
//   final AuthController _authController = AuthController();
//   GoogleMapController? _mapController;
//   LatLng? _currentLocation;
//   bool _isMapActive = false;
//   ActiveUsersModel activeUsersModel =
//       ActiveUsersModel(totalActiveUsers: 0, maxUsersNotification: 0);
//   bool _isLoading = false;

//   BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
//   final Set<Marker> markers = {};
//   int locStatus = 0; // 0 : out of range, 1 : Enter , 2 :  Out

//   @override
//   void initState() {
//     super.initState();
//     _loadInitialStatus();
//     _checkLocationPermission();
//     _checkNotificationStatus();

//     // Initialize and start service if needed
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (_isMapActive) {
//         await LocationBackgroundService().startService();
//         _startLiveLocation();

//         // Add periodic status validation
//         Timer.periodic(Duration(seconds: 30), (timer) {
//           if (_isMapActive) {
//             _validateLocationStatus();
//           } else {
//             timer.cancel();
//           }
//         });
//       }
//     });
//   }

//   Future<void> _loadInitialStatus() async {
//     final status = await sharedPreferencesHelper.getLocationStatus();
//     if (mounted) {
//       setState(() {
//         locStatus = status;
//       });
//     }
//   }

//   Future<void> _checkNotificationStatus() async {
//     final isActive = await PersistentNotificationService.isActive();
//     if (mounted) {
//       setState(() {
//         _isMapActive = isActive; // Sync toggle with notification status
//       });
//     }
//   }

//   Future<void> _initializeAfterPermission() async {
//     loadActiveUsers();
//     initData();
//     setCustomMarkerIcon();
//   }

//   Future<void> _checkLocationPermission() async {
//     LocationPermission permission;
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showLocationServiceDisabledDialog(context);
//       return;
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showLocationPermissionDeniedDialog(context);
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showLocationPermissionDeniedForeverDialog(
//           context); // Show the new dialog here
//       return;
//     }
//     _initializeAfterPermission();
//   }

//   StreamSubscription? _activeUsersSubscription;

//   @override
//   void dispose() {
//     _activeUsersSubscription?.cancel();
//     super.dispose();
//   }

//   void loadActiveUsers() async {
//     setState(() {
//       _isLoading = true;
//     });

//     _activeUsersSubscription?.cancel();

//     // Get the current value immediately
//     try {
//       final currentUsers = await LocationHandler().returnActiveUsers().first;
//       if (mounted) {
//         setState(() {
//           activeUsersModel = currentUsers;
//           _isLoading = false;
//         });
//         _handleActiveUserNotifications(currentUsers);
//       }
//     } catch (e) {
//       print("Error getting initial active users: $e");
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }

//     // Continue listening for updates
//     _activeUsersSubscription = LocationHandler().returnActiveUsers().listen(
//       (activeUsersModel) {
//         if (mounted) {
//           setState(() {
//             this.activeUsersModel = activeUsersModel;
//             _isLoading = false;
//           });
//           _handleActiveUserNotifications(activeUsersModel);
//         }
//       },
//       onError: (error) {
//         print("Error loading active users: $error");
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       },
//     );
//   }

//   void initData() {
//     String isToggleActive =
//         sharedPreferencesHelper.getStrValue("isActiveToggleStr");
//     if (isToggleActive == '1') {
//       _toggleMap(true);
//     } else {
//       _toggleMap(false);
//     }
//   }

//   void _toggleMap(bool value) async {
//     final locationService = LocationBackgroundService();

//     if (value) {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         _showLocationServiceDisabledDialog(context);
//         return;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         await _checkLocationPermission();
//         return;
//       }

//       await locationService.startService();
//       _startLiveLocation();
//       await PersistentNotificationService.show();

//       // Check active users immediately after toggle on
//       loadActiveUsers();
//     } else {
//       await locationService.stopService();
//       await PersistentNotificationService.cancel();
//     }

//     setState(() => _isMapActive = value);
//     await SharedPreferencesHelper.instance
//         .saveStrValue("isActiveToggleStr", value ? '1' : '0');

//     if (!value) {
//       final status = await SharedPreferencesHelper.instance.getLocationStatus();
//       if (status == 1) {
//         updateActiveInactiveStatus(false);
//         await SharedPreferencesHelper.instance.saveLocationStatus(0);
//         if (mounted) setState(() => locStatus = 0);
//       }
//     }
//   }

//   void _startBackgroundService() async {
//     final service = FlutterBackgroundService();
//     var isRunning = await service.isRunning();
//     if (!isRunning) {
//       await service.configure(
//         iosConfiguration: IosConfiguration(),
//         androidConfiguration: AndroidConfiguration(
//           onStart: onStart,
//           autoStart: true,
//           isForegroundMode: true,
//         ),
//       );
//       await service.startService();
//     }

//     // Send current status to background service
//     service.invoke('updateStatus', {
//       'status': locStatus,
//       'isMapActive': _isMapActive,
//     });
//   }

//   void _validateLocationStatus() async {
//     if (!_isMapActive) return;

//     try {
//       Position position = await getCurrentLocation();
//       await _checkAndUpdateActiveCount(position);
//     } catch (e) {
//       print("Error validating location status: $e");
//       if (mounted) {
//         setState(() {
//           locStatus = 0; // Set to unknown if validation fails
//         });
//       }
//     }
//   }

//   void _stopBackgroundService() async {
//     final service = FlutterBackgroundService();
//     var isRunning = await service.isRunning();
//     if (isRunning) {
//       service.invoke("stopService");
//     }
//   }

//   void updateActiveInactiveStatus(bool isActive) async {
//     final userDocRef =
//         FirebaseFirestore.instance.collection("active_users").doc("totalusers");
//     final docSnapshot = await userDocRef.get();
//     if (docSnapshot.exists) {
//       Map<String, dynamic>? data = docSnapshot.data();
//       int count = data!['active'] ?? 0;
//       await userDocRef.update({'active': isActive ? ++count : --count});
//     }
//   }

//   void _startLiveLocation() async {
//     try {
//       Position position = await getCurrentLocation();
//       String? userId = FirebaseAuth.instance.currentUser?.uid;

//       setState(() {
//         _currentLocation = LatLng(position.latitude, position.longitude);
//         _isLoading = false;
//       });

//       if (userId != null) {
//         await _checkAndUpdateActiveCount(position);
//       }

//       if (_mapController != null) {
//         _mapController!.animateCamera(
//           CameraUpdate.newLatLng(_currentLocation!),
//         );
//       }
//     } catch (e) {
//       print("Error getting live location: $e");
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _checkAndUpdateActiveCount(Position currentPosition) async {
//     try {
//       const double proximityThreshold = 500; // meters
//       final activeUsers = await LocationHandler().returnActiveUsers().first;

//       bool isWithinLocation1 = activeUsers.location1Latlng != null &&
//           _isWithinProximity(currentPosition, activeUsers.location1Latlng!,
//               proximityThreshold);

//       bool isWithinLocation2 = activeUsers.location2Latlng != null &&
//           _isWithinProximity(currentPosition, activeUsers.location2Latlng!,
//               proximityThreshold);

//       final bool isWithinAnyLocation = isWithinLocation1 || isWithinLocation2;
//       final int currentStatus =
//           await sharedPreferencesHelper.getLocationStatus();
//       final GeoPoint? lastLocation =
//           await sharedPreferencesHelper.getLastLocation();

//       GeoPoint? currentLocation;
//       if (isWithinLocation1) currentLocation = activeUsers.location1Latlng;
//       if (isWithinLocation2) currentLocation = activeUsers.location2Latlng;

//       bool sameLocation = lastLocation != null &&
//           currentLocation != null &&
//           lastLocation.latitude == currentLocation.latitude &&
//           lastLocation.longitude == currentLocation.longitude;

//       if (isWithinAnyLocation) {
//         if (currentStatus != 1 || !sameLocation) {
//           await _handleLocationStatusChange(
//             newStatus: 1,
//             isActive: true,
//             location: currentLocation!,
//             notificationTitle: "Location Update",
//             notificationBody: "You've entered the location radius",
//           );
//         }
//       } else {
//         if (currentStatus != 0) {
//           await _handleLocationStatusChange(
//             newStatus: 0,
//             isActive: false,
//             location: GeoPoint(0, 0),
//             notificationTitle: "Location Update",
//             notificationBody: "You've left the location radius",
//           );
//         }
//       }

//       if (mounted) {
//         setState(() {
//           activeUsersModel = activeUsers;
//           _isLoading = false;
//         });
//       }

//       _handleActiveUserNotifications(activeUsers);
//     } catch (e) {
//       print("Error in checkAndUpdateActiveCount: $e");
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _handleLocationStatusChange({
//     required int newStatus,
//     required bool isActive,
//     required GeoPoint location,
//     required String notificationTitle,
//     required String notificationBody,
//   }) async {
//     updateActiveInactiveStatus(isActive);
//     await sharedPreferencesHelper.saveLocationStatus(newStatus);
//     await sharedPreferencesHelper.saveLastLocation(location);

//     if (mounted) {
//       setState(() {
//         locStatus = newStatus;
//       });
//     }

//     notificationController.showNotificaiton(
//       title: notificationTitle,
//       body: notificationBody,
//     );
//   }

//   bool _isDialogShowing = false;

//   void _showThresholdDialog(ActiveUsersModel activeUsers) {
//     if (_isDialogShowing) return;

//     _isDialogShowing = true;
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Text("User Limit Reached"),
//         content: Text(
//           "Total active users (${activeUsers.totalActiveUsers}) have reached "
//           "or exceeded the threshold of ${activeUsers.maxUsersNotification}",
//           style: TextStyle(color: Colors.black), // Add this line
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               _isDialogShowing = false;
//               Navigator.pop(context);
//             },
//             child: Text("OK"),
//           ),
//         ],
//       ),
//     );
//   }

//   void _handleActiveUserNotifications(ActiveUsersModel activeUsers) async {
//     if (activeUsers.totalActiveUsers >= activeUsers.maxUsersNotification) {
//       // Always show notification
//       await notificationController.showNotificaiton(
//         title: "User Limit Reached",
//         body:
//             "Active users (${activeUsers.totalActiveUsers}) have reached the threshold (${activeUsers.maxUsersNotification})",
//       );

//       // Only show dialog if the app is in foreground
//       if (mounted &&
//           ModalRoute.of(context)?.isCurrent == true &&
//           !_isDialogShowing) {
//         _showThresholdDialog(activeUsers);
//       }
//     } else {
//       _isDialogShowing = false;
//     }
//   }

//   bool _isWithinProximity(
//       Position currentPosition, GeoPoint location, double threshold) {
//     double distance = Geolocator.distanceBetween(
//       currentPosition.latitude,
//       currentPosition.longitude,
//       location.latitude,
//       location.longitude,
//     );
//     return distance <= threshold;
//   }

//   Future<Position> getCurrentLocation() async {
//     return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           backgroundColor: Colors.teal,
//           title: DefaultLabel(
//             text: 'Drivers Coordination',
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//           actions: [
//             IconButton(
//               icon: Icon(Icons.logout, color: Colors.white),
//               onPressed: () => _showLogoutDialog(context),
//             ),
//           ],
//         ),
//         body: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//             child: Column(
//               children: [
//                 // ❌ Removed Expanded here
//                 Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         DefaultLabel(
//                           text: "Active",
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         Transform.scale(
//                           scale: .8,
//                           child: Switch(
//                             value: _isMapActive,
//                             onChanged: (value) async {
//                               _toggleMap(value);
//                               if (value) {
//                                 final success =
//                                     await PersistentNotificationService.show();
//                                 if (!success && mounted) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     SnackBar(
//                                         content: Text(
//                                             'Failed to show notification')),
//                                   );
//                                 }
//                               } else {
//                                 await PersistentNotificationService.cancel();
//                               }
//                             },
//                             activeColor: Colors.teal,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               height: 70,
//                               padding: EdgeInsets.all(10),
//                               decoration: BoxDecoration(
//                                 color: Color.fromARGB(255, 123, 192, 250),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Row(
//                                 children: [
//                                   Icon(Icons.person,
//                                       color: Colors.white, size: 30),
//                                   SizedBox(width: 10),
//                                   Expanded(
//                                     child: Column(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         DefaultLabel(
//                                           text: "Active Users",
//                                           fontSize: 14,
//                                           color: Colors.white,
//                                         ),
//                                         SizedBox(height: 2),
//                                         DefaultLabel(
//                                           text:
//                                               '${activeUsersModel.totalActiveUsers}',
//                                           fontSize: 16,
//                                           color: Colors.white,
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 10),
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: loadActiveUsers,
//                               child: Container(
//                                 height: 70,
//                                 padding: EdgeInsets.all(10),
//                                 decoration: BoxDecoration(
//                                   color: Color.fromARGB(255, 171, 246, 186),
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Center(
//                                   child: _isLoading
//                                       ? Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           children: [
//                                             SizedBox(
//                                               height: 16,
//                                               width: 16,
//                                               child: CircularProgressIndicator(
//                                                 color: Colors.black,
//                                                 strokeWidth: 2,
//                                               ),
//                                             ),
//                                             SizedBox(width: 8),
//                                             DefaultLabel(
//                                               text: "Updating...",
//                                               fontSize: 14,
//                                               fontWeight: FontWeight.bold,
//                                               color: Colors.black,
//                                             ),
//                                           ],
//                                         )
//                                       : Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           children: [
//                                             Icon(Icons.refresh,
//                                                 color: Colors.black, size: 26),
//                                             SizedBox(width: 8),
//                                             Column(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment.center,
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 DefaultLabel(
//                                                   text: "Login Update",
//                                                   fontSize: 14,
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.black,
//                                                 ),
//                                                 DefaultLabel(
//                                                   text: "1 min ago",
//                                                   fontSize: 14,
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.black,
//                                                 ),
//                                               ],
//                                             ),
//                                           ],
//                                         ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 6),
//                       Center(
//                         child: DefaultLabel(
//                           text: _getLocationStatusText(),
//                           fontSize: 12,
//                           color: _getLocationStatusColor(),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 10),

//                 // ❌ Removed Expanded here — wrap with Container instead
//                 Container(
//                     height: 596,
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(15),
//                       child: _isMapActive
//                           ? GoogleMap(
//                               initialCameraPosition: CameraPosition(
//                                 target: _currentLocation ??
//                                     LatLng(37.7749, -122.4194),
//                                 zoom: 20.0,
//                               ),
//                               onMapCreated: (GoogleMapController controller) {
//                                 _mapController = controller;
//                                 if (_currentLocation != null) {
//                                   _mapController?.animateCamera(
//                                     CameraUpdate.newLatLngZoom(
//                                         _currentLocation!, 20.0),
//                                   );
//                                 }
//                               },
//                               markers: markers.union({
//                                 Marker(
//                                   markerId: MarkerId("My Location"),
//                                   icon: currentLocationIcon,
//                                   position: _currentLocation ??
//                                       LatLng(37.7749, -122.4194),
//                                 ),
//                               }),
//                               myLocationEnabled: true,
//                               zoomControlsEnabled: false,
//                             )
//                           : Center(
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.map, size: 50, color: Colors.grey),
//                                   SizedBox(height: 10),
//                                   DefaultLabel(
//                                     text: "Tap the switch to enable the map",
//                                     color: Colors.grey,
//                                     fontSize: 16,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                     )),
//               ],
//             ),
//           ),
//         ));
//   }

//   String _getLocationStatusText() {
//     if (!_isMapActive) {
//       return "Location tracking is disabled";
//     }

//     switch (locStatus) {
//       case 1:
//         return "You are within the location radius";
//       case 2:
//         return "You are outside the location radius";
//       case 0:
//       default:
//         if (_currentLocation == null) {
//           return "Acquiring location...";
//         } else {
//           return "Location acquired - determining status...";
//         }
//     }
//   }

//   Color _getLocationStatusColor() {
//     if (!_isMapActive) return Colors.orange;

//     switch (locStatus) {
//       case 1:
//         return const Color.fromARGB(255, 0, 150, 95);
//       case 2:
//         return Colors.red;
//       case 0:
//       default:
//         return _currentLocation == null ? Colors.blue : Colors.blueAccent;
//     }
//   }

//   void setCustomMarkerIcon() {
//     BitmapDescriptor.fromAssetImage(
//       ImageConfiguration(size: Size(48, 48)), // Adjust size here
//       "assets/marker_loc.png",
//     ).then((icon) {
//       if (mounted) {
//         setState(() {
//           currentLocationIcon = icon;
//         });
//       }
//     });
//   }

//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           title: DefaultLabel(
//             text: 'Logout',
//             color: Colors.black,
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//           content: DefaultLabel(text: 'Are you sure you want to log out?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: DefaultLabel(text: 'Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _authController.signOut(context);
//               },
//               child: DefaultLabel(
//                 text: 'Logout',
//                 color: Colors.red,
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showLocationPermissionDeniedForeverDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           title: DefaultLabel(
//             text: 'Location Permission Denied Forever',
//             fontWeight: FontWeight.bold,
//           ),
//           content: DefaultLabel(
//             text:
//                 'Location permission is required to use this feature. Please enable it in app settings.',
//             color: Colors.black,
//           ),
//           actions: [
//             TextButton(
//               child: DefaultLabel(
//                 text: 'Cancel',
//                 color: Colors.grey,
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: DefaultLabel(
//                 text: 'Open Settings',
//                 color: Colors.black,
//               ),
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 await openAppSettings(); // uses permission_handler package
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showLocationServiceDisabledDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: DefaultLabel(text: 'Location Services Disabled'),
//           content: DefaultLabel(
//               text: 'Please enable location services to use this feature.'),
//           actions: [
//             TextButton(
//               child: DefaultLabel(text: 'Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: DefaultLabel(text: 'Enable Location'),
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 // Open device location settings
//                 if (Platform.isAndroid) {
//                   await Geolocator.openLocationSettings();
//                 } else if (Platform.isIOS) {
//                   await openAppSettings(); //permission_handler package
//                 }
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _showLocationPermissionDeniedDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: DefaultLabel(text: 'Location Permission Denied'),
//           content: DefaultLabel(
//               text:
//                   'Location permission is required to use this feature. Please enable it.'),
//           actions: [
//             TextButton(
//               child: DefaultLabel(text: 'Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: DefaultLabel(text: 'Request Permission'),
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 await _checkLocationPermission(); // Re-request permission
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
// }






