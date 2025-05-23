import 'package:geoflutterfire2/geoflutterfire2.dart';

class UserLocation {
  late GeoFirePoint? userLocation;
  late String userId;
}


// void updateLocation(String userId, Position position) async {
//     GeoFirePoint myLocation =
//         geo.point(latitude: position.latitude, longitude: position.longitude);
//     final userDocRef =
//         FirebaseFirestore.instance.collection("location").doc(userId);
//     final docSnapshot = await userDocRef.get();
//     if (docSnapshot.exists) {
//       await userDocRef.update({'position': myLocation.data});
//     } else {
//       await userDocRef.set({'position': myLocation.data});
//     }
//   }

