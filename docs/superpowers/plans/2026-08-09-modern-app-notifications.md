# Modern App Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace every bottom `SnackBar` with a responsive, app-wide notification card that appears at the top center on mobile/tablet and top right on wide screens.

**Architecture:** A focused `AppNotificationController` owns one visible notification plus a FIFO queue, while a global `AppNotifications` facade gives feature code semantic success/error/warning/info calls without requiring a widget context. `AppNotificationHost`, installed through `MaterialApp.router.builder`, renders the controller state above the routed application and keeps presentation independent from feature screens.

**Tech Stack:** Flutter Material 3, Dart `ChangeNotifier`, `ListQueue`, `Timer`, Flutter widget/unit tests; no new package dependency.

## Global Constraints

- No user-facing notification may appear from the bottom of the application.
- Mobile and tablet notifications appear top-center; viewports at least 840 logical pixels wide use top-right alignment.
- Support `success`, `error`, `warning`, and `info` with icon plus color; meaning must not rely on color alone.
- Preserve existing action callbacks such as `GERİ AL` and invoke an action at most once.
- Show one notification at a time, queue distinct notifications, and suppress equivalent current/queued duplicates.
- Use the existing light/dark theme and add no third-party dependency.
- Respect safe areas, large text, and `MediaQuery.disableAnimations`.

---

### Task 1: Notification Domain and Queue Controller

**Files:**
- Create: `lib/core/notifications/app_notification.dart`
- Create: `test/core/notifications/app_notification_controller_test.dart`

**Interfaces:**
- Produces: `AppNotificationType`, immutable `AppNotificationData`, `AppNotificationController.show(...)`, `dismiss()`, `performAction()`, `current`, and the global `AppNotifications.success/error/warning/info(...)` facade.
- Consumes: Dart `ListQueue`, `Timer`, and Flutter `VoidCallback`/`ChangeNotifier`.

- [ ] **Step 1: Write failing queue and deduplication tests**

```dart
test('shows one notification and queues the next distinct notification', () {
  final controller = AppNotificationController();
  addTearDown(controller.dispose);

  controller.show(message: 'Birinci', type: AppNotificationType.info);
  controller.show(message: 'İkinci', type: AppNotificationType.success);

  expect(controller.current?.message, 'Birinci');
  controller.dismiss();
  expect(controller.current?.message, 'İkinci');
});

test('suppresses an equivalent current or queued notification', () {
  final controller = AppNotificationController();
  addTearDown(controller.dispose);

  controller.show(message: 'Aynı mesaj', type: AppNotificationType.warning);
  controller.show(message: 'Aynı mesaj', type: AppNotificationType.warning);
  controller.dismiss();

  expect(controller.current, isNull);
});
```

- [ ] **Step 2: Run the controller tests and verify RED**

Run: `flutter test test/core/notifications/app_notification_controller_test.dart`

Expected: FAIL because `app_notification.dart` and its public types do not exist.

- [ ] **Step 3: Implement the minimal model and controller**

