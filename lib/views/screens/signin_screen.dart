import 'package:driver_app/views/widgets/label/default_label.dart';
import 'package:flutter/material.dart';
import '../../controller/auth_controller.dart';

class SigninScreen extends StatefulWidget {
  @override
  _SigninScreenState createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final AuthController _authController = AuthController();
  bool isGoogleLoading = false;

  void _handleGoogleLogin() async {
    setState(() => isGoogleLoading = true);
    await _authController.signInWithGoogle(context);
    if (mounted) {
      setState(() => isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/uber.png', // Path to your image
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Positioned(
                      left: 5,
                      bottom: 10,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                        color: Colors.black
                            .withOpacity(0.7), // Semi-transparent background
                        child: DefaultLabel(
                          text: "Drivers Community",
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
                padding: EdgeInsets.only(left: 15, right: 15, top: 10),
                child: _buildGoogleLoginButton()),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: Column(
  //       children: [
  //         SizedBox(
  //           child: Image.asset(
  //             'assets/main_screen_img.jpeg',
  //             fit: BoxFit.cover,
  //             width: double.infinity,
  //           ),
  //         ),
  //         Expanded(
  //           child: Center(
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Padding(
  //                   padding: const EdgeInsets.symmetric(horizontal: 20),
  //                   child: _buildGoogleLoginButton(),
  //                 ),
  //                 const SizedBox(height: 20),
  //                 _buildTermsAndConditionsText(),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildGoogleLoginButton() {
    return ElevatedButton(
      onPressed: isGoogleLoading ? null : _handleGoogleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        side: const BorderSide(color: Colors.teal),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(200, 45),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/google.png'),
            ),
          ),
          const Align(
            alignment: Alignment.center,
            child: Text(
              'Login with Google',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
          ),
          if (isGoogleLoading)
            const Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.teal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditionsText() {
    return const Text(
      'By continuing, you agree to our Terms & Conditions',
      style: TextStyle(fontSize: 12, color: Colors.grey),
    );
  }
}

// import 'package:flutter/material.dart';
// import '../../controller/auth_controller.dart';

// class SigninScreen extends StatefulWidget {
//   @override
//   _SigninScreenState createState() => _SigninScreenState();
// }

// class _SigninScreenState extends State<SigninScreen> {
//   final AuthController _authController = AuthController();
//   bool isGoogleLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkIfUserLoggedIn();
//   }

//   void _checkIfUserLoggedIn() {
//     _authController.isUserLoggedIn().then((isLoggedIn) {
//       if (isLoggedIn) {
//         _authController.getUserEmail().then((userEmail) {
//           Future.microtask(() {
//             Navigator.pushReplacementNamed(context, '/updateProfile',
//                 arguments: userEmail);
//           });
//         });
//       }
//     });
//   }

//   void _handleGoogleLogin() async {
//     if (mounted) {
//       setState(() => isGoogleLoading = true);
//     }

//     await _authController.signInWithGoogle(context);

//     if (mounted) {
//       setState(() => isGoogleLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final double screenHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//       body: Column(
//         children: [
//           SizedBox(
//             height: screenHeight * 0.75,
//             child: Image.asset(
//               'assets/new_banner.png',
//               fit: BoxFit.cover,
//               width: double.infinity,
//             ),
//           ),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   const Text(
//                     'Terms and Conditions',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: isGoogleLoading ? null : _handleGoogleLogin,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.orange,
//                       side: const BorderSide(color: Colors.orange),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 10, vertical: 10),
//                     ),
//                     child: isGoogleLoading
//                         ? _buildGoogleLoadingIndicator()
//                         : _buildGoogleLoginContent(),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGoogleLoadingIndicator() {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: const [
//         CircularProgressIndicator(color: Colors.orange),
//         SizedBox(width: 10),
//         Text('Logging in with Google...', style: TextStyle(fontSize: 16)),
//       ],
//     );
//   }

//   Widget _buildGoogleLoginContent() {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: const [
//         CircleAvatar(
//           radius: 20,
//           backgroundImage: AssetImage('assets/google.png'),
//         ),
//         SizedBox(width: 10),
//         Text('Login with Google', style: TextStyle(fontSize: 18)),
//       ],
//     );
//   }
// }
