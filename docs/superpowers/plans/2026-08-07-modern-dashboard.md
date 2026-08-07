# Modern Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the selected third dashboard design as a compact, accessible Flutter dashboard with six admin grid actions, four non-admin grid actions, and a full-width archive action.

**Architecture:** Keep provider reads, navigation callbacks, and the bulk-import workflow in `DashboardScreen`. Extract immutable action metadata and dashboard-specific visual tones into focused presentation files, keep vertical and horizontal actions as separate widgets, and replace height-dependent grid fitting with a scrollable sliver composition whose columns depend only on available width.

**Tech Stack:** Flutter Material 3, Dart 3.5+, Riverpod 2.6, GoRouter 17, `flutter_test`.

## Global Constraints

- Follow `docs/superpowers/specs/2026-08-07-modern-dashboard-design.md`.
- Preserve all current Turkish labels, routes, provider reads, permissions, settings behavior, and bulk-import repository invalidation.
- Preserve light and dark themes.
- Admin layout contains six compact grid actions plus a full-width archive action.
- Non-admin layout contains four compact grid actions plus a full-width archive action.
- Use existing Material icons; add no image, SVG, font, or package dependency.
- Keep minimum touch targets at 48 px and avoid text clipping at increased text scale.
- Do not modify the unrelated generated plugin registrant files already dirty in the worktree.
- Figma library creation is out of scope for this plan and begins only after an editable target Figma file is supplied.

---

## File Structure

- Create `lib/features/dashboard/presentation/models/dashboard_action_item.dart`: immutable dashboard action metadata.
- Create `lib/features/dashboard/presentation/widgets/dashboard_action_tone.dart`: semantic dashboard tones and theme-aware palette resolution.
- Create `lib/features/dashboard/presentation/widgets/dashboard_archive_action.dart`: full-width horizontal archive action.
- Modify `lib/features/dashboard/presentation/widgets/dashboard_menu_card.dart`: compact vertical tile driven by semantic tone.
- Modify `lib/features/dashboard/presentation/widgets/dashboard_grid_layout.dart`: width-based two/three-column geometry.
- Modify `lib/features/dashboard/presentation/dashboard_screen.dart`: action construction and scrollable sliver composition.
- Create `test/features/dashboard/dashboard_grid_layout_test.dart`: deterministic layout-unit coverage.
- Create `test/features/dashboard/dashboard_action_widgets_test.dart`: light/dark, semantics, and interaction coverage for both action widgets.
- Modify `test/features/dashboard/dashboard_personnel_menu_test.dart`: role layout, scrolling, archive placement, and route regression coverage.
- Create `design-qa.md`: final reference-versus-implementation QA result after the app is captured.

---

### Task 1: Width-Based Dashboard Grid Geometry

**Files:**
- Create: `test/features/dashboard/dashboard_grid_layout_test.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_grid_layout.dart:1`

**Interfaces:**
- Consumes: `BoxConstraints.maxWidth` and `AppSpacing.cardGap`.
- Produces: `DashboardGridLayout.calculate(BoxConstraints constraints)`, `int columnCount`, and `double mainAxisExtent` for `DashboardScreen`.

- [ ] **Step 1: Write failing layout tests**

Create `test/features/dashboard/dashboard_grid_layout_test.dart`:

```dart
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_grid_layout.dart';

void main() {
  group('DashboardGridLayout', () {
    test('uses two columns on phone widths', () {
      for (final width in <double>[320, 360, 390, 600, 719]) {
        final layout = DashboardGridLayout.calculate(
          BoxConstraints.tightFor(width: width, height: 844),
        );

        expect(layout.columnCount, 2, reason: 'width=$width');
        expect(layout.mainAxisExtent, greaterThanOrEqualTo(168));
      }
    });

    test('uses three columns on wide content', () {
      final layout = DashboardGridLayout.calculate(
        const BoxConstraints.tightFor(width: 860, height: 800),
      );

      expect(layout.columnCount, 3);
      expect(layout.mainAxisExtent, greaterThanOrEqualTo(168));
    });

    test('ignores available height so page can scroll', () {
      final short = DashboardGridLayout.calculate(
        const BoxConstraints.tightFor(width: 390, height: 320),
      );
      final tall = DashboardGridLayout.calculate(
        const BoxConstraints.tightFor(width: 390, height: 1200),
      );

      expect(short.columnCount, tall.columnCount);
      expect(short.mainAxisExtent, tall.mainAxisExtent);
    });
  });
}
```

