import 'package:flutter/material.dart';

Widget homeServiceCard(VoidCallback onTap, MaterialColor iconColor,
    IconData icon, String title, String subtitle) {
  return GestureDetector(
    onTap: onTap,
    child: Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      elevation: 5,
      shadowColor: Colors.grey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: iconColor[800],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 7,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Icon(
              Icons.keyboard_double_arrow_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    ),
  );
}
