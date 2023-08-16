import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  static Route get route => MaterialPageRoute(
    builder: (context) => const HomeScreen(),
    );
    
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Welcome to Kueue!"),
      ),
    );
  }
}