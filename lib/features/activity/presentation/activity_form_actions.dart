part of 'activity_form_screen.dart';

extension _ActivityFormActions on _ActivityFormScreenState {
  Future<void> _submitActivity() async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_draft.selectedDate);
    final name = _draft.activityName.trim();
    final userSession = ref.read(userSessionProvider);
    if (userSession == null) {
      AppNotifications.error('Oturum doğrulanamadı.');
      return;
    }

    if (name.isEmpty) {
      _updateState(() => _showNameError = true);
      return;
    }

    final payload = _draft.resolvedDuties.entries.map((
      e,
    ) {
      final note = _draft.notes[e.key]?.trim();
      return PersonnelAssignmentInput(
        personnelId: e.key,
        duty: e.value,
        note: (note != null && note.isNotEmpty) ? note : null,
      );
    }).toList();

    if (payload.isEmpty) {
      AppNotifications.warning(
        'Lütfen en az bir personel için görev seçiniz.',
      );
      return;
    }

    final repo = ref.read(activityRepositoryProvider);
    try {
      final preview = await repo.previewActivityAssignments(
        tarih: dateStr,
        personnelAssignments: payload,
        actor: userSession,
      );
      if (!mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ActivityAssignmentPreviewScreen(
            activityName: name,
            date: _draft.selectedDate,
            preview: preview,
            requiresAdminApproval: !userSession.isAdmin,
            onConfirm: () => _persistActivity(
              name: name,
              dateStr: dateStr,
              payload: payload,
              userSession: userSession,
            ),
          ),
        ),
      );
      if (saved == true && mounted) {
        _updateState(() => _allowPop = true);
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      AppNotifications.error('Önizleme hazırlanamadı: $error');
    }
  }

  Future<bool> _persistActivity({
    required String name,
    required String dateStr,
    required List<PersonnelAssignmentInput> payload,
    required UserSessionState userSession,
  }) async {
    final repo = ref.read(activityRepositoryProvider);
    final isCommander = !userSession.isAdmin;
    final matches = await repo.findMatchingActivities(
      faaliyetAdi: name,
      tarih: dateStr,
      personnelAssignments: payload,
    );
    if (!mounted) return false;

    ActivityMergeResult? mergeResult;
    if (matches.isNotEmpty) {
      final choice = await ExistingActivityDialog.show(context, matches);
      if (choice == null || !mounted) return false;
      if (choice.action == ExistingActivityAction.merge) {
        mergeResult = await repo.mergeAssignmentsIntoActivity(
          activityId: choice.activityId!,
          personnelAssignments: payload,
          updateDifferentAssignments: choice.updateDifferentAssignments,
          actor: userSession,
        );
      } else {
        await repo.createActivityWithAssignments(
          faaliyetAdi: name,
          tarih: dateStr,
          olusturanKullanici: userSession.username,
          personnelAssignments: payload,
          actor: userSession,
        );
      }
    } else {
      await repo.createActivityWithAssignments(
        faaliyetAdi: name,
        tarih: dateStr,
        olusturanKullanici: userSession.username,
        personnelAssignments: payload,
        actor: userSession,
      );
    }

    if (mounted) {
      final msg = mergeResult != null
          ? '${mergeResult.addedCount} personel eklendi, '
              '${mergeResult.updatedCount} güncellendi, '
              '${mergeResult.skippedCount} kayıt korundu.'
          : isCommander
              ? 'Faaliyet Kaydedildi! Admin onayına gönderildi.'
              : 'Faaliyet Çizelgesi Kaydedildi & Çakışma Denetimi Yapıldı!';
      AppNotifications.approvalResult(
        msg,
        pendingApproval: isCommander,
      );
      return true;
    }
    return false;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      _updateState(() => _draft.setDate(picked));
    }
  }

  Future<void> _showBulkImportSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Toplu metin içe aktar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Birden fazla faaliyet ve personel kaydını panodaki '
                'metinden hızlıca oluşturun.',
                style: context.textStyleSecondary,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  icon: const Icon(Icons.content_paste_go_rounded),
                  label: const Text('Metni yapıştır'),
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final db = ref.read(databaseProvider);
                    final activityRepo = ref.read(activityRepositoryProvider);
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => BulkImportDialog(
                        database: db,
                        activityRepository: activityRepo,
                      ),
                    );
                    if (result == true && mounted) {
                      ref.invalidate(activityRepositoryProvider);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
