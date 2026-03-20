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
      child: _AppRoot(appRouter: appRouter),
    ),
  );
}

class _AppRoot extends StatefulWidget {
  final RouterConfig<Object> appRouter;

  const _AppRoot({required this.appRouter});

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _disconnectFromChat();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // For app close/restart/refresh flows, force socket disconnect so backend
    // removes user from waiting queue/active chat.
    if (state == AppLifecycleState.detached) {
      _disconnectFromChat();
    }
  }

  void _disconnectFromChat() {
    final chat = context.read<ChatProvider>();
    chat.leaveChat();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Anon Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: widget.appRouter,
      builder: (context, child) => AppFeedbackListener(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
