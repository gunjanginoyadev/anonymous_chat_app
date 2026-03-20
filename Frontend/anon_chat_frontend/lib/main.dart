import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/router/router_refresh_notifier.dart';
import 'core/widgets/app_feedback_listener.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final routerRefresh = RouterRefreshNotifier();
  final appRouter = createAppRouter(routerRefresh);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(routerRefresh: routerRefresh),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(routerRefresh: routerRefresh),
        ),
      ],
      child: MaterialApp.router(
        title: 'Anon Chat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: appRouter,
        builder: (context, child) => AppFeedbackListener(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
}
