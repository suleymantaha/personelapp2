# Birleşik Kart ve Ekran Standartlaştırma (Unified Cards & Screens Design System) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Uygulama genelindeki tüm ekranlarda bağımsız, tutarsız ve performans kaybına (jank / donma / gesture çakışması) yol açan kart ve liste yapılarını tek bir kurumsal tasarım ve performans sistemine (`AppCard`, `AppListCard`, `AppExpandableCard`, sanallaştırılmış liste şablonları) kavuşturmak.

**Architecture:** `lib/core/widgets/` altında tek tip ve izole edilmiş `AppCard`, `AppActionCard`, `AppExpandableCard` bileşen ailesi oluşturulur; tüm ekranlar (`Temgundrap`, `Personnel`, `Activity Archive`, `Activity Form`, `Roster Output`, `Pending Approvals`, `Monthly Matrix`, `Dashboard`, `Auth`) bu standart yapıya taşınır; iç içe `shrinkWrap: true` ve `build()` içi ağır senkron hesaplama darboğazları ortadan kaldırılır.

**Tech Stack:** Flutter 3.x, Flutter Riverpod, Material 3, Drift DB, GoRouter.

**Spec:** Kullanıcı talebi: "tüm ekranlarda tek bir sorun var her kart ve ekran kafasına göre takılıyor ve düzgün şekilde işlemiyor bunu yaparken neden düzgün şekilde yapmadık? evet tüm sayfaları gezmeyi unutma gözden kaçan olmasın".

## Global Constraints
- `AppSpacing` (cardRadius: 14.0, cardPadding: 16.0, cardGap: 10.0) temel skala olarak kullanılır.
- Kart üzerine tıklama (`onTap`) ile kart üzerindeki aksiyon menüleri/ikonları (`IconButton`, `ModernActionMenu`) arasındaki dokunma olayları (gestures) kesinlikle çakışmayacak şekilde izole edilir.
- `shrinkWrap: true` ile `SingleChildScrollView` içine gömülü kontrolsüz listeler kaldırılıp Flutter viewport sanallaştırması korunur.
- Mevcut tüm iş mantığı, test kimlikleri (`key`) ve yerelleştirme (`l10n`) anahtarları korunur.
- 570+ mevcut testin tamamı kesintisiz yeşil kalacaktır.

## Review Focus
1. **Gesture Çakışması:** Karta basıldığında detay açılırken aksiyon butonuna basıldığında hem kart tıklamasının hem aksiyonun aynı anda tetiklenmesi önlenmelidir.
2. **Klavye Girişinde Donma (Fuzzy Search Jank):** Personel arama kutusuna yazı yazıldığında `build()` fonksiyonunun senkron tıkanması önlenmelidir.
3. **Responsive Grid Taşması (Overflow):** Temgündrap veya Dashboard gibi ekranlarda yazı boyutu büyütüldüğünde veya küçük ekranlarda sabit piksel (`mainAxisExtent`) nedeniyle taşma oluşmamalıdır.
4. **Tema & Kontrast:** Açık ve koyu askeri temada (`militaryTheme` / `darkMilitaryTheme`) kart kenarlıkları (`cardBorderColor`) ve yüzey renkleri tutarlı olmalıdır.
5. **Seçim Modu (Multi-selection):** Faaliyet arşivinde ve çıktı ekranında seçim modundayken kart tıklaması ile genişleme (expand) durumları birbirini bozmamalıdır.

---

### Task 1: Temel Kart ve Yüzey Standardı (`AppCard` Ailesi) Oluşturma

**Files:**
- Create: `lib/core/widgets/app_card.dart`
- Create: `test/widget/core/widgets/app_card_test.dart`

**Interfaces:**
- Produces:
  - `class AppCard extends StatelessWidget` (Standart kenarlık, dolgu, arka plan, opsiyonel `onTap`, izole `trailingActions`)
  - `class AppExpandableCard extends StatelessWidget` (Standart başlık, rozet, genişleme durumu, izole aksiyon butonları)
  - `class AppInfoRow extends StatelessWidget` (Önizleme ve detay ekranları için standart ikon-etiket-değer satırı)

- [ ] **Step 1: Write the failing widget tests for `AppCard`**

