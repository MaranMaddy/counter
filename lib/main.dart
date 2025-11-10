import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'screens/login_screen.dart';

void main() {
  // Initialize sqflite for desktop platforms
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    debugPrint('🔄 MAIN: Initializing sqflite_ffi for desktop platform');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    debugPrint('✅ MAIN: sqflite_ffi initialized successfully');
  } else if (kIsWeb) {
    debugPrint('🌐 MAIN: Running on web platform, using SharedPreferences');
  } else {
    debugPrint('✅ MAIN: Running on mobile platform, using native sqflite');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}