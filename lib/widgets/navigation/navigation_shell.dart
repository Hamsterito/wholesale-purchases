import 'package:flutter/material.dart';
import 'package:flutter_project/services/notification_service.dart';
import 'package:flutter_project/services/storage/auth_storage.dart';
import 'package:flutter_project/widgets/messages/top_message.dart';

import 'nav_role.dart';
import 'role_nav_config.dart';
import 'role_navigation_bar.dart';
import 'package:flutter_project/services/moderation_alert_service.dart';
import 'package:flutter_project/widgets/messages/moderation_alert_banner.dart';
import 'package:flutter_project/profile/support_chat_page.dart';

/// Корневой контейнер навигации. Читает роль один раз при монтировании,
/// строит набор вкладок и хостит их страницы в IndexedStack.
///
/// Роль не меняется без нового входа (а вход пушит свежий shell), поэтому
/// перечитывать её на каждый build не нужно.
class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell>
    with WidgetsBindingObserver {
  late NavRole _role;
  List<RoleNavTab> _tabs = [];
  bool _tabsInitialized = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _role = resolveNavRole(AuthStorage.role);
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    
    if (_role == NavRole.supplier) {
      ModerationAlertService().checkNewAlerts();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    // Переключение вкладок IndexedStack идёт через setState, без push/pop
    // на корневом Navigator. NavigatorObserver такие смены не видит,
    // поэтому закрываем активный top-message вручную.
    dismissTopMessage();
    setState(() => _currentIndex = index);
  }

  /// Управляем polling при переходе приложения в фон и обратно
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        NotificationService().pausePolling();
      case AppLifecycleState.resumed:
        NotificationService().resumePolling();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Инициализируем вкладки с контекстом для локализации
    if (!_tabsInitialized) {
      _tabs = tabsForRole(_role, context);
      _tabsInitialized = true;
      // Зажимаем initialIndex в границы набора вкладок
      if (_currentIndex < 0 || _currentIndex >= _tabs.length) {
        _currentIndex = 0;
      }
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                for (final tab in _tabs) tab.pageBuilder(context),
              ],
            ),
          ),
          if (_role == NavRole.supplier)
            ListenableBuilder(
              listenable: ModerationAlertService(),
              builder: (context, _) {
                final service = ModerationAlertService();
                return ModerationAlertBanner(
                  alerts: service.pendingAlerts
                      .map((msg) => ModerationAlertService.parseMessageText(msg.text))
                      .toList(),
                  onDismiss: () => service.dismissAllAlerts(),
                  onContactSupport: () {
                    service.dismissAllAlerts();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UserSupportChatPage(),
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: RoleNavigationBar(
        tabs: _tabs,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
