# Turkish Calendar Localization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every Material date picker in the application use Turkish labels and a Monday-first week.

**Architecture:** Configure localization once at the root `MaterialApp.router`, allowing all current and future picker routes to inherit the same Turkish `MaterialLocalizations`. Verify the app-level contract through the existing root widget test instead of modifying each picker call.

**Tech Stack:** Flutter, `flutter_localizations`, `flutter_test`, Riverpod

## Global Constraints

- Keep persisted date formats and picker date bounds unchanged.
- Use the Flutter 3.44.4 SDK-pinned `intl ^0.20.2` constraint required by `flutter_localizations`.
- Do not modify individual `showDatePicker` call sites.
- Preserve router, themes, and the global notification host.
- Do not touch unrelated working-tree changes.

---

### Task 1: Root Turkish Material localization

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: Flutter's `GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, and `GlobalCupertinoLocalizations` delegates.
- Produces: A root widget tree whose `Localizations.localeOf(context)` is `tr_TR` and whose `MaterialLocalizations.firstDayOfWeekIndex` is `1` (Monday in Material's Sunday-based weekday list).

- [x] **Step 1: Write the failing root widget regression test**

Add a test that pumps `ProviderScope(child: PersonelApp())`, reads the context below `MaterialApp.router`, and asserts:

```dart
final context = tester.element(find.byKey(const Key('app-notification-host')));
final locale = Localizations.localeOf(context);
final material = MaterialLocalizations.of(context);

expect(locale, const Locale('tr', 'TR'));
expect(material.datePickerHelpText, 'Tarih seçin');
expect(material.cancelButtonLabel, 'İptal');
expect(material.okButtonLabel, 'Tamam');
expect(material.firstDayOfWeekIndex, 1);
```

- [x] **Step 2: Run the test and verify RED**

Run: `flutter test test/widget_test.dart`

Expected: FAIL because the current app resolves the default English locale and labels.

- [x] **Step 3: Add the SDK localization dependency**

Add under `dependencies` in `pubspec.yaml`:

```yaml
flutter_localizations:
  sdk: flutter
```

Align the existing direct dependency with the Flutter SDK pin:

```yaml
intl: ^0.20.2
```

Run `flutter pub get` to update `pubspec.lock` through Flutter's package resolver.

- [x] **Step 4: Configure the root app locale**

Import `package:flutter_localizations/flutter_localizations.dart` in `lib/main.dart`, then add to `MaterialApp.router`:

```dart
locale: const Locale('tr', 'TR'),
supportedLocales: const [Locale('tr', 'TR')],
localizationsDelegates: const [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
```

- [x] **Step 5: Run the target test and verify GREEN**

Run: `flutter test test/widget_test.dart`

Expected: PASS with Turkish labels and Monday-first metadata.

- [x] **Step 6: Format and validate the scoped change**

Run:

```powershell
dart format lib/main.dart test/widget_test.dart
git diff --check
flutter analyze
flutter test test/widget_test.dart
```

Expected: all commands succeed without new warnings or failures.
