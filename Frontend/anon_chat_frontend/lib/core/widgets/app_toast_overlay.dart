import 'dart:async';

import 'package:flutter/material.dart';
import '../router/app_router.dart';

enum AppToastType { info, success, error }

final class AppToastOverlay {
  static OverlayEntry? _activeEntry;

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (message.trim().isEmpty) return;

    _activeEntry?.remove();
    _activeEntry = null;

    final overlay =
        appNavigatorKey.currentState?.overlay ??
        Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastViewport(
        message: message,
        type: type,
        duration: duration,
        onDismissed: () {
          if (_activeEntry == entry) {
            _activeEntry?.remove();
            _activeEntry = null;
          }
        },
      ),
    );
    _activeEntry = entry;
    overlay.insert(entry);
  }
}

class _ToastViewport extends StatefulWidget {
  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDismissed;

  const _ToastViewport({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_ToastViewport> createState() => _ToastViewportState();
}

class _ToastViewportState extends State<_ToastViewport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _lifecycleTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0.1, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _runToastLifecycle();
  }

  Future<void> _runToastLifecycle() async {
    await _controller.forward();
    _lifecycleTimer = Timer(widget.duration, () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _lifecycleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: _ToastCard(message: widget.message, type: widget.type),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  final String message;
  final AppToastType type;

  const _ToastCard({required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = _colorSet(type);
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(theme.icon, color: theme.foreground, size: 18),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: theme.foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _ToastColors _colorSet(AppToastType type) {
    switch (type) {
      case AppToastType.success:
        return const _ToastColors(
          background: Color(0xFF0E2E23),
          border: Color(0xFF1F8A62),
          foreground: Color(0xFF79F0BE),
          icon: Icons.check_circle_outline_rounded,
        );
      case AppToastType.error:
        return const _ToastColors(
          background: Color(0xFF32171A),
          border: Color(0xFFB7434E),
          foreground: Color(0xFFFFA8AF),
          icon: Icons.error_outline_rounded,
        );
      case AppToastType.info:
        return const _ToastColors(
          background: Color(0xFF151F36),
          border: Color(0xFF4568B7),
          foreground: Color(0xFFA7C5FF),
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _ToastColors {
  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;

  const _ToastColors({
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });
}
