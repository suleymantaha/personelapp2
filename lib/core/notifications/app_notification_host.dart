import 'package:flutter/material.dart';

import 'app_notification.dart';
import 'app_notification_card.dart';

class AppNotificationHost extends StatefulWidget {
  const AppNotificationHost({
    super.key,
    required this.child,
    this.controller,
  });

  final Widget child;
  final AppNotificationController? controller;

  @override
  State<AppNotificationHost> createState() => _AppNotificationHostState();
}

class _AppNotificationHostState extends State<AppNotificationHost> {
  late AppNotificationController _activeController;

  @override
  void initState() {
    super.initState();
    _activeController = widget.controller ?? AppNotifications.controller;
    _activeController.attach();
  }

  @override
  void didUpdateWidget(covariant AppNotificationHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextController = widget.controller ?? AppNotifications.controller;
    if (identical(nextController, _activeController)) return;
    _activeController.detach();
    _activeController = nextController;
    _activeController.attach();
  }

  @override
  void dispose() {
    _activeController.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const Key('app-notification-host'),
      children: [
        widget.child,
        Positioned.fill(
          child: SafeArea(
            child: ListenableBuilder(
              listenable: _activeController,
              builder: (context, _) {
                final notification = _activeController.current;
                final reduceMotion = MediaQuery.disableAnimationsOf(context);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final alignment = constraints.maxWidth >= 840
                        ? Alignment.topRight
                        : Alignment.topCenter;
                    return IgnorePointer(
                      ignoring: notification == null,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Align(
                          alignment: alignment,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: AnimatedSwitcher(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : const Duration(milliseconds: 220),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, -0.12),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                              child: notification == null
                                  ? const SizedBox.shrink()
                                  : AppNotificationCard(
                                      key: ValueKey(notification.id),
                                      notification: notification,
                                      onDismiss: _activeController.dismiss,
                                      onAction: _activeController.performAction,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
