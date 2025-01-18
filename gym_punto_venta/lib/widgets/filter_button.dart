import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  final String text;
  final bool isActive;
  final VoidCallback onPressed;
  bool mode;

   FilterButton({
    Key? key,
    required this.mode,
    required this.text,
    required this.isActive,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.blue : mode ? Colors.grey[800]:Colors.white,
        foregroundColor: isActive ? Colors.white : Colors.blue,
      ),
      child: Text(text),
    );
  }
}

