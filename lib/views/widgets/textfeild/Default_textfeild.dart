import 'package:driver_app/helper/colors.dart';
import 'package:driver_app/theme/font_size.dart';
import 'package:flutter/material.dart';

class DefaultTextField extends StatelessWidget {
  const DefaultTextField({
    Key? key,
    required this.hint,
    required this.textEditingController,
    this.onPressed,
    this.fontSize = LABEL_FONT_SIZE,
    this.fontWeight = FontWeight.normal,
    this.isPrimary = true,
    this.enabled = true,
    this.maxChar = 100,
    this.maxLength = 1,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
  }) : super(key: key);

  final TextEditingController textEditingController;
  final double fontSize;
  final TextInputType keyboardType;
  final FontWeight fontWeight;
  final int maxLength;
  final int maxChar;
  final String hint;
  final VoidCallback? onPressed;
  final bool isPrimary; // Flag to determine button color
  final IconData? prefixIcon; // Icon to display on the left side
  final bool enabled; // Flag to control editing

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed, // Call the onPressed callback when tapped
      child: TextField(
        onTapOutside: (event) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        textCapitalization: TextCapitalization.sentences,
        maxLines: maxLength,
        //maxLength: maxChar,
        keyboardType: keyboardType,
        controller: textEditingController,
        enabled: enabled, // Set the enabled property
        style: TextStyle(
          fontSize: fontSize,
          color: isPrimary ? ColorSys.kWhiteColor : Colors.black,
          fontFamily: 'Lato', // Reference custom font family
        ),
        cursorColor: isPrimary ? ColorSys.kWhiteColor : ColorSys.kSecondary,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade500, // Change hint text color
          ),
          filled: true,
          fillColor: Colors
              .white, // isPrimary ? ColorSys.kPrimary : Colors.grey.shade200,

          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.0),
              //  borderSide: BorderSide.none,
              borderSide: BorderSide(
                //color: Colors.red, // Grey color for enabled state
                width: 1,
              )),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: ColorSys.kSecondary,
                )
              : null, // Add prefix icon
        ),
      ),
    );
  }
}
