import 'package:flutter/material.dart';
import 'auth_screen.dart';

void main() {
  runApp(const CrimeDetectionApp());
}

class CrimeDetectionApp extends StatelessWidget {
  const CrimeDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crime Swiper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}