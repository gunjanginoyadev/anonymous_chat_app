import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/chat_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/waiting_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const RandomChatApp(),
    ),
  );
}

class RandomChatApp extends StatelessWidget {
  const RandomChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anon Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _AppRouter(),
    );
  }
}

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();

    // Not logged in → show auth screens
    if (!auth.isAuthenticated) {
      return _showLogin
          ? LoginScreen(
              onGoToRegister: () => setState(() => _showLogin = false),
            )
          : RegisterScreen(
              onGoToLogin: () => setState(() => _showLogin = true),
            );
    }

    return switch (chat.status) {
      ChatStatus.idle => const HomeScreen(),
      ChatStatus.waiting => const WaitingScreen(),
      ChatStatus.chatting => const ChatScreen(),
    };
  }
}
