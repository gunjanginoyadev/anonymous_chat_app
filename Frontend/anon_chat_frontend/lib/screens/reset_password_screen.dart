import 'package:anon_chat_frontend/core/extensions/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;

  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _tokenFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _tokenCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _tokenVerified = false;
  bool _passwordChanged = false;

  @override
  void initState() {
    super.initState();
    if (widget.token != null && widget.token!.isNotEmpty) {
      _tokenCtrl.text = widget.token!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _verifyToken());
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyToken() async {
    if (_tokenCtrl.text.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyResetToken(_tokenCtrl.text.trim());
    if (success && mounted) {
      setState(() => _tokenVerified = true);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(
      _tokenCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (success && mounted) {
      setState(() => _passwordChanged = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 40),
                if (_passwordChanged)
                  _buildSuccessCard(auth)
                else if (_tokenVerified)
                  _buildPasswordForm(auth.forgotLoading)
                else
                  _buildTokenForm(auth.forgotLoading),
                const SizedBox(height: 28),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final String title;
    final String subtitle;

    if (_passwordChanged) {
      title = 'All done!';
      subtitle = 'Your password has been reset successfully.';
    } else if (_tokenVerified) {
      title = 'New password';
      subtitle = 'Choose a strong password for your account.';
    } else {
      title = 'Reset password';
      subtitle = 'Paste the token from the email we sent you.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.setOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: AppColors.primaryGradient,
              ).createShader(bounds),
              child: const Text(
                'Anon Chat',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTokenForm(bool isLoading) {
    return Form(
      key: _tokenFormKey,
      child: Column(
        children: [
          AuthTextField(
            label: 'RESET TOKEN',
            hint: 'Paste your token here',
            controller: _tokenCtrl,
            prefixIcon: Icons.vpn_key_outlined,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Token is required';
              return null;
            },
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Verify Token',
            onTap: _verifyToken,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm(bool isLoading) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        children: [
          AuthTextField(
            label: 'NEW PASSWORD',
            hint: 'At least 6 characters',
            controller: _passwordCtrl,
            obscure: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) {
                return 'Password must be at least 6 characters long';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          AuthTextField(
            label: 'CONFIRM PASSWORD',
            hint: 'Repeat your password',
            controller: _confirmCtrl,
            obscure: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordCtrl.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Change Password',
            onTap: _changePassword,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(AuthProvider auth) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.setOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.setOpacity(0.2),
                      AppColors.secondary.setOpacity(0.2),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Password changed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                auth.forgotSuccessMessage ??
                    'You can now sign in with your new password.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Back to Sign In',
          onTap: () {
            auth.clearForgotState();
            context.go(AppRoutes.login);
          },
        ),
      ],
    );
  }

  Widget _buildFooter() {
    if (_passwordChanged) return const SizedBox.shrink();

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Didn't get the email? ",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: () {
              context.read<AuthProvider>().clearForgotState();
              context.go(AppRoutes.forgotPassword);
            },
            child: const Text(
              'Try again',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
