# Single Personnel Transfer Between Activity Cards — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adminlerin bir personeli, aynı gün içindeki bir faaliyet kartından başka bir faaliyet kartına tek dokunuşla, çakışma hatası olmadan taşımasını sağlamak.

**Architecture:**
- Repository katmanına `transferPersonnelBetweenActivities()` eklenir — tek transaction içinde sil + çakışma kontrol + ekle mantığı (mevcut `transferSquadBetweenActivities` ile aynı desen).
- Yeni `TransferPersonnelDialog` widget'ı: aynı günün diğer kartlarını listeler, onay alır.
- Mevcut `assignmentBuilder` closure'una bir "Taşı" icon button eklenir — Düzenle/Sil butonlarıyla aynı satırda.

**Tech Stack:** Flutter · Riverpod · Drift ORM · `flutter_test` · `drift/native.dart` (bellek içi test DB)

---

## Dosya Haritası

| İşlem | Dosya |
|-------|-------|
| MODIFY | `lib/features/activity/data/activity_repository.dart` |
| CREATE | `lib/features/activity/presentation/dialogs/transfer_personnel_dialog.dart` |
| MODIFY | `lib/features/activity/presentation/widgets/activity_detail_sheet.dart` |
| CREATE | `test/features/activity/personnel_transfer_test.dart` |

---

## Task 1: Repository — `transferPersonnelBetweenActivities()`

**Files:**
- Modify: `lib/features/activity/data/activity_repository.dart` (~satır 140, `SquadTransferResult` bloğunun hemen altı)
- Test: `test/features/activity/personnel_transfer_test.dart`

### Neden bu sıra?

Repository saf Dart + Drift — Flutter olmadan test edilebilir. Önce testi yazıp geçirmek, UI'den bağımsız güven verir.

---

- [ ] **Step 1.1 — Test dosyasını oluştur**

`test/features/activity/personnel_transfer_test.dart`:

```dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

void main() {
  late AppDatabase db;
  late ActivityRepository repo;

  const adminSession = UserSessionState(
    username: 'admin',
    role: UserRole.admin,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ActivityRepository(db);
  });

  tearDown(() => db.close());

  // ── helpers ──────────────────────────────────────────────────

  Future<int> addActivity(String date, {String? title}) =>
      db.into(db.gunlukFaaliyetTable).insert(
            GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: title ?? 'Günlük Faaliyet ($date)',
              tarih: date,
              olusturanKullanici: 'admin',
              olusturmaTarihi: '2026-08-03',
            ),
          );

  Future<int> addPersonnel(String name) =>
      db.into(db.personelTable).insert(
            PersonelTableCompanion.insert(
              adSoyad: name,
              rutbe: 'Er',
              birlik: 'K.H',
              kayitTarihi: '2026-08-03',
            ),
          );

  Future<int> addAssignment({
    required int activityId,
    required int personnelId,
    String duty = 'GÖREVLİ',
    String status = AssignmentStatus.onaylandi,
    String? note,
  }) =>
      db.into(db.faaliyetPersonelAtamaTable).insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: activityId,
              personelId: personnelId,
              gorevVeyaIzin: duty,
              durum: status,
              aciklama: Value(note),
            ),
          );

  Future<List<FaaliyetPersonelAtamaTableData>> assignmentsFor(int aid) =>
      (db.select(db.faaliyetPersonelAtamaTable)
            ..where((t) => t.faaliyetId.equals(aid)))
          .get();

  // ── tests ────────────────────────────────────────────────────

  test('taşıma başarılı: personel kaynak karttan çıkar, hedef karta girer',
      () async {
    final p = await addPersonnel('Ali Er');
    final src = await addActivity('2026-08-03', title: 'Sabah');
    final tgt = await addActivity('2026-08-03', title: 'Öğle');
    await addAssignment(
        activityId: src, personnelId: p, duty: 'NÖBETÇİ', note: 'Gece nöbeti');

    final result = await repo.transferPersonnelBetweenActivities(
      assignmentId: (await assignmentsFor(src)).single.id,
      targetActivityId: tgt,
      actor: adminSession,
    );

    expect(result.moved, isTrue);
    expect(result.reason, isNull);
    expect(await assignmentsFor(src), isEmpty);
    final tgtRows = await assignmentsFor(tgt);
    expect(tgtRows.length, 1);
    expect(tgtRows.single.personelId, p);
    expect(tgtRows.single.gorevVeyaIzin, 'NÖBETÇİ');
    expect(tgtRows.single.aciklama, 'Gece nöbeti');
  });

  test('hedefte aynı personel varsa moved:false döner, kaynak değişmez',
      () async {
    final p = await addPersonnel('Veli Er');
    final src = await addActivity('2026-08-03', title: 'Sabah');
    final tgt = await addActivity('2026-08-03', title: 'Öğle');
    await addAssignment(activityId: src, personnelId: p);
    // p zaten hedefte
    await addAssignment(activityId: tgt, personnelId: p);

    final id = (await assignmentsFor(src)).single.id;
    final result = await repo.transferPersonnelBetweenActivities(
      assignmentId: id,
      targetActivityId: tgt,
      actor: adminSession,
    );

    expect(result.moved, isFalse);
    expect(result.reason, contains('zaten'));
    expect(await assignmentsFor(src), hasLength(1));
  });

  test('onaylı durum korunur (aynı tarihte başka çakışma yok)', () async {
    final p = await addPersonnel('Ahmet Er');
    final src = await addActivity('2026-08-03');
    final tgt = await addActivity('2026-08-03', title: 'Akşam');
    await addAssignment(
        activityId: src, personnelId: p, status: AssignmentStatus.onaylandi);

    final id = (await assignmentsFor(src)).single.id;
    await repo.transferPersonnelBetweenActivities(
      assignmentId: id,
      targetActivityId: tgt,
      actor: adminSession,
    );

    final row = (await assignmentsFor(tgt)).single;
    expect(row.durum, AssignmentStatus.onaylandi);
  });

  test('varolan atama bulunamazsa ArgumentError', () async {
    final tgt = await addActivity('2026-08-03');
    await expectLater(
      repo.transferPersonnelBetweenActivities(
        assignmentId: 99999,
        targetActivityId: tgt,
        actor: adminSession,
      ),
      throwsArgumentError,
    );
  });

  test('hedef faaliyet bulunamazsa ArgumentError, kaynak değişmez', () async {
    final p = await addPersonnel('Mehmet Er');
    final src = await addActivity('2026-08-03');
    await addAssignment(activityId: src, personnelId: p);
    final id = (await assignmentsFor(src)).single.id;

    await expectLater(
      repo.transferPersonnelBetweenActivities(
        assignmentId: id,
        targetActivityId: 99999,
        actor: adminSession,
      ),
      throwsArgumentError,
    );
    expect(await assignmentsFor(src), hasLength(1));
  });

  test('admin değilse AuthorizationException', () async {
    final p = await addPersonnel('Kemal Er');
    final src = await addActivity('2026-08-03');
    final tgt = await addActivity('2026-08-03', title: 'Hedef');
    await addAssignment(activityId: src, personnelId: p);
    final id = (await assignmentsFor(src)).single.id;

    const nonAdmin = UserSessionState(
      username: 'komutan',
      role: UserRole.teamCommander,
      timId: 1,
    );

    expect(
      () => repo.transferPersonnelBetweenActivities(
        assignmentId: id,
        targetActivityId: tgt,
        actor: nonAdmin,
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('yöneticiler tarafından'),
        ),
      ),
    );
  });
}
```

- [ ] **Step 1.2 — Testlerin FAIL ettiğini doğrula**

```powershell
flutter test test/features/activity/personnel_transfer_test.dart --reporter=compact
```

Beklenen: derleme hatası — `transferPersonnelBetweenActivities` ve `PersonnelTransferResult` tanımlı değil.

- [ ] **Step 1.3 — `PersonnelTransferResult` sınıfını ekle**

`lib/features/activity/data/activity_repository.dart` içinde `SquadTransferResult` bloğunun (satır ~122–140) hemen altına:

```dart
/// Result returned by [ActivityRepository.transferPersonnelBetweenActivities].
class PersonnelTransferResult {
  const PersonnelTransferResult({required this.moved, this.reason});

  /// Taşıma başarıyla gerçekleşti mi?
  final bool moved;

  /// moved == false ise neden taşınamadığı (kullanıcıya gösterilecek mesaj).
  final String? reason;
}
```

- [ ] **Step 1.4 — `transferPersonnelBetweenActivities()` metodunu ekle**