```dart
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
  });

  final int id;
  final String message;
  final AppNotificationType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;

  String get fingerprint => '$type|$message|${actionLabel ?? ''}';
}

class AppNotificationController extends ChangeNotifier {
  final ListQueue<AppNotificationData> _queue = ListQueue();
  AppNotificationData? _current;
  Timer? _timer;
  int _nextId = 0;

  AppNotificationData? get current => _current;

  void show({
    required String message,
    required AppNotificationType type,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
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
    );
    final isDuplicate = _current?.fingerprint == notification.fingerprint ||
        _queue.any((item) => item.fingerprint == notification.fingerprint);
    if (isDuplicate) return;
    if (_current == null) {
      _activate(notification);
    } else {
      _queue.addLast(notification);
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
    final active = _current;
    if (active == null) return;
    dismiss();
    active.onAction?.call();
  }

  void _activate(AppNotificationData notification) {
    _current = notification;
    _timer = Timer(notification.duration, dismiss);
    notifyListeners();
  }

  Duration _defaultDuration(AppNotificationType type) => switch (type) {
        AppNotificationType.success || AppNotificationType.info =>
          const Duration(seconds: 4),
        AppNotificationType.warning => const Duration(seconds: 6),
        AppNotificationType.error => const Duration(seconds: 8),
      };

  @override
  void dispose() {
    _timer?.cancel();
    _queue.clear();
    super.dispose();
  }
}

class AppNotifications {
  AppNotifications._();

  static final AppNotificationController controller =
      AppNotificationController();

  static void success(String message,
          {String? actionLabel, VoidCallback? onAction, Duration? duration}) =>
      controller.show(
        message: message,
        type: AppNotificationType.success,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      );

  static void error(String message,
          {String? actionLabel, VoidCallback? onAction, Duration? duration}) =>
      controller.show(
        message: message,
        type: AppNotificationType.error,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      );

  static void warning(String message,
          {String? actionLabel, VoidCallback? onAction, Duration? duration}) =>
      controller.show(
        message: message,
        type: AppNotificationType.warning,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      );

  static void info(String message,
          {String? actionLabel, VoidCallback? onAction, Duration? duration}) =>
      controller.show(
        message: message,
        type: AppNotificationType.info,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      );
}
```

Default durations: success/info 4 seconds, warning 6 seconds, error 8 seconds. Reject blank messages. Cancel timers in `dispose()`.

- [ ] **Step 4: Add action, timer, and error-safety tests**

```dart
testWidgets('action runs once and advances the queue even if tapped twice',
    (tester) async {
  var calls = 0;
  final controller = AppNotificationController();
  addTearDown(controller.dispose);
  controller.show(
    message: 'Silindi',
    type: AppNotificationType.info,
    actionLabel: 'GERİ AL',
    onAction: () => calls++,
  );
  controller.performAction();
  controller.performAction();
  expect(calls, 1);
});

testWidgets('automatically dismisses after the configured duration',
    (tester) async {
  final controller = AppNotificationController();
  addTearDown(controller.dispose);
  controller.show(
    message: 'Tamamlandı',
    type: AppNotificationType.success,
    duration: const Duration(seconds: 2),
  );
  await tester.pump(const Duration(seconds: 2));
  expect(controller.current, isNull);
});
```

- [ ] **Step 5: Run the controller tests and verify GREEN**

Run: `flutter test test/core/notifications/app_notification_controller_test.dart`

Expected: all controller tests PASS.

- [ ] **Step 6: Commit the controller**

```powershell
git add -- lib/core/notifications/app_notification.dart test/core/notifications/app_notification_controller_test.dart
git commit -m "feat: add app notification controller"
```

---

### Task 2: Responsive Notification Card and Host

**Files:**
- Create: `lib/core/notifications/app_notification_card.dart`
- Create: `lib/core/notifications/app_notification_host.dart`
- Create: `test/core/notifications/app_notification_host_test.dart`

**Interfaces:**
- Consumes: `AppNotificationController` and `AppNotificationData` from Task 1.
- Produces: `AppNotificationHost({required Widget child, AppNotificationController? controller})` and visible keys `app-notification-host` and `app-notification-card` for behavioral widget tests.

- [ ] **Step 1: Write failing responsive placement and semantics tests**

```dart
Future<void> pumpHost(
  WidgetTester tester, {
  required Size size,
  required AppNotificationController controller,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    home: AppNotificationHost(
      controller: controller,
      child: const Scaffold(body: Text('İçerik')),
    ),
  ));
}

testWidgets('mobile notification is top centered', (tester) async {
  final controller = AppNotificationController();
  addTearDown(controller.dispose);
  await pumpHost(tester, size: const Size(390, 844), controller: controller);
  controller.show(message: 'Bilgi', type: AppNotificationType.info);
  await tester.pump();
  final rect = tester.getRect(find.byKey(const Key('app-notification-card')));
  expect(rect.top, lessThan(80));
  expect(rect.center.dx, closeTo(195, 2));
});

testWidgets('wide notification is aligned to the top right', (tester) async {
  final controller = AppNotificationController();
  addTearDown(controller.dispose);
  await pumpHost(tester, size: const Size(1200, 800), controller: controller);
  controller.show(message: 'Bilgi', type: AppNotificationType.info);
  await tester.pump();
  final rect = tester.getRect(find.byKey(const Key('app-notification-card')));
  expect(rect.top, lessThan(80));
  expect(rect.right, closeTo(1184, 2));
});
```

