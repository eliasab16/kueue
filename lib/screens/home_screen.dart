import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:kueue/pages/sessions_page.dart';
import 'package:kueue/screens/screens.dart';
import '../app.dart';

class HomeScreen extends StatelessWidget {
  static Route get route => MaterialPageRoute(
    builder: (context) => const HomeScreen(),
    );
    
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: _SignOutButton(),
          )
        ],
      ),
      body: const Center(
        child: SessionsPage(),
      ),
    );
  }
}

class _SignOutButton extends StatefulWidget {
    const _SignOutButton({
      Key? key,
    }) : super(key: key);

    @override
    __SignOutButtonState createState() => __SignOutButtonState();
  }

  class __SignOutButtonState extends State<_SignOutButton> {
    bool _loading = false;

    Future<void> _signOut() async {
      setState(() {
        _loading = true;
      });

      try {
        final nav = Navigator.of(context);
        await firebase.FirebaseAuth.instance.signOut();

        nav.pushReplacement(SplashScreen.route);
      } on Exception catch (e, st) {
        logger.e('Could not sign out, $e, $st');
        setState(() {
          _loading = false;
        });
      }
    }

    @override
    Widget build(BuildContext context) {
      return _loading
          ? const CircularProgressIndicator()
          : TextButton(
              onPressed: _signOut,
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                foregroundColor: Colors.blue,
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Sign out'),
            );
    }
  }