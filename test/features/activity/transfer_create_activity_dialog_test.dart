import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/transfer_personnel_dialog.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/transfer_squad_dialog.dart';

void main() {
  const source = GunlukFaaliyetTableData(
    id: 1,
    faaliyetAdi: 'Kaynak Kart',
    tarih: '2026-08-05',
    olusturanKullanici: 'admin',
    olusturmaTarihi: '2026-08-05',
  );
  const assignment = FaaliyetPersonelAtamaTableData(
    id: 10,
    faaliyetId: 1,
    personelId: 20,
    gorevVeyaIzin: 'GÖREVLİ',
    durum: 'onaylandi',
  );
  const transferTargets = [
    GunlukFaaliyetTableData(
      id: 2,
      faaliyetAdi: 'GÜLÜŞKÜR',
      tarih: '2026-08-05',
      olusturanKullanici: 'admin',
      olusturmaTarihi: '2026-08-05',
    ),
    GunlukFaaliyetTableData(
      id: 3,
      faaliyetAdi: 'HAZIR KITA',
      tarih: '2026-08-05',
      olusturanKullanici: 'admin',
      olusturmaTarihi: '2026-08-05',
    ),
  ];

  Widget subject(
    Widget child, {
    List<GunlukFaaliyetTableData> activities = const [source],
  }) =>
      ProviderScope(
        overrides: [
          userSessionProvider.overrideWith(
            (ref) => const UserSessionState(
              username: 'admin',
              role: UserRole.admin,
            ),
          ),
          filteredActivitiesProvider.overrideWith(
            (ref) => Stream.value(activities),
          ),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('klavye açıkken tim taşı butonu faaliyet adıyla çakışmaz',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      subject(
        Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                await showTransferSquadDialog(
                  context,
                  sourceActivity: source,
                  squadId: 3,
                  squadName: 'K.H',
                );
              },
              child: const Text('Tim taşıma penceresini aç'),
            ),
          ),
        ),
        activities: const [source, ...transferTargets],
      ),
    );

    await tester.tap(find.text('Tim taşıma penceresini aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('squad-transfer-create-activity')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();

    final fieldRect = tester.getRect(
      find.byKey(const Key('squad-transfer-new-activity-name')),
    );
    final confirmRect = tester.getRect(
      find.byKey(const Key('transfer-squad-confirm')),
    );
    expect(
      fieldRect.overlaps(confirmRect),
      isFalse,
      reason: 'Metin alanı $fieldRect ve TAŞI butonu $confirmRect çakışıyor.',
    );
  });

  testWidgets('personel taşıma yeni faaliyet adı girişini açar',
      (tester) async {
    await tester.pumpWidget(
      subject(
        const TransferPersonnelDialog(
          sourceActivity: source,
          assignment: assignment,
          personnelDisplayName: 'Ali Veli',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('başka faaliyet kartı bulunamadı.'),
        findsOneWidget);
    await tester.tap(
      find.byKey(const Key('personnel-transfer-create-activity')),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('personnel-transfer-new-activity-name')),
      findsOneWidget,
    );
    final nameField = tester.widget<TextField>(
      find.byKey(const Key('personnel-transfer-new-activity-name')),
    );
    expect(nameField.decoration?.hintText, isNull);

    var confirm = tester.widget<FilledButton>(
      find.byKey(const Key('personnel-transfer-confirm')),
    );
    expect(confirm.onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('personnel-transfer-new-activity-name')),
      'Yeni Kart',
    );
    await tester.pump();
    confirm = tester.widget<FilledButton>(
      find.byKey(const Key('personnel-transfer-confirm')),
    );
    expect(confirm.onPressed, isNotNull);
  });

  testWidgets('tim taşıma yeni faaliyet adı girişini açar', (tester) async {
    await tester.pumpWidget(
      subject(
        const TransferSquadDialog(
          sourceActivity: source,
          squadId: 3,
          squadName: '3-B Timi',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('squad-transfer-create-activity')));
    await tester.pump();
    expect(
      find.byKey(const Key('squad-transfer-new-activity-name')),
      findsOneWidget,
    );
    final nameField = tester.widget<TextField>(
      find.byKey(const Key('squad-transfer-new-activity-name')),
    );
    expect(nameField.decoration?.hintText, isNull);
    await tester.enterText(
      find.byKey(const Key('squad-transfer-new-activity-name')),
      'Tim Hedef Kartı',
    );
    await tester.pump();
    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('transfer-squad-confirm')),
    );
    expect(confirm.onPressed, isNotNull);
  });
}
