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
  String get commonCancel => 'Vazgeç';

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
  String get commonSaving => 'KAYDEDİLİYOR…';

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
}
