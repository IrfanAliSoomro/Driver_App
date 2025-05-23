// import 'package:flutter/material.dart';

// class SocialButton extends StatelessWidget {
//   const SocialButton({
//     super.key,
//     required this.name,
//     required this.icon,
//     required this.onPressed,
//     this.isLoading = false,
//     this.isLogo = false,
//   });
//   final VoidCallback? onPressed;
//   final String name;
//   final IconData icon;
//   final bool isLogo;
//   final bool isLoading;

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       onPressed: isLoading ? null : onPressed,
//       style: ElevatedButton.styleFrom(
//         shape: RoundedRectangleBorder(
//           borderRadius:
//               BorderRadius.circular(8.0), // Adjust the border radius as needed
//           side: BorderSide(
//             width: .8, // Set border width
//             color: Colors.teal, // Set border color
//           ),
//         ),
//         backgroundColor: Colors.white,
//         padding: EdgeInsets.all(MediaQuery.of(context).size.width / 30),
//       ),
//       child: Row(
//         children: [
//           Align(
//             alignment: Alignment.centerLeft,
//             child: SizedBox(
//               height: 30.0,
//               width: 30.0,
//               child: isLogo
//                   ? Image.asset(
//                       'assets/images/gmail.png', // Path to your car top view image
//                     )
//                   : SizedBox(),
//             ),
//           ),
//           const SizedBox(
//             width: 16.0,
//           ),
//           Expanded(
//             flex: 1,
//             child: Container(
//               //width: 230,
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Align(
//                       alignment: Alignment.center,
//                       child: DefaultLabel(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                         color: Colors.black,
//                         text: name,
//                       ),
//                     ),
//                   ),
//                   if (isLoading)
//                     SizedBox(
//                       height: 24,
//                       width: 24,
//                       child: CircularProgressIndicator(
//                         color: Colors.black,
//                         strokeWidth: 2.0,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
