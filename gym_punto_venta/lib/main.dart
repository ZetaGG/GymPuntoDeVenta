import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'Screens/PrincipalScreen.dart';

// Agrega este import para sqflite_common_ffi:
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Inicializa sqflite_common_ffi en plataformas de escritorio
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: GymManagementScreen(),
    );
  }
}