Add tests that each type exposes its own icon and semantic label, the close button dismisses, `GERİ AL` invokes the callback once, dark theme renders, and text scale 2.0 produces no overflow exception.

- [ ] **Step 2: Run host tests and verify RED**

Run: `flutter test test/core/notifications/app_notification_host_test.dart`

Expected: FAIL because the card and host do not exist.

- [ ] **Step 3: Implement the notification card**

```dart
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
    final colors = _appearanceFor(context, notification.type);
    return Semantics(
      liveRegion: true,
      label: '${colors.semanticLabel}: ${notification.message}',
      child: Material(
        key: const Key('app-notification-card'),
        elevation: 12,
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: colors.accent, width: 4)),
          ),
          child: Row(children: [
            Icon(colors.icon, color: colors.accent),
            const SizedBox(width: 10),
            Expanded(child: Text(notification.message)),
            if (notification.actionLabel != null)
              TextButton(
                onPressed: onAction,
                child: Text(notification.actionLabel!),
              ),
            IconButton(
              tooltip: 'Bildirimi kapat',
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
            ),
          ]),
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
          accent: const Color(0xFF2E7D32),
          semanticLabel: 'Başarılı',
        ),
      AppNotificationType.error => (
          icon: Icons.error_rounded,
          accent: scheme.error,
          semanticLabel: 'Hata',
        ),
      AppNotificationType.warning => (
          icon: Icons.warning_amber_rounded,
          accent: const Color(0xFFF57F17),
          semanticLabel: 'Uyarı',
        ),
      AppNotificationType.info => (
          icon: Icons.info_rounded,
          accent: scheme.primary,
          semanticLabel: 'Bilgi',
        ),
    };
  }
}
```

Use `check_circle_rounded`, `error_rounded`, `warning_amber_rounded`, and `info_rounded`; add a 4-pixel accent edge and theme-derived surface/text colors.

- [ ] **Step 4: Implement the responsive host and animation**

```dart
class AppNotificationHost extends StatelessWidget {
  const AppNotificationHost({
    super.key,
    required this.child,
    this.controller,
  });

  final Widget child;
  final AppNotificationController? controller;

  @override
  Widget build(BuildContext context) {
    final activeController = controller ?? AppNotifications.controller;
    return Stack(
      key: const Key('app-notification-host'),
      children: [
        child,
        Positioned.fill(
          child: SafeArea(
            child: ListenableBuilder(
              listenable: activeController,
              builder: (context, _) {
                final notification = activeController.current;
                final reduceMotion =
                    MediaQuery.maybeOf(context)?.disableAnimations ?? false;
                return LayoutBuilder(builder: (context, constraints) {
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
                                    onDismiss: activeController.dismiss,
                                    onAction: activeController.performAction,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
```

The overlay must use `IgnorePointer(ignoring: current == null)`, max width 420, 16-pixel horizontal/top inset, top-center below 840 pixels, top-right at or above 840 pixels, and `AnimatedSwitcher` with fade plus a small upward slide. Use a zero/near-zero duration when `MediaQuery.disableAnimationsOf(context)` is true.

- [ ] **Step 5: Run host and controller tests and verify GREEN**

Run: `flutter test test/core/notifications/app_notification_host_test.dart test/core/notifications/app_notification_controller_test.dart`

Expected: all notification tests PASS with no overflow exceptions.

- [ ] **Step 6: Commit the presentation layer**

