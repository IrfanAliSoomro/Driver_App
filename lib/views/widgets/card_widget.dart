import 'package:flutter/material.dart';

import 'label/default_label.dart';

class CardWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final String icon;
  final Color color;
  final VoidCallback onClick;

  const CardWidget(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.color,
      this.status = '',
      required this.onClick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onClick,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified, color: Colors.black),
                  SizedBox(height: 10),
                  DefaultLabel(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                    text: title,
                  ),
                ],
              ),

              // Image.asset(
              //   "assets/images/$icon", // Path to your car top view image
              //   width: 50, // Adjust the width as needed
              //   height: 50,
              // ),

              SizedBox(height: 8),
              Column(
                children: [
                  DefaultLabel(
                    //overflow: TextOverflow.ellipsis,
                    text: subtitle,
                  ),
                ],
              ),
              // SizedBox(
              //   height: 10,
              // ),
              // Column(
              //   children: [
              //     DefaultLabel(
              //       fontWeight: FontWeight.bold,
              //       color: Colors.green,
              //       //overflow: TextOverflow.ellipsis,
              //       text: status,
              //     ),
              //   ],
              // )
            ],
          ),
        ));
  }
}