- [ ] **Step 2: Run the test and verify the API mismatch fails**

Run:

```powershell
flutter test test/features/dashboard/dashboard_grid_layout_test.dart
```

Expected: compile failure because `calculate` still requires `count` and `mainAxisExtent` does not exist.

- [ ] **Step 3: Replace height-fitting geometry with width-based geometry**

Replace `dashboard_grid_layout.dart` with:

```dart
import 'package:flutter/material.dart';

class DashboardGridLayout {
  const DashboardGridLayout._({
    required this.columnCount,
    required this.mainAxisExtent,
  });

  final int columnCount;
  final double mainAxisExtent;

  factory DashboardGridLayout.calculate(BoxConstraints constraints) {
    final columns = constraints.maxWidth >= 720 ? 3 : 2;
    return DashboardGridLayout._(
      columnCount: columns,
      mainAxisExtent: columns == 3 ? 168 : 184,
    );
  }
}
```

- [ ] **Step 4: Run the focused test**

Run:

```powershell
flutter test test/features/dashboard/dashboard_grid_layout_test.dart
```

Expected: all three tests pass.

- [ ] **Step 5: Commit the layout unit**

```powershell
git add lib/features/dashboard/presentation/widgets/dashboard_grid_layout.dart test/features/dashboard/dashboard_grid_layout_test.dart
git commit -m "refactor: make dashboard grid width based"
```

---

### Task 2: Semantic Dashboard Action Components

**Files:**
- Create: `lib/features/dashboard/presentation/models/dashboard_action_item.dart`
- Create: `lib/features/dashboard/presentation/widgets/dashboard_action_tone.dart`
- Create: `lib/features/dashboard/presentation/widgets/dashboard_archive_action.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_menu_card.dart:5`
- Create: `test/features/dashboard/dashboard_action_widgets_test.dart`

**Interfaces:**
- Consumes: existing `AppColors`, `ThemeContext`, `AppSpacing`, Material `IconData`, and callbacks.
- Produces: `DashboardActionTone`, `DashboardActionPalette`, `DashboardActionItem`, updated `DashboardMenuCard`, and `DashboardArchiveAction`.

- [ ] **Step 1: Write failing widget tests for vertical and horizontal actions**

Create `test/features/dashboard/dashboard_action_widgets_test.dart` with a helper that pumps both light and dark themes:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_action_tone.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_archive_action.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_menu_card.dart';

void main() {
  Widget subject(Widget child, {ThemeMode mode = ThemeMode.light}) {
    return MaterialApp(
      theme: AppTheme.militaryTheme,
      darkTheme: AppTheme.darkMilitaryTheme,
      themeMode: mode,
      home: Scaffold(body: Center(child: SizedBox(width: 360, child: child))),
    );
  }

  testWidgets('menu card exposes one button semantic and invokes tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      subject(
        SizedBox(
          height: 184,
          child: DashboardMenuCard(
            icon: Icons.edit_calendar,
            title: 'Faaliyet Çizelgesi',
            subtitle: 'Günlük görev gir',
            tone: DashboardActionTone.primary,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Faaliyet Çizelgesi, Günlük görev gir'),
      findsOneWidget,
    );
    await tester.tap(find.text('Faaliyet Çizelgesi'));
    expect(taps, 1);
  });

  testWidgets('archive action is horizontal and works in dark mode', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      subject(
        DashboardArchiveAction(
          icon: Icons.inventory_2_outlined,
          title: 'Faaliyet Arşivi',
          subtitle: 'Arama ve İnceleme',
          onTap: () => taps++,
        ),
        mode: ThemeMode.dark,
      ),
    );

    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Faaliyet Arşivi'));
    expect(taps, 1);
  });
}
```

- [ ] **Step 2: Run the widget tests and verify missing types fail**

Run:

```powershell
flutter test test/features/dashboard/dashboard_action_widgets_test.dart
```

Expected: compile failure for missing `DashboardActionTone`, `DashboardArchiveAction`, and the new `tone` parameter.

- [ ] **Step 3: Add immutable action metadata**

Create `dashboard_action_item.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_action_tone.dart';

class DashboardActionItem {
  const DashboardActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final DashboardActionTone tone;
  final VoidCallback onTap;
}
```

- [ ] **Step 4: Add semantic tones and theme-aware palettes**

Create `dashboard_action_tone.dart` with the exact public API:

```dart
import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