```powershell
git add -- lib/core/notifications/app_notification_card.dart lib/core/notifications/app_notification_host.dart test/core/notifications/app_notification_host_test.dart
git commit -m "feat: add responsive notification overlay"
```

---

### Task 3: Install the Host at Application Root

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `AppNotificationHost` and `AppNotifications.controller` from Tasks 1-2.
- Produces: every routed screen is rendered beneath the single app-wide host.

- [ ] **Step 1: Write a failing root integration widget test**

```dart
testWidgets('PersonelApp installs the global notification host',
    (tester) async {
  await tester.pumpWidget(const ProviderScope(child: PersonelApp()));
  expect(find.byKey(const Key('app-notification-host')), findsOneWidget);
});
```

- [ ] **Step 2: Run the root test and verify RED**

Run: `flutter test test/widget_test.dart`

Expected: FAIL because `PersonelApp` does not yet install the host.

- [ ] **Step 3: Wrap the router child through `MaterialApp.router.builder`**

```dart
return MaterialApp.router(
  title: 'Nizam',
  debugShowCheckedModeBanner: false,
  theme: AppTheme.militaryTheme,
  darkTheme: AppTheme.darkMilitaryTheme,
  themeMode: themeMode,
  routerConfig: router,
  builder: (context, child) => AppNotificationHost(
    child: child ?? const SizedBox.shrink(),
  ),
);
```

Import `package:personelapp2/core/notifications/app_notification_host.dart`.

- [ ] **Step 4: Run root and notification tests and verify GREEN**

Run: `flutter test test/widget_test.dart test/core/notifications`

Expected: all tests PASS.

- [ ] **Step 5: Commit root integration**

```powershell
git add -- lib/main.dart test/widget_test.dart
git commit -m "feat: install global notification host"
```

---

### Task 4: Migrate Every Feature Notification

**Files:**
- Modify standalone callers: `lib/features/activity/presentation/activity_assignment_preview_screen.dart`, `lib/features/activity/presentation/dialogs/add_personnel_dialog.dart`, `lib/features/activity/presentation/dialogs/bulk_import/bulk_import_save_handler.dart`, `lib/features/activity/presentation/dialogs/bulk_import/learned_aliases_dialog.dart`, `lib/features/activity/presentation/dialogs/edit_assignment_dialog.dart`, `lib/features/activity/presentation/dialogs/transfer_personnel_dialog.dart`, `lib/features/activity/presentation/dialogs/transfer_squad_dialog.dart`, `lib/features/activity/presentation/pending_approvals_screen.dart`, `lib/features/activity/presentation/widgets/activity_summary_card.dart`, `lib/features/auth/presentation/login_screen.dart`, `lib/features/dashboard/presentation/widgets/dashboard_settings.dart`, `lib/features/personnel/presentation/widgets/personnel_form_dialog.dart`, `lib/features/temgundrap/presentation/temgundrap_form_screen.dart`, `lib/features/temgundrap/presentation/temgundrap_screen.dart`, `lib/features/temgundrap/presentation/widgets/temgundrap_commander_picker.dart`, `lib/features/temgundrap/presentation/widgets/temgundrap_operation_editor_dialog.dart`
- Modify library import owners for part files: `lib/features/activity/presentation/activity_archive_screen.dart`, `lib/features/activity/presentation/activity_form_screen.dart`, `lib/features/activity/presentation/dialogs/bulk_import_dialog.dart`, `lib/features/activity/presentation/widgets/activity_detail_sheet.dart`, `lib/features/personnel/presentation/personnel_management_screen.dart`
- Modify part callers: `lib/features/activity/presentation/activity_archive_actions.dart`, `lib/features/activity/presentation/activity_form_actions.dart`, `lib/features/activity/presentation/dialogs/bulk_import_dialog_actions.dart`, `lib/features/activity/presentation/widgets/activity_detail_assignments.dart`, `lib/features/personnel/presentation/personnel_management_actions.dart`
- Test existing suites: `test/features/activity`, `test/features/auth`, `test/features/dashboard`, `test/features/personnel`, `test/features/temgundrap`

