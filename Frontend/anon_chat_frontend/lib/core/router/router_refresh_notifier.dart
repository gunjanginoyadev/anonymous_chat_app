import 'package:flutter/foundation.dart';

/// Notifier used by [GoRouter]'s [RefreshListenable]. When auth or chat state
/// changes, providers notify this so the router re-runs redirects.
final class RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
