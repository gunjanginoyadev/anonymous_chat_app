import 'package:anon_chat_frontend/core/extensions/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? token;

  const VerifyEmailScreen({super.key, this.token});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _showResend = false;
  final _resendEmailCtrl = TextEditingController();
  final _resendFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.token != null && widget.token!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AuthProvider>().verifyEmail(widget.token!);
      });
    }
  }

  @override
  void dispose() {
    _resendEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    if (!_resendFormKey.currentState!.validate()) return;
    await context
        .read<AuthProvider>()
        .resendVerificationEmail(_resendEmailCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hasToken = widget.token != null && widget.token!.isNotEmpty;

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
                if (!hasToken)
                  _buildNoTokenCard()
                else if (auth.verifyEmailLoading)
                  _buildLoadingCard()
                else if (auth.verifyEmailSuccess == true)
                  _buildSuccessCard(auth)
                else if (auth.verifyEmailSuccess == false)
                  _buildErrorCard(auth)
                else
                  _buildLoadingCard(),
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
                Icons.verified_outlined,
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
          'Email Verification',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Confirming your email address',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
              backgroundColor: AppColors.primary.setOpacity(0.15),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Verifying your email...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please wait while we confirm your email address.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
                'Email verified!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                auth.verifyEmailMessage ??
                    'Your email has been verified. You can now sign in.',
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
          label: 'Go to Sign In',
          onTap: () {
            auth.clearVerifyEmailState();
            context.go(AppRoutes.login);
          },
        ),
      ],
    );
  }

  Widget _buildErrorCard(AuthProvider auth) {
    final message = auth.verifyEmailMessage ?? 'Verification failed.';
    final isExpired = message.toLowerCase().contains('expired');

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.errorBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.setOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.setOpacity(0.15),
                ),
                child: Icon(
                  isExpired
                      ? Icons.timer_off_outlined
                      : Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isExpired ? 'Link expired' : 'Verification failed',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
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
        if (_showResend)
          _buildResendForm(auth)
        else ...[
          GradientButton(
            label: 'Resend Verification Email',
            onTap: () => setState(() => _showResend = true),
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () {
                auth.clearVerifyEmailState();
                context.go(AppRoutes.login);
              },
              child: const Text(
                'Back to Sign In',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResendForm(AuthProvider auth) {
    final sent = auth.resendMessage != null;

    if (sent) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.setOpacity(0.3)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.mark_email_read_rounded,
              color: AppColors.secondary,
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              auth.resendMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            GradientButton(
              label: 'Back to Sign In',
              onTap: () {
                auth.clearVerifyEmailState();
                auth.clearResendState();
                context.go(AppRoutes.login);
              },
            ),
          ],
        ),
      );
    }

    return Form(
      key: _resendFormKey,
      child: Column(
        children: [
          AuthTextField(
            label: 'EMAIL',
            hint: 'you@example.com',
            controller: _resendEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: 'Send New Link',
            onTap: _resend,
            isLoading: auth.resendLoading,
          ),
          const SizedBox(height: 12),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _showResend = false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTokenCard() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.errorBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.setOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.setOpacity(0.15),
                ),
                child: const Icon(
                  Icons.link_off_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Invalid link',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'No verification token was found. Please use the link from the email we sent you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GradientButton(
          label: 'Back to Sign In',
          onTap: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Need a new account? ",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          GestureDetector(
            onTap: () {
              context.read<AuthProvider>().clearVerifyEmailState();
              context.go(AppRoutes.register);
            },
            child: const Text(
              'Register',
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
