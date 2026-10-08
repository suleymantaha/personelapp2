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
  String get commonClose => 'Kapat';

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
  String get commonSaving => 'KAYDEDİLİYOR…';

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
}