`ActivityRepository` sınıfı içinde `transferSquadBetweenActivities` metodunun hemen altına (satır ~1370):

```dart
/// Tek bir personel atamasını (assignmentId) kaynak faaliyet kartından
/// [targetActivityId] numaralı karta atomik olarak taşır.
///
/// İşlem adımları (tek transaction):
///   1. [assignmentId]'yi doğrula — yoksa [ArgumentError].
///   2. [targetActivityId]'yi doğrula — yoksa [ArgumentError].
///   3. Hedefte aynı personel varsa [PersonnelTransferResult(moved: false)] döner.
///   4. Çakışma kontrolü (ConflictChecker) — kaynak atamanın ID'si hariç tutulur.
///   5. Kaynak atamayı siler, hedef karta yeni durum ile ekler.
Future<PersonnelTransferResult> transferPersonnelBetweenActivities({
  required int assignmentId,
  required int targetActivityId,
  required UserSessionState actor,
}) {
  _requireAdmin(actor);
  return db.transaction(() async {
    // 1. Kaynak atamayı yükle
    final assignment = await (db.select(db.faaliyetPersonelAtamaTable)
          ..where((tbl) => tbl.id.equals(assignmentId)))
        .getSingleOrNull();
    if (assignment == null) {
      throw ArgumentError('Atama bulunamadı: $assignmentId');
    }

    // 2. Hedef faaliyeti yükle
    final target = await (db.select(db.gunlukFaaliyetTable)
          ..where((tbl) => tbl.id.equals(targetActivityId)))
        .getSingleOrNull();
    if (target == null) {
      throw ArgumentError('Hedef faaliyet bulunamadı: $targetActivityId');
    }

    // 3. Hedefte zaten var mı?
    final alreadyInTarget = await (db.select(db.faaliyetPersonelAtamaTable)
          ..where(
            (tbl) =>
                tbl.faaliyetId.equals(targetActivityId) &
                tbl.personelId.equals(assignment.personelId),
          ))
        .getSingleOrNull();
    if (alreadyInTarget != null) {
      return const PersonnelTransferResult(
        moved: false,
        reason: 'Bu personel zaten hedef faaliyette mevcut.',
      );
    }

    // 4. Çakışma kontrolü (kaynak atama dışlanır → kendi kendini bloklamamak için)
    final reports = await _loadDomainReports();
    final existingAssignments = await _loadExistingAssignments();
    final status = ConflictChecker.evaluateAssignmentStatus(
      personelId: assignment.personelId,
      targetDate: target.tarih,
      targetDuty: assignment.gorevVeyaIzin,
      reports: reports,
      existingAssignments: existingAssignments,
      excludeAssignmentId: assignment.id,
    );

    // 5. Sil & ekle
    await (db.delete(db.faaliyetPersonelAtamaTable)
          ..where((tbl) => tbl.id.equals(assignment.id)))
        .go();

    await db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: targetActivityId,
            personelId: assignment.personelId,
            gorevVeyaIzin: assignment.gorevVeyaIzin,
            durum: status,
            aciklama: Value(assignment.aciklama),
          ),
        );

    return const PersonnelTransferResult(moved: true);
  });
}
```

- [ ] **Step 1.5 — Testlerin PASS ettiğini doğrula**

```powershell
flutter test test/features/activity/personnel_transfer_test.dart --reporter=compact
```

Beklenen: `+6: All tests passed!`

- [ ] **Step 1.6 — Commit**

```powershell
git add lib/features/activity/data/activity_repository.dart test/features/activity/personnel_transfer_test.dart
git commit -m "feat(repo): add transferPersonnelBetweenActivities atomic method"
```

---

## Task 2: Dialog — `TransferPersonnelDialog`

**Files:**
- Create: `lib/features/activity/presentation/dialogs/transfer_personnel_dialog.dart`

`TransferSquadDialog` ile aynı iskelet — tek fark: başlıkta personel adı gösterilir, `transferPersonnelBetweenActivities()` çağrılır.

- [ ] **Step 2.1 — Dosyayı oluştur**

