import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'features/auth/login_screen.dart';
import 'features/employer/employer_home_screen.dart';
import 'features/worker/worker_home_screen.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding
      .ensureInitialized();

  ApiClient.initialize();

  runApp(
    const JobLinkApp(),
  );
}

class JobLinkApp
    extends StatelessWidget {
  const JobLinkApp({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return MaterialApp(
      title: 'JobLink',
      debugShowCheckedModeBanner:
      false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed:
        Colors.blue,
      ),
      home:
      const AuthGate(),
    );
  }
}

class AuthGate
    extends StatefulWidget {
  const AuthGate({
    super.key,
  });

  @override
  State<AuthGate>
  createState() =>
      _AuthGateState();
}

class _AuthGateState
    extends State<AuthGate> {
  final AuthService _authService =
  AuthService();

  @override
  Widget build(
      BuildContext context,
      ) {
    return FutureBuilder(
      future:
      _checkSession(),
      builder: (
          context,
          snapshot,
          ) {
        if (
        snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child:
              CircularProgressIndicator(),
            ),
          );
        }

        final user =
            snapshot.data;

        if (user == null) {
          return const LoginScreen();
        }

        if (
        user.role ==
            'WORKER') {
          return const WorkerHomeScreen();
        }

        if (
        user.role ==
            'EMPLOYER') {
          return const EmployerHomeScreen();
        }

        return const LoginScreen();
      },
    );
  }

  Future<dynamic>
  _checkSession() async {
    try {
      if (
      !await _authService.hasToken()) {
        return null;
      }

      return await _authService.getMe();
    } catch (_) {
      await _authService.logout();
      return null;
    }
  }
}