enum DashboardActionTone { primary, neutral, personnel, import, pending }

class DashboardActionPalette {
  const DashboardActionPalette({
    required this.surface,
    required this.border,
    required this.iconSurface,
    required this.content,
  });

  final Color surface;
  final Color border;
  final Color iconSurface;
  final Color content;
}

extension DashboardActionTonePalette on DashboardActionTone {
  DashboardActionPalette resolve(BuildContext context) {
    final dark = context.isDarkMode;
    final accent = switch (this) {
      DashboardActionTone.primary || DashboardActionTone.neutral =>
        context.accentOrOlive,
      DashboardActionTone.personnel => context.blueGreyColor,
      DashboardActionTone.import =>
        dark ? const Color(0xFF64B5F6) : Colors.blue.shade700,
      DashboardActionTone.pending => context.pendingColor,
    };
    final alpha = this == DashboardActionTone.primary ? 0.14 : 0.08;
    return DashboardActionPalette(
      surface: accent.withValues(alpha: dark ? alpha + 0.04 : alpha),
      border: accent.withValues(
        alpha: this == DashboardActionTone.primary ? 0.85 : 0.32,
      ),
      iconSurface: accent.withValues(alpha: dark ? 0.22 : 0.10),
      content: accent,
    );
  }
}
```

If contrast measurement during Task 4 fails, adjust only palette alpha/content values; keep this public API unchanged.

- [ ] **Step 5: Rebuild `DashboardMenuCard` around semantic tone**

Change the constructor from `Color color` to `DashboardActionTone tone`. Implement one outer `Semantics(button: true, label: '$title, $subtitle')`, exclude duplicate descendant semantics, use `Material` plus `InkWell`, and render:

```dart
final palette = tone.resolve(context);

return Semantics(
  button: true,
  label: '$title, $subtitle',
  child: ExcludeSemantics(
    child: Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.iconSurface,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Icon(icon, size: 28, color: palette.content),
                ),
              ),
              const Spacer(),
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.rowGap),
              Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    ),
  ),
);
```

Apply theme text styles with bold title and `context.textSecondary` subtitle; do not hardcode font families.

- [ ] **Step 6: Add the full-width archive action**

Create `DashboardArchiveAction` with required `icon`, `title`, `subtitle`, and `onTap` arguments. Use the same single-node semantics pattern, a minimum height of 88, 16 px radius, a leading circular icon surface, `Expanded` title/subtitle content, and `Icons.chevron_right_rounded` excluded from semantics.

- [ ] **Step 7: Run component tests in light and dark themes**

Run:

```powershell
flutter test test/features/dashboard/dashboard_action_widgets_test.dart
```

Expected: both tests pass with no overflow or semantics duplication.

- [ ] **Step 8: Format and commit the component unit**

```powershell
dart format lib/features/dashboard/presentation/models/dashboard_action_item.dart lib/features/dashboard/presentation/widgets/dashboard_action_tone.dart lib/features/dashboard/presentation/widgets/dashboard_archive_action.dart lib/features/dashboard/presentation/widgets/dashboard_menu_card.dart test/features/dashboard/dashboard_action_widgets_test.dart
git add lib/features/dashboard/presentation/models/dashboard_action_item.dart lib/features/dashboard/presentation/widgets/dashboard_action_tone.dart lib/features/dashboard/presentation/widgets/dashboard_archive_action.dart lib/features/dashboard/presentation/widgets/dashboard_menu_card.dart test/features/dashboard/dashboard_action_widgets_test.dart
git commit -m "feat: add semantic dashboard action components"
```

---

### Task 3: Compose The Modern Role-Aware Dashboard

**Files:**
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart:14`
- Modify: `test/features/dashboard/dashboard_personnel_menu_test.dart:1`

**Interfaces:**
- Consumes: `DashboardActionItem`, `DashboardActionTone`, `DashboardMenuCard`, `DashboardArchiveAction`, `DashboardGridLayout`, existing Riverpod providers, GoRouter routes, and `BulkImportDialog`.
- Produces: the selected option-3 dashboard for admin and non-admin users without changing business behavior.

- [ ] **Step 1: Extend the dashboard regression test with role and structure assertions**

Refactor `dashboard_personnel_menu_test.dart` to provide a `buildSubject(UserSessionState session)` helper and add these exact cases:

