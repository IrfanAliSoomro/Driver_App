import 'package:driver_app/helper/colors.dart';
import 'package:driver_app/views/widgets/label/default_label.dart';
import 'package:flutter/material.dart';

class DefaultButton extends StatelessWidget {
  DefaultButton({
    Key? key,
    required this.name,
    this.icon, // New parameter for icon
    this.onPressed,
    this.isPrimary = true,
    this.height = 50,
    this.color,
    this.isLoading = false,
  }) : super(key: key);

  final Color? color;
  final String name;
  final IconData? icon; // Icon parameter
  final double height;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final Color buttonColor =
        isPrimary ? ColorSys.kPrimary : (color ?? Colors.black26);

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isPrimary && !isLoading || color != null ? onPressed : null,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
          minimumSize: const Size.fromHeight(40),
          padding: EdgeInsets.zero,
          backgroundColor: buttonColor,
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.0,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) // Conditionally add icon if provided
                    Icon(icon, color: Colors.white), // Icon widget
                  SizedBox(width: 5), // Adjust spacing between icon and text
                  DefaultLabel(
                    text: name,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
      ),
    );
  }
}
