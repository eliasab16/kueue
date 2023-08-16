import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:kueue/screens/screens.dart';

class SplashScreen extends StatefulWidget {
  static Route get route => MaterialPageRoute(
        builder: (context) => const SplashScreen(),
      );
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final StreamSubscription<firebase.User?> listener;

  @override
  void initState() {
    super.initState();
    _handleAuthenticatedState();
  }

  Future<void> _handleAuthenticatedState() async {
    final auth = firebase.FirebaseAuth.instance;
    if (!mounted) {
      return;
    }

    listener = auth.authStateChanges().listen((user) async {
      if (user != null) {
        if (!mounted) return;
        // authenticated
        Navigator.of(context).pushReplacement(HomeScreen.route);
      } else {
        if (!mounted) return;
        // not authenticated
        Navigator.of(context).pushReplacement(SignInScreen.route);
      }
    });
  }

  @override
  void dispose() {
    listener.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
