import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../screens/chat_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/forgot_password_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/register_screen.dart';
import '../../screens/reset_password_screen.dart';
import '../../screens/verify_email_screen.dart';
import '../../screens/waiting_screen.dart';
import 'router_refresh_notifier.dart';

final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

abstract final class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
  static const String waiting = '/waiting';
  static const String chat = '/chat';
}

/// Builds the app [GoRouter] with auth and chat redirect logic.
GoRouter createAppRouter(RouterRefreshNotifier refreshNotifier) {
  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final auth = context.read<AuthProvider>();
      final chat = context.read<ChatProvider>();
      final path = state.uri.path;

      final isAuthRoute = path == AppRoutes.login ||
          path == AppRoutes.register ||
          path == AppRoutes.verifyEmail ||
          path == AppRoutes.forgotPassword ||
          path == AppRoutes.resetPassword;
      final isAppRoute =
          path == AppRoutes.home ||
          path == AppRoutes.waiting ||
          path == AppRoutes.chat;

      if (!auth.isAuthenticated) {
        if (isAppRoute) return AppRoutes.login;
        return null;
      }

      if (isAuthRoute) return AppRoutes.home;

      switch (chat.status) {
        case ChatStatus.waiting:
          if (path == AppRoutes.home) return AppRoutes.waiting;
          break;
        case ChatStatus.chatting:
          if (path == AppRoutes.home || path == AppRoutes.waiting) {
            return AppRoutes.chat;
          }
          break;
        case ChatStatus.idle:
          if (path == AppRoutes.waiting || path == AppRoutes.chat) {
            return AppRoutes.home;
          }
          break;
      }

      if (path == '/' || path.isEmpty) {
        return auth.isAuthenticated ? AppRoutes.home : AppRoutes.login;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        name: 'verifyEmail',
        builder: (_, state) => VerifyEmailScreen(
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        builder: (_, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'],
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.waiting,
        name: 'waiting',
        builder: (_, __) => const WaitingScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (_, __) => const ChatScreen(),
      ),
    ],
  );
}
