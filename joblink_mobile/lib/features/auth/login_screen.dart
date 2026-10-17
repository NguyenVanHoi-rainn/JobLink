import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../employer/employer_home_screen.dart';
import '../worker/worker_home_screen.dart';
import 'register_screen.dart';

class LoginScreen
    extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final _emailController =
  TextEditingController();

  final _passwordController =
  TextEditingController();

  final _authService =
  AuthService();

  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (
    _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage(
        'Vui lòng nhập email và mật khẩu',
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final user =
      await _authService.login(
        email:
        _emailController.text,
        password:
        _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Widget destination;

      if (user.role == 'WORKER') {
        destination =
        const WorkerHomeScreen();
      } else if (
      user.role ==
          'EMPLOYER') {
        destination =
        const EmployerHomeScreen();
      } else {
        await _authService.logout();

        _showMessage(
          'Ứng dụng mobile không dành cho Admin',
        );

        return;
      }

      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
          destination,
        ),
            (_) => false,
      );
    } on DioException catch (e) {
      final message =
      e.response?.data is Map
          ? e.response?.data['message']
          ?.toString()
          : null;

      _showMessage(
        message ??
            'Đăng nhập thất bại',
      );
    } catch (e) {
      _showMessage(
        'Không thể kết nối máy chủ',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showMessage(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'JobLink',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(
            24,
          ),
          child: Column(
            children: [
              const SizedBox(
                height: 40,
              ),

              const Text(
                'Đăng nhập',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 32,
              ),

              TextField(
                controller:
                _emailController,
                keyboardType:
                TextInputType
                    .emailAddress,
                decoration:
                const InputDecoration(
                  labelText: 'Email',
                  border:
                  OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              TextField(
                controller:
                _passwordController,
                obscureText:
                _obscurePassword,
                decoration:
                InputDecoration(
                  labelText:
                  'Mật khẩu',
                  border:
                  const OutlineInputBorder(),
                  suffixIcon:
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword =
                        !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons
                          .visibility
                          : Icons
                          .visibility_off,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                width:
                double.infinity,
                height: 50,
                child:
                ElevatedButton(
                  onPressed:
                  _loading
                      ? null
                      : _login,
                  child:
                  _loading
                      ? const CircularProgressIndicator()
                      : const Text(
                    'Đăng nhập',
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const RegisterScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Chưa có tài khoản? Đăng ký',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}