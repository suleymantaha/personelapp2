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
  String get dashboardTitle => 'Ana Sayfa';

  @override
  String get dashboardQuickActions => 'Hızlı İşlemler';

  @override
  String get dashboardStatistics => 'İstatistikler';

  @override
  String get dashboardRecentActivities => 'Son Faaliyetler';

  @override
  String get authLoginTitle => 'Giriş Yap';

  @override
  String get authUsername => 'Kullanıcı Adı';

  @override
  String get authPassword => 'Şifre';

  @override
  String get authLoginButton => 'Giriş';

  @override
  String get authLogoutButton => 'Çıkış Yap';

  @override
  String get authSessionExpired => 'Oturum süresi doldu';

  @override
  String get matrixTitle => 'Matris ve Çizelge';

  @override
  String get reportTitle => 'Raporlar';
}