`lib/features/activity/presentation/dialogs/transfer_personnel_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/core/theme/app_theme.dart';

/// Açılır diyalog: [assignment] sahibi personeli, [sourceActivity] ile
/// aynı tarihteki başka bir faaliyet kartına taşır.
///
/// `true` → başarılı taşıma, `false/null` → iptal veya başarısız.
Future<bool?> showTransferPersonnelDialog(
  BuildContext context, {
  required GunlukFaaliyetTableData sourceActivity,
  required FaaliyetPersonelAtamaTableData assignment,
  required String personnelDisplayName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => TransferPersonnelDialog(
      sourceActivity: sourceActivity,
      assignment: assignment,
      personnelDisplayName: personnelDisplayName,
    ),
  );
}

class TransferPersonnelDialog extends ConsumerStatefulWidget {
  const TransferPersonnelDialog({
    required this.sourceActivity,
    required this.assignment,
    required this.personnelDisplayName,
    super.key,
  });

  final GunlukFaaliyetTableData sourceActivity;
  final FaaliyetPersonelAtamaTableData assignment;
  final String personnelDisplayName;

  @override
  ConsumerState<TransferPersonnelDialog> createState() =>
      _TransferPersonnelDialogState();
}

class _TransferPersonnelDialogState
    extends ConsumerState<TransferPersonnelDialog> {
  int? _selectedTargetId;
  bool _isTransferring = false;

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(filteredActivitiesProvider);
    final session = ref.watch(userSessionProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.person_pin_rounded,
              color: context.accentOrOlive, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personel Taşı',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                Text(
                  widget.personnelDisplayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_upward_rounded,
                      size: 14, color: context.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kaynak: ${widget.sourceActivity.faaliyetAdi}',
                      style: TextStyle(
                          fontSize: 12, color: context.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hedef Faaliyet Kartını Seçin:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            activitiesAsync.when(
              data: (activities) {
                final sameDay = activities
                    .where((a) =>
                        a.tarih == widget.sourceActivity.tarih &&
                        a.id != widget.sourceActivity.id)
                    .toList();

                if (sameDay.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: context.pendingColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${widget.sourceActivity.tarih} tarihinde '
                            'başka faaliyet kartı bulunamadı.',
                            style: TextStyle(
                              color: context.pendingColor,
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: SingleChildScrollView(
                    child: Column(
                      children: sameDay.map((activity) {
                        final isSelected = _selectedTargetId == activity.id;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.accentOrOlive.withValues(alpha: 0.10)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? context.accentOrOlive
                                  : context.colorScheme.outlineVariant
                                      .withValues(alpha: 0.4),
                            ),
                          ),
                          child: RadioListTile<int>(
                            key: Key('personnel-transfer-target-${activity.id}'),
                            dense: true,
                            value: activity.id,
                            groupValue: _selectedTargetId,
                            activeColor: context.accentOrOlive,
                            title: Text(
                              activity.faaliyetAdi,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            onChanged: (val) =>
                                setState(() => _selectedTargetId = val),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Text(
                'Hata: $err',
                style: TextStyle(color: context.rejectedColor),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isTransferring
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('IPTAL'),
        ),
        FilledButton.icon(
          key: const Key('personnel-transfer-confirm'),
          icon: _isTransferring
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.person_pin_rounded, size: 18),
          label: const Text('TASI'),
          onPressed: (_selectedTargetId == null || _isTransferring)
              ? null
              : () async {
                  setState(() => _isTransferring = true);
                  try {
                    final result = await ref
                        .read(activityRepositoryProvider)
                        .transferPersonnelBetweenActivities(
                          assignmentId: widget.assignment.id,
                          targetActivityId: _selectedTargetId!,
                          actor: session!,
                        );

                    if (!mounted) return;
                    Navigator.of(context).pop(result.moved);

                    if (result.moved && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${widget.personnelDisplayName} basariyla tasindi.',
                          ),
                          backgroundColor: context.approvedColor,
                        ),
                      );
                    } else if (!result.moved && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.reason ?? 'Tasima yapilamadi.'),
                          backgroundColor: context.pendingColor,
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Tasima hatasi: $e'),
                        backgroundColor: context.rejectedColor,
                      ),
                    );
                    Navigator.of(context).pop(false);
                  } finally {
                    if (mounted) setState(() => _isTransferring = false);
                  }
                },
        ),
      ],
    );
  }
}
```

- [ ] **Step 2.2 — Derleme kontrolü**

```powershell
flutter analyze lib/features/activity/presentation/dialogs/transfer_personnel_dialog.dart
```

Beklenen: `No issues found!`

- [ ] **Step 2.3 — Commit**

