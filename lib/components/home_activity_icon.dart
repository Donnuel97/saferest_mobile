import 'package:flutter/material.dart';

Widget activityCardIcon(int value, MaterialColor color, IconData icon) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: color[100],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Icon(
            icon,
            color: color,
          ),
        ],
      ),
    ),
  );
}
