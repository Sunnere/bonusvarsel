import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../pages/login_page.dart';

/// Wrapper som viser login-siden hvis bruker ikke er innlogget
class AuthGate extends StatelessWidget {
  final Widget child;
  final bool required;

  const AuthGate({
    super.key,
    required this.child,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!required) return child;

    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          return const LoginPage();
        }
        return child;
      },
    );
  }
}