**Interfaces:**
- Consumes: `AppNotifications.success/error/warning/info` facade.
- Produces: no feature code directly invokes `ScaffoldMessenger.showSnackBar`; existing message text and undo behavior remain user-visible through the top overlay.

- [ ] **Step 1: Record the migration baseline**

Run: `rg -n "showSnackBar|SnackBar\(" lib`

Expected: matches in the 22 caller files listed above. Save the output in the execution notes, not in a source-based automated test.

- [ ] **Step 2: Migrate error and warning notifications**

Replace patterns such as:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(message), backgroundColor: Colors.red),
);
```

with:

```dart
AppNotifications.error(message);
```

Use `warning` for validation or recoverable attention states (previous orange styling) and `error` for failed operations, authorization/session errors, invalid credentials, or blocking states. Add imports only to standalone files and the five parent library files; Dart part files inherit their parent's imports.

- [ ] **Step 3: Migrate success and informational notifications**

Use `success` for completed save/export/update/link operations and `info` for neutral conditions such as “already selected”, “nothing to export”, or removed items.

- [ ] **Step 4: Preserve undo and other actions**

Replace action snackbars with:

```dart
AppNotifications.info(
  '${removed.rawRank} ${removed.rawName} kaldırıldı.',
  actionLabel: 'GERİ AL',
  onAction: () {
    if (!mounted || blockIndex >= _parsedBlocks.length) return;
    _updateState(() {
      final current = _parsedBlocks[blockIndex];
      final restored = List<ParsedPersonnelItem>.from(current.personnelList);
      restored.insert(personIndex.clamp(0, restored.length), removed);
      _parsedBlocks[blockIndex] = current.copyWith(personnelList: restored);
    });
  },
);
```

Remove only `hideCurrentSnackBar()` calls that existed to replace a bottom snackbar; the controller queue/deduplication owns replacement behavior.

- [ ] **Step 5: Run feature suites and fix only migration regressions**

Run: `flutter test test/features/activity test/features/auth test/features/dashboard test/features/personnel test/features/temgundrap`

Expected: all feature tests PASS. If an existing test asserts a `SnackBar`, update it to assert the real visible top card message/action through `AppNotificationHost`, never an implementation symbol.

- [ ] **Step 6: Verify no bottom notification calls remain**

Run: `rg -n "showSnackBar|SnackBar\(" lib`

Expected: no matches. `ScaffoldMessenger` may remain only if used for a non-notification framework behavior; otherwise remove unused imports/references.

- [ ] **Step 7: Commit the feature migration**

```powershell
git add -- lib/features
git commit -m "refactor: migrate app notifications to top overlay"
```

---

### Task 5: Final Quality Verification

**Files:**
- Modify only files required by formatter/analyzer findings introduced by Tasks 1-4.

**Interfaces:**
- Consumes: complete notification implementation and migrated feature callers.
- Produces: a formatted, analyzer-clean, fully tested feature branch ready for review.

- [ ] **Step 1: Format changed Dart files**

Run: `dart format lib/core/notifications lib/main.dart test/core/notifications test/widget_test.dart lib/features`

Expected: formatter completes successfully.

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`

Expected: `No issues found!`

- [ ] **Step 3: Run the full test suite**

Run: `flutter test -r compact`

Expected: all tests PASS.

- [ ] **Step 4: Re-run the bottom-notification audit**

Run: `rg -n "showSnackBar|SnackBar\(" lib`

Expected: no matches.

- [ ] **Step 5: Inspect scope and commit final cleanup if needed**

Run: `git status --short` and `git diff --check`

If formatting or analyzer cleanup changed files:

```powershell
git add -- lib test
git commit -m "chore: finalize modern notification migration"
```

Expected: clean working tree and only notification-related commits on `feat/modern-app-notifications` beyond the updated `main` base.