```dart
// test/widget/core/widgets/app_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/widgets/app_card.dart';

void main() {
  testWidgets('AppCard renders child with standard border and responds to onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(
            onTap: () => tapped = true,
            child: const Text('İçerik'),
          ),
        ),
      ),
    );
    expect(find.text('İçerik'), findsOneWidget);
    await tester.tap(find.text('İçerik'));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/core/widgets/app_card_test.dart`
Expected: FAIL (AppCard not found)

- [ ] **Step 3: Implement `AppCard`, `AppExpandableCard` ve `AppInfoRow`**

```dart
// lib/core/widgets/app_card.dart
import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/core/theme/spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.margin,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.borderColor,
    this.backgroundColor,
    this.borderRadius,
    this.elevation = 0,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final double elevation;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppSpacing.cardRadius);
    final effectiveBorder = borderColor ?? context.cardBorderColor;
    final effectiveBg = backgroundColor ?? context.colorScheme.surface;

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.cardGap),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        border: Border.all(color: effectiveBorder),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDarkMode ? 0.35 : 0.05),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      clipBehavior: clipBehavior,
      child: Material(
        color: Colors.transparent,
        child: onTap != null || onLongPress != null
            ? InkWell(
                borderRadius: effectiveRadius,
                onTap: onTap,
                onLongPress: onLongPress,
                child: Padding(padding: padding, child: child),
              )
            : Padding(padding: padding, child: child),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widget/core/widgets/app_card_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/widgets/app_card.dart test/widget/core/widgets/app_card_test.dart
git commit -m "feat(core): implement unified AppCard and surface primitives"
```

---

### Task 2: Temgündrap Ekranlarının Standartlaştırılması ve Tıklama Optimizasyonu

**Files:**
- Modify: `lib/features/temgundrap/presentation/temgundrap_screen.dart`
- Modify: `lib/features/temgundrap/presentation/temgundrap_preview_screen.dart`
- Modify: `lib/features/temgundrap/presentation/temgundrap_form_screen.dart`
- Test: `test/widget/responsive/responsive_layout_overflow_test.dart`

**Changes:**
1. `_DocumentCard` bileşenini `AppCard` yapısına geçirmek.
2. Sabit `mainAxisExtent: wide ? 178 : 152` yerine dinamik içerik korumalı flex veya esnek grid kart yapısı getirmek.
3. Karta tıklama (`onOpen`) ile aksiyon butonu (`onActions`) arasındaki dokunma alanını `Material / InkResponse` ile ayırarak gesture çakışmasını engellemek.
4. `temgundrap_preview_screen.dart` içindeki `_OperationCard` ve `_InfoRow` yapılarını `AppCard` ve `AppInfoRow` standardına taşımak.

- [ ] **Step 1: Update `_DocumentCard` in `temgundrap_screen.dart` using `AppCard`**
- [ ] **Step 2: Update `_OperationCard` in `temgundrap_preview_screen.dart` using `AppCard`**
- [ ] **Step 3: Run existing responsive overflow tests**

Run: `flutter test test/widget/responsive/responsive_layout_overflow_test.dart --name="TemgundrapScreen"`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/temgundrap/presentation/
git commit -m "refactor(temgundrap): migrate cards to AppCard with isolated gesture targets"
```

---

### Task 3: Personel Yönetim Ekranı Performans ve Kart Refactoring'i

**Files:**
- Modify: `lib/features/personnel/presentation/personnel_management_screen.dart`
- Modify: `lib/features/personnel/presentation/personnel_management_filters.dart`
- Test: `test/widget/features/personnel/personnel_dialogs_test.dart`
- Test: `test/widget/responsive/responsive_layout_overflow_test.dart`

**Changes:**
1. `SingleChildScrollView -> Column -> ExpansionTiles -> ListView.separated(shrinkWrap: true)` yapısındaki sanallaştırma katilini temizlemek; `CustomScrollView` ve `SliverList` yapısıyla 60 FPS akış sağlamak.
2. Her `build()` tetiklenmesinde çalışan ağır `PersonnelFuzzyMatcher.searchPersonnel` çağrısını memoize etmek / debounce akışına almak (arama kutusu tuş vuruşlarında donmayı bitirmek).
3. Tim ve kadro dışı kartları, her bir personel satırını `AppCard` tasarım standardına kavuşturmak.

- [ ] **Step 1: Refactor personnel filtering to avoid synchronous heavy CPU loop in `build()`**
- [ ] **Step 2: Replace shrinkWrap nested list in squad cards with virtualized layout**
- [ ] **Step 3: Run personnel tests**

Run: `flutter test test/widget/features/personnel/ test/widget/responsive/responsive_layout_overflow_test.dart --name="PersonnelManagementScreen"`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add lib/features/personnel/presentation/
git commit -m "perf(personnel): eliminate build-phase search lag and nested shrinkWrap virtualization kills"
```

