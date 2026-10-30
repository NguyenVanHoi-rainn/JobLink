import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'core/navigation/app_navigator.dart';
import 'core/network/api_client.dart';
import 'features/auth/login_screen.dart';
import 'features/employer/employer_home_screen.dart';
import 'features/worker/worker_home_screen.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  ApiClient.initialize();

  await PushNotificationService.instance
      .initialize();

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
      navigatorKey:
      appNavigatorKey,
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

        WidgetsBinding.instance
            .addPostFrameCallback(
              (_) {
            PushNotificationService
                .instance
                .handlePendingNavigation();
          },
        );

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
      !await _authService
          .hasToken()) {
        return null;
      }

      final user =
      await _authService.getMe();

      await PushNotificationService
          .instance
          .syncToken();

      return user;
    } catch (_) {
      await _authService.logout();
      return null;
    }
  }
}
