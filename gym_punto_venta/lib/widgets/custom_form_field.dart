import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool darkMode;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  final bool autofocus;

  const CustomFormField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.darkMode,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.hintText,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(color: darkMode ? Colors.white70 : Colors.black54),
      hintStyle: TextStyle(color: darkMode ? Colors.white38 : Colors.black38),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: darkMode ? Colors.white54 : Colors.black38),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: darkMode ? Colors.blueAccent : Colors.blue),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: darkMode ? Colors.redAccent : Colors.red),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: darkMode ? Colors.redAccent : Colors.red, width: 2.0),
      ),
    );
    final textStyle = TextStyle(color: darkMode ? Colors.white : Colors.black);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: inputDecoration,
        style: textStyle,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        autofocus: autofocus,
      ),
    );
  }
}
