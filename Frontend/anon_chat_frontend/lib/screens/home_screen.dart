import 'package:anon_chat_frontend/core/extensions/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 48),
                _buildTagline(),
                const SizedBox(height: 64),
                _buildStartButton(context),
              ],
            ),
          ),
          Positioned(top: 20, right: 20, child: _buildUserChip(context, auth)),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.setOpacity(0.4),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
          ).createShader(bounds),
          child: const Text(
            'Anon Chat',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return const Text(
      'Talk to a stranger. Just conversation.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textTertiary,
        height: 1.6,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return _HoverScale(
      onTap: () {
        final token = auth.user?.token ?? '';
        if (token.trim().isNotEmpty) {
          context.read<ChatProvider>().startChat(token);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF3ECFCF)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.setOpacity(0.35),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Start Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserChip(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.borderSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(auth.user?.profilePic ?? ''),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            auth.user?.name ?? '',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => auth.logout(),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverScale({required this.child, required this.onTap});

  @override
  State<_HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<_HoverScale> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          scale: _hovered ? 1.02 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}
