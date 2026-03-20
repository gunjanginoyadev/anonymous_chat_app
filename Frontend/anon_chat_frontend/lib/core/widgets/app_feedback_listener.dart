import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'app_toast_overlay.dart';

class AppFeedbackListener extends StatefulWidget {
  final Widget child;

  const AppFeedbackListener({super.key, required this.child});

  @override
  State<AppFeedbackListener> createState() => _AppFeedbackListenerState();
}

class _AppFeedbackListenerState extends State<AppFeedbackListener> {
  String? _lastAuthError;
  String? _lastChatError;

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, auth, chat, _) {
        _emitAuthErrorIfNeeded(context, auth);
        _emitChatErrorIfNeeded(context, chat);
        return widget.child;
      },
    );
  }

  void _emitAuthErrorIfNeeded(BuildContext context, AuthProvider auth) {
    final message = auth.errorMessage;
    if (message == null || message == _lastAuthError) return;

    _lastAuthError = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppToastOverlay.show(
        context,
        message: message,
        type: AppToastType.error,
      );
      auth.clearError();
    });
  }

  void _emitChatErrorIfNeeded(BuildContext context, ChatProvider chat) {
    final message = chat.errorMessage;
    if (message == null || message == _lastChatError) return;

    _lastChatError = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppToastOverlay.show(
        context,
        message: message,
        type: AppToastType.error,
      );
      chat.clearError();
    });
  }
}
