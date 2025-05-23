import 'package:driver_app/controller/shared_prefs_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signInWithGoogle11() async {
    try {
      await _googleSignIn.signOut();
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();

      if (googleSignInAccount != null) {
        // Obtain authentication credentials from the GoogleSignInAccount
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        // Authenticate with Firebase using the Google authentication credentials
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        // Sign in to Firebase with the Google credentials
        final UserCredential userCredential =
            await _firebaseAuth.signInWithCredential(credential);

        // Access the signed-in user's information
        final User? user = userCredential.user;
        if (user != null) {}
      } else {
        print("error");
      }
    } catch (error) {
      print('$error');
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      // Ensure sign-out before signing in (optional)
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _showSnackBar(context, "Google Sign-In was canceled.");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final String userEmail = userCredential.user!.email ?? "No Email";
        await PrefsController().saveLoginStatus(true, userEmail);

        final bool isUserRegistered = await _isUserRegistered(
          userCredential.user!.uid,
        );

        // Navigate to the appropriate screen
        if (context.mounted) {
          Navigator.pushReplacementNamed(
            context,
            isUserRegistered ? '/mainScreen' : '/home',
          );
        }
      } else {
        _showSnackBar(context, "Google Sign-In failed. User data is null.");
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(context, "Authentication failed: ${e.message}");
    } catch (e) {
      _showSnackBar(context, "Google Sign-In failed: ${e.toString()}");
      print(e.toString());
    }
  }

  Future<void> signInWithGoogle1(BuildContext context) async {
    try {
      // await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _showSnackBar(context, "Google Sign-In was canceled");
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user != null) {
        final String userEmail = userCredential.user!.email!;
        await PrefsController().saveLoginStatus(true, userEmail);
        final bool isUserRegistered = await _isUserRegistered(
          userCredential.user!.uid,
        );
        Navigator.pushReplacementNamed(
          context,
          isUserRegistered ? '/mainScreen' : '/home',
        );
      } else {
        _showSnackBar(context, "Google Sign-In failed. User data is null.");
      }
    } catch (e) {
      _showSnackBar(context, "Google Sign-In failed: ${e.toString()}");
    }
  }

  Future<void> updateUserLocation() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user == null) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _firestore.collection('users').doc(user.email).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await PrefsController().logout();
      // _showSnackBar(context, "Successfully signed out.");
      Navigator.pushReplacementNamed(context, '/signin');
    } catch (e) {
      _showSnackBar(context, "Sign-out failed: ${e.toString()}");
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _isUserRegistered(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }
}
