import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../employer/employer_home_screen.dart';
import '../worker/worker_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final user = await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      Widget destination;

      if (user.role == 'WORKER') {
        destination = const WorkerHomeScreen();
      } else if (user.role == 'EMPLOYER') {
        destination = const EmployerHomeScreen();
      } else {
        await _authService.logout();

        if (!mounted) return;

        _showMessage(
          'Ứng dụng mobile không dành cho tài khoản Admin',
          isError: true,
        );

        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => destination,
        ),
            (_) => false,
      );
    } on DioException catch (e) {
      final data = e.response?.data;

      String? message;

      if (data is Map) {
        final rawMessage = data['message'];

        if (rawMessage is List) {
          message = rawMessage.join('\n');
        } else {
          message = rawMessage?.toString();
        }
      }

      _showMessage(
        message ?? 'Email hoặc mật khẩu không chính xác',
        isError: true,
      );
    } catch (_) {
      _showMessage(
        'Không thể kết nối đến máy chủ',
        isError: true,
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
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red.shade700 : null,
        ),
      );
  }

  void _googleLogin() {
    _showMessage(
      'Đăng nhập Google sẽ được kết nối ở bước tiếp theo.',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB);
    const backgroundColor = Color(0xFFF5F7FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 28,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.25),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.work_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'JobLink',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kết nối công việc phù hợp với bạn',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Chào mừng bạn quay trở lại JobLink',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.email,
                              ],
                              decoration: _inputDecoration(
                                label: 'Email',
                                hint: 'example@gmail.com',
                                icon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'Vui lòng nhập email';
                                }

                                final validEmail = RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(email);

                                if (!validEmail) {
                                  return 'Email không đúng định dạng';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!_loading) {
                                  _login();
                                }
                              },
                              decoration: _inputDecoration(
                                label: 'Mật khẩu',
                                hint: 'Nhập mật khẩu',
                                icon: Icons.lock_outline_rounded,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword =
                                      !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập mật khẩu';
                                }

                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  _showMessage(
                                    'Chức năng quên mật khẩu sẽ được bổ sung sau.',
                                  );
                                },
                                child: const Text(
                                  'Quên mật khẩu?',
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: FilledButton(
                                onPressed: _loading ? null : _login,
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(14),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child:
                                  CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'hoặc',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                onPressed:
                                _loading ? null : _googleLogin,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'G',
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Tiếp tục với Google',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Chưa có tài khoản?',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Đăng ký ngay',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
    );
  }
}