```dart
testWidgets('admin sees six grid actions and a separate archive action', (
  tester,
) async {
  await pumpDashboard(
    tester,
    const UserSessionState(username: 'admin', role: UserRole.admin),
  );

  expect(find.byType(CustomScrollView), findsOneWidget);
  expect(find.byType(DashboardMenuCard), findsNWidgets(6));
  expect(find.byType(DashboardArchiveAction), findsOneWidget);
  expect(find.text('Metinden Toplu Aktar'), findsOneWidget);
  expect(find.text('Bekleyen Onaylar'), findsOneWidget);
});

testWidgets('non-admin sees four grid actions and a separate archive action', (
  tester,
) async {
  await pumpDashboard(
    tester,
    const UserSessionState(username: 'tim', role: UserRole.teamCommander),
  );

  expect(find.byType(DashboardMenuCard), findsNWidgets(4));
  expect(find.byType(DashboardArchiveAction), findsOneWidget);
  expect(find.text('Metinden Toplu Aktar'), findsNothing);
  expect(find.text('Bekleyen Onaylar'), findsNothing);
  expect(find.text('Kadro Durumu'), findsOneWidget);
});
```

Keep the existing `Personel & Tim` navigation regression. Add imports for the two dashboard action widgets.

- [ ] **Step 2: Run the screen test and verify current structure fails**

Run:

```powershell
flutter test test/features/dashboard/dashboard_personnel_menu_test.dart
```

Expected: failures because the current screen has seven/five `DashboardMenuCard` widgets and no `DashboardArchiveAction` or `CustomScrollView`.

- [ ] **Step 3: Build role-aware action metadata without changing callbacks**

Inside `DashboardScreen.build`, create `gridActions` as `List<DashboardActionItem>` in this order:

1. `Faaliyet Çizelgesi` → `/activity-form` → `DashboardActionTone.primary`
2. `Aylık Matris` → `/monthly-matrix` → `DashboardActionTone.neutral`
3. `TEMGÜNDRAP` → `/temgundrap` → `DashboardActionTone.neutral`
4. `Personel & Tim` → `/personnel-management` → `DashboardActionTone.personnel`
5. admin only `Metinden Toplu Aktar` → existing dialog callback → `DashboardActionTone.import`
6. admin only `Bekleyen Onaylar` → `/pending-approvals` → `DashboardActionTone.pending`

Create the archive callback separately so `Faaliyet Arşivi` never participates in grid count or geometry.

- [ ] **Step 4: Replace the fixed column with a scrollable sliver composition**

Inside the existing `ResponsiveCenter`, use `LayoutBuilder` and return:

```dart
final gridLayout = DashboardGridLayout.calculate(constraints);

return CustomScrollView(
  slivers: [
    if (isAdmin) SliverToBoxAdapter(child: pendingWarning),
    const SliverToBoxAdapter(child: dashboardHeading),
    SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridLayout.columnCount,
        mainAxisExtent: gridLayout.mainAxisExtent,
        crossAxisSpacing: AppSpacing.cardGap,
        mainAxisSpacing: AppSpacing.cardGap,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final action = gridActions[index];
          return DashboardMenuCard(
            key: ValueKey('dashboard-action-${action.title}'),
            icon: action.icon,
            title: action.title,
            subtitle: action.subtitle,
            tone: action.tone,
            onTap: action.onTap,
          );
        },
        childCount: gridActions.length,
      ),
    ),
    const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.cardGap)),
    SliverToBoxAdapter(
      child: DashboardArchiveAction(
        key: const ValueKey('dashboard-archive-action'),
        icon: Icons.inventory_2_outlined,
        title: 'Faaliyet Arşivi',
        subtitle: 'Arama ve İnceleme',
        onTap: () => context.push('/activity-archive'),
      ),
    ),
    const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
  ],
);
```

Extract `pendingWarning` and `dashboardHeading` as local widgets or private methods so they can be inserted into slivers without duplicating provider logic. Preserve the warning's current data/loading/error behavior and callback.

- [ ] **Step 5: Update the widget preview**

Change the existing dashboard card preview to pass `tone: DashboardActionTone.neutral`. Keep the preview name and dimensions unless the updated tile needs `height: 184` to avoid truncation.

- [ ] **Step 6: Run dashboard tests**

Run:

```powershell
flutter test test/features/dashboard/dashboard_grid_layout_test.dart test/features/dashboard/dashboard_action_widgets_test.dart test/features/dashboard/dashboard_personnel_menu_test.dart
```

Expected: all dashboard tests pass.

- [ ] **Step 7: Run the dashboard screen at multiple viewport and text-scale combinations**