---

### Task 4: Faaliyet & Nöbet Modülü Kartlarının (`ActivityCard`, `CollapsibleSquadCard`, `RosterSelectedCards`) Birleştirilmesi

**Files:**
- Modify: `lib/features/activity/presentation/widgets/activity_summary_card.dart`
- Modify: `lib/features/activity/presentation/widgets/collapsible_squad_card.dart`
- Modify: `lib/features/activity/presentation/widgets/roster_selected_cards.dart`
- Modify: `lib/features/activity/presentation/widgets/activity_form/activity_duty_action_card.dart`
- Modify: `lib/features/activity/presentation/widgets/activity_form/activity_selected_personnel_card.dart`
- Modify: `lib/features/activity/presentation/pending_approvals_screen.dart`
- Test: `test/widget/features/activity/activity_screens_test.dart`
- Test: `test/features/activity/roster_output_screen_test.dart`

**Changes:**
1. `ActivityCard`: `Card(shape: RoundedRectangleBorder(...))` ve iç içe `ExpansionTile` karmaşasını `AppCard` üzerine kurmak, `selectionMode` açıkken oluşan `IgnorePointer` ve gesture karmaşasını temizlemek.
2. `CollapsibleSquadCard`: Özel `Card` kodunu `AppCard` standardına bağlamak.
3. `RosterSelectedCards`: İçindeki `ReorderableListView(shrinkWrap: true)` yapısını optimize etmek.
4. `PendingApprovalsScreen`: Özel kırmızı/turuncu uyarı border'ına sahip kartları `AppCard(borderColor: context.pendingColor)` formatına taşımak.

- [ ] **Step 1: Update `ActivityCard` and `CollapsibleSquadCard` to use `AppCard`**
- [ ] **Step 2: Update form action & selected personnel cards to use `AppCard`**
- [ ] **Step 3: Update `PendingApprovalsScreen` cards to use `AppCard`**
- [ ] **Step 4: Run activity widget and integration tests**

Run: `flutter test test/widget/features/activity/activity_screens_test.dart test/features/activity/roster_output_screen_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/activity/presentation/
git commit -m "refactor(activity): standardize activity cards and resolve selection gesture conflicts"
```

---

### Task 5: Nöbet Matrisi (`MonthlyMatrix`) Mobil & Masaüstü Kart Düzenlemesi

**Files:**
- Modify: `lib/features/matrix/presentation/monthly_matrix_mobile_view.dart`
- Modify: `lib/features/matrix/presentation/monthly_matrix_desktop_view.dart`
- Test: `test/widget/features/matrix/team_duty_calendar_modal_test.dart`

**Changes:**
1. `monthly_matrix_mobile_view.dart` içindeki tim kartlarını `AppCard` yapısına geçirmek.
2. Trailing içindeki `IconButton` takvim butonu ile `ExpansionTile` açılma aksiyonunun dokunma alanlarını izole etmek.
3. İçerideki personel satırlarının köşe ve aralıklarını `AppSpacing` değerleriyle senkronize etmek.

- [ ] **Step 1: Refactor mobile matrix squad expansion card to use `AppCard` with isolated calendar icon**
- [ ] **Step 2: Run matrix tests**

Run: `flutter test test/widget/features/matrix/team_duty_calendar_modal_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add lib/features/matrix/presentation/
git commit -m "refactor(matrix): standardize matrix mobile squad cards and trailing calendar actions"
```

---

### Task 6: Bütüncül Doğrulama ve Git Dağıtım Akışı

**Files:**
- Tüm proje dosyaları
- Verification: `flutter test`
- Verification: `dart analyze`

- [ ] **Step 1: Run complete unit & widget test suite**

Run: `flutter test`
Expected: All 570+ tests PASS (0 failures)

- [ ] **Step 2: Run static analysis**

Run: `dart analyze`
Expected: 0 errors, clean output

- [ ] **Step 3: Auto Git Flow (Rule execution)**
  - Create new branch: `refactor/unified-cards-and-screens-design-system`
  - Commit all changes
  - Push branch to remote
  - Notify user with PR guidance.
