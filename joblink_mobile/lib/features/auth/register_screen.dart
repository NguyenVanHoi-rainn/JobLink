import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();

  String _role = 'WORKER';

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = false;

  bool get _hasMinLength =>
      _passwordController.text.length >= 8;

  bool get _hasUppercase =>
      RegExp(r'[A-Z]').hasMatch(_passwordController.text);

  bool get _hasLowercase =>
      RegExp(r'[a-z]').hasMatch(_passwordController.text);

  bool get _hasNumber =>
      RegExp(r'[0-9]').hasMatch(_passwordController.text);

  bool get _hasSpecial =>
      RegExp(r'[^A-Za-z0-9]').hasMatch(_passwordController.text);

  bool get _isStrongPassword =>
      _hasMinLength &&
          _hasUppercase &&
          _hasLowercase &&
          _hasNumber &&
          _hasSpecial;

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeTerms) {
      _showMessage(
        'Bạn cần đồng ý với Điều khoản sử dụng.',
        isError: true,
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await _authService.register(
        email: _emailController.text,
        password: _passwordController.text,
        role: _role,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đăng ký thành công. Hãy đăng nhập.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
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
        message ?? 'Đăng ký thất bại',
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB);
    const backgroundColor = Color(0xFFF5F7FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Tạo tài khoản',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            12,
            24,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bắt đầu với JobLink',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn loại tài khoản phù hợp với nhu cầu của bạn.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 26),

              const Text(
                'Bạn là',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _RoleCard(
                      selected: _role == 'WORKER',
                      icon: Icons.person_search_rounded,
                      title: 'Người tìm việc',
                      subtitle: 'Tìm việc bán thời gian',
                      onTap: () {
                        setState(() {
                          _role = 'WORKER';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleCard(
                      selected: _role == 'EMPLOYER',
                      icon: Icons.business_center_outlined,
                      title: 'Nhà tuyển dụng',
                      subtitle: 'Đăng tuyển nhân sự',
                      onTap: () {
                        setState(() {
                          _role = 'EMPLOYER';
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
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
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration: _inputDecoration(
                          label: 'Mật khẩu',
                          hint: 'Tạo mật khẩu',
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

                          if (!_isStrongPassword) {
                            return 'Mật khẩu chưa đáp ứng yêu cầu';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      _PasswordRequirement(
                        valid: _hasMinLength,
                        text: 'Ít nhất 8 ký tự',
                      ),
                      _PasswordRequirement(
                        valid: _hasUppercase &&
                            _hasLowercase,
                        text: 'Có chữ hoa và chữ thường',
                      ),
                      _PasswordRequirement(
                        valid: _hasNumber,
                        text: 'Có ít nhất 1 chữ số',
                      ),
                      _PasswordRequirement(
                        valid: _hasSpecial,
                        text: 'Có ít nhất 1 ký tự đặc biệt',
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        decoration: _inputDecoration(
                          label: 'Xác nhận mật khẩu',
                          hint: 'Nhập lại mật khẩu',
                          icon: Icons.lock_reset_rounded,
                        ).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng xác nhận mật khẩu';
                          }

                          if (value != _passwordController.text) {
                            return 'Mật khẩu xác nhận không khớp';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      CheckboxListTile(
                        value: _agreeTerms,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity:
                        ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setState(() {
                            _agreeTerms = value ?? false;
                          });
                        },
                        title: const Text.rich(
                          TextSpan(
                            text: 'Tôi đồng ý với ',
                            children: [
                              TextSpan(
                                text: 'Điều khoản sử dụng',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: ' và Chính sách bảo mật.',
                              ),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed:
                          _loading ? null : _register,
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
                              : Text(
                            _role == 'WORKER'
                                ? 'Tạo tài khoản người tìm việc'
                                : 'Tạo tài khoản nhà tuyển dụng',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Đã có tài khoản?',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Đăng nhập',
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? primaryColor
                : Colors.grey.shade300,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color: selected
                  ? primaryColor
                  : Colors.grey.shade600,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected
                    ? primaryColor
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordRequirement extends StatelessWidget {
  const _PasswordRequirement({
    required this.valid,
    required this.text,
  });

  final bool valid;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 5,
      ),
      child: Row(
        children: [
          Icon(
            valid
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: valid
                ? Colors.green
                : Colors.grey.shade400,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: valid
                  ? Colors.green.shade700
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}