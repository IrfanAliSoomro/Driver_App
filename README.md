import 'dart:async';
import 'dart:io';
import 'package:driver_app/utils/shared_pref.dart';
import 'package:driver_app/views/widgets/label/default_label.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../controller/auth_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire2/geoflutterfire2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../controller/location_handler.dart';
import '../../helper/colors.dart';
import '../widgets/card_widget.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final geo = GeoFlutterFire();
  SharedPreferencesHelper sharedPreferencesHelper =
      SharedPreferencesHelper.instance;
  final AuthController _authController = AuthController();
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  bool _isMapActive = false;
  ActiveUsersModel activeUsersModel = ActiveUsersModel(totalActiveUsers: 0);
  bool _isLoading = false;

  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  final Set<Marker> markers = {};
  int locStatus = 0; // 0 : out of range, 1 : Enter , 2 :  Out
  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _initializeAfterPermission() async {
    loadActiveUsers();
    initData();
    setCustomMarkerIcon();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission;
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceDisabledDialog(context);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationPermissionDeniedDialog(context);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationPermissionDeniedForeverDialog(
          context); // Show the new dialog here
      return;
    }
    _initializeAfterPermission();
  }

  StreamSubscription? _activeUsersSubscription;

  @override
  void dispose() {
    _activeUsersSubscription?.cancel();
    super.dispose();
  }

  void loadActiveUsers() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    LocationHandler().returnActiveUsers().listen((activeUsersModel) {
      setState(() {
        activeUsersModel = activeUsersModel;
        _isLoading = false; // Stop loading
      });
    });
  }

  void initData() {
    String isToggleActive =
        sharedPreferencesHelper.getStrValue("isActiveToggleStr");
    if (isToggleActive == '1') {
      _toggleMap(true);
    } else {
      _toggleMap(false);
    }
  }

  void _toggleMap(bool value) async {
    setState(() => _isMapActive = value);
    //updateActiveInactiveStatus(value);
    if (_isMapActive) {
      locStatus = 0;
      await sharedPreferencesHelper.saveStrValue("isActiveToggleStr", '1');
      _startLiveLocation(); // Start tracking immediately
      Timer.periodic(Duration(seconds: 10), (timer) {
        _startLiveLocation();
      });
    } else {
      await sharedPreferencesHelper.saveStrValue("isActiveToggleStr", '0');
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDocRef =
            FirebaseFirestore.instance.collection("location").doc(userId);
        final docSnapshot = await userDocRef.get();
        if (docSnapshot.exists) {
          await userDocRef.update({'isActive': false});
        }
      }
    }
  }

  void updateActiveInactiveStatus(bool isActive) async {
    final userDocRef =
        FirebaseFirestore.instance.collection("active_users").doc("totalusers");
    final docSnapshot = await userDocRef.get();
    if (docSnapshot.exists) {
      Map<String, dynamic>? data = docSnapshot.data();
      int count = data!['active'] ?? 0;
      await userDocRef.update({'active': isActive ? ++count : --count});
    }
  }

  void _startLiveLocation() async {
    Position position = await getCurrentLocation();
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      _checkAndUpdateActiveCount(position);
    }

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _isLoading = false;
    });

    // Check if near location1 or location2 and update active count

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_currentLocation!),
      );
    }
  }

  Future<void> _checkAndUpdateActiveCount(Position currentPosition) async {
    const double proximityThreshold = 500; // meters

    bool isInside = false;

    if (activeUsersModel.location1Latlng != null) {
      double distanceToLocation1 = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        activeUsersModel.location1Latlng!.latitude,
        activeUsersModel.location1Latlng!.longitude,
      );

      if (distanceToLocation1 <= proximityThreshold) {
        isInside = true;
      } else {
        isInside = false;
      }
    }

    if (activeUsersModel.location2Latlng != null) {
      double distanceToLocation2 = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        activeUsersModel.location2Latlng!.latitude,
        activeUsersModel.location2Latlng!.longitude,
      );

      if (distanceToLocation2 <= proximityThreshold) {
        isInside = true;
      } else {
        isInside = false;
      }
    }

    if (isInside && locStatus != 1) {
      updateActiveInactiveStatus(true); // Increment active count
      locStatus = 1;
    } else if (!isInside && locStatus == 1) {
      updateActiveInactiveStatus(false); // Decrement active count
      locStatus = 2;
    }

    setState(() {
      activeUsersModel = activeUsers;
      _isLoading = false;
    });
  }

  // Future<void> _checkAndUpdateActiveCount(Position currentPosition) async {
  //   const double proximityThreshold = 5000; // meters

  //   // Fetch the latest active users data
  //   ActiveUsersModel activeUsers = await LocationHandler()
  //       .returnActiveUsers()
  //       .first; // Get the first emitted value from the stream

  //   //

  //   if (activeUsers.location1Latlng != null) {
  //     double distanceToLocation1 = Geolocator.distanceBetween(
  //       currentPosition.latitude,
  //       currentPosition.longitude,
  //       activeUsers.location1Latlng!.latitude,
  //       activeUsers.location1Latlng!.longitude,
  //     );

  //     if (distanceToLocation1 <= proximityThreshold && locStatus != 1) {
  //       updateActiveInactiveStatus(true); // Increment active count
  //       locStatus = 1;
  //       return; // Exit to prevent double counting if also near location2
  //     } else if (locStatus == 1) {
  //       locStatus = 2;
  //     }
  //   }

  //   if (activeUsers.location2Latlng != null) {
  //     double distanceToLocation2 = Geolocator.distanceBetween(
  //       currentPosition.latitude,
  //       currentPosition.longitude,
  //       activeUsers.location2Latlng!.latitude,
  //       activeUsers.location2Latlng!.longitude,
  //     );

  //     if (distanceToLocation2 <= proximityThreshold && locStatus != 1) {
  //       updateActiveInactiveStatus(true); // Increment active count
  //     } else if (locStatus == 1) {
  //       locStatus = 2;
  //     }
  //   }
  //   if (locStatus == 2) {
  //     updateActiveInactiveStatus(false); // Decreament active count
  //   }

  //   setState(() {
  //     activeUsersModel = activeUsers;
  //     _isLoading = false; // Stop loading
  //   });
  // }

  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: DefaultLabel(
          text: 'Drivers Coordination',
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          children: [
            Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DefaultLabel(
                          text: "Active",
                          fontSize: 16,
                        ),
                        Transform.scale(
                          scale: .8,
                          child: Switch(
                            value: _isMapActive,
                            onChanged: _toggleMap,
                            activeColor: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                )),
            Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 123, 192, 250),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person,
                                    color: Colors.white, size: 30),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      DefaultLabel(
                                        text: "Active Users",
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 4),
                                      Center(
                                        child: DefaultLabel(
                                          text:
                                              '${activeUsersModel.totalActiveUsers}',
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: loadActiveUsers,
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 171, 246, 186),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SizedBox(
                              height: 50,
                              width: double.infinity, // 🛠️ Add this line!
                              child: Center(
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.refresh,
                                              color: Colors.black, size: 30),
                                          SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              DefaultLabel(
                                                text: "Login Update",
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                              DefaultLabel(
                                                text: "10 min ago",
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Vote for Logout",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ),
                          SizedBox(width: 50),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () {},
                                  borderRadius: BorderRadius.circular(20),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.red,
                                    radius: 15,
                                    child: Icon(Icons.close,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                                SizedBox(width: 30),
                                InkWell(
                                  onTap: () {},
                                  borderRadius: BorderRadius.circular(20),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.green,
                                    radius: 15,
                                    child: Icon(Icons.check,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                                SizedBox(width: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Expanded(
                flex: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _isMapActive
                      ? GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target:
                                _currentLocation ?? LatLng(37.7749, -122.4194),
                            zoom: 20.0,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                            if (_currentLocation != null) {
                              _mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                      _currentLocation!, 20.0));
                            }
                          },
                          markers: markers.union({
                            Marker(
                              markerId: MarkerId("My Location"),
                              icon: currentLocationIcon,
                              position: _currentLocation ??
                                  LatLng(37.7749, -122.4194),
                            ),
                          }),
                          myLocationEnabled: true,
                          zoomControlsEnabled: false,
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map, size: 50, color: Colors.grey),
                              SizedBox(height: 10),
                              Text("Tap the switch to enable the map",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        ),
                )),
          ],
        ),
      ),
    );
  }

  void setCustomMarkerIcon() {
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)), // Adjust size here
      "assets/marker_loc.png",
    ).then((icon) {
      if (mounted) {
        setState(() {
          currentLocationIcon = icon;
        });
      }
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _authController.signOut(context);
              },
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showLocationPermissionDeniedForeverDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Denied Forever'),
          content: Text(
              'Location permission is required to use this feature. Please enable it in app settings.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings(); // uses permission_handler package
              },
            ),
          ],
        );
      },
    );
  }

  void _showLocationServiceDisabledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Services Disabled'),
          content: Text('Please enable location services to use this feature.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Enable Location'),
              onPressed: () async {
                Navigator.of(context).pop();
                // Open device location settings
                if (Platform.isAndroid) {
                  await Geolocator.openLocationSettings();
                } else if (Platform.isIOS) {
                  await openAppSettings(); //permission_handler package
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showLocationPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Denied'),
          content: Text(
              'Location permission is required to use this feature. Please enable it.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Request Permission'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _checkLocationPermission(); // Re-request permission
              },
            ),
          ],
        );
      },
    );
  }
}
