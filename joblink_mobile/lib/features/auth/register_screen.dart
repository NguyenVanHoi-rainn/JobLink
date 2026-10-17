import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class RegisterScreen
    extends StatefulWidget {
  const RegisterScreen({
    super.key,
  });

  @override
  State<RegisterScreen>
  createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final _emailController =
  TextEditingController();

  final _passwordController =
  TextEditingController();

  String _role = 'WORKER';

  bool _loading = false;

  final _authService =
  AuthService();

  Future<void> _register() async {
    if (
    _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage(
        'Vui lòng nhập đầy đủ thông tin',
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _authService.register(
        email:
        _emailController.text,
        password:
        _passwordController.text,
        role:
        _role,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Đăng ký thành công. Hãy đăng nhập.',
          ),
        ),
      );

      Navigator.pop(context);
    } on DioException catch (e) {
      final message =
      e.response?.data is Map
          ? e.response?.data['message']
          ?.toString()
          : null;

      _showMessage(
        message ??
            'Đăng ký thất bại',
      );
    } catch (_) {
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
          'Đăng ký',
        ),
      ),
      body: SingleChildScrollView(
        padding:
        const EdgeInsets.all(
          24,
        ),
        child: Column(
          children: [
            TextField(
              controller:
              _emailController,
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
              obscureText: true,
              decoration:
              const InputDecoration(
                labelText:
                'Mật khẩu',
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            DropdownButtonFormField<String>(
              initialValue:
              _role,
              decoration:
              const InputDecoration(
                labelText:
                'Loại tài khoản',
                border:
                OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value:
                  'WORKER',
                  child: Text(
                    'Người tìm việc',
                  ),
                ),
                DropdownMenuItem(
                  value:
                  'EMPLOYER',
                  child: Text(
                    'Nhà tuyển dụng',
                  ),
                ),
              ],
              onChanged: (
                  value,
                  ) {
                if (
                value !=
                    null) {
                  setState(() {
                    _role =
                        value;
                  });
                }
              },
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
                    : _register,
                child:
                _loading
                    ? const CircularProgressIndicator()
                    : const Text(
                  'Đăng ký',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}