Extend the existing test loop to cover:

```dart
for (final size in <Size>[
  const Size(320, 568),
  const Size(390, 844),
  const Size(600, 960),
  const Size(1280, 800),
]) {
  tester.view.physicalSize = size;
  await tester.pump();
  expect(tester.takeException(), isNull, reason: 'Overflow at $size');
}
```

Run once with `textScaleFactorTestValue = 1.3` and verify `tester.takeException()` stays null.

- [ ] **Step 8: Format and commit the composed screen**

```powershell
dart format lib/features/dashboard/presentation/dashboard_screen.dart test/features/dashboard/dashboard_personnel_menu_test.dart
git add lib/features/dashboard/presentation/dashboard_screen.dart test/features/dashboard/dashboard_personnel_menu_test.dart
git commit -m "feat: modernize dashboard layout"
```

---

### Task 4: Static Analysis, Visual QA, And Handoff

**Files:**
- Create: `design-qa.md`
- Modify only if QA finds P0-P2 issues: dashboard files and tests from Tasks 1-3.

**Interfaces:**
- Consumes: selected third generated design, original screenshot, running Flutter app, and completed dashboard tests.
- Produces: analyzed, tested, visually verified dashboard and `design-qa.md` with `final result: passed`.

- [ ] **Step 1: Run formatter verification**

```powershell
dart format --output=none --set-exit-if-changed lib/features/dashboard test/features/dashboard
```

Expected: exit code 0 and no changed files.

- [ ] **Step 2: Run static analysis**

```powershell
flutter analyze
```

Expected: no analyzer errors or warnings introduced by the dashboard work.

- [ ] **Step 3: Run focused dashboard tests**

```powershell
flutter test test/features/dashboard
```

Expected: all dashboard tests pass.

- [ ] **Step 4: Run the full test suite**

```powershell
flutter test
```

Expected: all tests pass. If an unrelated pre-existing failure appears, record its exact test and failure separately; do not weaken dashboard assertions.

- [ ] **Step 5: Launch the Flutter app on an available mobile target**

Discover targets:

```powershell
flutter devices
```

Run on the available Android/iOS/desktop target that can display a 390 × 844-equivalent mobile viewport:

```powershell
flutter run -d <device-id>
```

Log in with an existing local test/admin account; do not create or alter production credentials.

- [ ] **Step 6: Capture the selected state and compare it to the visual target**

Capture the admin dashboard at 390 × 844-equivalent dimensions. Open both:

- selected third generated design from the current Product Design ideation set
- latest running dashboard capture

Compare hierarchy, spacing, typography, icon scale, card dimensions, color, border, radius, archive width, and clipping. Record findings in `design-qa.md` using severity P0-P3 and include exactly one terminal line:

```text
final result: passed
```

Use `final result: blocked` if the selected target or running capture cannot be obtained.

- [ ] **Step 7: Fix every P0-P2 mismatch and repeat capture**

For each P0-P2 finding, change only the responsible dashboard widget or tone value, rerun the focused tests, capture again, and update `design-qa.md`. Stop only when no P0-P2 findings remain and the file says `final result: passed`.

- [ ] **Step 8: Commit QA-backed polish**

```powershell
git add lib/features/dashboard test/features/dashboard design-qa.md
git commit -m "test: verify modern dashboard design"
```

- [ ] **Step 9: Confirm unrelated user changes remain untouched**

```powershell
git status --short
git diff -- linux/flutter/generated_plugin_registrant.cc linux/flutter/generated_plugins.cmake macos/Flutter/GeneratedPluginRegistrant.swift windows/flutter/generated_plugin_registrant.cc windows/flutter/generated_plugins.cmake
```

Expected: the existing generated plugin changes may remain in the worktree, but none are staged or included in dashboard commits.

---

## Plan Self-Review

- Spec coverage: role visibility, routes, bulk import, settings, warning banner, archive placement, scrolling, responsive columns, dark mode, accessibility, tests, and visual QA are each assigned to a task.
- Placeholder scan: the plan contains no deferred implementation placeholders.
- Type consistency: `DashboardActionTone`, `DashboardActionPalette`, `DashboardActionItem`, `DashboardMenuCard.tone`, `DashboardArchiveAction`, and `DashboardGridLayout.mainAxisExtent` use the same names in every task.
- Scope check: Flutter implementation is independently testable; Figma library generation remains a separate follow-up that requires a target file.
