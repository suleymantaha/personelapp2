// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Nizam';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonDismiss => 'Vazgeç';

  @override
  String get commonReset => 'Sıfırla';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonBack => 'Geri';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonEdit => 'Düzenle';

  @override
  String get commonAdd => 'Ekle';

  @override
  String get commonSelect => 'Seç';

  @override
  String get commonSearch => 'Ara...';

  @override
  String get commonFilter => 'Filtrele';

  @override
  String get commonClear => 'Temizle';

  @override
  String get commonSuccess => 'Başarılı';

  @override
  String get commonError => 'Hata';

  @override
  String get commonWarning => 'Uyarı';

  @override
  String get commonInfo => 'Bilgi';

  @override
  String get commonConfirm => 'Onayla';

  @override
  String get commonYes => 'Evet';

  @override
  String get commonNo => 'Hayır';

  @override
  String get commonOk => 'Tamam';

  @override
  String get commonAll => 'Tümü';

  @override
  String get commonRequired => 'Zorunlu alan';

  @override
  String get commonLoading => 'Yükleniyor...';

  @override
  String get commonNoData => 'Kayıt bulunamadı';

  @override
  String get commonActivity => 'Faaliyet';

  @override
  String get commonApprove => 'Onayla';

  @override
  String get commonReject => 'Reddet';

  @override
  String get commonUnauthorized => 'Bu sayfaya erişim yetkiniz bulunmuyor.';

  @override
  String get activitySelectDutyTitle => 'Görev veya İzin Seçin';

  @override
  String get activityCommonDuty => 'Ortak Görev';

  @override
  String get activityPersonalDuty => 'Kişisel Görev';

  @override
  String get activitySelectPersonalDuty => 'Özel Görev Seç';

  @override
  String get activityDutyChangeTitle => 'Görev / Durum Değiştir';

  @override
  String get activityDutyChangeSubtitle =>
      'Seçilen personel için geçerli görev veya izin durumunu güncelleyin.';

  @override
  String get activityUpdateSuccess => 'Görev başarıyla güncellendi';

  @override
  String get activityScheduleTitle => 'Faaliyet Çizelgesi';

  @override
  String get activityAddPersonnel => 'Personel Ekle';

  @override
  String get activityArchive => 'Faaliyet Arşivi';

  @override
  String get activityDate => 'Tarih';

  @override
  String get activityPersonnelCount => 'Personel Sayısı';

  @override
  String get activityDuty => 'Görev';

  @override
  String get activityShift => 'Vardiya';

  @override
  String get activityNotes => 'Notlar';

  @override
  String get activitySelectDutyHint => 'Bir görev türü seçiniz';

  @override
  String get activitySearchDutyHint => 'Görev ara...';

  @override
  String get activityLeaveType => 'İzin Türü';

  @override
  String get activityDutyChange => 'Görev Değişikliği';

  @override
  String get activityDutyOrLeaveType => 'Görev / İzin Türü';

  @override
  String get activityDutyNoteOptional => 'Açıklama / Not (İsteğe Bağlı)';

  @override
  String get activityDutyNoteHint => 'Örn: Gece nöbeti, özel devriye vb.';

  @override
  String get activityAssignCommonDuty => 'Ortak Görev';

  @override
  String get activityAssignDutyToSelected => 'Seçilen personele görev ata';

  @override
  String get activitySelectCommonDuty => 'Ortak görev seç';

  @override
  String get activityUseCommonDuty => 'Ortak görevi kullan';

  @override
  String activitySquadDutyAssignTitle(String squadName) {
    return '$squadName timine görev ata';
  }

  @override
  String activityPersonnelDutyTitle(String name) {
    return '$name için görev';
  }

  @override
  String activityPersonnelNoteTitle(String name) {
    return '$name için not';
  }

  @override
  String get activitySelectDifferentDuty => 'Farklı görev seç';

  @override
  String get activityDutyNotSelected => 'Görev seçilmedi';

  @override
  String get activityAddOrEditNote => 'Not ekle veya düzenle';

  @override
  String get activityNoNote => 'Not yok';

  @override
  String get activityOptionalNoteHint => 'İsteğe bağlı not';

  @override
  String get activityPreviewHint =>
      'Bilgileri kontrol ettikten sonra görevlendirme önizlemesine geçebilirsiniz.';

  @override
  String activitySelectedPersonnelCount(int count) {
    return '$count personel seçildi';
  }

  @override
  String get activityChange => 'Değiştir';

  @override
  String get activityCommonDutyHelper => 'Tüm seçilen personele uygular';

  @override
  String get activityPersonalDutyLabel => 'Kişiye özel görev';

  @override
  String get activityOutsideSquad => 'Tim Dışı';

  @override
  String get activityAdminAddNotice =>
      'Seçilen personel bu faaliyete eklenecek.';

  @override
  String get activityUserAddNotice =>
      'Personel eklendikten sonra admin onayına gönderilecek.';

  @override
  String get activityCloseNote => 'Notu kapat';

  @override
  String get activityAddNote => 'Not ekle';

  @override
  String get activityEditNote => 'Notu düzenle';

  @override
  String get activityGeneralDutyNoteHint => 'Görevle ilgili not';

  @override
  String get personnelManagementTitle => 'Personel Yönetimi';

  @override
  String get personnelListTitle => 'Personel Listesi';

  @override
  String get personnelAddTitle => 'Yeni Personel Ekle';

  @override
  String get personnelEditTitle => 'Personeli Düzenle';

  @override
  String get personnelName => 'Ad';

  @override
  String get personnelSurname => 'Soyad';

  @override
  String get personnelFullName => 'Ad Soyad';

  @override
  String get personnelRank => 'Rütbe';

  @override
  String get personnelBranch => 'Sınıf / Kuvvet';

  @override
  String get personnelPhone => 'Telefon';

  @override
  String get personnelRole => 'Rol';

  @override
  String get personnelStatus => 'Durum';

  @override
  String get personnelActive => 'Aktif';

  @override
  String get personnelInactive => 'Pasif';

  @override
  String get personnelWarningEnterName => 'Lütfen ad soyad giriniz.';

  @override
  String get personnelWarningSelectRank => 'Lütfen rütbe seçiniz.';

  @override
  String personnelErrorSaveFailed(String error) {
    return 'Personel kaydedilemedi: $error';
  }

  @override
  String personnelEditNamed(String name) {
    return '$name - Düzenle';
  }

  @override
  String get personnelSelectRankHint => 'Rütbe Seçiniz';

  @override
  String get personnelCustomRankLabel => 'Özel Rütbe Metni';

  @override
  String get personnelCustomRankHint => 'Örn: J.Uz.Çvş. (Kıd.Kd.Çvş)';

  @override
  String get personnelSquadLabel => 'Bağlı Olduğu Tim';

  @override
  String get personnelIndependentSquad => 'Bağımsız / Tim Dışı';

  @override
  String get personnelUnitLabel => 'Birlik / Bölük';

  @override
  String get personnelSelectUnitTooltip => 'Birlik seç';

  @override
  String get personnelSelectUnitTitle => 'Birlik seç';

  @override
  String get personnelFrequentlyUsedUnits => 'Sık kullanılan birlikler';

  @override
  String get personnelSearchHint => 'Personel ad, rütbe veya birlik ara...';

  @override
  String get personnelSquadFilter => 'Tim Filtresi';

  @override
  String get personnelNewSquad => 'Yeni Tim';

  @override
  String get personnelAllPersonnel => 'Tüm Personel';

  @override
  String get personnelUnassignedOrOffRoster => 'Boşta / Kadro Dışı';

  @override
  String personnelAuthorizedSquad(String squadName) {
    return 'Yetkili Olduğunuz Tim: $squadName';
  }

  @override
  String get personnelAllUnit => 'Tüm Birlik';

  @override
  String get personnelNoSubscription => 'Abonelik Yok';

  @override
  String get personnelNoCriteriaMatches =>
      'Kriterlere uygun personel bulunamadı.';

  @override
  String get commonSaving => 'Kaydediliyor…';

  @override
  String get commonRetry => 'TEKRAR DENE';

  @override
  String get authLoginTitle => 'Giriş Yap';

  @override
  String get authUsername => 'Kullanıcı Adı';

  @override
  String get authPassword => 'Şifre';

  @override
  String get authLoginButton => 'GİRİŞ YAP';

  @override
  String get authLogoutButton => 'Çıkış Yap';

  @override
  String get authSessionExpired => 'Oturum süresi doldu';

  @override
  String get authInvalidCredentials => 'Geçersiz kullanıcı adı veya parola!';

  @override
  String get authMissionManagement => 'Görev Yönetimi';

  @override
  String get authFirstLoginTitle => 'İlk Giriş: Parola Belirleyin';

  @override
  String authFirstLoginSubtitle(String username) {
    return 'Sayın $username, hesabınız için yeni bir parola belirleyiniz.';
  }

  @override
  String get authNewPassword => 'Yeni Parola';

  @override
  String get authNewPasswordRepeat => 'Yeni Parola (Tekrar)';

  @override
  String get authPasswordsDoNotMatch => 'Parolalar eşleşmiyor!';

  @override
  String get authSavePasswordAndLogin => 'PAROLAYI KAYDET VE GİRİŞ YAP';

  @override
  String get dashboardTitle => 'Ana Sayfa';

  @override
  String get dashboardQuickActions => 'Hızlı İşlemler';

  @override
  String get dashboardStatistics => 'İstatistikler';

  @override
  String get dashboardRecentActivities => 'Son Faaliyetler';

  @override
  String get dashboardActivitySchedule => 'Faaliyet Çizelgesi';

  @override
  String get dashboardDailyDutyEntry => 'Günlük görev gir';

  @override
  String get dashboardMonthlyMatrix => 'Aylık Matris';

  @override
  String get dashboardExcelDistribution => 'Excel / Dağıtım';

  @override
  String get dashboardTemgundrapSubtitle => 'Çizelge oluştur ve yönet';

  @override
  String get dashboardPersonnelAndSquad => 'Personel & Tim';

  @override
  String get dashboardRegisterAndAuth => 'Kayıt ve Yetki';

  @override
  String get dashboardRosterStatus => 'Kadro Durumu';

  @override
  String get dashboardBulkImportText => 'Metinden Toplu Aktar';

  @override
  String get dashboardWhatsAppListUpload => 'WhatsApp / Liste Yükle';

  @override
  String get dashboardBulkImportImage => 'Görselden Toplu Aktar';

  @override
  String get dashboardOcrNameMatch => 'OCR ile isim eşleştir';

  @override
  String get dashboardOcrPlatformWarning =>
      'Görselden aktarım Android ve iOS cihazlarda kullanılabilir.';

  @override
  String get dashboardThemeMilitaryLight => 'Askeri Haki (Açık)';

  @override
  String get dashboardThemeMilitaryDark => 'Taktik Gece (Koyu)';

  @override
  String get dashboardThemeSystem => 'Sistem Teması';

  @override
  String get dashboardSettingsTitle => 'Uygulama Ayarları';

  @override
  String get dashboardThemeMode => 'Tema Modu';

  @override
  String get dashboardPendingAssignments => 'Onay Bekleyen Görevler';

  @override
  String dashboardPendingAssignmentsDesc(int count) {
    return '$count personelin görev değişikliği onay bekliyor';
  }

  @override
  String get dashboardOperations => 'İşlemler';

  @override
  String dashboardPendingConflictsNotice(int count) {
    return '$count Görevlendirmede Çakışma / Rapor Var!';
  }

  @override
  String get dashboardPendingTapToReview =>
      'Onaylamak veya reddetmek için dokunun.';

  @override
  String get dashboardSearchAndReview => 'Arama ve İnceleme';

  @override
  String get settingsChangePassword => 'Şifremi Değiştir';

  @override
  String get settingsNewPassword => 'Yeni Şifreniz';

  @override
  String get settingsPasswordUpdated => 'Şifreniz başarıyla güncellendi!';

  @override
  String settingsUserAccount(String username) {
    return 'Hesap: $username';
  }

  @override
  String get settingsRoleAdmin => 'Rol: Birlik Yöneticisi (Admin)';

  @override
  String get settingsRoleCommander => 'Rol: Tim Komutanı';

  @override
  String get settingsAppTheme => 'Uygulama Teması';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsFullBackup => 'Tam Yedekleme';

  @override
  String get settingsFullBackupSubtitle =>
      'Tüm uygulama verilerini cihazda sakla veya geri yükle';

  @override
  String get settingsUpdate => 'GÜNCELLE';

  @override
  String get matrixTitle => 'Matris ve Çizelge';

  @override
  String get reportTitle => 'Raporlar';

  @override
  String get rosterOutputTitle => 'Çıktı Hazırla';

  @override
  String get rosterSelectCardsHint =>
      'Yazdırılacak kartları seçin. Önceki gün kartları listenin sonunda yer alır. Aynı kişi bir kez yazılır.';

  @override
  String get rosterReload => 'Yeniden yükle';

  @override
  String rosterIncludedItemsCount(int count) {
    return 'Çıktıya Eklenecekler ($count)';
  }

  @override
  String get rosterReorderHint =>
      'Sırayı tutamaçtan sürükleyerek değiştirebilirsiniz.';

  @override
  String get rosterSameDayOutputOrder => 'Aynı Gün — Çıktı Sırası';

  @override
  String get rosterPreviousDayOutputOrder => 'Önceki Gün — Çıktı Sırası';

  @override
  String get rosterSameDayCards => 'Aynı Günün Kartları';

  @override
  String get rosterPreviousDayCards => 'Önceki Günün Kartları';

  @override
  String get rosterNoCardsForDay => 'Bu güne ait kart bulunamadı.';

  @override
  String get rosterAllCardsAdded => 'Bu güne ait tüm kartlar çıktıya eklendi.';

  @override
  String get rosterPreparing => 'Hazırlanıyor…';

  @override
  String rosterPreviewWithCount(int count) {
    return 'Önizle ($count)';
  }

  @override
  String get rosterNoApprovedPersonnel =>
      'Seçilen kartlarda dışa aktarılacak onaylı personel bulunamadı.';

  @override
  String get activityArchiveTitle => 'Faaliyet Arşivi';

  @override
  String get activityArchiveTeamTitle => 'Tim Faaliyet Arşivi';

  @override
  String activityArchiveSelectedCount(int count) {
    return '$count faaliyet seçildi';
  }

  @override
  String get activityArchiveCloseSelection => 'Seçimi Kapat';

  @override
  String get activityArchiveExportSelectedTooltip => 'Seçilenleri Dışa Aktar';

  @override
  String get activityArchiveSelectButton => 'Seç';

  @override
  String get activityArchiveMenuTooltip => 'Arşiv işlemleri';

  @override
  String get activityArchiveMenuHeader => 'Arşiv İşlemleri';

  @override
  String get activityArchiveMenuSubtitle => 'Görünüm ve arşiv araçları';

  @override
  String get activityArchivePrepareOutputTitle => 'Çıktı Hazırla';

  @override
  String get activityArchivePrepareOutputSubtitle =>
      'Kartları seç, sırala ve imzalı çıktı al';

  @override
  String get activityArchiveExportPrintTitle => 'Dışa Aktar / Yazdır';

  @override
  String get activityArchiveExportPrintSubtitle =>
      'Görüntülenen günü paylaş veya yazdır';

  @override
  String get activityArchiveSelectOptionTitle => 'Faaliyet seç';

  @override
  String get activityArchiveSelectOptionSubtitle =>
      'Birden fazla kayıt üzerinde çalış';

  @override
  String get activityArchiveFinishReorder => 'Sıralamayı bitir';

  @override
  String get activityArchiveMoveCards => 'Kartları taşı';

  @override
  String get activityArchiveExitReorderSubtitle => 'Sürükleme modundan çık';

  @override
  String get activityArchiveMoveCardsSubtitle =>
      'Kartları sürükleyerek yeniden sırala';

  @override
  String get activityArchiveResetOrder => 'Sıralamayı sıfırla';

  @override
  String get activityArchiveResetOrderSubtitle => 'Varsayılan sıralamaya dön';

  @override
  String get activityArchiveReturnToday => 'Bugüne dön';

  @override
  String get activityArchiveReturnTodaySubtitle => 'Güncel faaliyetleri göster';

  @override
  String get activityArchiveAuditTitle => 'Çakışmaları denetle';

  @override
  String get activityArchiveAuditSubtitle =>
      'Personel görevlendirmelerini kontrol et';

  @override
  String get activityArchiveFilterByDate => 'Tarihe göre süz';

  @override
  String get activityArchiveFilterByDateSubtitle =>
      'Belirli bir günün arşivini aç';

  @override
  String activityArchiveNoRecordsFound(String date) {
    return '$date tarihine ait faaliyet kaydı bulunamadı.';
  }

  @override
  String get activityArchiveReorderHint =>
      'Kartları tutamaçtan sürükleyerek taşıyın. Sıralama bu güne kaydedilir.';

  @override
  String get activityArchiveConflictAuditTitle =>
      'Geçmiş Kayıt Çakışma Denetimi';

  @override
  String get activityArchiveConflictAuditNone =>
      'Çakışan geçmiş kayıt bulunamadı.';

  @override
  String get activityArchiveConflictAuditReadOnly =>
      'Bu liste salt okunurdur; hiçbir kayıt silinmedi.';

  @override
  String get activityArchiveSaveOrderFailed => 'Sıralama kaydedilemedi.';

  @override
  String get activityArchiveResetOrderFailed => 'Sıralama sıfırlanamadı.';

  @override
  String get activityArchiveOrderResetSuccess =>
      'Kart sıralaması varsayılana döndürüldü.';

  @override
  String get activityArchiveNoActivitiesToExport =>
      'Dışa aktarılacak faaliyet bulunamadı.';

  @override
  String get activityArchiveAllActivitiesDefaultName =>
      'GÜNLÜK TÜM FAALİYETLER';

  @override
  String activityArchiveExportFailed(String error) {
    return 'Dışa aktarılamadı: $error';
  }

  @override
  String get matrixSearchHint => 'Personel veya rütbe ara';

  @override
  String get matrixClearSearchTooltip => 'Aramayı temizle';

  @override
  String get matrixPreviousMonth => 'Önceki ay';

  @override
  String get matrixNextMonth => 'Sonraki ay';

  @override
  String get matrixCloseSearchTooltip => 'Aramayı kapat';

  @override
  String get matrixSearchPersonnelTooltip => 'Personel ara';

  @override
  String get matrixExportExcel => 'Excel\'e Aktar';

  @override
  String get matrixTeamDutyCalendar => 'Tim Görev Takvimi';

  @override
  String get matrixMonthlyTitle => 'Aylık Matris';

  @override
  String get matrixMonthlySubtitle => 'Personel görev ve durum çizelgesi';

  @override
  String get matrixNoMatchingPersonnel =>
      'Aramanızla eşleşen personel bulunamadı';

  @override
  String get matrixNoPersonnelToShow =>
      'Gösterilecek kayıtlı personel bulunmuyor.';

  @override
  String matrixExportFailed(String error) {
    return 'Çizelge dışa aktarılamadı: $error';
  }

  @override
  String get matrixUnassignedTeam => 'Timsiz Personel';

  @override
  String get matrixUnknownTeam => 'Bilinmeyen Tim';

  @override
  String matrixPersonnelCount(int count) {
    return '$count Personel';
  }

  @override
  String get matrixOrderNumberShort => 'S.N.';

  @override
  String get matrixTotalShort => 'Top.';

  @override
  String matrixDaysCount(int count) {
    return '$count gün';
  }

  @override
  String matrixMonthlyScheduleDays(int count) {
    return 'Aylık çizelge · $count gün';
  }

  @override
  String get temgundrapTitle => 'TEMGÜNDRAP Çizelgeleri';

  @override
  String get temgundrapDailyTitle => 'Günlük TEMGÜNDRAP';

  @override
  String get temgundrapArchiveTitle => 'TEMGÜNDRAP Arşivi';

  @override
  String temgundrapFailedToLoad(String error) {
    return 'Çizelgeler yüklenemedi: $error';
  }

  @override
  String get temgundrapArchivedSuccess => 'Çizelge arşive taşındı.';

  @override
  String get temgundrapUnarchivedSuccess => 'Çizelge yeniden taslağa alındı.';

  @override
  String temgundrapUpdateFailed(String error) {
    return 'Çizelge güncellenemedi: $error';
  }

  @override
  String get temgundrapDeleteTitle => 'Çizelgeyi sil';

  @override
  String get temgundrapDeleteContent =>
      'Bu TEMGÜNDRAP çizelgesi kalıcı olarak silinecek.';

  @override
  String temgundrapDeleteFailed(String error) {
    return 'Çizelge silinemedi: $error';
  }

  @override
  String get temgundrapPickDateTooltip => 'Tarih seç';

  @override
  String get temgundrapNewDocument => 'Yeni Çizelge';

  @override
  String get temgundrapEditDocument => 'Çizelgeyi Düzenle';

  @override
  String get temgundrapFailedToLoadDocs => 'Kayıtlar yüklenemedi';

  @override
  String get temgundrapActionsTitle => 'Çizelge İşlemleri';

  @override
  String get temgundrapEditSubtitle => 'Çizelge bilgilerini güncelle';

  @override
  String get temgundrapArchiveOption => 'Arşivle';

  @override
  String get temgundrapArchiveSubtitle => 'Çizelgeyi tamamla ve arşive taşı';

  @override
  String get temgundrapRestoreOption => 'Taslağa al';

  @override
  String get temgundrapRestoreSubtitle => 'Çizelgeyi yeniden düzenlemeye aç';

  @override
  String get temgundrapDeleteSubtitle => 'Bu çizelgeyi kalıcı olarak kaldır';

  @override
  String temgundrapDailyWithCount(int count) {
    return 'Günlük Çizelge ($count)';
  }

  @override
  String temgundrapArchiveWithCount(int count) {
    return 'Arşiv ($count)';
  }

  @override
  String get temgundrapPreviousDay => 'Önceki gün';

  @override
  String get temgundrapNextDay => 'Sonraki gün';

  @override
  String get temgundrapBackToToday => 'BUGÜNE DÖN';

  @override
  String temgundrapOperationsCount(int count) {
    return '$count operasyon';
  }

  @override
  String get temgundrapBadgeDraft => 'TASLAK';

  @override
  String get temgundrapBadgeArchived => 'ARŞİVDE';

  @override
  String get temgundrapNoDailyDraftTitle => 'Bu güne ait taslak çizelge yok';

  @override
  String get temgundrapNoArchivedDocTitle =>
      'Bu tarihte arşivlenmiş çizelge yok';

  @override
  String temgundrapNoDailyDraftMessage(String date) {
    return '$date için yeni bir TEMGÜNDRAP çizelgesi oluşturun.';
  }

  @override
  String get temgundrapNoArchivedDocMessage =>
      'Başka bir tarih seçebilir veya tamamlanan bir taslağı arşivleyebilirsiniz.';

  @override
  String get temgundrapNewDocButton => 'YENİ ÇİZELGE';

  @override
  String get temgundrapPickDateButton => 'TARİH SEÇ';

  @override
  String temgundrapApproverDefaultsLoadFailed(String error) {
    return 'Onay bilgileri yüklenemedi: $error';
  }

  @override
  String get temgundrapAtLeastOneOperationRequired =>
      'En az bir operasyon ekleyin.';

  @override
  String temgundrapSaveFailed(String error) {
    return 'Çizelge kaydedilemedi: $error';
  }

  @override
  String get temgundrapUnitTitle => 'Birlik başlığı';

  @override
  String get temgundrapDocumentDate => 'Çizelge tarihi';

  @override
  String get temgundrapOperations => 'Operasyonlar';

  @override
  String get temgundrapAddOperation => 'Operasyon Ekle';

  @override
  String get temgundrapNoOperationsAddedYet => 'Henüz operasyon eklenmedi.';

  @override
  String get temgundrapEditOperationTooltip => 'Operasyonu düzenle';

  @override
  String get temgundrapDeleteOperationTooltip => 'Operasyonu sil';

  @override
  String get temgundrapApprovalInfo => 'Onay Bilgileri';

  @override
  String get temgundrapApproverName => 'Onaylayan ad soyad';

  @override
  String get temgundrapApproverDuty => 'Görevi';

  @override
  String get temgundrapSaveAsDraft => 'Taslak olarak kaydet';

  @override
  String get temgundrapSaveDocumentButton => 'ÇİZELGEYİ KAYDET';

  @override
  String get temgundrapRequiredField => 'Bu alan zorunludur.';

  @override
  String get pendingApprovalsTitle => 'Bekleyen Görev Onayları';

  @override
  String get pendingApprovalsEmptyTitle => 'Bekleyen Onay Yok';

  @override
  String get pendingApprovalsEmptyDesc =>
      'Onay bekleyen veya çakışan görev kaydı bulunmuyor.';

  @override
  String pendingApprovalsAssignmentConflict(int id) {
    return 'Görevlendirme #$id (ÇAKIŞMA VAR)';
  }

  @override
  String get pendingApprovalsPersonnelLabel => 'Personel';

  @override
  String get pendingApprovalsRequestedDutyLabel => 'Talep Edilen Görev';

  @override
  String pendingApprovalsDescriptionLabel(String description) {
    return 'Açıklama: $description';
  }

  @override
  String get pendingApprovalsApprove => 'ONAYLA';

  @override
  String get pendingApprovalsReject => 'REDDET';

  @override
  String pendingApprovalsApprovalFailed(String reason) {
    return 'Onaylanamadı: $reason';
  }

  @override
  String get activityDeleteTitle => 'Faaliyeti Sil';

  @override
  String activityDeleteConfirm(String name, String date) {
    return '$name ($date) faaliyet kaydı silinecektir. Emin misiniz?';
  }

  @override
  String get activityRenameTitle => 'Faaliyet Adını Değiştir';

  @override
  String get activityRenameLabel => 'Faaliyet adı';

  @override
  String get activityRenameHint => 'Örn. Gece nöbeti';

  @override
  String get activityActionsTitle => 'Faaliyet İşlemleri';

  @override
  String get activityActionsSubtitle =>
      'Bu faaliyet için kullanılabilir işlemler';

  @override
  String get activityApproveAllTitle => 'Tümünü onayla';

  @override
  String get activityApproveAllSubtitle => 'Bekleyen tüm atamaları onayla';

  @override
  String get activityRenameOptionTitle => 'Faaliyet adını değiştir';

  @override
  String get activityRenameOptionSubtitle => 'Kart başlığını yeniden adlandır';

  @override
  String get activityChangeDateOptionTitle => 'Tarihi değiştir';

  @override
  String get activityChangeDateOptionSubtitle =>
      'Faaliyeti başka bir güne taşı';

  @override
  String get activityDeleteOptionTitle => 'Faaliyeti sil';

  @override
  String get activityDeleteOptionSubtitle => 'Bu işlem geri alınamaz';

  @override
  String activityApproveAllSuccess(int count) {
    return '$count atama onaylandı.';
  }

  @override
  String activityApproveAllWithConflicts(
      int approvedCount, int blockedCount, String reasons) {
    return '$approvedCount onaylandı, $blockedCount çakışma nedeniyle beklemede kaldı: $reasons';
  }

  @override
  String activityCreatedBy(String user) {
    return 'Yazan: $user';
  }

  @override
  String get activityStatusApproved => 'ONAYLANDI';

  @override
  String get activityStatusPendingAdmin => 'ADMIN ONAYI BEKLİYOR';

  @override
  String get activityStatusConflictOrRejected => 'ÇAKIŞMA / RED';

  @override
  String get activityChangeDateTitle => 'Faaliyet Tarihini Değiştir';

  @override
  String get activityChangeDateAlreadyOnDate =>
      'Faaliyet zaten seçilen tarihte.';

  @override
  String get activityChangeDatePrepareFailed =>
      'Tarih değişikliği hazırlanamadı.';

  @override
  String activityChangeDatePersonnelCountNotice(int count) {
    return '$count personel yeni tarihe taşınacak.';
  }

  @override
  String activityChangeDatePendingNotice(int count) {
    return '$count personel rapor/görev çakışması nedeniyle yeniden onaya alınacak.';
  }

  @override
  String get activityChangeDateSubmit => 'TARİHİ DEĞİŞTİR';

  @override
  String activityChangeDateMovedNotice(int count, String date) {
    return '$count personel $date tarihine taşındı.';
  }

  @override
  String activityChangeDatePendingCountNotice(int count) {
    return '$count personel yeniden onay bekliyor.';
  }

  @override
  String get activityChangeDateFailed =>
      'Tarih değiştirilemedi. Hedef tarih yeniden kontrol edilmelidir.';

  @override
  String get activityRenameSuccess => 'Faaliyet adı güncellendi.';

  @override
  String activityRenameFailed(String error) {
    return 'Faaliyet adı değiştirilemedi: $error';
  }

  @override
  String get settingsUserNotFound => 'Kullanıcı bulunamadı.';

  @override
  String settingsPasswordUpdateFailed(String error) {
    return 'Şifre güncellenemedi: $error';
  }

  @override
  String get settingsAddTestPersonnelTitle => '10\'ar Test Personeli Ekle';

  @override
  String get settingsAddTestPersonnelSubtitle =>
      'Her time 10 adet sahte personel oluşturur';

  @override
  String settingsTestPersonnelAddedSuccess(int count) {
    return '$count adet test personeli başarıyla eklendi!';
  }

  @override
  String get settingsClearTestPersonnelTitle => 'Test Personellerini Temizle';

  @override
  String get settingsClearTestPersonnelSubtitle =>
      'Yalnızca işaretlenmiş test personellerini temizler';

  @override
  String get settingsDeletePersonnelConfirmTitle => 'Personelleri Sil';

  @override
  String get settingsDeleteTestPersonnelConfirmMessage =>
      'Yalnızca test olarak işaretlenmiş personel kayıtları silinecektir. Emin misiniz?';

  @override
  String get settingsTestPersonnelCleared =>
      'İşaretlenmiş test personelleri temizlendi!';

  @override
  String activityArchiveSelectedActivitiesCount(String dateTitle, int count) {
    return '$dateTitle • $count Seçili Faaliyet';
  }

  @override
  String activityArchiveFallbackPersonnelName(int id) {
    return 'Personel #$id';
  }

  @override
  String get activityArchiveUnknownTeamHistory => 'Tim geçmişi bilinmiyor';

  @override
  String get backupRestoreTitle => 'Yedekleme ve Geri Yükleme';

  @override
  String get backupExportTab => 'Dışa Aktar';

  @override
  String get backupImportTab => 'İçe Aktar';

  @override
  String get backupExportSuccess => 'Tam uygulama yedeği dışa aktarıldı.';

  @override
  String get backupSaveCancelled => 'Kaydetme işlemi iptal edildi.';

  @override
  String backupExportFailed(String error) {
    return 'Yedek dışa aktarılamadı: $error';
  }

  @override
  String get backupImportSuccess => 'Yedek başarıyla geri yüklendi.';

  @override
  String backupImportFailed(String error) {
    return 'Yedek geri yüklenemedi: $error';
  }

  @override
  String backupFilePickerError(String error) {
    return 'Dosya seçilemedi: $error';
  }

  @override
  String get backupInvalidJson => 'Geçerli bir JSON yedek verisi giriniz.';

  @override
  String get backupVerifyButton => 'Yedeği Doğrula';

  @override
  String get backupRestoreConfirmTitle => 'Yedeği Geri Yükle';

  @override
  String get backupRestoreConfirmMessage =>
      'Mevcut tüm veriler yedekteki verilerle değiştirilecektir. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?';

  @override
  String get backupRestoreButton => 'GERİ YÜKLE';

  @override
  String get backupExportSubtitle =>
      'Uygulamanın tam yedeğini cihazınıza kaydedin veya paylaşın.';

  @override
  String get backupImportSubtitle =>
      'Daha önce alınmış bir yedeği yükleyerek verilerinizi geri yükleyin.';

  @override
  String get backupStatsPersonnel => 'Personel Sayısı';

  @override
  String get backupStatsActivities => 'Faaliyet Sayısı';

  @override
  String get backupStatsAssignments => 'Atama Sayısı';

  @override
  String get backupStatsTemgundrap => 'TEMGÜNDRAP Kayıtları';

  @override
  String get backupExportDate => 'Yedek Tarihi';

  @override
  String get backupCopyJson => 'JSON Kopyala';

  @override
  String get backupJsonCopied => 'Yedek verisi panoya kopyalandı.';

  @override
  String get backupDownloadFile => 'Dosya Olarak Kaydet';

  @override
  String get addPersonnelDialogTitle => 'Personel Ekle';

  @override
  String get addPersonnelResultTitle => 'Ekleme sonucu';

  @override
  String addPersonnelResultContent(int added, int already, int conflict) {
    return '$added personel eklendi.\n$already personel zaten kayıtlı.\n$conflict personel çakışma nedeniyle eklenemedi.';
  }

  @override
  String addPersonnelFailed(String error) {
    return 'Personel eklenemedi: $error';
  }

  @override
  String addPersonnelSelectedCount(int count) {
    return '$count personel seçildi';
  }

  @override
  String get addPersonnelLoadError =>
      'Personel bilgileri yüklenemedi. Ekranı kapatıp yeniden deneyin.';

  @override
  String get addPersonnelNoAvailable => 'Eklenebilecek personel bulunamadı.';

  @override
  String get addPersonnelAlreadyRegistered => 'Bu faaliyette zaten kayıtlı';

  @override
  String get addPersonnelStepPersonnel => 'Personel';

  @override
  String get addPersonnelStepDuty => 'Görev';

  @override
  String get addPersonnelAddToActivity => 'Faaliyete Ekle';

  @override
  String get addPersonnelContinue => 'Devam et';

  @override
  String get conflictPersonnelTitle => 'Bazı personeller eklenmedi';

  @override
  String conflictPersonnelMessage(int count) {
    return 'Kayıt tamamlandı. Aynı gün için başka kaydı bulunan $count personel atlandı.';
  }

  @override
  String get conflictPersonnelUnderstood => 'ANLADIM';

  @override
  String get conflictPersonnelFallback => 'Çakışan kayıt';

  @override
  String get conflictPersonnelDetail =>
      'Bu tarihte başka bir faaliyet kaydı bulunuyor.';

  @override
  String get transferPersonnelTitle => 'Personel Taşı';

  @override
  String transferPersonnelSourceLabel(String activityName) {
    return 'Kaynak: $activityName';
  }

  @override
  String get transferPersonnelSelectTarget => 'Hedef Faaliyet Kartını Seçin:';

  @override
  String transferPersonnelNoOtherActivity(String date) {
    return '$date tarihinde başka faaliyet kartı bulunamadı.';
  }

  @override
  String get transferPersonnelCreateNewOption => 'YENİ FAALİYET KARTI OLUŞTUR';

  @override
  String get transferPersonnelNewActivityLabel => 'Yeni faaliyet adı';

  @override
  String get transferPersonnelButton => 'TAŞI';

  @override
  String transferPersonnelSuccess(String name) {
    return '$name başarıyla taşındı.';
  }

  @override
  String get transferPersonnelFailed => 'Taşıma yapılamadı.';

  @override
  String transferPersonnelError(String error) {
    return 'Taşıma hatası: $error';
  }

  @override
  String get transferSquadTitle => 'Tim Taşı';

  @override
  String get transferSquadButton => 'TAŞI';

  @override
  String transferSquadSuccess(String squadName, int count, String skippedNote) {
    return '$squadName: $count personel başarıyla taşındı.$skippedNote';
  }

  @override
  String transferSquadSkippedNote(int count) {
    return ' ($count personel zaten hedef faaliyette olduğu için atlandı)';
  }

  @override
  String get transferSquadAllExisting =>
      'Tüm personel zaten hedef faaliyette mevcut, taşıma yapılmadı.';

  @override
  String transferSquadError(String error) {
    return 'Taşıma hatası: $error';
  }

  @override
  String get excelPickerSelectCardsTitle => 'Çıktıya Eklenecek Kartlar';

  @override
  String get excelPickerNotice =>
      'Ana Heybet kartı dahil edilir. Ek kartları seçin; aynı kişi çıktıda yalnızca bir kez yer alır.';

  @override
  String get excelPickerNoExtraCards => 'Bu güne ait ek kart bulunamadı.';

  @override
  String get excelPickerSameDayCards => 'Aynı Günün Kartları';

  @override
  String get excelPickerPreviousDayCards => 'Önceki Günün Kartları';

  @override
  String excelPickerPreviewButton(int count) {
    return 'Önizleme ($count)';
  }

  @override
  String get excelPickerCombinedPreviewTitle => 'Birleşik Çıktı Önizlemesi';

  @override
  String excelPickerCombinedNotice(int count) {
    return '$count personel • Her kişi bir kez • Toplam baskıda gösterilmez';
  }

  @override
  String get excelPickerSelectExport => 'Çıktı Seç';

  @override
  String get bulkImportHeaderTitle => 'Metinden Toplu Aktarım';

  @override
  String get bulkImportHeaderSubtitle =>
      'WhatsApp / Telegram nöbet listelerini yapıştırıp akıllı ayrıştırın';

  @override
  String get bulkImportMemoryButton => 'Eşleşme Hafızası';

  @override
  String get bulkImportCloseTooltip => 'Kapat';

  @override
  String get bulkImportStepPaste => 'Yapıştır';

  @override
  String get bulkImportStepPreview => 'Önizleme';

  @override
  String get bulkImportStepConfirm => 'Kaydet';

  @override
  String get bulkImportInputPlaceholder => 'Mesaj metnini buraya yapıştırın…';

  @override
  String get bulkImportKeepAuditTextLabel =>
      'Ham metni yerel denetim kaydında sakla';

  @override
  String get bulkImportKeepAuditTextTooltip =>
      'Varsayılan kapalıdır; veri yalnızca bu cihazda tutulur.';

  @override
  String get bulkImportParseButton => 'Metni Ayrıştır ve Kartları Oluştur';

  @override
  String get bulkImportParsingButton => 'Ayrıştırılıyor...';

  @override
  String get bulkImportStepperUnlockHint =>
      'Tüm kart sorunları çözülünce kaydet adımı açılır';

  @override
  String get bulkImportClearButton => 'Temizle';

  @override
  String get bulkImportPasteSampleButton => 'Örnek Metin';

  @override
  String get bulkImportConfirmTitle => 'Aktarım Özeti ve Kayıt';

  @override
  String get bulkImportConfirmSubtitle =>
      'Ayrıştırılan kayıtlar doğrulanarak veritabanına aktarılacaktır.';

  @override
  String get bulkImportConfirmTotalCards => 'Oluşturulacak Kart:';

  @override
  String get bulkImportConfirmTotalPersonnel => 'Görevlendirilecek Personel:';

  @override
  String get bulkImportConfirmSaveButton => 'TÜMÜNÜ KAYDET';

  @override
  String get bulkImportConfirmReturnButton => 'Önizlemeye Dön';

  @override
  String get bulkImportEmptyTitle => 'Henüz ayrıştırılmış veri yok';

  @override
  String get bulkImportEmptySubtitle =>
      'Sol taraftan metin yapıştırıp \'Metni Ayrıştır\' butonuna basarak başlayabilirsiniz.';

  @override
  String get bulkImportStatTotalCards => 'Kart';

  @override
  String get bulkImportStatTotalPeople => 'Personel';

  @override
  String get bulkImportStatReady => 'Hazır';

  @override
  String get bulkImportStatIssues => 'Sorunlu';

  @override
  String bulkImportFilterAll(int count) {
    return 'Tümü ($count)';
  }

  @override
  String bulkImportFilterProblems(int count) {
    return 'Sorunlar ($count)';
  }

  @override
  String bulkImportFilterReady(int count) {
    return 'Hazır ($count)';
  }

  @override
  String get bulkImportWizardStart => 'Sorun Sihirbazı';

  @override
  String get bulkImportWizardPrev => 'Önceki Sorun';

  @override
  String get bulkImportWizardNext => 'Sonraki Sorun';

  @override
  String get bulkImportConfirmAllSuggestions => 'Tüm Önerileri Onayla';

  @override
  String get bulkImportClearAllCards => 'Tümünü Temizle';

  @override
  String get bulkImportClearAllConfirmTitle => 'Tüm Kartları Temizle';

  @override
  String get bulkImportClearAllConfirmMessage =>
      'Ayrıştırılmış tüm faaliyet kartları silinecektir. Emin misiniz?';

  @override
  String get bulkImportSaveBarSave => 'KAYDET';

  @override
  String get bulkImportSaveBarSaving => 'KAYDEDİLİYOR…';

  @override
  String get bulkImportSaveBarFixIssues => 'Sorunları Düzeltin';

  @override
  String get bulkImportNoCardsToSave => 'Kaydedilecek kart bulunamadı.';

  @override
  String bulkImportUnresolvedPersonnelError(int count) {
    return '$count personel eşleşmedi. Lütfen tüm personelleri seçin veya listeden kaldırın.';
  }

  @override
  String get bulkImportEmptyCardsError =>
      'Personeli bulunmayan boş kartlar var. Lütfen kartları düzenleyin veya silin.';

  @override
  String get bulkImportBlockingIssuesError =>
      'Lütfen önce çözülmemiş kart sorunlarını (tarih, tim veya görev türü) tamamlayın.';

  @override
  String get bulkImportCompletedTitle => 'Aktarım Tamamlandı';

  @override
  String bulkImportSuccessNotification(String activityName, int count) {
    return '$activityName faaliyetine $count personel eklendi.';
  }

  @override
  String bulkImportPersonRemoved(String rank, String name) {
    return '$rank $name kaldırıldı.';
  }

  @override
  String bulkImportBlockRemoved(String activityType) {
    return '$activityType kartı kaldırıldı.';
  }

  @override
  String get bulkImportUndo => 'GERİ AL';

  @override
  String get bulkImportDuplicateTitle => 'Yinelenen Personel';

  @override
  String get bulkImportDuplicateDesc =>
      'Aynı personel aynı gün birden fazla karta atanmış.';

  @override
  String get bulkImportEditBlockTitle => 'Faaliyet kartını düzenle';

  @override
  String get bulkImportBlockDate => 'Tarih';

  @override
  String get bulkImportBlockSquad => 'Bağlı Tim';

  @override
  String get bulkImportBlockActivity => 'Faaliyet / Görev Türü';

  @override
  String get bulkImportBlockTimeRange => 'Saat Aralığı (İsteğe bağlı)';

  @override
  String get bulkImportMemoryTitle => 'Öğrenilen İsim Eşleştirmeleri';

  @override
  String get bulkImportMemoryEmpty =>
      'Henüz kaydedilmiş bir eşleştirme hafızası bulunmuyor.';

  @override
  String get bulkImportMemoryClearAll => 'Tüm Hafızayı Temizle';

  @override
  String get bulkImportMemoryAliasRemoved => 'Eşleştirme silindi.';

  @override
  String get backupRestoreSurfaceTitle => 'Tam yedekleme ve geri yükleme';

  @override
  String get backupRestoreSurfaceSubtitle =>
      'Bulut gerekmez; dosya sizin seçtiğiniz yerde kalır.';

  @override
  String get backupModeExport => 'Yedekle';

  @override
  String get backupModeImport => 'Geri yükle';

  @override
  String get backupInfoWhatIsInsideTitle => 'Yedekte neler var?';

  @override
  String get backupInfoWhatIsInsideDesc =>
      'İsimler, timler, kullanıcılar, telefonlar, görevler, aylık matris, faaliyet arşivi, raporlar, takma adlar, toplu aktarım geçmişi ve TEMGÜNDRAP belgeleri.';

  @override
  String get backupInfoPreserveTitle => 'Uygulama silinse de koruyun';

  @override
  String get backupInfoPreserveDesc =>
      'Açılan kaydet ekranından İndirilenler gibi cihazın yerel bir klasörünü seçin. Uygulamanın kendi klasörüne bırakmayın.';

  @override
  String get backupInfoSecurityTitle => 'Dosyayı güvenli tutun';

  @override
  String get backupInfoSecurityDesc =>
      'Yedek kişisel bilgiler içerir. Yalnızca güvenilir bir yerel klasörde saklayın ve başkalarıyla paylaşmayın.';

  @override
  String get backupSaveToDeviceButton => 'Tam yedeği cihazda sakla';

  @override
  String get backupCopyTextButton => 'Yedek metnini de kopyala';

  @override
  String get backupPickFileButton => 'Yedek dosyası seç';

  @override
  String get backupPasteFromClipboardButton => 'Panodaki eski yedeği kullan';

  @override
  String get backupRestoreExecuteButton => 'Yedeği geri yükle';

  @override
  String get backupPreviewLegacyDate => 'Eski yedek';

  @override
  String get backupPreviewLegacyTitle => 'Eski personel yedeği';

  @override
  String get backupPreviewVerifiedTitle => 'Doğrulanmış tam yedek';

  @override
  String backupPreviewSummary(String date, int personnelCount,
      int activityCount, int assignmentCount, int temgundrapCount) {
    return '$date • $personnelCount personel • $activityCount faaliyet • $assignmentCount görev kaydı • $temgundrapCount TEMGÜNDRAP';
  }

  @override
  String get backupConfirmOverwriteTitle => 'Mevcut veriler değiştirilsin mi?';

  @override
  String get backupConfirmOverwriteMessage =>
      'Tam geri yükleme mevcut personel, görev, matris ve TEMGÜNDRAP kayıtlarının yerine yedekteki verileri koyar. Bu işlem geri alınamaz.';

  @override
  String get backupClipboardEmpty => 'Panoda yedek metni bulunamadı.';

  @override
  String get backupClipboardReadError => 'Panodaki yedek okunamadı.';

  @override
  String get backupPickFilePrompt => 'Önce bir yedek dosyası seçin.';

  @override
  String get backupTextCopied => 'Yedek metni panoya kopyalandı.';

  @override
  String get backupVerifiedReady => 'Yedek doğrulandı ve geri yüklemeye hazır.';

  @override
  String get backupCreateFailed =>
      'Yedek oluşturulamadı. Lütfen tekrar deneyin.';

  @override
  String get backupFileReadError => 'Yedek dosyası okunamadı.';

  @override
  String get backupRestoreFailedDataPreserved =>
      'Yedek geri yüklenemedi; mevcut veriler korunmuştur.';

  @override
  String backupLegacyImportSuccess(int count) {
    return '$count yeni personel eski yedekten aktarıldı.';
  }

  @override
  String backupFullRestoreSuccess(
      int personnelCount, int activityCount, int temgundrapCount) {
    return 'Geri yükleme tamamlandı: $personnelCount personel, $activityCount faaliyet ve $temgundrapCount TEMGÜNDRAP belgesi.';
  }

  @override
  String activityDutyForPersonnel(String name) {
    return '$name için görev';
  }

  @override
  String get bulkImportBannerTitle => 'Metinden Toplu Aktarım';

  @override
  String get bulkImportManageMemoryTooltip =>
      'Sistem Hafızasını (Takma Adları) Yönet';

  @override
  String get bulkImportStepSaveLockedTooltip =>
      'Tüm kart sorunları çözülünce kaydet adımı açılır';

  @override
  String get bulkImportConfirmCannotSave => 'Kaydedilemiyor';

  @override
  String get bulkImportConfirmReadyToSave => 'Kayda Hazır';

  @override
  String get bulkImportConfirmResolveIssues =>
      'Lütfen önizleme adımına dönüp sorunları çözün.';

  @override
  String bulkImportConfirmSummary(
      int cardCount, int personnelCount, int dayCount) {
    return '$cardCount kart, $personnelCount personel, $dayCount gün';
  }

  @override
  String get bulkImportInputRawTitle => 'Ham Metni Yapıştırın:';

  @override
  String get bulkImportInputRawSubtitle =>
      'Tarih, görev türü ve personel listesini içeren mesajı olduğu gibi yapıştırabilirsiniz.';

  @override
  String get bulkImportKeepAuditTextDesc =>
      'Varsayılan kapalıdır; veri yalnızca bu cihazda tutulur.';

  @override
  String get bulkImportInputPlaceholderShort =>
      'Mesaj metnini buraya yapıştırın…';

  @override
  String get bulkImportParseAndCreateCards =>
      'Metni Ayrıştır ve Kartları Oluştur';

  @override
  String get bulkImportEmptyNoCardIssues => 'Kartlara bağlı sorun kalmadı';

  @override
  String get bulkImportEmptyAllIssuesResolved => 'Tüm kart sorunları çözüldü';

  @override
  String get bulkImportEmptyCheckNoticePanel =>
      'Kalan kritik ayrıştırma sorunlarını yukarıdaki uyarı panelinden inceleyin.';

  @override
  String get bulkImportEmptyReturnToAllCards =>
      'İsterseniz tüm faaliyet kartlarına geri dönebilirsiniz.';

  @override
  String get bulkImportEmptyShowAllCards => 'TÜM KARTLARI GÖSTER';

  @override
  String bulkImportStatCardCount(int count) {
    return '$count Kart';
  }

  @override
  String bulkImportStatPersonnelCount(int count) {
    return '$count Personel';
  }

  @override
  String bulkImportStatDayCount(int count) {
    return '$count Gün';
  }

  @override
  String get bulkImportSearchHint => 'Personel, tim veya satır ara';

  @override
  String get bulkImportFilterProblemsLabel => 'Sorunlar';

  @override
  String get bulkImportCorrectnessPanelTitle => 'Doğruluk Paneli';

  @override
  String get bulkImportCannotSaveStatus => 'Kaydedilemiyor';

  @override
  String get bulkImportAllChecksPassed => 'Tüm kontroller tamam';

  @override
  String bulkImportActionsRequiredBeforeSave(int count) {
    return 'Kaydetmeden önce $count işlem tamamlanmalı';
  }

  @override
  String bulkImportOptionalReviews(int count) {
    return '$count isteğe bağlı inceleme';
  }

  @override
  String bulkImportCriticalErrors(int count) {
    return '$count kritik hata';
  }

  @override
  String bulkImportReviewsCount(int count) {
    return '$count inceleme';
  }

  @override
  String get bulkImportMetricCard => 'kart';

  @override
  String get bulkImportMetricPersonnel => 'personel';

  @override
  String get bulkImportMetricDay => 'gün';

  @override
  String get bulkImportMetricCritical => 'kritik';

  @override
  String get bulkImportMetricReview => 'inceleme';

  @override
  String bulkImportIgnoredLinesNotice(int count) {
    return '$count başlık, toplam veya not satırı personel kaydı olarak alınmadı.';
  }

  @override
  String get bulkImportNoCardsYet => 'Henüz Kart Oluşturulmadı';

  @override
  String get bulkImportReturnToPastePrompt =>
      'Yapıştır adımına dönüp mesajı yapıştırın.';

  @override
  String get bulkImportStatusCritical => 'Kritik';

  @override
  String get bulkImportStatusReview => 'İnceleme';

  @override
  String get bulkImportFixAction => 'Düzelt';

  @override
  String bulkImportLineNumber(int number) {
    return 'Satır $number';
  }

  @override
  String get bulkImportDuplicateListTitle => 'Bu Liste Daha Önce Aktarıldı';

  @override
  String bulkImportDuplicateListMessage(
      String dates, String recordDate, String user, int activeCount) {
    return '$dates tarihli bu içerik $recordDate tarihinde $user tarafından kaydedilmiş.\n\nVeritabanında bu listeye ait $activeCount personel kaydı aktif duruyor. Eksik olanları tamamlamak veya yeniden aktarmak istiyor musunuz?';
  }

  @override
  String get bulkImportCompleteMissingOrReimport =>
      'EKSİKLERİ TAMAMLA / YENİDEN AKTAR';

  @override
  String bulkImportSummaryActivitiesProcessed(int count) {
    return '$count günlük faaliyet işlendi.';
  }

  @override
  String bulkImportSummaryPersonnelAdded(int count) {
    return '$count yeni personel eklendi.';
  }

  @override
  String bulkImportSummaryAlreadyAssigned(int count) {
    return '$count personel zaten o görevde ekliydi.';
  }

  @override
  String bulkImportSummaryDeduplicated(int count) {
    return '$count tekrar tekilleştirildi.';
  }

  @override
  String bulkImportSummarySkippedConflict(int count) {
    return '$count çakışan kayıt atlandı.';
  }

  @override
  String bulkImportSuccessBanner(
      int blockCount, int activityCount, int personnelCount) {
    return '$blockCount blok → $activityCount günlük faaliyet, $personnelCount personel başarıyla eklendi.';
  }

  @override
  String bulkImportSaveButtonSummary(int blockCount, int dayCount) {
    return '$blockCount blok -> $dayCount günlük faaliyet';
  }

  @override
  String bulkImportSaveActivitiesWithCardCount(int count) {
    return 'Faaliyetleri Kaydet ($count Kart)';
  }

  @override
  String get bulkImportNextReview => 'Sonraki inceleme';

  @override
  String get bulkImportOpenNextProblem => 'Sonraki sorunu aç';

  @override
  String bulkImportRemainingActionsBeforeSave(int count) {
    return 'Kaydetmek için $count işlem kaldı';
  }

  @override
  String bulkImportCriticalAndReviewCount(int criticalCount, int reviewCount) {
    return '$criticalCount kritik hata • $reviewCount inceleme';
  }

  @override
  String get bulkImportPendingReviewItemsTitle =>
      'İnceleme Bekleyen Ögeler Var';

  @override
  String bulkImportReviewItemsSubtitle(int count) {
    return '$count eşleşme/tim kontrolü gerektiriyor';
  }

  @override
  String get bulkImportReadyToSaveSubtitle => 'Kayda hazır';

  @override
  String get bulkImportHighlightedCardsPrompt =>
      'Lütfen aşağıda vurgulanan kartlardaki eksik personelleri eşleştirin, tekrarları düzeltin veya boş kartları silin.';

  @override
  String get bulkImportDuplicateSubtitle =>
      'Aynı personel aynı tarihte birden fazla görevde bulunuyor. Aktarmadan önce önizlemedeki tekrarları düzeltin.';

  @override
  String get bulkImportReturnToPreviewButton => 'ÖNİZLEMEYE DÖN';

  @override
  String get bulkImportDefaultTeamOption => 'Varsayılan / Personel Timi';

  @override
  String get bulkImportCustomOption => 'DİĞER (Elle Yaz...)';

  @override
  String get bulkImportQuickDutySelection => 'Hızlı Görev Seçimi';

  @override
  String get bulkImportSelectDutyHint => 'Görev seç';

  @override
  String get bulkImportSelectDutyType => 'Görev / Faaliyet Türü Seçin';

  @override
  String get bulkImportCustomDutyName => 'Görev / Faaliyet Adı (Elle Düzenle)';

  @override
  String get bulkImportSelectTeam => 'Takım / Tim Seçin';

  @override
  String get bulkImportCustomTeamName => 'Takım / Tim Adı (Elle Düzenle)';

  @override
  String get bulkImportApplyChanges => 'DEĞİŞİKLİKLERİ UYGULA';

  @override
  String get bulkImportDeleteAliasTitle => 'Eşleşmeyi Sil';

  @override
  String bulkImportDeleteAliasConfirm(
      String rawName, String rank, String name) {
    return '\'$rawName\' ➔ \'$rank $name\' öğrenilmiş takma ad eşleşmesi silinsin mi?';
  }

  @override
  String bulkImportAliasDeletedFromMemory(String name) {
    return '\'$name\' hafızadan silindi.';
  }

  @override
  String get bulkImportSystemMemoryTitle => 'Sistem Hafızası';

  @override
  String bulkImportLearnedAliasesCount(int count) {
    return '$count Öğrenilmiş İsim Takma Adı';
  }

  @override
  String get bulkImportSearchAliasHintMobile => 'Yazım veya personel adı ara';

  @override
  String get bulkImportSearchAliasHintDesktop =>
      'Metindeki yazım veya personel adıyla ara...';

  @override
  String get bulkImportNoAliasFoundForSearch =>
      'Aramanıza uygun takma ad bulunamadı.';

  @override
  String get bulkImportNoLearnedAliasesYet =>
      'Henüz öğrenilmiş bir takma ad bulunmuyor.\nToplu aktarımlarda onayladığınız eşleşmeler otomatik hafızaya alınır.';

  @override
  String get bulkImportTextName => 'Metindeki ad';

  @override
  String get bulkImportMatchedPersonnel => 'Eşleştiği personel';

  @override
  String get bulkImportDeleteAliasTooltip => 'Takma adı hafızadan sil';

  @override
  String get bulkImportUnassignedOrOtherPersonnel =>
      'Timsiz / Diğer Personeller';

  @override
  String get bulkImportPersonnelNotSelected => 'Personel seçilmedi';

  @override
  String get bulkImportAutoMatchedFromMemory => 'Hafızadan Otomatik Eşleşti';

  @override
  String get bulkImportFromMemory => 'Hafızadan';

  @override
  String bulkImportInText(String text) {
    return 'Metinde: $text';
  }

  @override
  String get bulkImportRemovePersonnelTooltip => 'Personeli kaldır';

  @override
  String get bulkImportSelectedError => 'SEÇİLİ HATA';

  @override
  String get bulkImportReviewedPersonnel => 'İNCELENEN PERSONEL';

  @override
  String bulkImportDuplicateOnSameDate(String assignments) {
    return 'Aynı tarihte ayrıca: $assignments';
  }

  @override
  String get bulkImportTeamMismatchAccept => 'Tim disi gorev (Kabul et)';

  @override
  String get bulkImportUserConfirmed => 'Kullanıcı onayladı';

  @override
  String get bulkImportTeamMismatchDuty => 'Tim disi gorev';

  @override
  String get bulkImportDeleteAliasAction => 'SİL';

  @override
  String bulkImportCheckMatchWithPercent(int percent) {
    return 'Eşleşmeyi kontrol edin (%$percent)';
  }

  @override
  String get bulkImportCheckMatch => 'Eşleşmeyi kontrol edin';

  @override
  String get bulkImportMatched => 'Eşleşti';

  @override
  String get bulkImportNotMatched => 'Eşleşmedi';

  @override
  String bulkImportError(String error) {
    return 'Hata oluştu: $error';
  }

  @override
  String get bulkImportNoPersonnelToAdd => 'Eklenecek personel bulunamadı.';

  @override
  String get bulkImportClearPreviewTitle => 'Önizlemeyi temizle?';

  @override
  String get bulkImportClearPreviewMessage =>
      'Oluşturulan tüm kartlar ve ayrıştırma uyarıları kaldırılacak.';

  @override
  String get bulkImportAllSuggestionsConfirmed =>
      'Tüm önerilen personel eşleşmeleri onaylandı.';

  @override
  String bulkImportPersonAddedToDbAndMatched(
      String rank, String name, String team) {
    return '$rank $name veritabanına ($team) eklendi ve eşleştirildi.';
  }

  @override
  String get commonNoTeam => 'Timsiz';

  @override
  String get bulkImportSelectDate => 'Tarih seç';

  @override
  String get personnelPageTitle => 'Personel ve Timler';

  @override
  String get personnelBackupRestoreTooltip => 'Yedekle ve geri yükle';

  @override
  String get personnelCommanderDelegationTooltip => 'Komutan yetkileri';

  @override
  String get personnelNewSquadTooltip => 'Yeni tim';

  @override
  String get personnelManagementActionsTooltip => 'Yönetim işlemleri';

  @override
  String get personnelManagementActionsTitle => 'Yönetim İşlemleri';

  @override
  String get personnelManagementActionsSubtitle =>
      'Personel ve uygulama yönetimi';

  @override
  String get personnelCreateSquadOptionTitle => 'Yeni tim';

  @override
  String get personnelCreateSquadOptionSubtitle => 'Yeni bir tim oluştur';

  @override
  String get personnelCommanderOptionTitle => 'Komutan yetkileri';

  @override
  String get personnelCommanderOptionSubtitle =>
      'Tim komutanlarını ve yetkileri yönet';

  @override
  String get personnelBackupOptionTitle => 'Yedekle ve geri yükle';

  @override
  String get personnelBackupOptionSubtitle =>
      'Uygulama verilerini güvenli şekilde yönet';

  @override
  String get personnelAddButton => 'Personel Ekle';

  @override
  String personnelListCount(int count) {
    return 'Personel Listesi ($count Kişi)';
  }

  @override
  String get personnelOfficialOrderSubtitle => 'Resmi Tim & Kıdem Sıralı';

  @override
  String get personnelUnassignedSquad => 'Boşta / Kadro Dışı Personeller';

  @override
  String get personnelUnknownSquad => 'Bilinmeyen Tim';

  @override
  String personnelCountSubtitle(int count) {
    return '$count personel';
  }

  @override
  String personnelUnitAndRegistration(String unit, String date) {
    return 'Birlik: $unit | Kayıt: $date';
  }

  @override
  String get personnelActionsTooltip => 'İşlemler';

  @override
  String get personnelDeactivateTitle => 'Personeli Pasifleştir';

  @override
  String personnelDeactivateConfirm(String rank, String name) {
    return '$rank $name isimli personel pasifleştirilecektir. Geçmiş görev ve raporları korunur. Emin misiniz?';
  }

  @override
  String get personnelDeactivateAction => 'PASİFLEŞTİR';

  @override
  String get personnelActionsMenuTitle => 'Personel İşlemleri';

  @override
  String get personnelEditOptionTitle => 'Düzenle / Tim değiştir';

  @override
  String get personnelEditOptionSubtitle => 'Personel bilgilerini güncelle';

  @override
  String get personnelMakeCommanderOptionTitle => 'Komutan yetkileri';

  @override
  String get personnelMakeCommanderOptionSubtitle =>
      'Tim komutanı yap veya yetki ver';

  @override
  String get personnelDeleteOptionTitle => 'Personeli sil';

  @override
  String get personnelDeleteOptionSubtitle => 'Bu işlem geri alınamaz';

  @override
  String get personnelAddModalTitle => 'Personel Ekle';

  @override
  String get personnelAddSingleOptionTitle => 'Tek Personel Ekle';

  @override
  String get personnelAddSingleOptionSubtitle =>
      'Bilgileri form üzerinden girin';

  @override
  String get personnelAddBulkOptionTitle => 'Metinden Toplu Ekle';

  @override
  String get personnelAddBulkOptionSubtitle => 'Listeyi yapıştırıp önizleyin';

  @override
  String personnelBulkImportSuccess(int added, int updated, int skipped) {
    return '$added personel eklendi, $updated personel güncellendi, $skipped satır atlandı.';
  }

  @override
  String personnelMakeCommanderTitle(String rank, String name) {
    return '⭐ Tim Komutanı Yap: $rank $name';
  }

  @override
  String get personnelMakeCommanderDescription =>
      'Bu personeli bir Time Komutan olarak atayabilir ve giriş yetkisi verebilirsiniz.';

  @override
  String get personnelUsernameLabel => 'Kullanıcı Adı (Giriş için)';

  @override
  String get personnelTargetSquadLabel => 'Komutanı Olacağı Tim';

  @override
  String get personnelFirstLoginPasswordHint =>
      '💡 Personel ilk girişinde kendi parolasını belirleyecektir.';

  @override
  String get personnelMakeCommanderAction => 'KOMUTAN YAP VE YETKİLENDİR';

  @override
  String get personnelUsernameAndSquadWarning =>
      'Lütfen kullanıcı adı ve tim seçiniz.';

  @override
  String personnelCommanderSuccess(String name) {
    return '$name Tim Komutanı olarak yetkilendirildi!';
  }

  @override
  String get personnelCommanderDelegationTitle =>
      'Tim Komutanı Yetki Devri / Atama';

  @override
  String get personnelNoCommandersFound =>
      'Kayıtlı Tim Komutanı hesabı bulunamadı.';

  @override
  String personnelCommanderLabel(String name) {
    return 'Komutan: $name';
  }

  @override
  String get personnelAssignedSquadLabel => 'Atanan Tim';

  @override
  String get personnelUnassignedOrUnauthorized => 'BOŞTA / Yetkisiz';

  @override
  String get personnelAuthorizeNewCommander => 'YENİ KOMUTAN YETKİLENDİR';

  @override
  String get personnelNewCommanderDialogTitle => 'Yeni Komutan Yetkilendirme';

  @override
  String get personnelUsernameExampleLabel => 'Kullanıcı Adı (Örn: ahmet.kaya)';

  @override
  String get personnelNoPasswordNeededHint =>
      '💡 Şifre istenmez. Kullanıcı ilk girişinde kendi parolasını belirler.';

  @override
  String get personnelAuthorizeAction => 'YETKİLENDİR';

  @override
  String get squadCreateTitle => 'Yeni Tim Oluştur';

  @override
  String get squadCreateDescription =>
      'Tim bilgilerini girin. Komutan hesabını şimdi veya daha sonra atayabilirsiniz.';

  @override
  String get squadNameLabel => 'Tim adı';

  @override
  String get squadNameHint => 'Örn. 1-B Timi';

  @override
  String get squadNameRequired => 'Tim adı zorunludur';

  @override
  String get squadCommanderUserLabel => 'Komutan kullanıcı adı';

  @override
  String get squadCommanderPasswordHint =>
      'Komutan ilk girişinde kendi parolasını belirler.';

  @override
  String get squadCreateAction => 'Tim Oluştur';

  @override
  String get personnelCustomRankDropdownOption =>
      'DİĞER / ÖZEL RÜTBE (Elle Gir)';

  @override
  String personnelSquadsLoadError(String error) {
    return 'Timler yüklenemedi: $error';
  }

  @override
  String get bulkPersonnelImportTitle => 'Metinden Personel Ekle';

  @override
  String get bulkPersonnelInputLabel => 'Personel listesini yapıştırın';

  @override
  String get bulkPersonnelTargetSquadLabel => 'Hedef tim';

  @override
  String get bulkPersonnelOutsideSquad => 'Tim dışı';

  @override
  String bulkPersonnelCountFound(int count) {
    return '$count personel bulundu';
  }

  @override
  String bulkPersonnelUnknownRankCount(int count) {
    return '$count satırda rütbe bulunamadı. Kaydetmeden önce seçin.';
  }

  @override
  String bulkPersonnelUnreadableLines(int count) {
    return '$count satır okunamadı ve eklenmeyecek.';
  }

  @override
  String bulkPersonnelDuplicatesSkipped(int count) {
    return '$count mükerrer satır kayıtta atlanacak.';
  }

  @override
  String get bulkPersonnelNeedsIdentityDecision =>
      'Mevcut kişi veya ayrı kişi seçilmeli';

  @override
  String get bulkPersonnelDuplicateWillSkip => 'Mükerrer kayıt • Atlanacak';

  @override
  String get bulkPersonnelRankRequired => 'Rütbe seçilmeli';

  @override
  String get bulkPersonnelRemoveTooltip => 'Listeden çıkar';

  @override
  String get bulkPersonnelIdentityDecisionLabel => 'Personel kimliği';

  @override
  String get bulkPersonnelDecisionAuto => 'Karar seçin / aynı kayıt atlanır';

  @override
  String get bulkPersonnelDecisionNew => 'Ayrı bir kişi olarak ekle';

  @override
  String get bulkPersonnelDecisionSkip => 'Bu satırı atla';

  @override
  String bulkPersonnelDecisionUpdate(
      int id, String rank, String unit, String passiveSuffix) {
    return 'Güncelle: #$id • $rank • $unit$passiveSuffix';
  }

  @override
  String get bulkPersonnelPassiveSuffix => ' • Pasif kalır';

  @override
  String get bulkPersonnelNameLabel => 'Ad Soyad';

  @override
  String get bulkPersonnelRankLabel => 'Rütbe';

  @override
  String get bulkPersonnelUnitLabel => 'Birlik';

  @override
  String get bulkPersonnelSquadLabel => 'Tim';

  @override
  String get bulkPersonnelPreviewAction => 'ÖNİZLE';

  @override
  String get bulkPersonnelSavingAction => 'KAYDEDİLİYOR';

  @override
  String get bulkPersonnelSaveAction => 'KAYDET';

  @override
  String get commonActions => 'İşlemler';

  @override
  String commonErrorWithDetails(String error) {
    return 'Hata: $error';
  }

  @override
  String get squadCommanderOptionalHint => 'İsteğe bağlı';

  @override
  String bulkPersonnelErrorSaveFailed(String error) {
    return 'Personel aktarımı kaydedilemedi: $error';
  }

  @override
  String transferActivitiesNoOtherActivities(String date) {
    return '$date tarihinde başka faaliyet kartı bulunamadı.';
  }

  @override
  String get transferSquadAllAlreadyPresent =>
      'Tüm personel zaten hedef faaliyette mevcut, taşıma yapılmadı.';

  @override
  String get activityArchiveOrderSaveFailed => 'Sıralama kaydedilemedi.';

  @override
  String get activityArchiveOrderResetFailed => 'Sıralama sıfırlanamadı.';

  @override
  String activityArchiveDayActivityCount(String day, int count) {
    return '$day • $count faaliyet';
  }

  @override
  String activityArchiveExportSubtitle(
      String date, int count, String squadText) {
    return '$date • $count Faaliyet$squadText';
  }

  @override
  String get rosterSelectedCardsEmpty => 'Henüz kart eklenmedi.';

  @override
  String get rosterSelectedCardsRemoveTooltip => 'Çıktıdan çıkar';

  @override
  String collapsibleSquadCardWarningCount(int count) {
    return '$count uyarı';
  }

  @override
  String get archiveHeaderControlCenter => 'KONTROL MERKEZİ';

  @override
  String get archiveHeaderSquadArchive => 'TİM ARŞİVİ';

  @override
  String archiveHeaderRecordCount(int count) {
    return '$count Kayıt';
  }

  @override
  String archiveHeaderPendingCount(int count) {
    return '$count Bekliyor';
  }

  @override
  String get archiveHeaderExportPrint => 'Dışa Aktar / Yazdır';

  @override
  String get archiveExportSheetTitle => 'Dışa Aktar ve Yazdır';

  @override
  String get archiveExportSheetTimeRangeLabel => 'Saat Aralığı (İsteğe Bağlı)';

  @override
  String get archiveExportSheetTimeRangeHint =>
      'Örn: 06.00-08.00 veya 20.00-08.00';

  @override
  String get archiveExportSheetTimeRangeNote =>
      'Saat girmek istemiyorsanız boş bırakıp doğrudan aşağıdaki seçeneklerden birine basabilirsiniz.';

  @override
  String get archiveExportExcelTitle => 'Excel Olarak Aktar (.xlsx)';

  @override
  String get archiveExportExcelSubtitle =>
      'Hesap tabloları ve dijital arşiv için';

  @override
  String get archiveExportPdfTitle => 'PDF Belgesi Paylaş';

  @override
  String get archiveExportPdfSubtitle =>
      'Askeri formatta PDF oluşturur ve paylaşır';

  @override
  String get archiveExportPrintTitle => 'Doğrudan Yazdır';

  @override
  String get archiveExportPrintSubtitle =>
      'Bağlı yazıcıdan doğrudan çıktı alır';

  @override
  String get archiveExportTextTitle => 'Metin Listesi Paylaş';

  @override
  String get archiveExportTextSubtitle =>
      'WhatsApp/SMS için hizalı metin çıktısı';

  @override
  String get archivePreviousDayTooltip => 'Önceki gün';

  @override
  String get archiveNextDayTooltip => 'Sonraki gün';

  @override
  String archiveActivityCount(int count) {
    return '$count faaliyet';
  }

  @override
  String get personnelPickerTitle => 'Personel Seç';

  @override
  String get personnelPickerSearchHintSingle => 'İsim, soyisim veya rütbe ara';

  @override
  String get personnelPickerSearchHintMulti => 'İsim, rütbe veya tim ara';

  @override
  String get personnelPickerAll => 'Tümü';

  @override
  String get personnelPickerSuggestedMatch => 'Önerilen Eşleşme';

  @override
  String get personnelPickerSelectedPersonnel => 'Seçilen Personel';

  @override
  String get personnelPickerRecent => 'Son Seçilenler';

  @override
  String get personnelPickerUnassignedTeam => 'Tim Dışı';

  @override
  String get personnelPickerUnknownTeam => 'Bilinmeyen Tim';

  @override
  String personnelPickerTeamMemberCount(String teamName, int count) {
    return '$teamName — $count kişi';
  }

  @override
  String personnelPickerSelectedCount(int count) {
    return '$count kişi seçili';
  }

  @override
  String get personnelPickerNoMorePersonnel =>
      'Eklenebilecek personel kalmadı.';

  @override
  String personnelPickerRegisteredWithReason(String teamName, String reason) {
    return '$teamName • Kayıtlı: $reason';
  }

  @override
  String get personnelPickerNotFoundTitle =>
      'Aramanızla eşleşen personel bulunamadı.';

  @override
  String get personnelPickerNotFoundSubtitle =>
      'Yeni bir kayıt gerekiyorsa Personel Yönetimi ekranını kullanın.';

  @override
  String get activityExistingDialogTitle => 'Aynı faaliyet zaten var';

  @override
  String activityExistingDialogFound(String activityName, int count) {
    return '“$activityName” adlı $count kayıt bulundu.';
  }

  @override
  String get activityExistingDialogToUpdate => 'Güncellenecek faaliyet';

  @override
  String activityExistingDialogFoundDate(
      String date, String activityName, int count) {
    return '$date tarihinde “$activityName” adlı $count kayıt bulundu.';
  }

  @override
  String activityExistingDialogNewPersonnelToAdd(int count) {
    return '$count yeni personel eklenecek';
  }

  @override
  String activityExistingDialogAlreadyRegistered(int count) {
    return '$count personel zaten kayıtlı';
  }

  @override
  String activityExistingDialogDifferentPersonnelCountNote(int count) {
    return '$count personelin görev/not bilgisi farklı';
  }

  @override
  String get activityExistingDialogDifferentDutyNote =>
      'görev/not bilgisi farklı';

  @override
  String get activityExistingDialogUpdateDifferent =>
      'Farklı görev/not bilgilerini güncelle';

  @override
  String get activityExistingDialogKeepIfUnselected =>
      'Seçilmezse mevcut bilgiler korunur.';

  @override
  String get activityExistingDialogCreateNew => 'YENİ FAALİYET OLUŞTUR';

  @override
  String get activityExistingDialogAddToExisting => 'MEVCUDA EKLE';

  @override
  String get activityBatchDutyResetDialogTitle => 'Görevler sıfırlansın mı?';

  @override
  String activityBatchDutyResetDialogDesc(String squadName) {
    return '$squadName timindeki tüm görev seçimleri kaldırılacak.';
  }

  @override
  String get activityBatchDutyAssignTitle => 'Toplu görev ata';

  @override
  String activityBatchDutyAssignSquadDesc(String squadName) {
    return '$squadName timindeki tüm personele uygulanır';
  }

  @override
  String get activityBatchDutyResetActionTitle => 'Görevleri sıfırla';

  @override
  String get activityBatchDutyResetActionSubtitle =>
      'Timdeki tüm görev seçimlerini kaldır';

  @override
  String activityBatchDutyAssignSquadTooltip(String squadName) {
    return '$squadName timine toplu görev ata';
  }

  @override
  String activityPersonnelCountBadge(int count) {
    return '$count personel';
  }

  @override
  String get activitySelectedPersonnelEditHint =>
      'Bir personele farklı görev veya not vermek için adına dokunun.';

  @override
  String get activityPersonnelSelectionEmpty =>
      'Aramaya uygun personel bulunamadı.';

  @override
  String get activityFormSelectActivityPrompt => 'Faaliyet seçin';

  @override
  String get activityFormSelectActivityTitle => 'Faaliyet Seç';

  @override
  String get activityFormActivityNameTitle => 'Faaliyet adı';

  @override
  String get activityFormActivityNameHint => 'Faaliyet adını yazın';

  @override
  String get activityFormActivityNameRequired => 'Faaliyet adı zorunludur';

  @override
  String activityFormSelectedBadge(int count) {
    return 'Seçilenler ($count)';
  }

  @override
  String activityFormEditDutyLabel(String name) {
    return '$name görevini düzenle';
  }

  @override
  String activityFormRemoveSelectionTooltip(String name) {
    return '$name seçimini kaldır';
  }

  @override
  String activityAssignmentPreviewError(String error) {
    return 'Görevlendirme kaydedilemedi: $error';
  }

  @override
  String get activityAssignmentPreviewTitle => 'Görevlendirme Önizlemesi';

  @override
  String get activityAssignmentBackAndEdit => 'Geri dön ve düzelt';

  @override
  String activityAssignmentConflictWarning(int count) {
    return '$count personel mevcut görev, izin veya rapor çakışması nedeniyle kaydedilmeyecek.';
  }

  @override
  String activityAssignmentTeamSummary(
      String teamName, int count, String summary) {
    return '$teamName • $count kişi • $summary';
  }

  @override
  String get activityAssignmentPendingApproval => 'Admin onayı bekleyecek';

  @override
  String get activityFormTitle => 'Faaliyet Çizelgesi';

  @override
  String get activityFormBulkPasteTooltip => 'Toplu metin yapıştır';

  @override
  String activityFormSquadError(String error) {
    return 'Tim verileri alınamadı: $error';
  }

  @override
  String activityFormPersonnelLoadError(String error) {
    return 'Personel yüklenemedi: $error';
  }

  @override
  String get activityFormNoSquadWarning =>
      'Henüz bir time atanmadınız. Lütfen yöneticinizle iletişime geçin.';

  @override
  String get activityFormNoPersonnelWarning =>
      'Görevlendirilecek kayıtlı personel bulunamadı.';

  @override
  String activityFormPreviewAndSave(int count) {
    return 'Önizle ve Kaydet ($count)';
  }

  @override
  String activityFormPreviewAndSend(int count) {
    return 'Önizle ve Onaya Gönder ($count)';
  }

  @override
  String get activityFormDiscardChangesTitle => 'Değişiklikler silinsin mi?';

  @override
  String get activityFormDiscardChangesMessage =>
      'Seçtiğiniz personel ve faaliyet bilgileri kaydedilmedi.';

  @override
  String get activityFormCompletePersonnelSelection =>
      'Personel seçimini tamamlayın';

  @override
  String get activityFormCompleteActivityInfo =>
      'Faaliyet bilgilerini tamamlayın';

  @override
  String get activityFormSelectAtLeastOneDuty =>
      'Lütfen en az bir personel için görev seçiniz.';

  @override
  String activityFormPreviewPrepareError(String error) {
    return 'Önizleme hazırlanamadı: $error';
  }

  @override
  String get activityFormSavedAdminPending =>
      'Faaliyet Kaydedildi! Admin onayına gönderildi.';

  @override
  String get activityFormSavedConflictChecked =>
      'Faaliyet Çizelgesi Kaydedildi & Çakışma Denetimi Yapıldı!';

  @override
  String activityFormMergedSummary(int updated, int skipped) {
    return '$updated güncellendi, $skipped kayıt korundu.';
  }

  @override
  String get activityFormBulkImportTitle => 'Toplu metin içe aktar';

  @override
  String get activityFormBulkImportSubtitle =>
      'Birden fazla faaliyet ve personel kaydını panodaki metinden hızlıca oluşturun.';

  @override
  String get activityFormBulkImportPasteAction => 'Metni yapıştır';

  @override
  String get rosterOutputRecordsChangedError =>
      'Kayıtlar değişti. Önizlemeyi yeniden açın.';

  @override
  String rosterOutputSignedOutput(String date, int count) {
    return '$date • $count personel • İmzalı çıktı';
  }

  @override
  String get rosterOutputSelectedCardsTitle => 'Seçilen Kartlar';

  @override
  String get rosterOutputPreviewTitle => 'Birleşik Çıktı Önizlemesi';

  @override
  String rosterOutputPreviewDeduplicationNote(int count) {
    return '$count personel • Her kişi bir kez • Toplam baskıda gösterilmez';
  }

  @override
  String get rosterOutputPreparing => 'Çıktı hazırlanıyor…';

  @override
  String get rosterOutputGetOutput => 'Çıktı Al';

  @override
  String rosterOutputExportError(String error) {
    return 'Dışa aktarılamadı: $error';
  }

  @override
  String get activityFormSearchHint => 'Personel veya birlik ara...';

  @override
  String get activityFormFilterAll => 'Hepsi';

  @override
  String get activityFormFilterUnassigned => 'Atanmayanlar';

  @override
  String get activityNoteAdded => 'Not eklendi';

  @override
  String activitySquadCountBadge(int count) {
    return '$count tim';
  }

  @override
  String get activityAssignmentWillNotBeSaved => 'Kaydedilmeyecek';

  @override
  String get activityAssignmentWillBeSaved => 'Kaydedilecek';

  @override
  String activityFormContinueButton(int count) {
    return 'Devam ($count)';
  }

  @override
  String get commonExit => 'Çık';

  @override
  String get commonContinueRunning => 'Devam et';

  @override
  String activityFormMergeDetailedSummary(int added, int updated, int skipped) {
    return '$added personel eklendi, $updated güncellendi, $skipped kayıt korundu.';
  }

  @override
  String get authSessionFailed => 'Oturum doğrulanamadı.';

  @override
  String get authTeamPermissionExpired => 'Tim yetkiniz sona erdi.';

  @override
  String get activityDetailUnknownSquadHistory => 'Tim geçmişi bilinmiyor';

  @override
  String get activityDetailAddPersonnelButton => '+ Personel Ekle';

  @override
  String get activityDetailAddSingleOption => 'Personel Seçerek Ekle';

  @override
  String get activityDetailAddSingleOptionSubtitle =>
      'Bir veya birden fazla personel seçin';

  @override
  String get activityDetailAddBulkOption => 'Metinden Toplu Ekle';

  @override
  String get activityDetailAddBulkOptionSubtitle =>
      'Listeyi tam önizleme ve hata kontrolüyle aktar';

  @override
  String get activityDetailAddImageOption => 'Görselden Toplu Ekle';

  @override
  String get activityDetailAddImageOptionSubtitle =>
      'Personel listesini görselden okuyup bu karta ekle';

  @override
  String get activityDetailImagePlatformWarning =>
      'Görselden aktarım Android ve iOS cihazlarda kullanılabilir.';

  @override
  String activityDetailImageReadError(String error) {
    return 'Görsel okunamadı: $error';
  }

  @override
  String get activityDetailPersonnelAdded => 'Personel faaliyete eklendi.';

  @override
  String get activityDetailPersonnelAddedAdminPending =>
      'Personel eklendi, Admin onayına gönderildi.';

  @override
  String get activityDetailExportTooltip => 'Bu Faaliyeti Dışa Aktar';

  @override
  String get activityDetailExportTitle => 'Dışa Aktar';

  @override
  String get activityDetailExportSubtitle =>
      'Faaliyet listesini paylaş veya yazdır';

  @override
  String get activityDetailCombineOutputTitle =>
      'Kartları Birleştir ve Çıktı Al';

  @override
  String get activityDetailCombineOutputSubtitle =>
      'Aynı gün ve önceki gün kartlarını imzalı çıktıda birleştir';

  @override
  String get activityDetailExportExcel => 'Excel’e aktar';

  @override
  String get activityDetailExportExcelSubtitle => 'Hesap tablosu olarak paylaş';

  @override
  String get activityDetailExportPdf => 'PDF / Yazdır';

  @override
  String get activityDetailExportPdfSubtitle =>
      'PDF oluştur veya doğrudan yazdır';

  @override
  String get activityDetailExportText => 'Metin olarak paylaş';

  @override
  String get activityDetailExportTextSubtitle =>
      'Mesajlaşma uygulamaları için hazırla';

  @override
  String get activityDetailNoPersonnelAssigned =>
      'Bu faaliyette görevlendirilmiş personel bulunmuyor.';

  @override
  String get activityDetailNoPrintablePersonnel =>
      'Seçilen timlerde yazdırılabilir personel bulunamadı.';

  @override
  String get activityDetailOutSquad => 'Tim Dışı';

  @override
  String get activityDetailUnknownSquad => 'Bilinmeyen Tim';

  @override
  String get activityDetailDeleteSquadsTitle => 'Timleri Faaliyetten Sil';

  @override
  String activityDetailDeleteSquadsConfirm(String teamNames, int count) {
    return '$teamNames timlerindeki $count personel bu faaliyetten çıkarılacaktır. Emin misiniz?';
  }

  @override
  String get activityDetailDeleteSquadsAction => 'TİMLERİ SİL';

  @override
  String activityDetailPersonnelRemovedCount(int count) {
    return '$count personel faaliyetten çıkarıldı.';
  }

  @override
  String activityDetailDutyPending(String duty) {
    return '$duty • BEKLİYOR';
  }

  @override
  String activityDetailNoteLabel(String note) {
    return 'Not: $note';
  }

  @override
  String get commonApproveTooltip => 'Onayla';

  @override
  String get commonRejectTooltip => 'Reddet';

  @override
  String activityDetailApproveBlocked(String reason) {
    return 'Onaylanamadı: $reason';
  }

  @override
  String get commonActionsTooltip => 'İşlemler';

  @override
  String get activityDetailDutyUpdated => 'Görev güncellendi.';

  @override
  String get activityDetailDutyUpdatePending =>
      'Görev değişikliği kaydedildi, Admin onayına gönderildi.';

  @override
  String get activityDetailRemovePersonnelTitle => 'Personeli Görevden Çıkar';

  @override
  String activityDetailRemovePersonnelConfirm(String name, String activity) {
    return '$name adlı personel $activity faaliyetinden çıkarılacaktır. Emin misiniz?';
  }

  @override
  String get activityDetailRemoveAction => 'ÇIKAR';

  @override
  String activityDetailPersonnelRemoved(String name) {
    return '$name faaliyetten çıkarıldı.';
  }

  @override
  String get activityDetailAssignmentActions => 'Atama İşlemleri';

  @override
  String get activityDetailEditDutySubtitle =>
      'Görev veya izin bilgisini değiştir';

  @override
  String get activityDetailTransferCard => 'Başka karta taşı';

  @override
  String get activityDetailTransferCardSubtitle =>
      'Personeli farklı faaliyete aktar';

  @override
  String get activityDetailRemoveFromActivity => 'Faaliyetten çıkar';

  @override
  String get activityDetailRemoveFromActivitySubtitle =>
      'Personelin bu atamasını kaldır';

  @override
  String activitySelectedSquadCount(int count) {
    return '$count tim seçildi';
  }

  @override
  String get commonPrint => 'Yazdır';

  @override
  String get activityDeleteSelectedSquadsTooltip =>
      'Seçilen timleri faaliyetten sil';

  @override
  String activitySquadCardTitle(String teamName, int count) {
    return '$teamName — $count kişi';
  }

  @override
  String activityTransferSquadTooltip(String teamName) {
    return '$teamName timini başka karta taşı';
  }

  @override
  String activityDutyPickerTitleForPerson(String name) {
    return '$name için görev';
  }

  @override
  String get bulkImportKeepAuditTextTitle =>
      'Ham metni yerel denetim kaydında sakla';

  @override
  String get bulkImportSaveActivitiesButton => 'Faaliyetleri Kaydet';

  @override
  String bulkImportOptionalReviewsCount(int count) {
    return '$count isteğe bağlı inceleme';
  }

  @override
  String get bulkImportConfirmAllAction => 'Tümünü Onayla';

  @override
  String get bulkImportConfirmAction => 'Onayla';

  @override
  String get bulkImportNoCardsHint =>
      'Yapıştır adımına dönüp mesajı yapıştırın.';

  @override
  String get bulkImportProceedToSaveStep => 'Kaydetme Adımına Geç';

  @override
  String bulkImportSaveSummarySub(int blockCount, int dayCount) {
    return '$blockCount blok -> $dayCount günlük faaliyet';
  }

  @override
  String bulkImportSaveWithCardCount(int count) {
    return 'Faaliyetleri Kaydet ($count Kart)';
  }

  @override
  String bulkImportActionsRemainingToSave(int count) {
    return 'Kaydetmek için $count işlem kaldı';
  }

  @override
  String get bulkImportUnresolvedIssuesError =>
      'Lütfen önce çözülmemiş kart sorunlarını (tarih, tim veya görev türü) tamamlayın.';

  @override
  String get bulkImportClearPreviewConfirmDesc =>
      'Oluşturulan tüm kartlar ve ayrıştırma uyarıları kaldırılacak.';

  @override
  String bulkImportPersonnelAddedAndMatched(
      String rank, String name, String timName) {
    return '$rank $name veritabanına ($timName) eklendi ve eşleştirildi.';
  }

  @override
  String bulkImportIssueEmptyBlock(int number) {
    return 'Kart #$number: Personel bulunamadı.';
  }

  @override
  String bulkImportIssueMissingDate(int number) {
    return 'Kart #$number: Bu personel grubu için geçerli bir tarih bulunamadı.';
  }

  @override
  String bulkImportIssueUnknownTeam(int number) {
    return 'Kart #$number: Takım/tim adı belirtilmedi.';
  }

  @override
  String bulkImportIssueUnknownActivity(int number) {
    return 'Kart #$number: Görev türü tanınamadı.';
  }

  @override
  String bulkImportIssueUnmatchedPersonnel(String rank, String name) {
    return '$rank $name için personel seçimi yapılmadı.';
  }

  @override
  String bulkImportMobileSummaryReady(int cardCount, int personnelCount) {
    return '$cardCount kart • $personnelCount personel • Hazır';
  }

  @override
  String bulkImportMobileSummaryErrors(
      int cardCount, int personnelCount, int count) {
    return '$cardCount kart • $personnelCount personel • $count hata';
  }

  @override
  String bulkImportMobileSummaryReviews(
      int cardCount, int personnelCount, int count) {
    return '$cardCount kart • $personnelCount personel • $count inceleme';
  }

  @override
  String get cancelSelectionTooltip => 'Seçimi İptal Et';

  @override
  String bulkImportRegisteredTeamLabel(String team) {
    return 'Kayitli tim: $team';
  }

  @override
  String bulkImportListTeamLabel(String team) {
    return 'Liste timi: $team';
  }

  @override
  String get bulkImportNoTeamSpecified => 'Tim belirtilmedi';

  @override
  String get commonChange => 'Değiştir';

  @override
  String get bulkImportSelectPersonnelButton => 'Personel Seç';

  @override
  String bulkImportAddToTeamAction(String team) {
    return '+ $team Ekle';
  }

  @override
  String bulkImportAliasDeleteConfirm(String alias, String target) {
    return '\'$alias\' ➔ \'$target\' öğrenilmiş takma ad eşleşmesi silinsin mi?';
  }

  @override
  String bulkImportAliasDeletedMessage(String alias) {
    return '\'$alias\' hafızadan silindi.';
  }

  @override
  String bulkImportLearnedAliasCount(int count) {
    return '$count Öğrenilmiş İsim Takma Adı';
  }

  @override
  String get bulkImportSearchAliasShortHint => 'Yazım veya personel adı ara';

  @override
  String get bulkImportSearchAliasHint =>
      'Metindeki yazım veya personel adıyla ara...';

  @override
  String get bulkImportNoMatchingAliasFound =>
      'Aramanıza uygun takma ad bulunamadı.';

  @override
  String get bulkImportNoLearnedAliasesDesc =>
      'Henüz öğrenilmiş bir takma ad bulunmuyor.\nToplu aktarımlarda onayladığınız eşleşmeler otomatik hafızaya alınır.';

  @override
  String get bulkImportMatchedPersonnelLabel => 'Eşleştiği personel';

  @override
  String get bulkImportUnassignedPersonnelTitle => 'Timsiz / Diğer Personeller';

  @override
  String get bulkImportCustomTeamOption => 'DİĞER (Elle Yaz...)';

  @override
  String authPasswordPolicyMinLength(int count) {
    return 'Parola en az $count karakter olmalıdır.';
  }

  @override
  String dashboardImageReadError(String error) {
    return 'Görsel okunamadı: $error';
  }

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get commonUser => 'Kullanıcı';

  @override
  String authUnsupportedRole(String role) {
    return 'Desteklenmeyen kullanıcı rolü: $role';
  }

  @override
  String get commonSessionNotVerified => 'Oturum doğrulanamadı.';

  @override
  String get conflictConflictingRecord => 'Çakışan kayıt';

  @override
  String get conflictAnotherActivityExists =>
      'Bu tarihte başka bir faaliyet kaydı bulunuyor.';

  @override
  String get matrixSelectDate => 'Tarih Seçin';

  @override
  String get matrixEmpty => ', boş';

  @override
  String matrixDayNumber(int day, String status) {
    return '$day. gün$status';
  }

  @override
  String matrixSearchPersonnelResult(String query, int visible, int total) {
    return '“$query” · $visible/$total kişi';
  }

  @override
  String get matrixNoAuthorizedRecordsForExport =>
      'Dışa aktarılacak yetkili kayıt bulunamadı.';

  @override
  String matrixTeamDutyCalendarTitle(String team) {
    return '$team Görev Takvimi';
  }

  @override
  String matrixMonthlyOperationalView(int year, String month) {
    return '$year / $month Ayı Operasyonel Görünüm';
  }

  @override
  String get matrixMonthlyDailyDistribution => 'Aylık Günlük Dağılım';

  @override
  String get matrixClickDayForDetails => 'Detaylar için güne tıklayın';

  @override
  String get matrixDutyDay => 'Görevli Gün';

  @override
  String matrixDutyDayCount(int count) {
    return '$count Gün';
  }

  @override
  String matrixActivePersonnelCount(int count) {
    return '$count Kişi';
  }

  @override
  String get matrixPersonnelDayRatio => 'Personel-gün oranı';

  @override
  String matrixUnknownSquadAssignmentsNotice(int count) {
    return 'Bu ay tim geçmişi bilinmeyen $count eski atama var; tim hesabına katılmadı.';
  }

  @override
  String get matrixNoDutyPersonnelOnDate =>
      'Bu tarihte görevli personel kaydı bulunmuyor.';

  @override
  String get matrixApprovedStatus => 'Onaylı';

  @override
  String matrixContinuingFromPreviousDay(int count) {
    return 'Önceki günden devam eden $count kişi';
  }

  @override
  String temgundrapOutputPrepareError(String error) {
    return 'Çıktı hazırlanamadı: $error';
  }

  @override
  String get temgundrapPreviewTitle => 'TEMGÜNDRAP Önizleme';

  @override
  String get temgundrapSharePdfAction => 'PDF Paylaş';

  @override
  String get temgundrapIssuingUnit => 'Çıkaran birlik';

  @override
  String get temgundrapDescription => 'Açıklama';

  @override
  String get temgundrapSelectCommanderFirst =>
      'Önce operasyon komutanını seçin.';

  @override
  String get temgundrapSelectNumberToUse => 'Kullanılacak numarayı seçin';

  @override
  String get temgundrapNoValidPhoneFound =>
      'Seçilen kişide geçerli cep telefonu bulunamadı.';

  @override
  String get temgundrapPhoneMatchedWithPersonnel =>
      'Telefon personelle eşleştirildi.';

  @override
  String get temgundrapOperationCommander => 'Operasyon Komutanı';

  @override
  String get temgundrapSelectFromPersonnelList => 'Personel listesinden seçin';

  @override
  String get temgundrapPhoneToUse => 'Kullanılacak telefon';

  @override
  String get temgundrapPhoneAutoMatchesNextTime =>
      'Bir kez eşleştirilince sonraki seçimlerde otomatik gelir.';

  @override
  String get temgundrapSelectFromContacts => 'Telefon rehberinden seç';

  @override
  String get temgundrapEnterValidPhone => 'Geçerli bir cep telefonu girin.';

  @override
  String get temgundrapOperationArea => 'Operasyon bölgesi';

  @override
  String get temgundrapOperationAreaRequired => 'Operasyon bölgesi zorunludur.';

  @override
  String get temgundrapEnterCustomOperationArea =>
      'Özel operasyon bölgesini girin.';

  @override
  String get temgundrapTypeOperationArea => 'Operasyon bölgesini yazın';

  @override
  String get temgundrapEditOperationTitle => 'Operasyonu Düzenle';

  @override
  String get temgundrapOperationPurpose => 'Operasyon maksadı';

  @override
  String temgundrapPersonnelListLoadError(String error) {
    return 'Personel listesi yüklenemedi: $error';
  }

  @override
  String get temgundrapUpdateOperationAction => 'OPERASYONU GÜNCELLE';

  @override
  String get temgundrapStartTime => 'Başlama zamanı';

  @override
  String get temgundrapEndTime => 'Bitiş zamanı';

  @override
  String get temgundrapVehicles => 'Araçlar';

  @override
  String get temgundrapVehicleModel => 'Araç modeli';

  @override
  String get temgundrapRegisteredPlates => 'Kayıtlı plakalar:';

  @override
  String get rosterOutputCommanderTeamRevoked => 'Tim yetkiniz sona erdi.';

  @override
  String get statusApproved => 'Onaylı';

  @override
  String get statusPending => 'Bekleyen';

  @override
  String get statusRejected => 'Reddedilen';

  @override
  String get personnelUnitHint => 'Örn: 1\'inci Bl.';

  @override
  String get temgundrapAddOperationTitle => 'Operasyon Ekle';

  @override
  String get temgundrapAddOperationAction => 'OPERASYONU EKLE';

  @override
  String get commonUpdate => 'GÜNCELLE';

  @override
  String get confirmDiscardTitle => 'Değişikliklerden vazgeçilsin mi?';

  @override
  String get confirmDiscardContent => 'Kaydedilmeyen bilgiler kaybolacak.';

  @override
  String get confirmDiscardContinue => 'DÜZENLEMEYE DEVAM ET';

  @override
  String get confirmDiscardExit => 'VAZGEÇ VE ÇIK';

  @override
  String get authSessionUnverified => 'Oturum doğrulanamadı.';

  @override
  String get temgundrapUnitHint => 'Örn: KOVANCILAR J.KOMD.ÖZ.HRK.TB.K.LIĞI';

  @override
  String get temgundrapApproverNameHint => 'Örn: İhsan DAĞLI';

  @override
  String get temgundrapApproverRankHint => 'Örn: J.Ütğm.';

  @override
  String get temgundrapApproverDutyHint => 'Örn: Tb. K. V.';

  @override
  String get backupDialogTitle => 'Tam yedekleme ve geri yükleme';

  @override
  String get backupDialogSubtitle =>
      'Bulut gerekmez; dosya sizin seçtiğiniz yerde kalır.';

  @override
  String get backupTabExport => 'Yedekle';

  @override
  String get backupTabImport => 'Geri yükle';

  @override
  String get backupWhatsIncludedTitle => 'Yedekte neler var?';

  @override
  String get backupWhatsIncludedText =>
      'İsimler, timler, kullanıcılar, telefonlar, görevler, aylık matris, faaliyet arşivi, raporlar, takma adlar, toplu aktarım geçmişi ve TEMGÜNDRAP belgeleri.';

  @override
  String get backupKeepSafeTitle => 'Uygulama silinse de koruyun';

  @override
  String get backupKeepSafeText =>
      'Açılan kaydet ekranından İndirilenler gibi cihazın yerel bir klasörünü seçin. Uygulamanın kendi klasörüne bırakmayın.';

  @override
  String get backupSecurityTitle => 'Dosyayı güvenli tutun';

  @override
  String get backupSecurityText =>
      'Yedek kişisel bilgiler içerir. Yalnızca güvenilir bir yerel klasörde saklayın ve başkalarıyla paylaşmayın.';

  @override
  String get backupLegacyDateText => 'Eski yedek';

  @override
  String get backupLegacyTitle => 'Eski personel yedeği';

  @override
  String get backupVerifiedFullTitle => 'Doğrulanmış tam yedek';

  @override
  String backupPreviewStats(String date, int personnel, int activity,
      int assignment, int temgundrap) {
    return '$date • $personnel personel • $activity faaliyet • $assignment görev kaydı • $temgundrap TEMGÜNDRAP';
  }

  @override
  String backupLegacyRestoreSuccess(int count) {
    return '$count yeni personel eski yedekten aktarıldı.';
  }

  @override
  String get backupConfirmOverwriteContent =>
      'Tam geri yükleme mevcut personel, görev, matris ve TEMGÜNDRAP kayıtlarının yerine yedekteki verileri koyar. Bu işlem geri alınamaz.';

  @override
  String bulkImportCriticalErrorsCount(int count) {
    return '$count kritik hata';
  }

  @override
  String bulkImportLinePrefix(int line) {
    return 'Satır $line: ';
  }

  @override
  String get bulkImportEmptySummaryHint =>
      'Lütfen aşağıda vurgulanan kartlardaki eksik personelleri eşleştirin, tekrarları düzeltin veya boş kartları silin.';

  @override
  String get bulkParseEmptyInput => 'Ayrıştırılacak metin boş.';

  @override
  String get bulkParseMissingDate =>
      'Bu personel grubu için geçerli bir tarih bulunamadı.';

  @override
  String get bulkParseUnknownTeam => 'Takım/tim bilgisi tanınamadı.';

  @override
  String get bulkParseUnknownActivity => 'Görev türü tanınamadı.';

  @override
  String get bulkParseInvalidTime => 'Saat aralığı geçerli değil.';

  @override
  String get bulkParseInvalidDate => 'Tarih geçerli değil.';

  @override
  String get bulkParseInvalidPersonnel => 'Personel satırı çözümlenemedi.';

  @override
  String get bulkParseUnknownRank =>
      'Rütbe tanınamadı; ham personel adı korundu.';

  @override
  String get bulkParseNoBlocks =>
      'Metinde aktarılabilecek personel bloğu bulunamadı.';

  @override
  String get commonFix => 'Düzelt';

  @override
  String assignmentConflictHasRecord(String date) {
    return '$date tarihinde personelin başka bir kaydı bulunuyor.';
  }

  @override
  String assignmentConflictHasDutyOrRecord(String date) {
    return '$date tarihinde personelin başka bir görevi veya kaydı bulunuyor.';
  }

  @override
  String assignmentConflictDateChange(String date) {
    return '$date tarihinde personelin başka bir kaydı bulunuyor. Faaliyet tarihi değiştirilmedi.';
  }

  @override
  String assignmentConflictReport(String date) {
    return '$date tarihinde personelin başka bir görevi, izni veya raporu bulunuyor. Rapor kaydedilmedi.';
  }

  @override
  String get transferPersonnelAlreadyInTarget =>
      'Bu personel zaten hedef faaliyette mevcut.';

  @override
  String bulkImportDuplicateWarningContent(
      String dates, String recordDate, String user, int count) {
    return '$dates tarihli bu içerik $recordDate tarihinde $user tarafından kaydedilmiş.\n\nVeritabanında bu listeye ait $count personel kaydı aktif duruyor. Eksik olanları tamamlamak veya yeniden aktarmak istiyor musunuz?';
  }

  @override
  String get bulkImportDefaultSquad => 'Varsayılan Tim';

  @override
  String bulkImportBlockPersonnelCount(int count) {
    return '$count personel';
  }

  @override
  String get bulkImportFocusedError => 'ODAKLANILAN HATA';

  @override
  String get bulkImportInspectedCard => 'İNCELENEN KART';

  @override
  String get bulkImportEmptyCard => 'Boş Kart';

  @override
  String bulkImportUnmatchedCount(int count) {
    return '$count Eşleşmedi';
  }

  @override
  String bulkImportWarningCount(int count) {
    return '$count Uyarı';
  }

  @override
  String get bulkImportCardActionsTooltip => 'Kart işlemleri';

  @override
  String get bulkImportCardActionsTitle => 'Kart İşlemleri';

  @override
  String get bulkImportCardActionsSubtitle => 'İçe aktarma kartını yönet';

  @override
  String get bulkImportEditCardTitle => 'Kartı düzenle';

  @override
  String get bulkImportEditCardSubtitle =>
      'Faaliyet ve personel bilgilerini güncelle';

  @override
  String get bulkImportDeleteCardTitle => 'Kartı sil';

  @override
  String get bulkImportDeleteCardSubtitle =>
      'Kartı içe aktarma listesinden kaldır';

  @override
  String bulkImportProblemNoPersonnelInCard(String title) {
    return '$title kartında personel bulunamadı.';
  }

  @override
  String bulkImportProblemInvalidDate(int cardNumber) {
    return 'Kart #$cardNumber: Geçerli bir tarih bulunamadı.';
  }

  @override
  String bulkImportProblemMissingTeam(int cardNumber) {
    return 'Kart #$cardNumber: Takım adı belirtilmedi (Personelin kayıtlı timi kullanılacak).';
  }

  @override
  String bulkImportProblemUnknownActivity(int cardNumber) {
    return 'Kart #$cardNumber: Görev türü tanınamadı.';
  }

  @override
  String bulkImportProblemPersonnelNotSelected(
      String prefix, String rank, String name) {
    return '$prefix$rank $name - Personel seçilmedi.';
  }

  @override
  String bulkImportProblemConflictingDuty(
      String prefix, String rank, String name) {
    return '$prefix$rank $name - Çakışan görev ekli.';
  }

  @override
  String get bulkImportProblemCheckTeam => 'Tim kontrolü gerektiriyor.';

  @override
  String get bulkImportProblemCheckMatch => 'Eşleşme kontrolü gerektiriyor.';

  @override
  String bulkImportProblemLinePrefix(int lineNumber) {
    return 'Satır $lineNumber: ';
  }

  @override
  String get temgundrapIssuingUnitRequired => 'Çıkaran birlik zorunludur.';

  @override
  String get temgundrapCommanderRequired => 'Operasyon komutanı seçilmelidir.';

  @override
  String get temgundrapCommanderPhoneRequired => 'Komutan telefonu zorunludur.';

  @override
  String get temgundrapEndTimeMustBeAfterStart =>
      'Bitiş zamanı başlangıçtan sonra olmalıdır.';

  @override
  String get temgundrapPurposeRequired => 'Operasyon maksadı zorunludur.';

  @override
  String get temgundrapVehiclePlateAlreadyExists => 'Bu plaka zaten eklendi.';

  @override
  String get temgundrapPlateHint => 'Örn. 23 ABC 123';

  @override
  String get temgundrapAreaHint => 'Örn: ELAZIĞ ...';

  @override
  String get temgundrapPlateLabel => 'Plaka';

  @override
  String get commonConfirmAndSave => 'Onayla ve Kaydet';

  @override
  String monthlyMatrixOriginalDate(String duty, String date) {
    return '$duty • Asıl tarih: $date';
  }

  @override
  String get monthlyMatrixContinuedFromPreviousDay => 'Önceki günden devam';

  @override
  String get monthlyMatrixActivePersonnelLabel => 'Aktif Personel';

  @override
  String get monthlyMatrixMissingData => 'Veri eksik';

  @override
  String activityDetailPersonnelFallback(int id) {
    return 'Personel #$id';
  }

  @override
  String bulkImportSuccessMessage(
      int blockCount, int requestCount, int personnelCount) {
    return '$blockCount blok → $requestCount günlük faaliyet, $personnelCount personel başarıyla eklendi.';
  }

  @override
  String get bulkImportDuplicateDatePersonnelWarning =>
      'Aynı personel aynı tarihte birden fazla görevde bulunuyor. Aktarmadan önce önizlemedeki tekrarları düzeltin.';

  @override
  String get bulkImportNoPersonnelLeftInCard =>
      'Bu kartta personel kalmadı. Kartı silin veya metni yeniden ayrıştırın.';

  @override
  String get temgundrapSigned => '(İMZALI)';

  @override
  String get temgundrapCommanderLabel => 'Komutan';

  @override
  String get temgundrapForceLabel => 'Kuvvet';

  @override
  String get temgundrapTimeLabel => 'Zaman';
}
