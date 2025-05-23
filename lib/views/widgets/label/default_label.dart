import 'package:flutter/material.dart';

import '../../../utils/size_config.dart';

class DefaultLabel extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final bool isItalic;
  final TextOverflow overflow;
  final Color color;
  final VoidCallback? onTap;
  final int maxLines;

  const DefaultLabel({
    Key? key,
    this.isItalic = false,
    required this.text,
    this.fontSize = 14.0,
    this.overflow = TextOverflow.clip,
    this.color = const Color.fromRGBO(0, 0, 0, 0.6),
    this.fontWeight = FontWeight.normal,
    this.onTap,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Wrap Text with GestureDetector
      onTap: onTap, // Assign onTap callback to GestureDetector
      child: Text(
        text,
        style: _buildTextStyle(),
      ),
    );
  }

  TextStyle _buildTextStyle() {
    return TextStyle(
      color: color,
      fontSize: fontSize * SizeConfig.textMultiplier / 7,
      overflow:
          overflow == TextOverflow.ellipsis ? TextOverflow.ellipsis : null,
      fontWeight: fontWeight,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      fontFamily: 'Lato',
      // Add any other style properties here as needed
    );
  }
}
