import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SignUpScreen extends StatelessWidget {
  static Route get route => MaterialPageRoute(
    builder: (context) => const SignUpScreen()
    );

  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Sign up")
        ),
    );
  }
}