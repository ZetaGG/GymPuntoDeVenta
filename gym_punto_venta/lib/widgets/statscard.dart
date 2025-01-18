import 'package:flutter/material.dart';
import 'package:gym_punto_venta/Screens/PrincipalScreen.dart';


class StatCard extends StatelessWidget {
  final String title;
  final String value;
  bool mode;



   StatCard({Key? key, required this.mode,required this.title, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: mode ? Colors.grey[800]:Colors.white ,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

