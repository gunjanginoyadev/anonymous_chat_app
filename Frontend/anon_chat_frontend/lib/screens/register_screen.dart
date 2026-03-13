import 'package:anon_chat_frontend/core/extensions/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    await auth.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.loading;

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
                _buildForm(auth, isLoading),
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
                Icons.chat_bubble_outline_rounded,
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
        const Text(
          'Create account',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Join and start meeting strangers',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildForm(AuthProvider auth, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (auth.errorMessage != null) ...[
            AuthErrorBanner(message: auth.errorMessage!),
            const SizedBox(height: 20),
          ],
          AuthTextField(
            label: 'YOUR NAME',
            hint: 'How should we call you?',
            controller: _nameCtrl,
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Name is required';
              if (v.trim().length < 2)
                return 'Name must be at least 2 characters long';
              if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v.trim())) {
                return 'Please enter a valid name (alphabets only)';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          AuthTextField(
            label: 'EMAIL',
            hint: 'you@example.com',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(v)) {
                return 'Please enter a valid email address (e.g., name@domain.com)';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          AuthTextField(
            label: 'PASSWORD',
            hint: 'At least 6 characters',
            controller: _passwordCtrl,
            obscure: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6)
                return 'Password must be at least 6 characters long';
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
                return 'Passwords do not match. Please try again.';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Create Account',
            onTap: _submit,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Already have an account? ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: () => context.go(AppRoutes.login),
            child: const Text(
              'Sign in',
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
