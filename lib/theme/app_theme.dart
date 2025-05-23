import 'package:driver_app/theme/font_size.dart';
import 'package:flutter/material.dart';

import '../helper/colors.dart';

class AppTheme {
  static ThemeData theme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: ColorSys.kPrimary,
    scaffoldBackgroundColor: ColorSys.kBackgroundColor,
    fontFamily: 'Lato',
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.0),
        borderSide: BorderSide(
          color: Colors.grey.shade400, // Default grey border color
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5.0),
        borderSide: BorderSide(
          color: Colors.grey.shade400, // Grey color when enabled
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(
          color: Colors.grey.shade400, // Darker grey when focused
          width: 1, // Slightly thicker when focused
        ),
      ),
      // Add other InputDecoration configurations here
    ),
    textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: ColorSys.kTextColor,
          fontFamily: 'Lato',
        ),
        bodyMedium: TextStyle(
          fontSize: 16.0,
          color: Colors.white,
          // color: ColorSys
          //     .kSecondary, // Set the default text color to ensure readability against the background.
          fontFamily: 'Lato', // Apply the chosen font family to the body text.
        ),
        bodySmall: TextStyle(
          fontSize: 12.0,
          color: ColorSys
              .kTextColor, // Set the default text color to ensure readability against the background.
          fontFamily: 'Lato', // Apply the chosen font family to the body text.
        )
        // You can define additional text styles for different text elements in your app, such as headings, buttons, etc.
        ),
  );

  static const TextStyle bodySmallBlack = TextStyle(
    fontSize: 12.0,
    color: Colors.black,
    fontFamily: 'Lato',
  );

  // Primary Small text style

  static const TextStyle bodySmallPrimary = TextStyle(
    fontSize: 12.0,
    color: Color.fromRGBO(0x33, 0x8C, 0x90, 1.0),
    fontFamily: 'Lato',
  );

  static const TextStyle bodySmallPrimaryBold = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.bold,
    color: Color.fromRGBO(0x33, 0x8C, 0x90, 1.0),
    fontFamily: 'Lato',
  );

  // Secondary Small Text style

  static const TextStyle bodySmallSecondary = TextStyle(
    fontSize: 12.0,
    color: Color.fromRGBO(0, 0, 0, 0.6),
    fontFamily: 'Lato',
  );

  static const TextStyle bodySmallSecondaryBold = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.bold,
    color: Color.fromRGBO(0, 0, 0, 0.6),
    fontFamily: 'Lato',
  );

  // Primary Mediuam text style

  static const TextStyle bodyMediumPrimary = TextStyle(
    fontSize: 16.0,
    color: Color.fromRGBO(36, 36, 36, 1),
    fontFamily: 'Lato',
  );

  static const TextStyle bodyMediumPrimaryBold = TextStyle(
    fontSize: MAIN_TAB_FONT_SIZE,
    fontWeight: FontWeight.bold,
    color: Color.fromRGBO(0x33, 0x8C, 0x90, 1.0),
    fontFamily: 'Lato',
  );

  static const TextStyle bodyMediumPrimaryBold_1 = TextStyle(
    fontSize: LABEL_FONT_SIZE_14,
    fontWeight: FontWeight.bold,
    color: Color.fromRGBO(0x33, 0x8C, 0x90, 1.0),
    fontFamily: 'Lato',
  );

  // Secondary Medium Text style

  static const TextStyle bodyMediumSecondary = TextStyle(
    fontSize: 16.0,
    color: Color.fromRGBO(0, 0, 0, 0.6),
    fontFamily: 'Lato',
  );

  static const TextStyle bodyMediumSecondaryBold = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    color: Color.fromRGBO(0, 0, 0, 0.6),
    fontFamily: 'Lato',
  );

  // Grey Small Text style

  static const TextStyle bodySmallGrey = TextStyle(
    fontSize: 12.0,
    color: Colors.grey,
    fontFamily: 'Lato',
  );

  static const TextStyle bodySmallGreyBold = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.bold,
    color: Colors.grey,
    fontFamily: 'Lato',
  );

  // Grey Medium Text style

  static const TextStyle bodyMediumGrey = TextStyle(
    fontSize: 12.0,
    color: Colors.grey,
    fontFamily: 'Lato',
  );

  static const TextStyle bodyMediumGreyBold = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    color: Colors.grey,
    fontFamily: 'Lato',
  );

  static const TextStyle bodyMediumWhiteBold = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    fontFamily: 'Lato',
  );

  static Color getLighterColor(Color color) {
    // Adjust the color components to make it lighter
    int r = (color.red + 50).clamp(0, 255);
    int g = (color.green + 50).clamp(0, 255);
    int b = (color.blue + 50).clamp(0, 255);

    return Color.fromRGBO(r, g, b, 1.0); // Return the lighter color
  }
  // End Default Text Style font
}
