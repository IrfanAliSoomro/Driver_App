import 'package:flutter/material.dart';

class ColorSys {
  static Color kPrimary =
      Color(0xFF338C90); // const Color.fromRGBO(0x67, 0x8F, 0xF8, 1.0);
  static Color kBackgroundColor = const Color.fromARGB(255, 255, 255, 255);
  static Color kSecondary = const Color.fromRGBO(32, 34, 42, 100);
  static Color kkSecondary2 =
      Color(0xFFeac04a); // const Color.fromRGBO(0x67, 0x8F, 0xF8, 1.0);

  static Color kTextColor = const Color.fromARGB(255, 255, 255, 255);
  static Color themeTextfield = const Color.fromRGBO(32, 34, 42, 1);

  // Border Color
  static Color kBorderColor = Colors.grey;
  static Color kWhiteColor = const Color.fromARGB(255, 255, 255, 255);

  static Color kInactiveGray = Colors.grey;
  static Color klightGray = const Color.fromARGB(255, 192, 192, 192);

  static Color lighten(Color color, [double amount = 0.3]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }
}
