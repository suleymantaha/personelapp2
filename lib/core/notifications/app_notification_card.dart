import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_notification.dart';

typedef _NotificationAppearance = ({
  IconData icon,
  Color accent,
  String semanticLabel,
});

class AppNotificationCard extends StatelessWidget {
  const AppNotificationCard({
    super.key,
    required this.notification,
    required this.onDismiss,
    required this.onAction,
  });

  final AppNotificationData notification;
  final VoidCallback onDismiss;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final appearance = _appearanceFor(context, notification.type);
    final colorScheme = Theme.of(context).colorScheme;
    final surface = colorScheme.surfaceContainerHigh;
    final iconColor = _meetsContrast(appearance.accent, surface, 3)
        ? appearance.accent
        : colorScheme.onSurface;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      liveRegion: true,
      label: '${appearance.semanticLabel}: ${notification.message}',
      child: Material(
        key: const Key('app-notification-card'),
        elevation: 12,
        borderRadius: BorderRadius.circular(16),
        color: surface,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: appearance.accent, width: 4),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(appearance.icon, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  notification.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                ),
              ),
              if (notification.actionLabel != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                  ),
                  child: Text(notification.actionLabel!),
                ),
              IconButton(
                tooltip: 'Bildirimi kapat',
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _NotificationAppearance _appearanceFor(
    BuildContext context,
    AppNotificationType type,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return switch (type) {
      AppNotificationType.success => (
          icon: Icons.check_circle_rounded,
          accent: context.approvedColor,
          semanticLabel: 'Başarılı',
        ),
      AppNotificationType.error => (
          icon: Icons.error_rounded,
          accent: scheme.error,
          semanticLabel: 'Hata',
        ),
      AppNotificationType.warning => (
          icon: Icons.warning_amber_rounded,
          accent: context.pendingColor,
          semanticLabel: 'Uyarı',
        ),
      AppNotificationType.info => (
          icon: Icons.info_rounded,
          accent: scheme.primary,
          semanticLabel: 'Bilgi',
        ),
    };
  }

  bool _meetsContrast(Color foreground, Color background, double minimum) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();
    final lighter = foregroundLuminance > backgroundLuminance
        ? foregroundLuminance
        : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance
        ? backgroundLuminance
        : foregroundLuminance;
    return (lighter + 0.05) / (darker + 0.05) >= minimum;
  }
}
