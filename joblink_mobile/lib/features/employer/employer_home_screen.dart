import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class EmployerHomeScreen
    extends StatelessWidget {
  const EmployerHomeScreen({
    super.key,
  });

  Future<void> _logout(
      BuildContext context,
      ) async {
    await AuthService().logout();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
        const LoginScreen(),
      ),
          (_) => false,
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JobLink Employer',
        ),
        actions: [
          IconButton(
            onPressed: () =>
                _logout(context),
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Đăng nhập Employer thành công',
        ),
      ),
    );
  }
}