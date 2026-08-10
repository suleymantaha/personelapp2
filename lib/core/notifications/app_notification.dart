import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

enum AppNotificationType { success, error, warning, info }

@immutable
class AppNotificationData {
  const AppNotificationData({
    required this.id,
    required this.message,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.onAction,
    this.deduplicationKey,
  });

  final int id;
  final String message;
  final AppNotificationType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Object? deduplicationKey;

  String get fingerprint => '$type|$message|${actionLabel ?? ''}';

  bool get isActionable => actionLabel != null || onAction != null;

  bool isEquivalentTo(AppNotificationData other) {
    if (deduplicationKey != null || other.deduplicationKey != null) {
      return deduplicationKey != null &&
          deduplicationKey == other.deduplicationKey;
    }
    if (isActionable || other.isActionable) return false;
    return fingerprint == other.fingerprint;
  }
}

class AppNotificationController extends ChangeNotifier {
  final ListQueue<AppNotificationData> _queue = ListQueue();
  AppNotificationData? _current;
  Timer? _timer;
  int _nextId = 0;
  int _attachmentCount = 0;
  bool _isPerformingAction = false;

  AppNotificationData? get current => _current;

  void show({
    required String message,
    required AppNotificationType type,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    Object? deduplicationKey,
  }) {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) return;
    final notification = AppNotificationData(
      id: _nextId++,
      message: normalizedMessage,
      type: type,
      duration: duration ?? _defaultDuration(type),
      actionLabel: actionLabel,
      onAction: onAction,
      deduplicationKey: deduplicationKey,
    );
    final isDuplicate = _current?.isEquivalentTo(notification) == true ||
        _queue.any((item) => item.isEquivalentTo(notification));
    if (isDuplicate) return;
    if (_current == null) {
      _activate(notification);
    } else {
      _queue.addLast(notification);
    }
  }

  void attach() {
    _attachmentCount++;
    if (_attachmentCount == 1 && _current != null) {
      _startTimer();
    }
  }

  void detach() {
    if (_attachmentCount == 0) return;
    _attachmentCount--;
    if (_attachmentCount == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void dismiss() {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty) {
      _current = null;
      notifyListeners();
      return;
    }
    _activate(_queue.removeFirst());
  }

  void performAction() {
    if (_isPerformingAction) return;
    final active = _current;
    if (active == null) return;
    _isPerformingAction = true;
    try {
      dismiss();
      active.onAction?.call();
    } finally {
      scheduleMicrotask(() {
        _isPerformingAction = false;
      });
    }
  }

  void _activate(AppNotificationData notification) {
    _current = notification;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = null;
    if (_attachmentCount > 0 && _current != null) {
      _timer = Timer(_current!.duration, dismiss);
    }
  }

  Duration _defaultDuration(AppNotificationType type) => switch (type) {
        AppNotificationType.success ||
        AppNotificationType.info =>
          const Duration(seconds: 4),
        AppNotificationType.warning => const Duration(seconds: 6),
        AppNotificationType.error => const Duration(seconds: 8),
      };

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _queue.clear();
    _current = null;
    _attachmentCount = 0;
    super.dispose();
  }
}

class AppNotifications {
  AppNotifications._();

  static final AppNotificationController controller =
      AppNotificationController();

  static void success(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    Object? deduplicationKey,
  }) =>
      controller.show(
        message: message,
        type: AppNotificationType.success,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        deduplicationKey: deduplicationKey,
      );

  static void error(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    Object? deduplicationKey,
  }) =>
      controller.show(
        message: message,
        type: AppNotificationType.error,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        deduplicationKey: deduplicationKey,
      );

  static void warning(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    Object? deduplicationKey,
  }) =>
      controller.show(
        message: message,
        type: AppNotificationType.warning,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        deduplicationKey: deduplicationKey,
      );

  static void info(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    Object? deduplicationKey,
  }) =>
      controller.show(
        message: message,
        type: AppNotificationType.info,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        deduplicationKey: deduplicationKey,
      );

  static void approvalResult(
    String message, {
    required bool pendingApproval,
    Duration? duration,
  }) {
    if (pendingApproval) {
      warning(message, duration: duration);
    } else {
      success(message, duration: duration);
    }
  }
}