```powershell
git add lib/features/activity/presentation/dialogs/transfer_personnel_dialog.dart
git commit -m "feat(ui): add TransferPersonnelDialog for single-personnel transfer"
```

---

## Task 3: UI Baglamasi — Personel Satirina "Tasi" Butonu

**Files:**
- Modify: `lib/features/activity/presentation/widgets/activity_detail_sheet.dart`

### Ne degisecek?

Mevcut durumda her personel satirinda sagda:
```
[Gorev Rozeti]  [Duzenle pencil]  [Sil trash]
```

Hedef:
```
[Gorev Rozeti]  [Tasi swap_horiz]  [Duzenle pencil]  [Sil trash]
```

"Tasi" butonu yalnizca admin ise gorunur.

---

- [ ] **Step 3.1 — Import ekle**

`activity_detail_sheet.dart` import blogu icinde (satir ~13, `edit_assignment_dialog.dart` importununun hemen altina):

```dart
import 'package:personelapp2/features/activity/presentation/dialogs/transfer_personnel_dialog.dart';
```

- [ ] **Step 3.2 — "Tasi" butonunu ekle**

`assignmentBuilder` closure icinde (satir ~476), `if (isAdmin)` ile baslayan Duzenle butonunun hemen onesine:

```dart
if (isAdmin)
  IconButton(
    key: Key('personnel-transfer-btn-${atama.id}'),
    icon: Icon(
      Icons.swap_horiz_rounded,
      color: context.accentOrOlive,
      size: 18,
    ),
    padding: const EdgeInsets.all(4),
    constraints: const BoxConstraints(),
    tooltip: '$displayName kisisini baska karta tasi',
    onPressed: () async {
      await showTransferPersonnelDialog(
        context,
        sourceActivity: activity,
        assignment: atama,
        personnelDisplayName: displayName,
      );
    },
  ),
```

- [ ] **Step 3.3 — Tum activity testleri gectiğini dogrula**

```powershell
flutter test test/features/activity/ --reporter=compact
```

Beklenen: `All tests passed!` (mevcut 51 + 6 yeni = toplam 57)

- [ ] **Step 3.4 — Commit**

```powershell
git add lib/features/activity/presentation/widgets/activity_detail_sheet.dart
git commit -m "feat(ui): wire transfer-personnel button into assignment row"
```

---

## Task 4: Tam Entegrasyon Testi ve Push

- [ ] **Step 4.1 — Tum test suite**

```powershell
flutter test --reporter=compact
```

Beklenen: hic kirmizi test yok.

- [ ] **Step 4.2 — Statik analiz**

```powershell
flutter analyze
```

Beklenen: `No issues found!`

- [ ] **Step 4.3 — Push**

```powershell
git push origin feat/squad-transfer-between-activities
```

> Not: Yeni ozellik ayni branch'e ekleniyor. Takim tercihe gore ayri branch acabilir.

---

## Kapsam Kontrol Listesi (Self-Review)

| Gereksinim | Karsiligi |
|---|---|
| Tek personel tasima | Task 1 + Task 3 |
| Catisma hatasi olmadan | `ConflictChecker.evaluateAssignmentStatus` + `excludeAssignmentId` |
| Hedefte zaten varsa bilgi mesaji | `PersonnelTransferResult(moved: false, reason: ...)` |
| Yalnizca admin | `_requireAdmin(actor)` + `if (isAdmin)` kosulu |
| UI geri bildirimi (snackbar) | Dialog icindeki catch/then bloklari |
| Mevcut testler bozulmuyor | Task 4 step 4.1 |
| Commit sikligi | Her task sonunda commit |

**Placeholder taramasi:** Hicbir TBD / TODO / "implement later" icermiyor. Her step'te tam kod var. OK

**Tip tutarliligi:**
- `PersonnelTransferResult.moved: bool` — Task 1 step 1.3'te tanimlandi, Task 2'de `result.moved` ile kullanildi. OK
- `PersonnelTransferResult.reason: String?` — Task 1 step 1.3'te tanimlandi, Task 2'de `result.reason ?? '...'` ile kullanildi. OK
- `showTransferPersonnelDialog(context, sourceActivity:, assignment:, personnelDisplayName:)` — Task 2 step 2.1'de tanimlandi, Task 3 step 3.2'de ayni parametre adlariyla cagrildi. OK
