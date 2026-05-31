import 'package:flutter/material.dart';

import '../login_screen/login.dart';
import '../services/notification_service.dart';
import '../services/storage/auth_storage.dart';
import '../services/store/templates_store.dart';
import '../widgets/messages/top_message.dart';

Future<void> performLogout(BuildContext context) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  dismissTopMessage();

  navigator.pushAndRemoveUntil(
    _instantRoute(const _LogoutTransitionPage()),
    (_) => false,
  );

  try {
    await NotificationService().clearForLogout();
    await TemplatesStore.instance.clearCache();
  } catch (_) {
    // Logout must always finish even if local cleanup cannot complete.
  }

  try {
    await AuthStorage.forget();
  } catch (_) {
    // The login screen is still safer than leaving stale app screens mounted.
  }

  if (!navigator.mounted) return;
  navigator.pushAndRemoveUntil(
    _instantRoute(const LoginPage()),
    (_) => false,
  );
}

PageRoute<void> _instantRoute(Widget page) {
  return PageRouteBuilder<void>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}

class _LogoutTransitionPage extends StatelessWidget {
  const _LogoutTransitionPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
