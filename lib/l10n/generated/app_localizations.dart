import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('tr')];

  /// Uygulama adı
  ///
  /// In tr, this message translates to:
  /// **'Nizam'**
  String get appTitle;

  /// No description provided for @commonSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get commonCancel;

  /// No description provided for @commonDismiss.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get commonDismiss;

  /// No description provided for @commonReset.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get commonReset;

  /// No description provided for @commonClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get commonBack;

  /// No description provided for @commonDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get commonAdd;

  /// No description provided for @commonSelect.
  ///
  /// In tr, this message translates to:
  /// **'Seç'**
  String get commonSelect;

  /// No description provided for @commonSearch.
  ///
  /// In tr, this message translates to:
  /// **'Ara...'**
  String get commonSearch;

  /// No description provided for @commonFilter.
  ///
  /// In tr, this message translates to:
  /// **'Filtrele'**
  String get commonFilter;

  /// No description provided for @commonClear.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get commonClear;

  /// No description provided for @commonSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Başarılı'**
  String get commonSuccess;

  /// No description provided for @commonError.
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get commonError;

  /// No description provided for @commonWarning.
  ///
  /// In tr, this message translates to:
  /// **'Uyarı'**
  String get commonWarning;

  /// No description provided for @commonInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi'**
  String get commonInfo;

  /// No description provided for @commonConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get commonConfirm;

  /// No description provided for @commonYes.
  ///
  /// In tr, this message translates to:
  /// **'Evet'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In tr, this message translates to:
  /// **'Hayır'**
  String get commonNo;

  /// No description provided for @commonOk.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get commonOk;

  /// No description provided for @commonAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get commonAll;

  /// No description provided for @commonRequired.
  ///
  /// In tr, this message translates to:
  /// **'Zorunlu alan'**
  String get commonRequired;

  /// No description provided for @commonLoading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get commonLoading;

  /// No description provided for @commonNoData.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt bulunamadı'**
  String get commonNoData;

  /// No description provided for @commonActivity.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet'**
  String get commonActivity;

  /// No description provided for @commonApprove.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get commonApprove;

  /// No description provided for @commonReject.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get commonReject;

  /// No description provided for @commonUnauthorized.
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfaya erişim yetkiniz bulunmuyor.'**
  String get commonUnauthorized;

  /// No description provided for @activitySelectDutyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Görev veya İzin Seçin'**
  String get activitySelectDutyTitle;

  /// No description provided for @activityCommonDuty.
  ///
  /// In tr, this message translates to:
  /// **'Ortak Görev'**
  String get activityCommonDuty;

  /// No description provided for @activityPersonalDuty.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel Görev'**
  String get activityPersonalDuty;

  /// No description provided for @activitySelectPersonalDuty.
  ///
  /// In tr, this message translates to:
  /// **'Özel Görev Seç'**
  String get activitySelectPersonalDuty;

  /// No description provided for @activityDutyChangeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Görev / Durum Değiştir'**
  String get activityDutyChangeTitle;

  /// No description provided for @activityDutyChangeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen personel için geçerli görev veya izin durumunu güncelleyin.'**
  String get activityDutyChangeSubtitle;

  /// No description provided for @activityUpdateSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Görev başarıyla güncellendi'**
  String get activityUpdateSuccess;

  /// No description provided for @activityScheduleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet Çizelgesi'**
  String get activityScheduleTitle;

  /// No description provided for @activityAddPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Personel Ekle'**
  String get activityAddPersonnel;

  /// No description provided for @activityArchive.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet Arşivi'**
  String get activityArchive;

  /// No description provided for @activityDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get activityDate;

  /// No description provided for @activityPersonnelCount.
  ///
  /// In tr, this message translates to:
  /// **'Personel Sayısı'**
  String get activityPersonnelCount;

  /// No description provided for @activityDuty.
  ///
  /// In tr, this message translates to:
  /// **'Görev'**
  String get activityDuty;

  /// No description provided for @activityShift.
  ///
  /// In tr, this message translates to:
  /// **'Vardiya'**
  String get activityShift;

  /// No description provided for @activityNotes.
  ///
  /// In tr, this message translates to:
  /// **'Notlar'**
  String get activityNotes;

  /// No description provided for @activitySelectDutyHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir görev türü seçiniz'**
  String get activitySelectDutyHint;

  /// No description provided for @activitySearchDutyHint.
  ///
  /// In tr, this message translates to:
  /// **'Görev ara...'**
  String get activitySearchDutyHint;

  /// No description provided for @activityLeaveType.
  ///
  /// In tr, this message translates to:
  /// **'İzin Türü'**
  String get activityLeaveType;

  /// No description provided for @activityDutyChange.
  ///
  /// In tr, this message translates to:
  /// **'Görev Değişikliği'**
  String get activityDutyChange;

  /// No description provided for @activityDutyOrLeaveType.
  ///
  /// In tr, this message translates to:
  /// **'Görev / İzin Türü'**
  String get activityDutyOrLeaveType;

  /// No description provided for @activityDutyNoteOptional.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama / Not (İsteğe Bağlı)'**
  String get activityDutyNoteOptional;

  /// No description provided for @activityDutyNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Gece nöbeti, özel devriye vb.'**
  String get activityDutyNoteHint;

  /// No description provided for @activityAssignCommonDuty.
  ///
  /// In tr, this message translates to:
  /// **'Ortak Görev'**
  String get activityAssignCommonDuty;

  /// No description provided for @activityAssignDutyToSelected.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen personele görev ata'**
  String get activityAssignDutyToSelected;

  /// No description provided for @activitySelectCommonDuty.
  ///
  /// In tr, this message translates to:
  /// **'Ortak görev seç'**
  String get activitySelectCommonDuty;

  /// No description provided for @activityUseCommonDuty.
  ///
  /// In tr, this message translates to:
  /// **'Ortak görevi kullan'**
  String get activityUseCommonDuty;

  /// No description provided for @activitySquadDutyAssignTitle.
  ///
  /// In tr, this message translates to:
  /// **'{squadName} timine görev ata'**
  String activitySquadDutyAssignTitle(String squadName);

  /// No description provided for @activityPersonnelDutyTitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} için görev'**
  String activityPersonnelDutyTitle(String name);

  /// No description provided for @activityPersonnelNoteTitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} için not'**
  String activityPersonnelNoteTitle(String name);

  /// No description provided for @activitySelectDifferentDuty.
  ///
  /// In tr, this message translates to:
  /// **'Farklı görev seç'**
  String get activitySelectDifferentDuty;

  /// No description provided for @activityDutyNotSelected.
  ///
  /// In tr, this message translates to:
  /// **'Görev seçilmedi'**
  String get activityDutyNotSelected;

  /// No description provided for @activityAddOrEditNote.
  ///
  /// In tr, this message translates to:
  /// **'Not ekle veya düzenle'**
  String get activityAddOrEditNote;

  /// No description provided for @activityNoNote.
  ///
  /// In tr, this message translates to:
  /// **'Not yok'**
  String get activityNoNote;

  /// No description provided for @activityOptionalNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'İsteğe bağlı not'**
  String get activityOptionalNoteHint;

  /// No description provided for @activityPreviewHint.
  ///
  /// In tr, this message translates to:
  /// **'Bilgileri kontrol ettikten sonra görevlendirme önizlemesine geçebilirsiniz.'**
  String get activityPreviewHint;

  /// No description provided for @activitySelectedPersonnelCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel seçildi'**
  String activitySelectedPersonnelCount(int count);

  /// No description provided for @activityChange.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get activityChange;

  /// No description provided for @activityCommonDutyHelper.
  ///
  /// In tr, this message translates to:
  /// **'Tüm seçilen personele uygular'**
  String get activityCommonDutyHelper;

  /// No description provided for @activityPersonalDutyLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kişiye özel görev'**
  String get activityPersonalDutyLabel;

  /// No description provided for @activityOutsideSquad.
  ///
  /// In tr, this message translates to:
  /// **'Tim Dışı'**
  String get activityOutsideSquad;

  /// No description provided for @activityAdminAddNotice.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen personel bu faaliyete eklenecek.'**
  String get activityAdminAddNotice;

  /// No description provided for @activityUserAddNotice.
  ///
  /// In tr, this message translates to:
  /// **'Personel eklendikten sonra admin onayına gönderilecek.'**
  String get activityUserAddNotice;

  /// No description provided for @activityCloseNote.
  ///
  /// In tr, this message translates to:
  /// **'Notu kapat'**
  String get activityCloseNote;

  /// No description provided for @activityAddNote.
  ///
  /// In tr, this message translates to:
  /// **'Not ekle'**
  String get activityAddNote;

  /// No description provided for @activityEditNote.
  ///
  /// In tr, this message translates to:
  /// **'Notu düzenle'**
  String get activityEditNote;

  /// No description provided for @activityGeneralDutyNoteHint.
  ///
  /// In tr, this message translates to:
  /// **'Görevle ilgili not'**
  String get activityGeneralDutyNoteHint;

  /// No description provided for @personnelManagementTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personel Yönetimi'**
  String get personnelManagementTitle;

  /// No description provided for @personnelListTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personel Listesi'**
  String get personnelListTitle;

  /// No description provided for @personnelAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Personel Ekle'**
  String get personnelAddTitle;

  /// No description provided for @personnelEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personeli Düzenle'**
  String get personnelEditTitle;

  /// No description provided for @personnelName.
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get personnelName;

  /// No description provided for @personnelSurname.
  ///
  /// In tr, this message translates to:
  /// **'Soyad'**
  String get personnelSurname;

  /// No description provided for @personnelFullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get personnelFullName;

  /// No description provided for @personnelRank.
  ///
  /// In tr, this message translates to:
  /// **'Rütbe'**
  String get personnelRank;

  /// No description provided for @personnelBranch.
  ///
  /// In tr, this message translates to:
  /// **'Sınıf / Kuvvet'**
  String get personnelBranch;

  /// No description provided for @personnelPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get personnelPhone;

  /// No description provided for @personnelRole.
  ///
  /// In tr, this message translates to:
  /// **'Rol'**
  String get personnelRole;

  /// No description provided for @personnelStatus.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get personnelStatus;

  /// No description provided for @personnelActive.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get personnelActive;

  /// No description provided for @personnelInactive.
  ///
  /// In tr, this message translates to:
  /// **'Pasif'**
  String get personnelInactive;

  /// No description provided for @personnelWarningEnterName.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen ad soyad giriniz.'**
  String get personnelWarningEnterName;

  /// No description provided for @personnelWarningSelectRank.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen rütbe seçiniz.'**
  String get personnelWarningSelectRank;

  /// No description provided for @personnelErrorSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Personel kaydedilemedi: {error}'**
  String personnelErrorSaveFailed(String error);

  /// No description provided for @personnelEditNamed.
  ///
  /// In tr, this message translates to:
  /// **'{name} - Düzenle'**
  String personnelEditNamed(String name);

  /// No description provided for @personnelSelectRankHint.
  ///
  /// In tr, this message translates to:
  /// **'Rütbe Seçiniz'**
  String get personnelSelectRankHint;

  /// No description provided for @personnelCustomRankLabel.
  ///
  /// In tr, this message translates to:
  /// **'Özel Rütbe Metni'**
  String get personnelCustomRankLabel;

  /// No description provided for @personnelCustomRankHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: J.Uz.Çvş. (Kıd.Kd.Çvş)'**
  String get personnelCustomRankHint;

  /// No description provided for @personnelSquadLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı Olduğu Tim'**
  String get personnelSquadLabel;

  /// No description provided for @personnelIndependentSquad.
  ///
  /// In tr, this message translates to:
  /// **'Bağımsız / Tim Dışı'**
  String get personnelIndependentSquad;

  /// No description provided for @personnelUnitLabel.
  ///
  /// In tr, this message translates to:
  /// **'Birlik / Bölük'**
  String get personnelUnitLabel;

  /// No description provided for @personnelSelectUnitTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Birlik seç'**
  String get personnelSelectUnitTooltip;

  /// No description provided for @personnelSelectUnitTitle.
  ///
  /// In tr, this message translates to:
  /// **'Birlik seç'**
  String get personnelSelectUnitTitle;

  /// No description provided for @personnelFrequentlyUsedUnits.
  ///
  /// In tr, this message translates to:
  /// **'Sık kullanılan birlikler'**
  String get personnelFrequentlyUsedUnits;

  /// No description provided for @personnelSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Personel ad, rütbe veya birlik ara...'**
  String get personnelSearchHint;

  /// No description provided for @personnelSquadFilter.
  ///
  /// In tr, this message translates to:
  /// **'Tim Filtresi'**
  String get personnelSquadFilter;

  /// No description provided for @personnelNewSquad.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Tim'**
  String get personnelNewSquad;

  /// No description provided for @personnelAllPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Personel'**
  String get personnelAllPersonnel;

  /// No description provided for @personnelUnassignedOrOffRoster.
  ///
  /// In tr, this message translates to:
  /// **'Boşta / Kadro Dışı'**
  String get personnelUnassignedOrOffRoster;

  /// No description provided for @personnelAuthorizedSquad.
  ///
  /// In tr, this message translates to:
  /// **'Yetkili Olduğunuz Tim: {squadName}'**
  String personnelAuthorizedSquad(String squadName);

  /// No description provided for @personnelAllUnit.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Birlik'**
  String get personnelAllUnit;

  /// No description provided for @personnelNoSubscription.
  ///
  /// In tr, this message translates to:
  /// **'Abonelik Yok'**
  String get personnelNoSubscription;

  /// No description provided for @personnelNoCriteriaMatches.
  ///
  /// In tr, this message translates to:
  /// **'Kriterlere uygun personel bulunamadı.'**
  String get personnelNoCriteriaMatches;

  /// No description provided for @commonSaving.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor...'**
  String get commonSaving;

  /// No description provided for @commonRetry.
  ///
  /// In tr, this message translates to:
  /// **'TEKRAR DENE'**
  String get commonRetry;

  /// No description provided for @authLoginTitle.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get authLoginTitle;

  /// No description provided for @authUsername.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Adı'**
  String get authUsername;

  /// No description provided for @authPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get authPassword;

  /// No description provided for @authLoginButton.
  ///
  /// In tr, this message translates to:
  /// **'GİRİŞ YAP'**
  String get authLoginButton;

  /// No description provided for @authLogoutButton.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get authLogoutButton;

  /// No description provided for @authSessionExpired.
  ///
  /// In tr, this message translates to:
  /// **'Oturum süresi doldu'**
  String get authSessionExpired;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz kullanıcı adı veya parola!'**
  String get authInvalidCredentials;

  /// No description provided for @authMissionManagement.
  ///
  /// In tr, this message translates to:
  /// **'Görev Yönetimi'**
  String get authMissionManagement;

  /// No description provided for @authFirstLoginTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlk Giriş: Parola Belirleyin'**
  String get authFirstLoginTitle;

  /// No description provided for @authFirstLoginSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sayın {username}, hesabınız için yeni bir parola belirleyiniz.'**
  String authFirstLoginSubtitle(String username);

  /// No description provided for @authNewPassword.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Parola'**
  String get authNewPassword;

  /// No description provided for @authNewPasswordRepeat.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Parola (Tekrar)'**
  String get authNewPasswordRepeat;

  /// No description provided for @authPasswordsDoNotMatch.
  ///
  /// In tr, this message translates to:
  /// **'Parolalar eşleşmiyor!'**
  String get authPasswordsDoNotMatch;

  /// No description provided for @authSavePasswordAndLogin.
  ///
  /// In tr, this message translates to:
  /// **'PAROLAYI KAYDET VE GİRİŞ YAP'**
  String get authSavePasswordAndLogin;

  /// No description provided for @dashboardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get dashboardTitle;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı İşlemler'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardStatistics.
  ///
  /// In tr, this message translates to:
  /// **'İstatistikler'**
  String get dashboardStatistics;

  /// No description provided for @dashboardRecentActivities.
  ///
  /// In tr, this message translates to:
  /// **'Son Faaliyetler'**
  String get dashboardRecentActivities;

  /// No description provided for @dashboardActivitySchedule.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet Çizelgesi'**
  String get dashboardActivitySchedule;

  /// No description provided for @dashboardDailyDutyEntry.
  ///
  /// In tr, this message translates to:
  /// **'Günlük görev gir'**
  String get dashboardDailyDutyEntry;

  /// No description provided for @dashboardMonthlyMatrix.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Matris'**
  String get dashboardMonthlyMatrix;

  /// No description provided for @dashboardExcelDistribution.
  ///
  /// In tr, this message translates to:
  /// **'Excel / Dağıtım'**
  String get dashboardExcelDistribution;

  /// No description provided for @dashboardTemgundrapSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Çizelge oluştur ve yönet'**
  String get dashboardTemgundrapSubtitle;

  /// No description provided for @dashboardPersonnelAndSquad.
  ///
  /// In tr, this message translates to:
  /// **'Personel & Tim'**
  String get dashboardPersonnelAndSquad;

  /// No description provided for @dashboardRegisterAndAuth.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt ve Yetki'**
  String get dashboardRegisterAndAuth;

  /// No description provided for @dashboardRosterStatus.
  ///
  /// In tr, this message translates to:
  /// **'Kadro Durumu'**
  String get dashboardRosterStatus;

  /// No description provided for @dashboardBulkImportText.
  ///
  /// In tr, this message translates to:
  /// **'Metinden Toplu Aktar'**
  String get dashboardBulkImportText;

  /// No description provided for @dashboardWhatsAppListUpload.
  ///
  /// In tr, this message translates to:
  /// **'WhatsApp / Liste Yükle'**
  String get dashboardWhatsAppListUpload;

  /// No description provided for @dashboardBulkImportImage.
  ///
  /// In tr, this message translates to:
  /// **'Görselden Toplu Aktar'**
  String get dashboardBulkImportImage;

  /// No description provided for @dashboardOcrNameMatch.
  ///
  /// In tr, this message translates to:
  /// **'OCR ile isim eşleştir'**
  String get dashboardOcrNameMatch;

  /// No description provided for @dashboardOcrPlatformWarning.
  ///
  /// In tr, this message translates to:
  /// **'Görselden aktarım Android ve iOS cihazlarda kullanılabilir.'**
  String get dashboardOcrPlatformWarning;

  /// No description provided for @dashboardThemeMilitaryLight.
  ///
  /// In tr, this message translates to:
  /// **'Askeri Haki (Açık)'**
  String get dashboardThemeMilitaryLight;

  /// No description provided for @dashboardThemeMilitaryDark.
  ///
  /// In tr, this message translates to:
  /// **'Taktik Gece (Koyu)'**
  String get dashboardThemeMilitaryDark;

  /// No description provided for @dashboardThemeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Teması'**
  String get dashboardThemeSystem;

  /// No description provided for @dashboardSettingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Ayarları'**
  String get dashboardSettingsTitle;

  /// No description provided for @dashboardThemeMode.
  ///
  /// In tr, this message translates to:
  /// **'Tema Modu'**
  String get dashboardThemeMode;

  /// No description provided for @dashboardPendingAssignments.
  ///
  /// In tr, this message translates to:
  /// **'Onay Bekleyen Görevler'**
  String get dashboardPendingAssignments;

  /// No description provided for @dashboardPendingAssignmentsDesc.
  ///
  /// In tr, this message translates to:
  /// **'{count} personelin görev değişikliği onay bekliyor'**
  String dashboardPendingAssignmentsDesc(int count);

  /// No description provided for @dashboardOperations.
  ///
  /// In tr, this message translates to:
  /// **'İşlemler'**
  String get dashboardOperations;

  /// No description provided for @dashboardPendingConflictsNotice.
  ///
  /// In tr, this message translates to:
  /// **'{count} Görevlendirmede Çakışma / Rapor Var!'**
  String dashboardPendingConflictsNotice(int count);

  /// No description provided for @dashboardPendingTapToReview.
  ///
  /// In tr, this message translates to:
  /// **'Onaylamak veya reddetmek için dokunun.'**
  String get dashboardPendingTapToReview;

  /// No description provided for @dashboardSearchAndReview.
  ///
  /// In tr, this message translates to:
  /// **'Arama ve İnceleme'**
  String get dashboardSearchAndReview;

  /// No description provided for @settingsChangePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi Değiştir'**
  String get settingsChangePassword;

  /// No description provided for @settingsNewPassword.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifreniz'**
  String get settingsNewPassword;

  /// No description provided for @settingsPasswordUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Şifreniz başarıyla güncellendi!'**
  String get settingsPasswordUpdated;

  /// No description provided for @settingsUserAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap: {username}'**
  String settingsUserAccount(String username);

  /// No description provided for @settingsRoleAdmin.
  ///
  /// In tr, this message translates to:
  /// **'Rol: Birlik Yöneticisi (Admin)'**
  String get settingsRoleAdmin;

  /// No description provided for @settingsRoleCommander.
  ///
  /// In tr, this message translates to:
  /// **'Rol: Tim Komutanı'**
  String get settingsRoleCommander;

  /// No description provided for @settingsAppTheme.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Teması'**
  String get settingsAppTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get settingsThemeSystem;

  /// No description provided for @settingsFullBackup.
  ///
  /// In tr, this message translates to:
  /// **'Tam Yedekleme'**
  String get settingsFullBackup;

  /// No description provided for @settingsFullBackupSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm uygulama verilerini cihazda sakla veya geri yükle'**
  String get settingsFullBackupSubtitle;

  /// No description provided for @settingsUpdate.
  ///
  /// In tr, this message translates to:
  /// **'GÜNCELLE'**
  String get settingsUpdate;

  /// No description provided for @matrixTitle.
  ///
  /// In tr, this message translates to:
  /// **'Matris ve Çizelge'**
  String get matrixTitle;

  /// No description provided for @reportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Raporlar'**
  String get reportTitle;

  /// No description provided for @rosterOutputTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çıktı Hazırla'**
  String get rosterOutputTitle;

  /// No description provided for @rosterSelectCardsHint.
  ///
  /// In tr, this message translates to:
  /// **'Yazdırılacak kartları seçin. Önceki gün kartları listenin sonunda yer alır. Aynı kişi bir kez yazılır.'**
  String get rosterSelectCardsHint;

  /// No description provided for @rosterReload.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden yükle'**
  String get rosterReload;

  /// No description provided for @rosterIncludedItemsCount.
  ///
  /// In tr, this message translates to:
  /// **'Çıktıya Eklenecekler ({count})'**
  String rosterIncludedItemsCount(int count);

  /// No description provided for @rosterReorderHint.
  ///
  /// In tr, this message translates to:
  /// **'Sırayı tutamaçtan sürükleyerek değiştirebilirsiniz.'**
  String get rosterReorderHint;

  /// No description provided for @rosterSameDayOutputOrder.
  ///
  /// In tr, this message translates to:
  /// **'Aynı Gün — Çıktı Sırası'**
  String get rosterSameDayOutputOrder;

  /// No description provided for @rosterPreviousDayOutputOrder.
  ///
  /// In tr, this message translates to:
  /// **'Önceki Gün — Çıktı Sırası'**
  String get rosterPreviousDayOutputOrder;

  /// No description provided for @rosterSameDayCards.
  ///
  /// In tr, this message translates to:
  /// **'Aynı Günün Kartları'**
  String get rosterSameDayCards;

  /// No description provided for @rosterPreviousDayCards.
  ///
  /// In tr, this message translates to:
  /// **'Önceki Günün Kartları'**
  String get rosterPreviousDayCards;

  /// No description provided for @rosterNoCardsForDay.
  ///
  /// In tr, this message translates to:
  /// **'Bu güne ait kart bulunamadı.'**
  String get rosterNoCardsForDay;

  /// No description provided for @rosterAllCardsAdded.
  ///
  /// In tr, this message translates to:
  /// **'Bu güne ait tüm kartlar çıktıya eklendi.'**
  String get rosterAllCardsAdded;

  /// No description provided for @rosterPreparing.
  ///
  /// In tr, this message translates to:
  /// **'Hazırlanıyor…'**
  String get rosterPreparing;

  /// No description provided for @rosterPreviewWithCount.
  ///
  /// In tr, this message translates to:
  /// **'Önizle ({count})'**
  String rosterPreviewWithCount(int count);

  /// No description provided for @rosterNoApprovedPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen kartlarda dışa aktarılacak onaylı personel bulunamadı.'**
  String get rosterNoApprovedPersonnel;

  /// No description provided for @activityArchiveTitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet Arşivi'**
  String get activityArchiveTitle;

  /// No description provided for @activityArchiveTeamTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tim Faaliyet Arşivi'**
  String get activityArchiveTeamTitle;

  /// No description provided for @activityArchiveSelectedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} faaliyet seçildi'**
  String activityArchiveSelectedCount(int count);

  /// No description provided for @activityArchiveCloseSelection.
  ///
  /// In tr, this message translates to:
  /// **'Seçimi Kapat'**
  String get activityArchiveCloseSelection;

  /// No description provided for @activityArchiveExportSelectedTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Seçilenleri Dışa Aktar'**
  String get activityArchiveExportSelectedTooltip;

  /// No description provided for @activityArchiveSelectButton.
  ///
  /// In tr, this message translates to:
  /// **'Seç'**
  String get activityArchiveSelectButton;

  /// No description provided for @activityArchiveMenuTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Arşiv işlemleri'**
  String get activityArchiveMenuTooltip;

  /// No description provided for @activityArchiveMenuHeader.
  ///
  /// In tr, this message translates to:
  /// **'Arşiv İşlemleri'**
  String get activityArchiveMenuHeader;

  /// No description provided for @activityArchiveMenuSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm ve arşiv araçları'**
  String get activityArchiveMenuSubtitle;

  /// No description provided for @activityArchivePrepareOutputTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çıktı Hazırla'**
  String get activityArchivePrepareOutputTitle;

  /// No description provided for @activityArchivePrepareOutputSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kartları seç, sırala ve imzalı çıktı al'**
  String get activityArchivePrepareOutputSubtitle;

  /// No description provided for @activityArchiveExportPrintTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dışa Aktar / Yazdır'**
  String get activityArchiveExportPrintTitle;

  /// No description provided for @activityArchiveExportPrintSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Görüntülenen günü paylaş veya yazdır'**
  String get activityArchiveExportPrintSubtitle;

  /// No description provided for @activityArchiveSelectOptionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet seç'**
  String get activityArchiveSelectOptionTitle;

  /// No description provided for @activityArchiveSelectOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Birden fazla kayıt üzerinde çalış'**
  String get activityArchiveSelectOptionSubtitle;

  /// No description provided for @activityArchiveFinishReorder.
  ///
  /// In tr, this message translates to:
  /// **'Sıralamayı bitir'**
  String get activityArchiveFinishReorder;

  /// No description provided for @activityArchiveMoveCards.
  ///
  /// In tr, this message translates to:
  /// **'Kartları taşı'**
  String get activityArchiveMoveCards;

  /// No description provided for @activityArchiveExitReorderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sürükleme modundan çık'**
  String get activityArchiveExitReorderSubtitle;

  /// No description provided for @activityArchiveMoveCardsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kartları sürükleyerek yeniden sırala'**
  String get activityArchiveMoveCardsSubtitle;

  /// No description provided for @activityArchiveResetOrder.
  ///
  /// In tr, this message translates to:
  /// **'Sıralamayı sıfırla'**
  String get activityArchiveResetOrder;

  /// No description provided for @activityArchiveResetOrderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan sıralamaya dön'**
  String get activityArchiveResetOrderSubtitle;

  /// No description provided for @activityArchiveReturnToday.
  ///
  /// In tr, this message translates to:
  /// **'Bugüne dön'**
  String get activityArchiveReturnToday;

  /// No description provided for @activityArchiveReturnTodaySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Güncel faaliyetleri göster'**
  String get activityArchiveReturnTodaySubtitle;

  /// No description provided for @activityArchiveAuditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çakışmaları denetle'**
  String get activityArchiveAuditTitle;

  /// No description provided for @activityArchiveAuditSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Personel görevlendirmelerini kontrol et'**
  String get activityArchiveAuditSubtitle;

  /// No description provided for @activityArchiveFilterByDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarihe göre süz'**
  String get activityArchiveFilterByDate;

  /// No description provided for @activityArchiveFilterByDateSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Belirli bir günün arşivini aç'**
  String get activityArchiveFilterByDateSubtitle;

  /// No description provided for @activityArchiveNoRecordsFound.
  ///
  /// In tr, this message translates to:
  /// **'{date} tarihine ait faaliyet kaydı bulunamadı.'**
  String activityArchiveNoRecordsFound(String date);

  /// No description provided for @activityArchiveReorderHint.
  ///
  /// In tr, this message translates to:
  /// **'Kartları tutamaçtan sürükleyerek taşıyın. Sıralama bu güne kaydedilir.'**
  String get activityArchiveReorderHint;

  /// No description provided for @activityArchiveConflictAuditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş Kayıt Çakışma Denetimi'**
  String get activityArchiveConflictAuditTitle;

  /// No description provided for @activityArchiveConflictAuditNone.
  ///
  /// In tr, this message translates to:
  /// **'Çakışan geçmiş kayıt bulunamadı.'**
  String get activityArchiveConflictAuditNone;

  /// No description provided for @activityArchiveConflictAuditReadOnly.
  ///
  /// In tr, this message translates to:
  /// **'Bu liste salt okunurdur; hiçbir kayıt silinmedi.'**
  String get activityArchiveConflictAuditReadOnly;

  /// No description provided for @activityArchiveSaveOrderFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sıralama kaydedilemedi.'**
  String get activityArchiveSaveOrderFailed;

  /// No description provided for @activityArchiveResetOrderFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sıralama sıfırlanamadı.'**
  String get activityArchiveResetOrderFailed;

  /// No description provided for @activityArchiveOrderResetSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Kart sıralaması varsayılana döndürüldü.'**
  String get activityArchiveOrderResetSuccess;

  /// No description provided for @activityArchiveNoActivitiesToExport.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktarılacak faaliyet bulunamadı.'**
  String get activityArchiveNoActivitiesToExport;

  /// No description provided for @activityArchiveAllActivitiesDefaultName.
  ///
  /// In tr, this message translates to:
  /// **'GÜNLÜK TÜM FAALİYETLER'**
  String get activityArchiveAllActivitiesDefaultName;

  /// No description provided for @activityArchiveExportFailed.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktarılamadı: {error}'**
  String activityArchiveExportFailed(String error);

  /// No description provided for @matrixSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Personel veya rütbe ara'**
  String get matrixSearchHint;

  /// No description provided for @matrixClearSearchTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Aramayı temizle'**
  String get matrixClearSearchTooltip;

  /// No description provided for @matrixPreviousMonth.
  ///
  /// In tr, this message translates to:
  /// **'Önceki ay'**
  String get matrixPreviousMonth;

  /// No description provided for @matrixNextMonth.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki ay'**
  String get matrixNextMonth;

  /// No description provided for @matrixCloseSearchTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Aramayı kapat'**
  String get matrixCloseSearchTooltip;

  /// No description provided for @matrixSearchPersonnelTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Personel ara'**
  String get matrixSearchPersonnelTooltip;

  /// No description provided for @matrixExportExcel.
  ///
  /// In tr, this message translates to:
  /// **'Excel\'e Aktar'**
  String get matrixExportExcel;

  /// No description provided for @matrixTeamDutyCalendar.
  ///
  /// In tr, this message translates to:
  /// **'Tim Görev Takvimi'**
  String get matrixTeamDutyCalendar;

  /// No description provided for @matrixMonthlyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Matris'**
  String get matrixMonthlyTitle;

  /// No description provided for @matrixMonthlySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Personel görev ve durum çizelgesi'**
  String get matrixMonthlySubtitle;

  /// No description provided for @matrixNoMatchingPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Aramanızla eşleşen personel bulunamadı'**
  String get matrixNoMatchingPersonnel;

  /// No description provided for @matrixNoPersonnelToShow.
  ///
  /// In tr, this message translates to:
  /// **'Gösterilecek kayıtlı personel bulunmuyor.'**
  String get matrixNoPersonnelToShow;

  /// No description provided for @matrixExportFailed.
  ///
  /// In tr, this message translates to:
  /// **'Çizelge dışa aktarılamadı: {error}'**
  String matrixExportFailed(String error);

  /// No description provided for @matrixUnassignedTeam.
  ///
  /// In tr, this message translates to:
  /// **'Timsiz Personel'**
  String get matrixUnassignedTeam;

  /// No description provided for @matrixUnknownTeam.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen Tim'**
  String get matrixUnknownTeam;

  /// No description provided for @matrixPersonnelCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} Personel'**
  String matrixPersonnelCount(int count);

  /// No description provided for @matrixOrderNumberShort.
  ///
  /// In tr, this message translates to:
  /// **'S.N.'**
  String get matrixOrderNumberShort;

  /// No description provided for @matrixTotalShort.
  ///
  /// In tr, this message translates to:
  /// **'Top.'**
  String get matrixTotalShort;

  /// No description provided for @matrixDaysCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} gün'**
  String matrixDaysCount(int count);

  /// No description provided for @matrixMonthlyScheduleDays.
  ///
  /// In tr, this message translates to:
  /// **'Aylık çizelge · {count} gün'**
  String matrixMonthlyScheduleDays(int count);

  /// No description provided for @temgundrapTitle.
  ///
  /// In tr, this message translates to:
  /// **'TEMGÜNDRAP Çizelgeleri'**
  String get temgundrapTitle;

  /// No description provided for @temgundrapDailyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük TEMGÜNDRAP'**
  String get temgundrapDailyTitle;

  /// No description provided for @temgundrapArchiveTitle.
  ///
  /// In tr, this message translates to:
  /// **'TEMGÜNDRAP Arşivi'**
  String get temgundrapArchiveTitle;

  /// No description provided for @temgundrapFailedToLoad.
  ///
  /// In tr, this message translates to:
  /// **'Çizelgeler yüklenemedi: {error}'**
  String temgundrapFailedToLoad(String error);

  /// No description provided for @temgundrapArchivedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Çizelge arşive taşındı.'**
  String get temgundrapArchivedSuccess;

  /// No description provided for @temgundrapUnarchivedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Çizelge yeniden taslağa alındı.'**
  String get temgundrapUnarchivedSuccess;

  /// No description provided for @temgundrapUpdateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Çizelge güncellenemedi: {error}'**
  String temgundrapUpdateFailed(String error);

  /// No description provided for @temgundrapDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çizelgeyi sil'**
  String get temgundrapDeleteTitle;

  /// No description provided for @temgundrapDeleteContent.
  ///
  /// In tr, this message translates to:
  /// **'Bu TEMGÜNDRAP çizelgesi kalıcı olarak silinecek.'**
  String get temgundrapDeleteContent;

  /// No description provided for @temgundrapDeleteFailed.
  ///
  /// In tr, this message translates to:
  /// **'Çizelge silinemedi: {error}'**
  String temgundrapDeleteFailed(String error);

  /// No description provided for @temgundrapPickDateTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Tarih seç'**
  String get temgundrapPickDateTooltip;

  /// No description provided for @temgundrapNewDocument.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Çizelge'**
  String get temgundrapNewDocument;

  /// No description provided for @temgundrapEditDocument.
  ///
  /// In tr, this message translates to:
  /// **'Çizelgeyi Düzenle'**
  String get temgundrapEditDocument;

  /// No description provided for @temgundrapFailedToLoadDocs.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlar yüklenemedi'**
  String get temgundrapFailedToLoadDocs;

  /// No description provided for @temgundrapActionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çizelge İşlemleri'**
  String get temgundrapActionsTitle;

  /// No description provided for @temgundrapEditSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Çizelge bilgilerini güncelle'**
  String get temgundrapEditSubtitle;

  /// No description provided for @temgundrapArchiveOption.
  ///
  /// In tr, this message translates to:
  /// **'Arşivle'**
  String get temgundrapArchiveOption;

  /// No description provided for @temgundrapArchiveSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Çizelgeyi tamamla ve arşive taşı'**
  String get temgundrapArchiveSubtitle;

  /// No description provided for @temgundrapRestoreOption.
  ///
  /// In tr, this message translates to:
  /// **'Taslağa al'**
  String get temgundrapRestoreOption;

  /// No description provided for @temgundrapRestoreSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Çizelgeyi yeniden düzenlemeye aç'**
  String get temgundrapRestoreSubtitle;

  /// No description provided for @temgundrapDeleteSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu çizelgeyi kalıcı olarak kaldır'**
  String get temgundrapDeleteSubtitle;

  /// No description provided for @temgundrapDailyWithCount.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Çizelge ({count})'**
  String temgundrapDailyWithCount(int count);

  /// No description provided for @temgundrapArchiveWithCount.
  ///
  /// In tr, this message translates to:
  /// **'Arşiv ({count})'**
  String temgundrapArchiveWithCount(int count);

  /// No description provided for @temgundrapPreviousDay.
  ///
  /// In tr, this message translates to:
  /// **'Önceki gün'**
  String get temgundrapPreviousDay;

  /// No description provided for @temgundrapNextDay.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki gün'**
  String get temgundrapNextDay;

  /// No description provided for @temgundrapBackToToday.
  ///
  /// In tr, this message translates to:
  /// **'BUGÜNE DÖN'**
  String get temgundrapBackToToday;

  /// No description provided for @temgundrapOperationsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} operasyon'**
  String temgundrapOperationsCount(int count);

  /// No description provided for @temgundrapBadgeDraft.
  ///
  /// In tr, this message translates to:
  /// **'TASLAK'**
  String get temgundrapBadgeDraft;

  /// No description provided for @temgundrapBadgeArchived.
  ///
  /// In tr, this message translates to:
  /// **'ARŞİVDE'**
  String get temgundrapBadgeArchived;

  /// No description provided for @temgundrapNoDailyDraftTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu güne ait taslak çizelge yok'**
  String get temgundrapNoDailyDraftTitle;

  /// No description provided for @temgundrapNoArchivedDocTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu tarihte arşivlenmiş çizelge yok'**
  String get temgundrapNoArchivedDocTitle;

  /// No description provided for @temgundrapNoDailyDraftMessage.
  ///
  /// In tr, this message translates to:
  /// **'{date} için yeni bir TEMGÜNDRAP çizelgesi oluşturun.'**
  String temgundrapNoDailyDraftMessage(String date);

  /// No description provided for @temgundrapNoArchivedDocMessage.
  ///
  /// In tr, this message translates to:
  /// **'Başka bir tarih seçebilir veya tamamlanan bir taslağı arşivleyebilirsiniz.'**
  String get temgundrapNoArchivedDocMessage;

  /// No description provided for @temgundrapNewDocButton.
  ///
  /// In tr, this message translates to:
  /// **'YENİ ÇİZELGE'**
  String get temgundrapNewDocButton;

  /// No description provided for @temgundrapPickDateButton.
  ///
  /// In tr, this message translates to:
  /// **'TARİH SEÇ'**
  String get temgundrapPickDateButton;

  /// No description provided for @temgundrapApproverDefaultsLoadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Onay bilgileri yüklenemedi: {error}'**
  String temgundrapApproverDefaultsLoadFailed(String error);

  /// No description provided for @temgundrapAtLeastOneOperationRequired.
  ///
  /// In tr, this message translates to:
  /// **'En az bir operasyon ekleyin.'**
  String get temgundrapAtLeastOneOperationRequired;

  /// No description provided for @temgundrapSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Çizelge kaydedilemedi: {error}'**
  String temgundrapSaveFailed(String error);

  /// No description provided for @temgundrapUnitTitle.
  ///
  /// In tr, this message translates to:
  /// **'Birlik başlığı'**
  String get temgundrapUnitTitle;

  /// No description provided for @temgundrapDocumentDate.
  ///
  /// In tr, this message translates to:
  /// **'Çizelge tarihi'**
  String get temgundrapDocumentDate;

  /// No description provided for @temgundrapOperations.
  ///
  /// In tr, this message translates to:
  /// **'Operasyonlar'**
  String get temgundrapOperations;

  /// No description provided for @temgundrapAddOperation.
  ///
  /// In tr, this message translates to:
  /// **'Operasyon Ekle'**
  String get temgundrapAddOperation;

  /// No description provided for @temgundrapNoOperationsAddedYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz operasyon eklenmedi.'**
  String get temgundrapNoOperationsAddedYet;

  /// No description provided for @temgundrapEditOperationTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Operasyonu düzenle'**
  String get temgundrapEditOperationTooltip;

  /// No description provided for @temgundrapDeleteOperationTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Operasyonu sil'**
  String get temgundrapDeleteOperationTooltip;

  /// No description provided for @temgundrapApprovalInfo.
  ///
  /// In tr, this message translates to:
  /// **'Onay Bilgileri'**
  String get temgundrapApprovalInfo;

  /// No description provided for @temgundrapApproverName.
  ///
  /// In tr, this message translates to:
  /// **'Onaylayan ad soyad'**
  String get temgundrapApproverName;

  /// No description provided for @temgundrapApproverDuty.
  ///
  /// In tr, this message translates to:
  /// **'Görevi'**
  String get temgundrapApproverDuty;

  /// No description provided for @temgundrapSaveAsDraft.
  ///
  /// In tr, this message translates to:
  /// **'Taslak olarak kaydet'**
  String get temgundrapSaveAsDraft;

  /// No description provided for @temgundrapSaveDocumentButton.
  ///
  /// In tr, this message translates to:
  /// **'ÇİZELGEYİ KAYDET'**
  String get temgundrapSaveDocumentButton;

  /// No description provided for @temgundrapRequiredField.
  ///
  /// In tr, this message translates to:
  /// **'Bu alan zorunludur.'**
  String get temgundrapRequiredField;

  /// No description provided for @pendingApprovalsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen Görev Onayları'**
  String get pendingApprovalsTitle;

  /// No description provided for @pendingApprovalsEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen Onay Yok'**
  String get pendingApprovalsEmptyTitle;

  /// No description provided for @pendingApprovalsEmptyDesc.
  ///
  /// In tr, this message translates to:
  /// **'Onay bekleyen veya çakışan görev kaydı bulunmuyor.'**
  String get pendingApprovalsEmptyDesc;

  /// No description provided for @pendingApprovalsAssignmentConflict.
  ///
  /// In tr, this message translates to:
  /// **'Görevlendirme #{id} (ÇAKIŞMA VAR)'**
  String pendingApprovalsAssignmentConflict(int id);

  /// No description provided for @pendingApprovalsPersonnelLabel.
  ///
  /// In tr, this message translates to:
  /// **'Personel'**
  String get pendingApprovalsPersonnelLabel;

  /// No description provided for @pendingApprovalsRequestedDutyLabel.
  ///
  /// In tr, this message translates to:
  /// **'Talep Edilen Görev'**
  String get pendingApprovalsRequestedDutyLabel;

  /// No description provided for @pendingApprovalsDescriptionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama: {description}'**
  String pendingApprovalsDescriptionLabel(String description);

  /// No description provided for @pendingApprovalsApprove.
  ///
  /// In tr, this message translates to:
  /// **'ONAYLA'**
  String get pendingApprovalsApprove;

  /// No description provided for @pendingApprovalsReject.
  ///
  /// In tr, this message translates to:
  /// **'REDDET'**
  String get pendingApprovalsReject;

  /// No description provided for @pendingApprovalsApprovalFailed.
  ///
  /// In tr, this message translates to:
  /// **'Onaylanamadı: {reason}'**
  String pendingApprovalsApprovalFailed(String reason);

  /// No description provided for @activityDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyeti Sil'**
  String get activityDeleteTitle;

  /// No description provided for @activityDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{name} ({date}) faaliyet kaydı silinecektir. Emin misiniz?'**
  String activityDeleteConfirm(String name, String date);

  /// No description provided for @activityRenameTitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet Adını Değiştir'**
  String get activityRenameTitle;

  /// No description provided for @activityRenameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet adı'**
  String get activityRenameLabel;

  /// No description provided for @activityRenameHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Gece nöbeti'**
  String get activityRenameHint;

  /// No description provided for @activityActionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet İşlemleri'**
  String get activityActionsTitle;

  /// No description provided for @activityActionsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu faaliyet için kullanılabilir işlemler'**
  String get activityActionsSubtitle;

  /// No description provided for @activityApproveAllTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü onayla'**
  String get activityApproveAllTitle;

  /// No description provided for @activityApproveAllSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen tüm atamaları onayla'**
  String get activityApproveAllSubtitle;

  /// No description provided for @activityRenameOptionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet adını değiştir'**
  String get activityRenameOptionTitle;

  /// No description provided for @activityRenameOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kart başlığını yeniden adlandır'**
  String get activityRenameOptionSubtitle;

  /// No description provided for @activityChangeDateOptionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tarihi değiştir'**
  String get activityChangeDateOptionTitle;

  /// No description provided for @activityChangeDateOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyeti başka bir güne taşı'**
  String get activityChangeDateOptionSubtitle;

  /// No description provided for @activityDeleteOptionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyeti sil'**
  String get activityDeleteOptionTitle;

  /// No description provided for @activityDeleteOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz'**
  String get activityDeleteOptionSubtitle;

  /// No description provided for @activityApproveAllSuccess.
  ///
  /// In tr, this message translates to:
  /// **'{count} atama onaylandı.'**
  String activityApproveAllSuccess(int count);

  /// No description provided for @activityApproveAllWithConflicts.
  ///
  /// In tr, this message translates to:
  /// **'{approvedCount} onaylandı, {blockedCount} çakışma nedeniyle beklemede kaldı: {reasons}'**
  String activityApproveAllWithConflicts(
      int approvedCount, int blockedCount, String reasons);

  /// No description provided for @activityCreatedBy.
  ///
  /// In tr, this message translates to:
  /// **'Yazan: {user}'**
  String activityCreatedBy(String user);

  /// No description provided for @activityStatusApproved.
  ///
  /// In tr, this message translates to:
  /// **'ONAYLANDI'**
  String get activityStatusApproved;

  /// No description provided for @activityStatusPendingAdmin.
  ///
  /// In tr, this message translates to:
  /// **'ADMIN ONAYI BEKLİYOR'**
  String get activityStatusPendingAdmin;

  /// No description provided for @activityStatusConflictOrRejected.
  ///
  /// In tr, this message translates to:
  /// **'ÇAKIŞMA / RED'**
  String get activityStatusConflictOrRejected;

  /// No description provided for @activityChangeDateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet Tarihini Değiştir'**
  String get activityChangeDateTitle;

  /// No description provided for @activityChangeDateAlreadyOnDate.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet zaten seçilen tarihte.'**
  String get activityChangeDateAlreadyOnDate;

  /// No description provided for @activityChangeDatePrepareFailed.
  ///
  /// In tr, this message translates to:
  /// **'Tarih değişikliği hazırlanamadı.'**
  String get activityChangeDatePrepareFailed;

  /// No description provided for @activityChangeDatePersonnelCountNotice.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel yeni tarihe taşınacak.'**
  String activityChangeDatePersonnelCountNotice(int count);

  /// No description provided for @activityChangeDatePendingNotice.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel rapor/görev çakışması nedeniyle yeniden onaya alınacak.'**
  String activityChangeDatePendingNotice(int count);

  /// No description provided for @activityChangeDateSubmit.
  ///
  /// In tr, this message translates to:
  /// **'TARİHİ DEĞİŞTİR'**
  String get activityChangeDateSubmit;

  /// No description provided for @activityChangeDateMovedNotice.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel {date} tarihine taşındı.'**
  String activityChangeDateMovedNotice(int count, String date);

  /// No description provided for @activityChangeDatePendingCountNotice.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel yeniden onay bekliyor.'**
  String activityChangeDatePendingCountNotice(int count);

  /// No description provided for @activityChangeDateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Tarih değiştirilemedi. Hedef tarih yeniden kontrol edilmelidir.'**
  String get activityChangeDateFailed;

  /// No description provided for @activityRenameSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet adı güncellendi.'**
  String get activityRenameSuccess;

  /// No description provided for @activityRenameFailed.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet adı değiştirilemedi: {error}'**
  String activityRenameFailed(String error);

  /// No description provided for @settingsUserNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı bulunamadı.'**
  String get settingsUserNotFound;

  /// No description provided for @settingsPasswordUpdateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Şifre güncellenemedi: {error}'**
  String settingsPasswordUpdateFailed(String error);

  /// No description provided for @settingsAddTestPersonnelTitle.
  ///
  /// In tr, this message translates to:
  /// **'10\'ar Test Personeli Ekle'**
  String get settingsAddTestPersonnelTitle;

  /// No description provided for @settingsAddTestPersonnelSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Her time 10 adet sahte personel oluşturur'**
  String get settingsAddTestPersonnelSubtitle;

  /// No description provided for @settingsTestPersonnelAddedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'{count} adet test personeli başarıyla eklendi!'**
  String settingsTestPersonnelAddedSuccess(int count);

  /// No description provided for @settingsClearTestPersonnelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Test Personellerini Temizle'**
  String get settingsClearTestPersonnelTitle;

  /// No description provided for @settingsClearTestPersonnelSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca işaretlenmiş test personellerini temizler'**
  String get settingsClearTestPersonnelSubtitle;

  /// No description provided for @settingsDeletePersonnelConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personelleri Sil'**
  String get settingsDeletePersonnelConfirmTitle;

  /// No description provided for @settingsDeleteTestPersonnelConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca test olarak işaretlenmiş personel kayıtları silinecektir. Emin misiniz?'**
  String get settingsDeleteTestPersonnelConfirmMessage;

  /// No description provided for @settingsTestPersonnelCleared.
  ///
  /// In tr, this message translates to:
  /// **'İşaretlenmiş test personelleri temizlendi!'**
  String get settingsTestPersonnelCleared;

  /// No description provided for @activityArchiveSelectedActivitiesCount.
  ///
  /// In tr, this message translates to:
  /// **'{dateTitle} • {count} Seçili Faaliyet'**
  String activityArchiveSelectedActivitiesCount(String dateTitle, int count);

  /// No description provided for @activityArchiveFallbackPersonnelName.
  ///
  /// In tr, this message translates to:
  /// **'Personel #{id}'**
  String activityArchiveFallbackPersonnelName(int id);

  /// No description provided for @activityArchiveUnknownTeamHistory.
  ///
  /// In tr, this message translates to:
  /// **'Tim geçmişi bilinmiyor'**
  String get activityArchiveUnknownTeamHistory;

  /// No description provided for @backupRestoreTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme ve Geri Yükleme'**
  String get backupRestoreTitle;

  /// No description provided for @backupExportTab.
  ///
  /// In tr, this message translates to:
  /// **'Dışa Aktar'**
  String get backupExportTab;

  /// No description provided for @backupImportTab.
  ///
  /// In tr, this message translates to:
  /// **'İçe Aktar'**
  String get backupImportTab;

  /// No description provided for @backupExportSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Tam uygulama yedeği dışa aktarıldı.'**
  String get backupExportSuccess;

  /// No description provided for @backupSaveCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetme işlemi iptal edildi.'**
  String get backupSaveCancelled;

  /// No description provided for @backupExportFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yedek dışa aktarılamadı: {error}'**
  String backupExportFailed(String error);

  /// No description provided for @backupImportSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Yedek başarıyla geri yüklendi.'**
  String get backupImportSuccess;

  /// No description provided for @backupImportFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yedek geri yüklenemedi: {error}'**
  String backupImportFailed(String error);

  /// No description provided for @backupFilePickerError.
  ///
  /// In tr, this message translates to:
  /// **'Dosya seçilemedi: {error}'**
  String backupFilePickerError(String error);

  /// No description provided for @backupInvalidJson.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir JSON yedek verisi giriniz.'**
  String get backupInvalidJson;

  /// No description provided for @backupVerifyButton.
  ///
  /// In tr, this message translates to:
  /// **'Yedeği Doğrula'**
  String get backupVerifyButton;

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedeği Geri Yükle'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupRestoreConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut tüm veriler yedekteki verilerle değiştirilecektir. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?'**
  String get backupRestoreConfirmMessage;

  /// No description provided for @backupRestoreButton.
  ///
  /// In tr, this message translates to:
  /// **'GERİ YÜKLE'**
  String get backupRestoreButton;

  /// No description provided for @backupExportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamanın tam yedeğini cihazınıza kaydedin veya paylaşın.'**
  String get backupExportSubtitle;

  /// No description provided for @backupImportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Daha önce alınmış bir yedeği yükleyerek verilerinizi geri yükleyin.'**
  String get backupImportSubtitle;

  /// No description provided for @backupStatsPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Personel Sayısı'**
  String get backupStatsPersonnel;

  /// No description provided for @backupStatsActivities.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet Sayısı'**
  String get backupStatsActivities;

  /// No description provided for @backupStatsAssignments.
  ///
  /// In tr, this message translates to:
  /// **'Atama Sayısı'**
  String get backupStatsAssignments;

  /// No description provided for @backupStatsTemgundrap.
  ///
  /// In tr, this message translates to:
  /// **'TEMGÜNDRAP Kayıtları'**
  String get backupStatsTemgundrap;

  /// No description provided for @backupExportDate.
  ///
  /// In tr, this message translates to:
  /// **'Yedek Tarihi'**
  String get backupExportDate;

  /// No description provided for @backupCopyJson.
  ///
  /// In tr, this message translates to:
  /// **'JSON Kopyala'**
  String get backupCopyJson;

  /// No description provided for @backupJsonCopied.
  ///
  /// In tr, this message translates to:
  /// **'Yedek verisi panoya kopyalandı.'**
  String get backupJsonCopied;

  /// No description provided for @backupDownloadFile.
  ///
  /// In tr, this message translates to:
  /// **'Dosya Olarak Kaydet'**
  String get backupDownloadFile;

  /// No description provided for @addPersonnelDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personel Ekle'**
  String get addPersonnelDialogTitle;

  /// No description provided for @addPersonnelResultTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ekleme sonucu'**
  String get addPersonnelResultTitle;

  /// No description provided for @addPersonnelResultContent.
  ///
  /// In tr, this message translates to:
  /// **'{added} personel eklendi.\n{already} personel zaten kayıtlı.\n{conflict} personel çakışma nedeniyle eklenemedi.'**
  String addPersonnelResultContent(int added, int already, int conflict);

  /// No description provided for @addPersonnelFailed.
  ///
  /// In tr, this message translates to:
  /// **'Personel eklenemedi: {error}'**
  String addPersonnelFailed(String error);

  /// No description provided for @addPersonnelSelectedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel seçildi'**
  String addPersonnelSelectedCount(int count);

  /// No description provided for @addPersonnelLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Personel bilgileri yüklenemedi. Ekranı kapatıp yeniden deneyin.'**
  String get addPersonnelLoadError;

  /// No description provided for @addPersonnelNoAvailable.
  ///
  /// In tr, this message translates to:
  /// **'Eklenebilecek personel bulunamadı.'**
  String get addPersonnelNoAvailable;

  /// No description provided for @addPersonnelAlreadyRegistered.
  ///
  /// In tr, this message translates to:
  /// **'Bu faaliyette zaten kayıtlı'**
  String get addPersonnelAlreadyRegistered;

  /// No description provided for @addPersonnelStepPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Personel'**
  String get addPersonnelStepPersonnel;

  /// No description provided for @addPersonnelStepDuty.
  ///
  /// In tr, this message translates to:
  /// **'Görev'**
  String get addPersonnelStepDuty;

  /// No description provided for @addPersonnelAddToActivity.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyete Ekle'**
  String get addPersonnelAddToActivity;

  /// No description provided for @addPersonnelContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get addPersonnelContinue;

  /// No description provided for @conflictPersonnelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bazı personeller eklenmedi'**
  String get conflictPersonnelTitle;

  /// No description provided for @conflictPersonnelMessage.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt tamamlandı. Aynı gün için başka kaydı bulunan {count} personel atlandı.'**
  String conflictPersonnelMessage(int count);

  /// No description provided for @conflictPersonnelUnderstood.
  ///
  /// In tr, this message translates to:
  /// **'ANLADIM'**
  String get conflictPersonnelUnderstood;

  /// No description provided for @conflictPersonnelFallback.
  ///
  /// In tr, this message translates to:
  /// **'Çakışan kayıt'**
  String get conflictPersonnelFallback;

  /// No description provided for @conflictPersonnelDetail.
  ///
  /// In tr, this message translates to:
  /// **'Bu tarihte başka bir faaliyet kaydı bulunuyor.'**
  String get conflictPersonnelDetail;

  /// No description provided for @transferPersonnelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personel Taşı'**
  String get transferPersonnelTitle;

  /// No description provided for @transferPersonnelSourceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak: {activityName}'**
  String transferPersonnelSourceLabel(String activityName);

  /// No description provided for @transferPersonnelSelectTarget.
  ///
  /// In tr, this message translates to:
  /// **'Hedef Faaliyet Kartını Seçin:'**
  String get transferPersonnelSelectTarget;

  /// No description provided for @transferPersonnelNoOtherActivity.
  ///
  /// In tr, this message translates to:
  /// **'{date} tarihinde başka faaliyet kartı bulunamadı.'**
  String transferPersonnelNoOtherActivity(String date);

  /// No description provided for @transferPersonnelCreateNewOption.
  ///
  /// In tr, this message translates to:
  /// **'YENİ FAALİYET KARTI OLUŞTUR'**
  String get transferPersonnelCreateNewOption;

  /// No description provided for @transferPersonnelNewActivityLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yeni faaliyet adı'**
  String get transferPersonnelNewActivityLabel;

  /// No description provided for @transferPersonnelButton.
  ///
  /// In tr, this message translates to:
  /// **'TAŞI'**
  String get transferPersonnelButton;

  /// No description provided for @transferPersonnelSuccess.
  ///
  /// In tr, this message translates to:
  /// **'{name} başarıyla taşındı.'**
  String transferPersonnelSuccess(String name);

  /// No description provided for @transferPersonnelFailed.
  ///
  /// In tr, this message translates to:
  /// **'Taşıma yapılamadı.'**
  String get transferPersonnelFailed;

  /// No description provided for @transferPersonnelError.
  ///
  /// In tr, this message translates to:
  /// **'Taşıma hatası: {error}'**
  String transferPersonnelError(String error);

  /// No description provided for @transferSquadTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tim Taşı'**
  String get transferSquadTitle;

  /// No description provided for @transferSquadButton.
  ///
  /// In tr, this message translates to:
  /// **'TAŞI'**
  String get transferSquadButton;

  /// No description provided for @transferSquadSuccess.
  ///
  /// In tr, this message translates to:
  /// **'{squadName}: {count} personel başarıyla taşındı.{skippedNote}'**
  String transferSquadSuccess(String squadName, int count, String skippedNote);

  /// No description provided for @transferSquadSkippedNote.
  ///
  /// In tr, this message translates to:
  /// **' ({count} personel zaten hedef faaliyette olduğu için atlandı)'**
  String transferSquadSkippedNote(int count);

  /// No description provided for @transferSquadAllExisting.
  ///
  /// In tr, this message translates to:
  /// **'Tüm personel zaten hedef faaliyette mevcut, taşıma yapılmadı.'**
  String get transferSquadAllExisting;

  /// No description provided for @transferSquadError.
  ///
  /// In tr, this message translates to:
  /// **'Taşıma hatası: {error}'**
  String transferSquadError(String error);

  /// No description provided for @excelPickerSelectCardsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çıktıya Eklenecek Kartlar'**
  String get excelPickerSelectCardsTitle;

  /// No description provided for @excelPickerNotice.
  ///
  /// In tr, this message translates to:
  /// **'Ana Heybet kartı dahil edilir. Ek kartları seçin; aynı kişi çıktıda yalnızca bir kez yer alır.'**
  String get excelPickerNotice;

  /// No description provided for @excelPickerNoExtraCards.
  ///
  /// In tr, this message translates to:
  /// **'Bu güne ait ek kart bulunamadı.'**
  String get excelPickerNoExtraCards;

  /// No description provided for @excelPickerSameDayCards.
  ///
  /// In tr, this message translates to:
  /// **'Aynı Günün Kartları'**
  String get excelPickerSameDayCards;

  /// No description provided for @excelPickerPreviousDayCards.
  ///
  /// In tr, this message translates to:
  /// **'Önceki Günün Kartları'**
  String get excelPickerPreviousDayCards;

  /// No description provided for @excelPickerPreviewButton.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme ({count})'**
  String excelPickerPreviewButton(int count);

  /// No description provided for @excelPickerCombinedPreviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Birleşik Çıktı Önizlemesi'**
  String get excelPickerCombinedPreviewTitle;

  /// No description provided for @excelPickerCombinedNotice.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel • Her kişi bir kez • Toplam baskıda gösterilmez'**
  String excelPickerCombinedNotice(int count);

  /// No description provided for @excelPickerSelectExport.
  ///
  /// In tr, this message translates to:
  /// **'Çıktı Seç'**
  String get excelPickerSelectExport;

  /// No description provided for @bulkImportHeaderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Metinden Toplu Aktarım'**
  String get bulkImportHeaderTitle;

  /// No description provided for @bulkImportHeaderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'WhatsApp / Telegram nöbet listelerini yapıştırıp akıllı ayrıştırın'**
  String get bulkImportHeaderSubtitle;

  /// No description provided for @bulkImportMemoryButton.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşme Hafızası'**
  String get bulkImportMemoryButton;

  /// No description provided for @bulkImportCloseTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get bulkImportCloseTooltip;

  /// No description provided for @bulkImportStepPaste.
  ///
  /// In tr, this message translates to:
  /// **'Yapıştır'**
  String get bulkImportStepPaste;

  /// No description provided for @bulkImportStepPreview.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme'**
  String get bulkImportStepPreview;

  /// No description provided for @bulkImportStepConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get bulkImportStepConfirm;

  /// No description provided for @bulkImportInputPlaceholder.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj metnini buraya yapıştırın…'**
  String get bulkImportInputPlaceholder;

  /// No description provided for @bulkImportKeepAuditTextLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ham metni yerel denetim kaydında sakla'**
  String get bulkImportKeepAuditTextLabel;

  /// No description provided for @bulkImportKeepAuditTextTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan kapalıdır; veri yalnızca bu cihazda tutulur.'**
  String get bulkImportKeepAuditTextTooltip;

  /// No description provided for @bulkImportParseButton.
  ///
  /// In tr, this message translates to:
  /// **'Metni Ayrıştır ve Kartları Oluştur'**
  String get bulkImportParseButton;

  /// No description provided for @bulkImportParsingButton.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıştırılıyor...'**
  String get bulkImportParsingButton;

  /// No description provided for @bulkImportStepperUnlockHint.
  ///
  /// In tr, this message translates to:
  /// **'Tüm kart sorunları çözülünce kaydet adımı açılır'**
  String get bulkImportStepperUnlockHint;

  /// No description provided for @bulkImportClearButton.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get bulkImportClearButton;

  /// No description provided for @bulkImportPasteSampleButton.
  ///
  /// In tr, this message translates to:
  /// **'Örnek Metin'**
  String get bulkImportPasteSampleButton;

  /// No description provided for @bulkImportConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aktarım Özeti ve Kayıt'**
  String get bulkImportConfirmTitle;

  /// No description provided for @bulkImportConfirmSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıştırılan kayıtlar doğrulanarak veritabanına aktarılacaktır.'**
  String get bulkImportConfirmSubtitle;

  /// No description provided for @bulkImportConfirmTotalCards.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulacak Kart:'**
  String get bulkImportConfirmTotalCards;

  /// No description provided for @bulkImportConfirmTotalPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Görevlendirilecek Personel:'**
  String get bulkImportConfirmTotalPersonnel;

  /// No description provided for @bulkImportConfirmSaveButton.
  ///
  /// In tr, this message translates to:
  /// **'TÜMÜNÜ KAYDET'**
  String get bulkImportConfirmSaveButton;

  /// No description provided for @bulkImportConfirmReturnButton.
  ///
  /// In tr, this message translates to:
  /// **'Önizlemeye Dön'**
  String get bulkImportConfirmReturnButton;

  /// No description provided for @bulkImportEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz ayrıştırılmış veri yok'**
  String get bulkImportEmptyTitle;

  /// No description provided for @bulkImportEmptySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sol taraftan metin yapıştırıp \'Metni Ayrıştır\' butonuna basarak başlayabilirsiniz.'**
  String get bulkImportEmptySubtitle;

  /// No description provided for @bulkImportStatTotalCards.
  ///
  /// In tr, this message translates to:
  /// **'Kart'**
  String get bulkImportStatTotalCards;

  /// No description provided for @bulkImportStatTotalPeople.
  ///
  /// In tr, this message translates to:
  /// **'Personel'**
  String get bulkImportStatTotalPeople;

  /// No description provided for @bulkImportStatReady.
  ///
  /// In tr, this message translates to:
  /// **'Hazır'**
  String get bulkImportStatReady;

  /// No description provided for @bulkImportStatIssues.
  ///
  /// In tr, this message translates to:
  /// **'Sorunlu'**
  String get bulkImportStatIssues;

  /// No description provided for @bulkImportFilterAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü ({count})'**
  String bulkImportFilterAll(int count);

  /// No description provided for @bulkImportFilterProblems.
  ///
  /// In tr, this message translates to:
  /// **'Sorunlar ({count})'**
  String bulkImportFilterProblems(int count);

  /// No description provided for @bulkImportFilterReady.
  ///
  /// In tr, this message translates to:
  /// **'Hazır ({count})'**
  String bulkImportFilterReady(int count);

  /// No description provided for @bulkImportWizardStart.
  ///
  /// In tr, this message translates to:
  /// **'Sorun Sihirbazı'**
  String get bulkImportWizardStart;

  /// No description provided for @bulkImportWizardPrev.
  ///
  /// In tr, this message translates to:
  /// **'Önceki Sorun'**
  String get bulkImportWizardPrev;

  /// No description provided for @bulkImportWizardNext.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki Sorun'**
  String get bulkImportWizardNext;

  /// No description provided for @bulkImportConfirmAllSuggestions.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Önerileri Onayla'**
  String get bulkImportConfirmAllSuggestions;

  /// No description provided for @bulkImportClearAllCards.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Temizle'**
  String get bulkImportClearAllCards;

  /// No description provided for @bulkImportClearAllConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Kartları Temizle'**
  String get bulkImportClearAllConfirmTitle;

  /// No description provided for @bulkImportClearAllConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıştırılmış tüm faaliyet kartları silinecektir. Emin misiniz?'**
  String get bulkImportClearAllConfirmMessage;

  /// No description provided for @bulkImportSaveBarSave.
  ///
  /// In tr, this message translates to:
  /// **'KAYDET'**
  String get bulkImportSaveBarSave;

  /// No description provided for @bulkImportSaveBarSaving.
  ///
  /// In tr, this message translates to:
  /// **'KAYDEDİLİYOR…'**
  String get bulkImportSaveBarSaving;

  /// No description provided for @bulkImportSaveBarFixIssues.
  ///
  /// In tr, this message translates to:
  /// **'Sorunları Düzeltin'**
  String get bulkImportSaveBarFixIssues;

  /// No description provided for @bulkImportNoCardsToSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilecek kart bulunamadı.'**
  String get bulkImportNoCardsToSave;

  /// No description provided for @bulkImportUnresolvedPersonnelError.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel eşleşmedi. Lütfen tüm personelleri seçin veya listeden kaldırın.'**
  String bulkImportUnresolvedPersonnelError(int count);

  /// No description provided for @bulkImportEmptyCardsError.
  ///
  /// In tr, this message translates to:
  /// **'Personeli bulunmayan boş kartlar var. Lütfen kartları düzenleyin veya silin.'**
  String get bulkImportEmptyCardsError;

  /// No description provided for @bulkImportBlockingIssuesError.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen önce çözülmemiş kart sorunlarını (tarih, tim veya görev türü) tamamlayın.'**
  String get bulkImportBlockingIssuesError;

  /// No description provided for @bulkImportCompletedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aktarım Tamamlandı'**
  String get bulkImportCompletedTitle;

  /// No description provided for @bulkImportSuccessNotification.
  ///
  /// In tr, this message translates to:
  /// **'{activityName} faaliyetine {count} personel eklendi.'**
  String bulkImportSuccessNotification(String activityName, int count);

  /// No description provided for @bulkImportPersonRemoved.
  ///
  /// In tr, this message translates to:
  /// **'{rank} {name} kaldırıldı.'**
  String bulkImportPersonRemoved(String rank, String name);

  /// No description provided for @bulkImportBlockRemoved.
  ///
  /// In tr, this message translates to:
  /// **'{activityType} kartı kaldırıldı.'**
  String bulkImportBlockRemoved(String activityType);

  /// No description provided for @bulkImportUndo.
  ///
  /// In tr, this message translates to:
  /// **'GERİ AL'**
  String get bulkImportUndo;

  /// No description provided for @bulkImportDuplicateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yinelenen Personel'**
  String get bulkImportDuplicateTitle;

  /// No description provided for @bulkImportDuplicateDesc.
  ///
  /// In tr, this message translates to:
  /// **'Aynı personel aynı gün birden fazla karta atanmış.'**
  String get bulkImportDuplicateDesc;

  /// No description provided for @bulkImportEditBlockTitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet kartını düzenle'**
  String get bulkImportEditBlockTitle;

  /// No description provided for @bulkImportBlockDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get bulkImportBlockDate;

  /// No description provided for @bulkImportBlockSquad.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı Tim'**
  String get bulkImportBlockSquad;

  /// No description provided for @bulkImportBlockActivity.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet / Görev Türü'**
  String get bulkImportBlockActivity;

  /// No description provided for @bulkImportBlockTimeRange.
  ///
  /// In tr, this message translates to:
  /// **'Saat Aralığı (İsteğe bağlı)'**
  String get bulkImportBlockTimeRange;

  /// No description provided for @bulkImportMemoryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Öğrenilen İsim Eşleştirmeleri'**
  String get bulkImportMemoryTitle;

  /// No description provided for @bulkImportMemoryEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kaydedilmiş bir eşleştirme hafızası bulunmuyor.'**
  String get bulkImportMemoryEmpty;

  /// No description provided for @bulkImportMemoryClearAll.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Hafızayı Temizle'**
  String get bulkImportMemoryClearAll;

  /// No description provided for @bulkImportMemoryAliasRemoved.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştirme silindi.'**
  String get bulkImportMemoryAliasRemoved;

  /// No description provided for @backupRestoreSurfaceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tam yedekleme ve geri yükleme'**
  String get backupRestoreSurfaceTitle;

  /// No description provided for @backupRestoreSurfaceSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bulut gerekmez; dosya sizin seçtiğiniz yerde kalır.'**
  String get backupRestoreSurfaceSubtitle;

  /// No description provided for @backupModeExport.
  ///
  /// In tr, this message translates to:
  /// **'Yedekle'**
  String get backupModeExport;

  /// No description provided for @backupModeImport.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükle'**
  String get backupModeImport;

  /// No description provided for @backupInfoWhatIsInsideTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedekte neler var?'**
  String get backupInfoWhatIsInsideTitle;

  /// No description provided for @backupInfoWhatIsInsideDesc.
  ///
  /// In tr, this message translates to:
  /// **'İsimler, timler, kullanıcılar, telefonlar, görevler, aylık matris, faaliyet arşivi, raporlar, takma adlar, toplu aktarım geçmişi ve TEMGÜNDRAP belgeleri.'**
  String get backupInfoWhatIsInsideDesc;

  /// No description provided for @backupInfoPreserveTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama silinse de koruyun'**
  String get backupInfoPreserveTitle;

  /// No description provided for @backupInfoPreserveDesc.
  ///
  /// In tr, this message translates to:
  /// **'Açılan kaydet ekranından İndirilenler gibi cihazın yerel bir klasörünü seçin. Uygulamanın kendi klasörüne bırakmayın.'**
  String get backupInfoPreserveDesc;

  /// No description provided for @backupInfoSecurityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dosyayı güvenli tutun'**
  String get backupInfoSecurityTitle;

  /// No description provided for @backupInfoSecurityDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yedek kişisel bilgiler içerir. Yalnızca güvenilir bir yerel klasörde saklayın ve başkalarıyla paylaşmayın.'**
  String get backupInfoSecurityDesc;

  /// No description provided for @backupSaveToDeviceButton.
  ///
  /// In tr, this message translates to:
  /// **'Tam yedeği cihazda sakla'**
  String get backupSaveToDeviceButton;

  /// No description provided for @backupCopyTextButton.
  ///
  /// In tr, this message translates to:
  /// **'Yedek metnini de kopyala'**
  String get backupCopyTextButton;

  /// No description provided for @backupPickFileButton.
  ///
  /// In tr, this message translates to:
  /// **'Yedek dosyası seç'**
  String get backupPickFileButton;

  /// No description provided for @backupPasteFromClipboardButton.
  ///
  /// In tr, this message translates to:
  /// **'Panodaki eski yedeği kullan'**
  String get backupPasteFromClipboardButton;

  /// No description provided for @backupRestoreExecuteButton.
  ///
  /// In tr, this message translates to:
  /// **'Yedeği geri yükle'**
  String get backupRestoreExecuteButton;

  /// No description provided for @backupPreviewLegacyDate.
  ///
  /// In tr, this message translates to:
  /// **'Eski yedek'**
  String get backupPreviewLegacyDate;

  /// No description provided for @backupPreviewLegacyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Eski personel yedeği'**
  String get backupPreviewLegacyTitle;

  /// No description provided for @backupPreviewVerifiedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış tam yedek'**
  String get backupPreviewVerifiedTitle;

  /// No description provided for @backupPreviewSummary.
  ///
  /// In tr, this message translates to:
  /// **'{date} • {personnelCount} personel • {activityCount} faaliyet • {assignmentCount} görev kaydı • {temgundrapCount} TEMGÜNDRAP'**
  String backupPreviewSummary(String date, int personnelCount,
      int activityCount, int assignmentCount, int temgundrapCount);

  /// No description provided for @backupConfirmOverwriteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut veriler değiştirilsin mi?'**
  String get backupConfirmOverwriteTitle;

  /// No description provided for @backupConfirmOverwriteMessage.
  ///
  /// In tr, this message translates to:
  /// **'Tam geri yükleme mevcut personel, görev, matris ve TEMGÜNDRAP kayıtlarının yerine yedekteki verileri koyar. Bu işlem geri alınamaz.'**
  String get backupConfirmOverwriteMessage;

  /// No description provided for @backupClipboardEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Panoda yedek metni bulunamadı.'**
  String get backupClipboardEmpty;

  /// No description provided for @backupClipboardReadError.
  ///
  /// In tr, this message translates to:
  /// **'Panodaki yedek okunamadı.'**
  String get backupClipboardReadError;

  /// No description provided for @backupPickFilePrompt.
  ///
  /// In tr, this message translates to:
  /// **'Önce bir yedek dosyası seçin.'**
  String get backupPickFilePrompt;

  /// No description provided for @backupTextCopied.
  ///
  /// In tr, this message translates to:
  /// **'Yedek metni panoya kopyalandı.'**
  String get backupTextCopied;

  /// No description provided for @backupVerifiedReady.
  ///
  /// In tr, this message translates to:
  /// **'Yedek doğrulandı ve geri yüklemeye hazır.'**
  String get backupVerifiedReady;

  /// No description provided for @backupCreateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yedek oluşturulamadı. Lütfen tekrar deneyin.'**
  String get backupCreateFailed;

  /// No description provided for @backupFileReadError.
  ///
  /// In tr, this message translates to:
  /// **'Yedek dosyası okunamadı.'**
  String get backupFileReadError;

  /// No description provided for @backupRestoreFailedDataPreserved.
  ///
  /// In tr, this message translates to:
  /// **'Yedek geri yüklenemedi; mevcut veriler korunmuştur.'**
  String get backupRestoreFailedDataPreserved;

  /// No description provided for @backupLegacyImportSuccess.
  ///
  /// In tr, this message translates to:
  /// **'{count} yeni personel eski yedekten aktarıldı.'**
  String backupLegacyImportSuccess(int count);

  /// No description provided for @backupFullRestoreSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükleme tamamlandı: {personnelCount} personel, {activityCount} faaliyet ve {temgundrapCount} TEMGÜNDRAP belgesi.'**
  String backupFullRestoreSuccess(
      int personnelCount, int activityCount, int temgundrapCount);

  /// No description provided for @activityDutyForPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'{name} için görev'**
  String activityDutyForPersonnel(String name);

  /// No description provided for @bulkImportBannerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Metinden Toplu Aktarım'**
  String get bulkImportBannerTitle;

  /// No description provided for @bulkImportManageMemoryTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Hafızasını (Takma Adları) Yönet'**
  String get bulkImportManageMemoryTooltip;

  /// No description provided for @bulkImportStepSaveLockedTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Tüm kart sorunları çözülünce kaydet adımı açılır'**
  String get bulkImportStepSaveLockedTooltip;

  /// No description provided for @bulkImportConfirmCannotSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilemiyor'**
  String get bulkImportConfirmCannotSave;

  /// No description provided for @bulkImportConfirmReadyToSave.
  ///
  /// In tr, this message translates to:
  /// **'Kayda Hazır'**
  String get bulkImportConfirmReadyToSave;

  /// No description provided for @bulkImportConfirmResolveIssues.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen önizleme adımına dönüp sorunları çözün.'**
  String get bulkImportConfirmResolveIssues;

  /// No description provided for @bulkImportConfirmSummary.
  ///
  /// In tr, this message translates to:
  /// **'{cardCount} kart, {personnelCount} personel, {dayCount} gün'**
  String bulkImportConfirmSummary(
      int cardCount, int personnelCount, int dayCount);

  /// No description provided for @bulkImportInputRawTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ham Metni Yapıştırın:'**
  String get bulkImportInputRawTitle;

  /// No description provided for @bulkImportInputRawSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tarih, görev türü ve personel listesini içeren mesajı olduğu gibi yapıştırabilirsiniz.'**
  String get bulkImportInputRawSubtitle;

  /// No description provided for @bulkImportKeepAuditTextDesc.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan kapalıdır; veri yalnızca bu cihazda tutulur.'**
  String get bulkImportKeepAuditTextDesc;

  /// No description provided for @bulkImportInputPlaceholderShort.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj metnini buraya yapıştırın…'**
  String get bulkImportInputPlaceholderShort;

  /// No description provided for @bulkImportParseAndCreateCards.
  ///
  /// In tr, this message translates to:
  /// **'Metni Ayrıştır ve Kartları Oluştur'**
  String get bulkImportParseAndCreateCards;

  /// No description provided for @bulkImportEmptyNoCardIssues.
  ///
  /// In tr, this message translates to:
  /// **'Kartlara bağlı sorun kalmadı'**
  String get bulkImportEmptyNoCardIssues;

  /// No description provided for @bulkImportEmptyAllIssuesResolved.
  ///
  /// In tr, this message translates to:
  /// **'Tüm kart sorunları çözüldü'**
  String get bulkImportEmptyAllIssuesResolved;

  /// No description provided for @bulkImportEmptyCheckNoticePanel.
  ///
  /// In tr, this message translates to:
  /// **'Kalan kritik ayrıştırma sorunlarını yukarıdaki uyarı panelinden inceleyin.'**
  String get bulkImportEmptyCheckNoticePanel;

  /// No description provided for @bulkImportEmptyReturnToAllCards.
  ///
  /// In tr, this message translates to:
  /// **'İsterseniz tüm faaliyet kartlarına geri dönebilirsiniz.'**
  String get bulkImportEmptyReturnToAllCards;

  /// No description provided for @bulkImportEmptyShowAllCards.
  ///
  /// In tr, this message translates to:
  /// **'TÜM KARTLARI GÖSTER'**
  String get bulkImportEmptyShowAllCards;

  /// No description provided for @bulkImportStatCardCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} Kart'**
  String bulkImportStatCardCount(int count);

  /// No description provided for @bulkImportStatPersonnelCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} Personel'**
  String bulkImportStatPersonnelCount(int count);

  /// No description provided for @bulkImportStatDayCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} Gün'**
  String bulkImportStatDayCount(int count);

  /// No description provided for @bulkImportSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Personel, tim veya satır ara'**
  String get bulkImportSearchHint;

  /// No description provided for @bulkImportFilterProblemsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sorunlar'**
  String get bulkImportFilterProblemsLabel;

  /// No description provided for @bulkImportCorrectnessPanelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Doğruluk Paneli'**
  String get bulkImportCorrectnessPanelTitle;

  /// No description provided for @bulkImportCannotSaveStatus.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilemiyor'**
  String get bulkImportCannotSaveStatus;

  /// No description provided for @bulkImportAllChecksPassed.
  ///
  /// In tr, this message translates to:
  /// **'Tüm kontroller tamam'**
  String get bulkImportAllChecksPassed;

  /// No description provided for @bulkImportActionsRequiredBeforeSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetmeden önce {count} işlem tamamlanmalı'**
  String bulkImportActionsRequiredBeforeSave(int count);

  /// No description provided for @bulkImportOptionalReviews.
  ///
  /// In tr, this message translates to:
  /// **'{count} isteğe bağlı inceleme'**
  String bulkImportOptionalReviews(int count);

  /// No description provided for @bulkImportCriticalErrors.
  ///
  /// In tr, this message translates to:
  /// **'{count} kritik hata'**
  String bulkImportCriticalErrors(int count);

  /// No description provided for @bulkImportReviewsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} inceleme'**
  String bulkImportReviewsCount(int count);

  /// No description provided for @bulkImportMetricCard.
  ///
  /// In tr, this message translates to:
  /// **'kart'**
  String get bulkImportMetricCard;

  /// No description provided for @bulkImportMetricPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'personel'**
  String get bulkImportMetricPersonnel;

  /// No description provided for @bulkImportMetricDay.
  ///
  /// In tr, this message translates to:
  /// **'gün'**
  String get bulkImportMetricDay;

  /// No description provided for @bulkImportMetricCritical.
  ///
  /// In tr, this message translates to:
  /// **'kritik'**
  String get bulkImportMetricCritical;

  /// No description provided for @bulkImportMetricReview.
  ///
  /// In tr, this message translates to:
  /// **'inceleme'**
  String get bulkImportMetricReview;

  /// No description provided for @bulkImportIgnoredLinesNotice.
  ///
  /// In tr, this message translates to:
  /// **'{count} başlık, toplam veya not satırı personel kaydı olarak alınmadı.'**
  String bulkImportIgnoredLinesNotice(int count);

  /// No description provided for @bulkImportNoCardsYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz Kart Oluşturulmadı'**
  String get bulkImportNoCardsYet;

  /// No description provided for @bulkImportReturnToPastePrompt.
  ///
  /// In tr, this message translates to:
  /// **'Yapıştır adımına dönüp mesajı yapıştırın.'**
  String get bulkImportReturnToPastePrompt;

  /// No description provided for @bulkImportStatusCritical.
  ///
  /// In tr, this message translates to:
  /// **'Kritik'**
  String get bulkImportStatusCritical;

  /// No description provided for @bulkImportStatusReview.
  ///
  /// In tr, this message translates to:
  /// **'İnceleme'**
  String get bulkImportStatusReview;

  /// No description provided for @bulkImportFixAction.
  ///
  /// In tr, this message translates to:
  /// **'Düzelt'**
  String get bulkImportFixAction;

  /// No description provided for @bulkImportLineNumber.
  ///
  /// In tr, this message translates to:
  /// **'Satır {number}'**
  String bulkImportLineNumber(int number);

  /// No description provided for @bulkImportDuplicateListTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu Liste Daha Önce Aktarıldı'**
  String get bulkImportDuplicateListTitle;

  /// No description provided for @bulkImportDuplicateListMessage.
  ///
  /// In tr, this message translates to:
  /// **'{dates} tarihli bu içerik {recordDate} tarihinde {user} tarafından kaydedilmiş.\n\nVeritabanında bu listeye ait {activeCount} personel kaydı aktif duruyor. Eksik olanları tamamlamak veya yeniden aktarmak istiyor musunuz?'**
  String bulkImportDuplicateListMessage(
      String dates, String recordDate, String user, int activeCount);

  /// No description provided for @bulkImportCompleteMissingOrReimport.
  ///
  /// In tr, this message translates to:
  /// **'EKSİKLERİ TAMAMLA / YENİDEN AKTAR'**
  String get bulkImportCompleteMissingOrReimport;

  /// No description provided for @bulkImportSummaryActivitiesProcessed.
  ///
  /// In tr, this message translates to:
  /// **'{count} günlük faaliyet işlendi.'**
  String bulkImportSummaryActivitiesProcessed(int count);

  /// No description provided for @bulkImportSummaryPersonnelAdded.
  ///
  /// In tr, this message translates to:
  /// **'{count} yeni personel eklendi.'**
  String bulkImportSummaryPersonnelAdded(int count);

  /// No description provided for @bulkImportSummaryAlreadyAssigned.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel zaten o görevde ekliydi.'**
  String bulkImportSummaryAlreadyAssigned(int count);

  /// No description provided for @bulkImportSummaryDeduplicated.
  ///
  /// In tr, this message translates to:
  /// **'{count} tekrar tekilleştirildi.'**
  String bulkImportSummaryDeduplicated(int count);

  /// No description provided for @bulkImportSummarySkippedConflict.
  ///
  /// In tr, this message translates to:
  /// **'{count} çakışan kayıt atlandı.'**
  String bulkImportSummarySkippedConflict(int count);

  /// No description provided for @bulkImportSuccessBanner.
  ///
  /// In tr, this message translates to:
  /// **'{blockCount} blok → {activityCount} günlük faaliyet, {personnelCount} personel başarıyla eklendi.'**
  String bulkImportSuccessBanner(
      int blockCount, int activityCount, int personnelCount);

  /// No description provided for @bulkImportSaveButtonSummary.
  ///
  /// In tr, this message translates to:
  /// **'{blockCount} blok -> {dayCount} günlük faaliyet'**
  String bulkImportSaveButtonSummary(int blockCount, int dayCount);

  /// No description provided for @bulkImportSaveActivitiesWithCardCount.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyetleri Kaydet ({count} Kart)'**
  String bulkImportSaveActivitiesWithCardCount(int count);

  /// No description provided for @bulkImportNextReview.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki inceleme'**
  String get bulkImportNextReview;

  /// No description provided for @bulkImportOpenNextProblem.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki sorunu aç'**
  String get bulkImportOpenNextProblem;

  /// No description provided for @bulkImportRemainingActionsBeforeSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetmek için {count} işlem kaldı'**
  String bulkImportRemainingActionsBeforeSave(int count);

  /// No description provided for @bulkImportCriticalAndReviewCount.
  ///
  /// In tr, this message translates to:
  /// **'{criticalCount} kritik hata • {reviewCount} inceleme'**
  String bulkImportCriticalAndReviewCount(int criticalCount, int reviewCount);

  /// No description provided for @bulkImportPendingReviewItemsTitle.
  ///
  /// In tr, this message translates to:
  /// **'İnceleme Bekleyen Ögeler Var'**
  String get bulkImportPendingReviewItemsTitle;

  /// No description provided for @bulkImportReviewItemsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{count} eşleşme/tim kontrolü gerektiriyor'**
  String bulkImportReviewItemsSubtitle(int count);

  /// No description provided for @bulkImportReadyToSaveSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kayda hazır'**
  String get bulkImportReadyToSaveSubtitle;

  /// No description provided for @bulkImportHighlightedCardsPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen aşağıda vurgulanan kartlardaki eksik personelleri eşleştirin, tekrarları düzeltin veya boş kartları silin.'**
  String get bulkImportHighlightedCardsPrompt;

  /// No description provided for @bulkImportDuplicateSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Aynı personel aynı tarihte birden fazla görevde bulunuyor. Aktarmadan önce önizlemedeki tekrarları düzeltin.'**
  String get bulkImportDuplicateSubtitle;

  /// No description provided for @bulkImportReturnToPreviewButton.
  ///
  /// In tr, this message translates to:
  /// **'ÖNİZLEMEYE DÖN'**
  String get bulkImportReturnToPreviewButton;

  /// No description provided for @bulkImportDefaultTeamOption.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan / Personel Timi'**
  String get bulkImportDefaultTeamOption;

  /// No description provided for @bulkImportCustomOption.
  ///
  /// In tr, this message translates to:
  /// **'DİĞER (Elle Yaz...)'**
  String get bulkImportCustomOption;

  /// No description provided for @bulkImportQuickDutySelection.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Görev Seçimi'**
  String get bulkImportQuickDutySelection;

  /// No description provided for @bulkImportSelectDutyHint.
  ///
  /// In tr, this message translates to:
  /// **'Görev seç'**
  String get bulkImportSelectDutyHint;

  /// No description provided for @bulkImportSelectDutyType.
  ///
  /// In tr, this message translates to:
  /// **'Görev / Faaliyet Türü Seçin'**
  String get bulkImportSelectDutyType;

  /// No description provided for @bulkImportCustomDutyName.
  ///
  /// In tr, this message translates to:
  /// **'Görev / Faaliyet Adı (Elle Düzenle)'**
  String get bulkImportCustomDutyName;

  /// No description provided for @bulkImportSelectTeam.
  ///
  /// In tr, this message translates to:
  /// **'Takım / Tim Seçin'**
  String get bulkImportSelectTeam;

  /// No description provided for @bulkImportCustomTeamName.
  ///
  /// In tr, this message translates to:
  /// **'Takım / Tim Adı (Elle Düzenle)'**
  String get bulkImportCustomTeamName;

  /// No description provided for @bulkImportApplyChanges.
  ///
  /// In tr, this message translates to:
  /// **'DEĞİŞİKLİKLERİ UYGULA'**
  String get bulkImportApplyChanges;

  /// No description provided for @bulkImportDeleteAliasTitle.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşmeyi Sil'**
  String get bulkImportDeleteAliasTitle;

  /// No description provided for @bulkImportDeleteAliasConfirm.
  ///
  /// In tr, this message translates to:
  /// **'\'{rawName}\' ➔ \'{rank} {name}\' öğrenilmiş takma ad eşleşmesi silinsin mi?'**
  String bulkImportDeleteAliasConfirm(String rawName, String rank, String name);

  /// No description provided for @bulkImportAliasDeletedFromMemory.
  ///
  /// In tr, this message translates to:
  /// **'\'{name}\' hafızadan silindi.'**
  String bulkImportAliasDeletedFromMemory(String name);

  /// No description provided for @bulkImportSystemMemoryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sistem Hafızası'**
  String get bulkImportSystemMemoryTitle;

  /// No description provided for @bulkImportLearnedAliasesCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} Öğrenilmiş İsim Takma Adı'**
  String bulkImportLearnedAliasesCount(int count);

  /// No description provided for @bulkImportSearchAliasHintMobile.
  ///
  /// In tr, this message translates to:
  /// **'Yazım veya personel adı ara'**
  String get bulkImportSearchAliasHintMobile;

  /// No description provided for @bulkImportSearchAliasHintDesktop.
  ///
  /// In tr, this message translates to:
  /// **'Metindeki yazım veya personel adıyla ara...'**
  String get bulkImportSearchAliasHintDesktop;

  /// No description provided for @bulkImportNoAliasFoundForSearch.
  ///
  /// In tr, this message translates to:
  /// **'Aramanıza uygun takma ad bulunamadı.'**
  String get bulkImportNoAliasFoundForSearch;

  /// No description provided for @bulkImportNoLearnedAliasesYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz öğrenilmiş bir takma ad bulunmuyor.\nToplu aktarımlarda onayladığınız eşleşmeler otomatik hafızaya alınır.'**
  String get bulkImportNoLearnedAliasesYet;

  /// No description provided for @bulkImportTextName.
  ///
  /// In tr, this message translates to:
  /// **'Metindeki ad'**
  String get bulkImportTextName;

  /// No description provided for @bulkImportMatchedPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştiği personel'**
  String get bulkImportMatchedPersonnel;

  /// No description provided for @bulkImportDeleteAliasTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Takma adı hafızadan sil'**
  String get bulkImportDeleteAliasTooltip;

  /// No description provided for @bulkImportUnassignedOrOtherPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Timsiz / Diğer Personeller'**
  String get bulkImportUnassignedOrOtherPersonnel;

  /// No description provided for @bulkImportPersonnelNotSelected.
  ///
  /// In tr, this message translates to:
  /// **'Personel seçilmedi'**
  String get bulkImportPersonnelNotSelected;

  /// No description provided for @bulkImportAutoMatchedFromMemory.
  ///
  /// In tr, this message translates to:
  /// **'Hafızadan Otomatik Eşleşti'**
  String get bulkImportAutoMatchedFromMemory;

  /// No description provided for @bulkImportFromMemory.
  ///
  /// In tr, this message translates to:
  /// **'Hafızadan'**
  String get bulkImportFromMemory;

  /// No description provided for @bulkImportInText.
  ///
  /// In tr, this message translates to:
  /// **'Metinde: {text}'**
  String bulkImportInText(String text);

  /// No description provided for @bulkImportRemovePersonnelTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Personeli kaldır'**
  String get bulkImportRemovePersonnelTooltip;

  /// No description provided for @bulkImportSelectedError.
  ///
  /// In tr, this message translates to:
  /// **'SEÇİLİ HATA'**
  String get bulkImportSelectedError;

  /// No description provided for @bulkImportReviewedPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'İNCELENEN PERSONEL'**
  String get bulkImportReviewedPersonnel;

  /// No description provided for @bulkImportDuplicateOnSameDate.
  ///
  /// In tr, this message translates to:
  /// **'Aynı tarihte ayrıca: {assignments}'**
  String bulkImportDuplicateOnSameDate(String assignments);

  /// No description provided for @bulkImportTeamMismatchAccept.
  ///
  /// In tr, this message translates to:
  /// **'Tim disi gorev (Kabul et)'**
  String get bulkImportTeamMismatchAccept;

  /// No description provided for @bulkImportUserConfirmed.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı onayladı'**
  String get bulkImportUserConfirmed;

  /// No description provided for @bulkImportTeamMismatchDuty.
  ///
  /// In tr, this message translates to:
  /// **'Tim disi gorev'**
  String get bulkImportTeamMismatchDuty;

  /// No description provided for @bulkImportDeleteAliasAction.
  ///
  /// In tr, this message translates to:
  /// **'SİL'**
  String get bulkImportDeleteAliasAction;

  /// No description provided for @bulkImportCheckMatchWithPercent.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşmeyi kontrol edin (%{percent})'**
  String bulkImportCheckMatchWithPercent(int percent);

  /// No description provided for @bulkImportCheckMatch.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşmeyi kontrol edin'**
  String get bulkImportCheckMatch;

  /// No description provided for @bulkImportMatched.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşti'**
  String get bulkImportMatched;

  /// No description provided for @bulkImportNotMatched.
  ///
  /// In tr, this message translates to:
  /// **'Eşleşmedi'**
  String get bulkImportNotMatched;

  /// No description provided for @bulkImportError.
  ///
  /// In tr, this message translates to:
  /// **'Hata oluştu: {error}'**
  String bulkImportError(String error);

  /// No description provided for @bulkImportNoPersonnelToAdd.
  ///
  /// In tr, this message translates to:
  /// **'Eklenecek personel bulunamadı.'**
  String get bulkImportNoPersonnelToAdd;

  /// No description provided for @bulkImportClearPreviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Önizlemeyi temizle?'**
  String get bulkImportClearPreviewTitle;

  /// No description provided for @bulkImportClearPreviewMessage.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulan tüm kartlar ve ayrıştırma uyarıları kaldırılacak.'**
  String get bulkImportClearPreviewMessage;

  /// No description provided for @bulkImportAllSuggestionsConfirmed.
  ///
  /// In tr, this message translates to:
  /// **'Tüm önerilen personel eşleşmeleri onaylandı.'**
  String get bulkImportAllSuggestionsConfirmed;

  /// No description provided for @bulkImportPersonAddedToDbAndMatched.
  ///
  /// In tr, this message translates to:
  /// **'{rank} {name} veritabanına ({team}) eklendi ve eşleştirildi.'**
  String bulkImportPersonAddedToDbAndMatched(
      String rank, String name, String team);

  /// No description provided for @commonNoTeam.
  ///
  /// In tr, this message translates to:
  /// **'Timsiz'**
  String get commonNoTeam;

  /// No description provided for @bulkImportSelectDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih seç'**
  String get bulkImportSelectDate;

  /// No description provided for @personnelPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personel ve Timler'**
  String get personnelPageTitle;

  /// No description provided for @personnelBackupRestoreTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Yedekle ve geri yükle'**
  String get personnelBackupRestoreTooltip;

  /// No description provided for @personnelCommanderDelegationTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Komutan yetkileri'**
  String get personnelCommanderDelegationTooltip;

  /// No description provided for @personnelNewSquadTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Yeni tim'**
  String get personnelNewSquadTooltip;

  /// No description provided for @personnelManagementActionsTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Yönetim işlemleri'**
  String get personnelManagementActionsTooltip;

  /// No description provided for @personnelManagementActionsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yönetim İşlemleri'**
  String get personnelManagementActionsTitle;

  /// No description provided for @personnelManagementActionsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Personel ve uygulama yönetimi'**
  String get personnelManagementActionsSubtitle;

  /// No description provided for @personnelCreateSquadOptionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni tim'**
  String get personnelCreateSquadOptionTitle;

  /// No description provided for @personnelCreateSquadOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bir tim oluştur'**
  String get personnelCreateSquadOptionSubtitle;

  /// No description provided for @personnelCommanderOptionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Komutan yetkileri'**
  String get personnelCommanderOptionTitle;

  /// No description provided for @personnelCommanderOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tim komutanlarını ve yetkileri yönet'**
  String get personnelCommanderOptionSubtitle;

  /// No description provided for @personnelBackupOptionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedekle ve geri yükle'**
  String get personnelBackupOptionTitle;

  /// No description provided for @personnelBackupOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama verilerini güvenli şekilde yönet'**
  String get personnelBackupOptionSubtitle;

  /// No description provided for @personnelAddButton.
  ///
  /// In tr, this message translates to:
  /// **'Personel Ekle'**
  String get personnelAddButton;

  /// No description provided for @personnelListCount.
  ///
  /// In tr, this message translates to:
  /// **'Personel Listesi ({count} Kişi)'**
  String personnelListCount(int count);

  /// No description provided for @personnelOfficialOrderSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Resmi Tim & Kıdem Sıralı'**
  String get personnelOfficialOrderSubtitle;

  /// No description provided for @personnelUnassignedSquad.
  ///
  /// In tr, this message translates to:
  /// **'Boşta / Kadro Dışı Personeller'**
  String get personnelUnassignedSquad;

  /// No description provided for @personnelUnknownSquad.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen Tim'**
  String get personnelUnknownSquad;

  /// No description provided for @personnelCountSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel'**
  String personnelCountSubtitle(int count);

  /// No description provided for @personnelUnitAndRegistration.
  ///
  /// In tr, this message translates to:
  /// **'Birlik: {unit} | Kayıt: {date}'**
  String personnelUnitAndRegistration(String unit, String date);

  /// No description provided for @personnelActionsTooltip.
  ///
  /// In tr, this message translates to:
  /// **'İşlemler'**
  String get personnelActionsTooltip;

  /// No description provided for @personnelDeactivateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personeli Pasifleştir'**
  String get personnelDeactivateTitle;

  /// No description provided for @personnelDeactivateConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{rank} {name} isimli personel pasifleştirilecektir. Geçmiş görev ve raporları korunur. Emin misiniz?'**
  String personnelDeactivateConfirm(String rank, String name);

  /// No description provided for @personnelDeactivateAction.
  ///
  /// In tr, this message translates to:
  /// **'PASİFLEŞTİR'**
  String get personnelDeactivateAction;

  /// No description provided for @personnelActionsMenuTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personel İşlemleri'**
  String get personnelActionsMenuTitle;

  /// No description provided for @personnelEditOptionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle / Tim değiştir'**
  String get personnelEditOptionTitle;

  /// No description provided for @personnelEditOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Personel bilgilerini güncelle'**
  String get personnelEditOptionSubtitle;

  /// No description provided for @personnelMakeCommanderOptionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Komutan yetkileri'**
  String get personnelMakeCommanderOptionTitle;

  /// No description provided for @personnelMakeCommanderOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tim komutanı yap veya yetki ver'**
  String get personnelMakeCommanderOptionSubtitle;

  /// No description provided for @personnelDeleteOptionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personeli sil'**
  String get personnelDeleteOptionTitle;

  /// No description provided for @personnelDeleteOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alınamaz'**
  String get personnelDeleteOptionSubtitle;

  /// No description provided for @personnelAddModalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personel Ekle'**
  String get personnelAddModalTitle;

  /// No description provided for @personnelAddSingleOptionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tek Personel Ekle'**
  String get personnelAddSingleOptionTitle;

  /// No description provided for @personnelAddSingleOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bilgileri form üzerinden girin'**
  String get personnelAddSingleOptionSubtitle;

  /// No description provided for @personnelAddBulkOptionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Metinden Toplu Ekle'**
  String get personnelAddBulkOptionTitle;

  /// No description provided for @personnelAddBulkOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Listeyi yapıştırıp önizleyin'**
  String get personnelAddBulkOptionSubtitle;

  /// No description provided for @personnelBulkImportSuccess.
  ///
  /// In tr, this message translates to:
  /// **'{added} personel eklendi, {updated} personel güncellendi, {skipped} satır atlandı.'**
  String personnelBulkImportSuccess(int added, int updated, int skipped);

  /// No description provided for @personnelMakeCommanderTitle.
  ///
  /// In tr, this message translates to:
  /// **'⭐ Tim Komutanı Yap: {rank} {name}'**
  String personnelMakeCommanderTitle(String rank, String name);

  /// No description provided for @personnelMakeCommanderDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bu personeli bir Time Komutan olarak atayabilir ve giriş yetkisi verebilirsiniz.'**
  String get personnelMakeCommanderDescription;

  /// No description provided for @personnelUsernameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Adı (Giriş için)'**
  String get personnelUsernameLabel;

  /// No description provided for @personnelTargetSquadLabel.
  ///
  /// In tr, this message translates to:
  /// **'Komutanı Olacağı Tim'**
  String get personnelTargetSquadLabel;

  /// No description provided for @personnelFirstLoginPasswordHint.
  ///
  /// In tr, this message translates to:
  /// **'💡 Personel ilk girişinde kendi parolasını belirleyecektir.'**
  String get personnelFirstLoginPasswordHint;

  /// No description provided for @personnelMakeCommanderAction.
  ///
  /// In tr, this message translates to:
  /// **'KOMUTAN YAP VE YETKİLENDİR'**
  String get personnelMakeCommanderAction;

  /// No description provided for @personnelUsernameAndSquadWarning.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen kullanıcı adı ve tim seçiniz.'**
  String get personnelUsernameAndSquadWarning;

  /// No description provided for @personnelCommanderSuccess.
  ///
  /// In tr, this message translates to:
  /// **'{name} Tim Komutanı olarak yetkilendirildi!'**
  String personnelCommanderSuccess(String name);

  /// No description provided for @personnelCommanderDelegationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tim Komutanı Yetki Devri / Atama'**
  String get personnelCommanderDelegationTitle;

  /// No description provided for @personnelNoCommandersFound.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı Tim Komutanı hesabı bulunamadı.'**
  String get personnelNoCommandersFound;

  /// No description provided for @personnelCommanderLabel.
  ///
  /// In tr, this message translates to:
  /// **'Komutan: {name}'**
  String personnelCommanderLabel(String name);

  /// No description provided for @personnelAssignedSquadLabel.
  ///
  /// In tr, this message translates to:
  /// **'Atanan Tim'**
  String get personnelAssignedSquadLabel;

  /// No description provided for @personnelUnassignedOrUnauthorized.
  ///
  /// In tr, this message translates to:
  /// **'BOŞTA / Yetkisiz'**
  String get personnelUnassignedOrUnauthorized;

  /// No description provided for @personnelAuthorizeNewCommander.
  ///
  /// In tr, this message translates to:
  /// **'YENİ KOMUTAN YETKİLENDİR'**
  String get personnelAuthorizeNewCommander;

  /// No description provided for @personnelNewCommanderDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Komutan Yetkilendirme'**
  String get personnelNewCommanderDialogTitle;

  /// No description provided for @personnelUsernameExampleLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Adı (Örn: ahmet.kaya)'**
  String get personnelUsernameExampleLabel;

  /// No description provided for @personnelNoPasswordNeededHint.
  ///
  /// In tr, this message translates to:
  /// **'💡 Şifre istenmez. Kullanıcı ilk girişinde kendi parolasını belirler.'**
  String get personnelNoPasswordNeededHint;

  /// No description provided for @personnelAuthorizeAction.
  ///
  /// In tr, this message translates to:
  /// **'YETKİLENDİR'**
  String get personnelAuthorizeAction;

  /// No description provided for @squadCreateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Tim Oluştur'**
  String get squadCreateTitle;

  /// No description provided for @squadCreateDescription.
  ///
  /// In tr, this message translates to:
  /// **'Tim bilgilerini girin. Komutan hesabını şimdi veya daha sonra atayabilirsiniz.'**
  String get squadCreateDescription;

  /// No description provided for @squadNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tim adı'**
  String get squadNameLabel;

  /// No description provided for @squadNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. 1-B Timi'**
  String get squadNameHint;

  /// No description provided for @squadNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Tim adı zorunludur'**
  String get squadNameRequired;

  /// No description provided for @squadCommanderUserLabel.
  ///
  /// In tr, this message translates to:
  /// **'Komutan kullanıcı adı'**
  String get squadCommanderUserLabel;

  /// No description provided for @squadCommanderPasswordHint.
  ///
  /// In tr, this message translates to:
  /// **'Komutan ilk girişinde kendi parolasını belirler.'**
  String get squadCommanderPasswordHint;

  /// No description provided for @squadCreateAction.
  ///
  /// In tr, this message translates to:
  /// **'Tim Oluştur'**
  String get squadCreateAction;

  /// No description provided for @personnelCustomRankDropdownOption.
  ///
  /// In tr, this message translates to:
  /// **'DİĞER / ÖZEL RÜTBE (Elle Gir)'**
  String get personnelCustomRankDropdownOption;

  /// No description provided for @personnelSquadsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Timler yüklenemedi: {error}'**
  String personnelSquadsLoadError(String error);

  /// No description provided for @bulkPersonnelImportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Metinden Personel Ekle'**
  String get bulkPersonnelImportTitle;

  /// No description provided for @bulkPersonnelInputLabel.
  ///
  /// In tr, this message translates to:
  /// **'Personel listesini yapıştırın'**
  String get bulkPersonnelInputLabel;

  /// No description provided for @bulkPersonnelTargetSquadLabel.
  ///
  /// In tr, this message translates to:
  /// **'Hedef tim'**
  String get bulkPersonnelTargetSquadLabel;

  /// No description provided for @bulkPersonnelOutsideSquad.
  ///
  /// In tr, this message translates to:
  /// **'Tim dışı'**
  String get bulkPersonnelOutsideSquad;

  /// No description provided for @bulkPersonnelCountFound.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel bulundu'**
  String bulkPersonnelCountFound(int count);

  /// No description provided for @bulkPersonnelUnknownRankCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} satırda rütbe bulunamadı. Kaydetmeden önce seçin.'**
  String bulkPersonnelUnknownRankCount(int count);

  /// No description provided for @bulkPersonnelUnreadableLines.
  ///
  /// In tr, this message translates to:
  /// **'{count} satır okunamadı ve eklenmeyecek.'**
  String bulkPersonnelUnreadableLines(int count);

  /// No description provided for @bulkPersonnelDuplicatesSkipped.
  ///
  /// In tr, this message translates to:
  /// **'{count} mükerrer satır kayıtta atlanacak.'**
  String bulkPersonnelDuplicatesSkipped(int count);

  /// No description provided for @bulkPersonnelNeedsIdentityDecision.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut kişi veya ayrı kişi seçilmeli'**
  String get bulkPersonnelNeedsIdentityDecision;

  /// No description provided for @bulkPersonnelDuplicateWillSkip.
  ///
  /// In tr, this message translates to:
  /// **'Mükerrer kayıt • Atlanacak'**
  String get bulkPersonnelDuplicateWillSkip;

  /// No description provided for @bulkPersonnelRankRequired.
  ///
  /// In tr, this message translates to:
  /// **'Rütbe seçilmeli'**
  String get bulkPersonnelRankRequired;

  /// No description provided for @bulkPersonnelRemoveTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Listeden çıkar'**
  String get bulkPersonnelRemoveTooltip;

  /// No description provided for @bulkPersonnelIdentityDecisionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Personel kimliği'**
  String get bulkPersonnelIdentityDecisionLabel;

  /// No description provided for @bulkPersonnelDecisionAuto.
  ///
  /// In tr, this message translates to:
  /// **'Karar seçin / aynı kayıt atlanır'**
  String get bulkPersonnelDecisionAuto;

  /// No description provided for @bulkPersonnelDecisionNew.
  ///
  /// In tr, this message translates to:
  /// **'Ayrı bir kişi olarak ekle'**
  String get bulkPersonnelDecisionNew;

  /// No description provided for @bulkPersonnelDecisionSkip.
  ///
  /// In tr, this message translates to:
  /// **'Bu satırı atla'**
  String get bulkPersonnelDecisionSkip;

  /// No description provided for @bulkPersonnelDecisionUpdate.
  ///
  /// In tr, this message translates to:
  /// **'Güncelle: #{id} • {rank} • {unit}{passiveSuffix}'**
  String bulkPersonnelDecisionUpdate(
      int id, String rank, String unit, String passiveSuffix);

  /// No description provided for @bulkPersonnelPassiveSuffix.
  ///
  /// In tr, this message translates to:
  /// **' • Pasif kalır'**
  String get bulkPersonnelPassiveSuffix;

  /// No description provided for @bulkPersonnelNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get bulkPersonnelNameLabel;

  /// No description provided for @bulkPersonnelRankLabel.
  ///
  /// In tr, this message translates to:
  /// **'Rütbe'**
  String get bulkPersonnelRankLabel;

  /// No description provided for @bulkPersonnelUnitLabel.
  ///
  /// In tr, this message translates to:
  /// **'Birlik'**
  String get bulkPersonnelUnitLabel;

  /// No description provided for @bulkPersonnelSquadLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tim'**
  String get bulkPersonnelSquadLabel;

  /// No description provided for @bulkPersonnelPreviewAction.
  ///
  /// In tr, this message translates to:
  /// **'ÖNİZLE'**
  String get bulkPersonnelPreviewAction;

  /// No description provided for @bulkPersonnelSavingAction.
  ///
  /// In tr, this message translates to:
  /// **'KAYDEDİLİYOR'**
  String get bulkPersonnelSavingAction;

  /// No description provided for @bulkPersonnelSaveAction.
  ///
  /// In tr, this message translates to:
  /// **'KAYDET'**
  String get bulkPersonnelSaveAction;

  /// No description provided for @commonActions.
  ///
  /// In tr, this message translates to:
  /// **'İşlemler'**
  String get commonActions;

  /// No description provided for @commonErrorWithDetails.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String commonErrorWithDetails(String error);

  /// No description provided for @squadCommanderOptionalHint.
  ///
  /// In tr, this message translates to:
  /// **'İsteğe bağlı'**
  String get squadCommanderOptionalHint;

  /// No description provided for @bulkPersonnelErrorSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Personel aktarımı kaydedilemedi: {error}'**
  String bulkPersonnelErrorSaveFailed(String error);

  /// No description provided for @transferActivitiesNoOtherActivities.
  ///
  /// In tr, this message translates to:
  /// **'{date} tarihinde başka faaliyet kartı bulunamadı.'**
  String transferActivitiesNoOtherActivities(String date);

  /// No description provided for @transferSquadAllAlreadyPresent.
  ///
  /// In tr, this message translates to:
  /// **'Tüm personel zaten hedef faaliyette mevcut, taşıma yapılmadı.'**
  String get transferSquadAllAlreadyPresent;

  /// No description provided for @activityArchiveOrderSaveFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sıralama kaydedilemedi.'**
  String get activityArchiveOrderSaveFailed;

  /// No description provided for @activityArchiveOrderResetFailed.
  ///
  /// In tr, this message translates to:
  /// **'Sıralama sıfırlanamadı.'**
  String get activityArchiveOrderResetFailed;

  /// No description provided for @activityArchiveDayActivityCount.
  ///
  /// In tr, this message translates to:
  /// **'{day} • {count} faaliyet'**
  String activityArchiveDayActivityCount(String day, int count);

  /// No description provided for @activityArchiveExportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{date} • {count} Faaliyet{squadText}'**
  String activityArchiveExportSubtitle(
      String date, int count, String squadText);

  /// No description provided for @rosterSelectedCardsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kart eklenmedi.'**
  String get rosterSelectedCardsEmpty;

  /// No description provided for @rosterSelectedCardsRemoveTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Çıktıdan çıkar'**
  String get rosterSelectedCardsRemoveTooltip;

  /// No description provided for @collapsibleSquadCardWarningCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} uyarı'**
  String collapsibleSquadCardWarningCount(int count);

  /// No description provided for @archiveHeaderControlCenter.
  ///
  /// In tr, this message translates to:
  /// **'KONTROL MERKEZİ'**
  String get archiveHeaderControlCenter;

  /// No description provided for @archiveHeaderSquadArchive.
  ///
  /// In tr, this message translates to:
  /// **'TİM ARŞİVİ'**
  String get archiveHeaderSquadArchive;

  /// No description provided for @archiveHeaderRecordCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} Kayıt'**
  String archiveHeaderRecordCount(int count);

  /// No description provided for @archiveHeaderPendingCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} Bekliyor'**
  String archiveHeaderPendingCount(int count);

  /// No description provided for @archiveHeaderExportPrint.
  ///
  /// In tr, this message translates to:
  /// **'Dışa Aktar / Yazdır'**
  String get archiveHeaderExportPrint;

  /// No description provided for @archiveExportSheetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dışa Aktar ve Yazdır'**
  String get archiveExportSheetTitle;

  /// No description provided for @archiveExportSheetTimeRangeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Saat Aralığı (İsteğe Bağlı)'**
  String get archiveExportSheetTimeRangeLabel;

  /// No description provided for @archiveExportSheetTimeRangeHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: 06.00-08.00 veya 20.00-08.00'**
  String get archiveExportSheetTimeRangeHint;

  /// No description provided for @archiveExportSheetTimeRangeNote.
  ///
  /// In tr, this message translates to:
  /// **'Saat girmek istemiyorsanız boş bırakıp doğrudan aşağıdaki seçeneklerden birine basabilirsiniz.'**
  String get archiveExportSheetTimeRangeNote;

  /// No description provided for @archiveExportExcelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Excel Olarak Aktar (.xlsx)'**
  String get archiveExportExcelTitle;

  /// No description provided for @archiveExportExcelSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap tabloları ve dijital arşiv için'**
  String get archiveExportExcelSubtitle;

  /// No description provided for @archiveExportPdfTitle.
  ///
  /// In tr, this message translates to:
  /// **'PDF Belgesi Paylaş'**
  String get archiveExportPdfTitle;

  /// No description provided for @archiveExportPdfSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Askeri formatta PDF oluşturur ve paylaşır'**
  String get archiveExportPdfSubtitle;

  /// No description provided for @archiveExportPrintTitle.
  ///
  /// In tr, this message translates to:
  /// **'Doğrudan Yazdır'**
  String get archiveExportPrintTitle;

  /// No description provided for @archiveExportPrintSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı yazıcıdan doğrudan çıktı alır'**
  String get archiveExportPrintSubtitle;

  /// No description provided for @archiveExportTextTitle.
  ///
  /// In tr, this message translates to:
  /// **'Metin Listesi Paylaş'**
  String get archiveExportTextTitle;

  /// No description provided for @archiveExportTextSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'WhatsApp/SMS için hizalı metin çıktısı'**
  String get archiveExportTextSubtitle;

  /// No description provided for @archivePreviousDayTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Önceki gün'**
  String get archivePreviousDayTooltip;

  /// No description provided for @archiveNextDayTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki gün'**
  String get archiveNextDayTooltip;

  /// No description provided for @archiveActivityCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} faaliyet'**
  String archiveActivityCount(int count);

  /// No description provided for @personnelPickerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personel Seç'**
  String get personnelPickerTitle;

  /// No description provided for @personnelPickerSearchHintSingle.
  ///
  /// In tr, this message translates to:
  /// **'İsim, soyisim veya rütbe ara'**
  String get personnelPickerSearchHintSingle;

  /// No description provided for @personnelPickerSearchHintMulti.
  ///
  /// In tr, this message translates to:
  /// **'İsim, rütbe veya tim ara'**
  String get personnelPickerSearchHintMulti;

  /// No description provided for @personnelPickerAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get personnelPickerAll;

  /// No description provided for @personnelPickerSuggestedMatch.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen Eşleşme'**
  String get personnelPickerSuggestedMatch;

  /// No description provided for @personnelPickerSelectedPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen Personel'**
  String get personnelPickerSelectedPersonnel;

  /// No description provided for @personnelPickerRecent.
  ///
  /// In tr, this message translates to:
  /// **'Son Seçilenler'**
  String get personnelPickerRecent;

  /// No description provided for @personnelPickerUnassignedTeam.
  ///
  /// In tr, this message translates to:
  /// **'Tim Dışı'**
  String get personnelPickerUnassignedTeam;

  /// No description provided for @personnelPickerUnknownTeam.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen Tim'**
  String get personnelPickerUnknownTeam;

  /// No description provided for @personnelPickerTeamMemberCount.
  ///
  /// In tr, this message translates to:
  /// **'{teamName} — {count} kişi'**
  String personnelPickerTeamMemberCount(String teamName, int count);

  /// No description provided for @personnelPickerSelectedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} kişi seçili'**
  String personnelPickerSelectedCount(int count);

  /// No description provided for @personnelPickerNoMorePersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Eklenebilecek personel kalmadı.'**
  String get personnelPickerNoMorePersonnel;

  /// No description provided for @personnelPickerRegisteredWithReason.
  ///
  /// In tr, this message translates to:
  /// **'{teamName} • Kayıtlı: {reason}'**
  String personnelPickerRegisteredWithReason(String teamName, String reason);

  /// No description provided for @personnelPickerNotFoundTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aramanızla eşleşen personel bulunamadı.'**
  String get personnelPickerNotFoundTitle;

  /// No description provided for @personnelPickerNotFoundSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni bir kayıt gerekiyorsa Personel Yönetimi ekranını kullanın.'**
  String get personnelPickerNotFoundSubtitle;

  /// No description provided for @activityExistingDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Aynı faaliyet zaten var'**
  String get activityExistingDialogTitle;

  /// No description provided for @activityExistingDialogFound.
  ///
  /// In tr, this message translates to:
  /// **'“{activityName}” adlı {count} kayıt bulundu.'**
  String activityExistingDialogFound(String activityName, int count);

  /// No description provided for @activityExistingDialogToUpdate.
  ///
  /// In tr, this message translates to:
  /// **'Güncellenecek faaliyet'**
  String get activityExistingDialogToUpdate;

  /// No description provided for @activityExistingDialogFoundDate.
  ///
  /// In tr, this message translates to:
  /// **'{date} tarihinde “{activityName}” adlı {count} kayıt bulundu.'**
  String activityExistingDialogFoundDate(
      String date, String activityName, int count);

  /// No description provided for @activityExistingDialogNewPersonnelToAdd.
  ///
  /// In tr, this message translates to:
  /// **'{count} yeni personel eklenecek'**
  String activityExistingDialogNewPersonnelToAdd(int count);

  /// No description provided for @activityExistingDialogAlreadyRegistered.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel zaten kayıtlı'**
  String activityExistingDialogAlreadyRegistered(int count);

  /// No description provided for @activityExistingDialogDifferentPersonnelCountNote.
  ///
  /// In tr, this message translates to:
  /// **'{count} personelin görev/not bilgisi farklı'**
  String activityExistingDialogDifferentPersonnelCountNote(int count);

  /// No description provided for @activityExistingDialogDifferentDutyNote.
  ///
  /// In tr, this message translates to:
  /// **'görev/not bilgisi farklı'**
  String get activityExistingDialogDifferentDutyNote;

  /// No description provided for @activityExistingDialogUpdateDifferent.
  ///
  /// In tr, this message translates to:
  /// **'Farklı görev/not bilgilerini güncelle'**
  String get activityExistingDialogUpdateDifferent;

  /// No description provided for @activityExistingDialogKeepIfUnselected.
  ///
  /// In tr, this message translates to:
  /// **'Seçilmezse mevcut bilgiler korunur.'**
  String get activityExistingDialogKeepIfUnselected;

  /// No description provided for @activityExistingDialogCreateNew.
  ///
  /// In tr, this message translates to:
  /// **'YENİ FAALİYET OLUŞTUR'**
  String get activityExistingDialogCreateNew;

  /// No description provided for @activityExistingDialogAddToExisting.
  ///
  /// In tr, this message translates to:
  /// **'MEVCUDA EKLE'**
  String get activityExistingDialogAddToExisting;

  /// No description provided for @activityBatchDutyResetDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Görevler sıfırlansın mı?'**
  String get activityBatchDutyResetDialogTitle;

  /// No description provided for @activityBatchDutyResetDialogDesc.
  ///
  /// In tr, this message translates to:
  /// **'{squadName} timindeki tüm görev seçimleri kaldırılacak.'**
  String activityBatchDutyResetDialogDesc(String squadName);

  /// No description provided for @activityBatchDutyAssignTitle.
  ///
  /// In tr, this message translates to:
  /// **'Toplu görev ata'**
  String get activityBatchDutyAssignTitle;

  /// No description provided for @activityBatchDutyAssignSquadDesc.
  ///
  /// In tr, this message translates to:
  /// **'{squadName} timindeki tüm personele uygulanır'**
  String activityBatchDutyAssignSquadDesc(String squadName);

  /// No description provided for @activityBatchDutyResetActionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Görevleri sıfırla'**
  String get activityBatchDutyResetActionTitle;

  /// No description provided for @activityBatchDutyResetActionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Timdeki tüm görev seçimlerini kaldır'**
  String get activityBatchDutyResetActionSubtitle;

  /// No description provided for @activityBatchDutyAssignSquadTooltip.
  ///
  /// In tr, this message translates to:
  /// **'{squadName} timine toplu görev ata'**
  String activityBatchDutyAssignSquadTooltip(String squadName);

  /// No description provided for @activityPersonnelCountBadge.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel'**
  String activityPersonnelCountBadge(int count);

  /// No description provided for @activitySelectedPersonnelEditHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir personele farklı görev veya not vermek için adına dokunun.'**
  String get activitySelectedPersonnelEditHint;

  /// No description provided for @activityPersonnelSelectionEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Aramaya uygun personel bulunamadı.'**
  String get activityPersonnelSelectionEmpty;

  /// No description provided for @activityFormSelectActivityPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet seçin'**
  String get activityFormSelectActivityPrompt;

  /// No description provided for @activityFormSelectActivityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet Seç'**
  String get activityFormSelectActivityTitle;

  /// No description provided for @activityFormActivityNameTitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet adı'**
  String get activityFormActivityNameTitle;

  /// No description provided for @activityFormActivityNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet adını yazın'**
  String get activityFormActivityNameHint;

  /// No description provided for @activityFormActivityNameRequired.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet adı zorunludur'**
  String get activityFormActivityNameRequired;

  /// No description provided for @activityFormSelectedBadge.
  ///
  /// In tr, this message translates to:
  /// **'Seçilenler ({count})'**
  String activityFormSelectedBadge(int count);

  /// No description provided for @activityFormEditDutyLabel.
  ///
  /// In tr, this message translates to:
  /// **'{name} görevini düzenle'**
  String activityFormEditDutyLabel(String name);

  /// No description provided for @activityFormRemoveSelectionTooltip.
  ///
  /// In tr, this message translates to:
  /// **'{name} seçimini kaldır'**
  String activityFormRemoveSelectionTooltip(String name);

  /// No description provided for @activityAssignmentPreviewError.
  ///
  /// In tr, this message translates to:
  /// **'Görevlendirme kaydedilemedi: {error}'**
  String activityAssignmentPreviewError(String error);

  /// No description provided for @activityAssignmentPreviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Görevlendirme Önizlemesi'**
  String get activityAssignmentPreviewTitle;

  /// No description provided for @activityAssignmentBackAndEdit.
  ///
  /// In tr, this message translates to:
  /// **'Geri dön ve düzelt'**
  String get activityAssignmentBackAndEdit;

  /// No description provided for @activityAssignmentConflictWarning.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel mevcut görev, izin veya rapor çakışması nedeniyle kaydedilmeyecek.'**
  String activityAssignmentConflictWarning(int count);

  /// No description provided for @activityAssignmentTeamSummary.
  ///
  /// In tr, this message translates to:
  /// **'{teamName} • {count} kişi • {summary}'**
  String activityAssignmentTeamSummary(
      String teamName, int count, String summary);

  /// No description provided for @activityAssignmentPendingApproval.
  ///
  /// In tr, this message translates to:
  /// **'Admin onayı bekleyecek'**
  String get activityAssignmentPendingApproval;

  /// No description provided for @activityFormTitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet Çizelgesi'**
  String get activityFormTitle;

  /// No description provided for @activityFormBulkPasteTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Toplu metin yapıştır'**
  String get activityFormBulkPasteTooltip;

  /// No description provided for @activityFormSquadError.
  ///
  /// In tr, this message translates to:
  /// **'Tim verileri alınamadı: {error}'**
  String activityFormSquadError(String error);

  /// No description provided for @activityFormPersonnelLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Personel yüklenemedi: {error}'**
  String activityFormPersonnelLoadError(String error);

  /// No description provided for @activityFormNoSquadWarning.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir time atanmadınız. Lütfen yöneticinizle iletişime geçin.'**
  String get activityFormNoSquadWarning;

  /// No description provided for @activityFormNoPersonnelWarning.
  ///
  /// In tr, this message translates to:
  /// **'Görevlendirilecek kayıtlı personel bulunamadı.'**
  String get activityFormNoPersonnelWarning;

  /// No description provided for @activityFormPreviewAndSave.
  ///
  /// In tr, this message translates to:
  /// **'Önizle ve Kaydet ({count})'**
  String activityFormPreviewAndSave(int count);

  /// No description provided for @activityFormPreviewAndSend.
  ///
  /// In tr, this message translates to:
  /// **'Önizle ve Onaya Gönder ({count})'**
  String activityFormPreviewAndSend(int count);

  /// No description provided for @activityFormDiscardChangesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Değişiklikler silinsin mi?'**
  String get activityFormDiscardChangesTitle;

  /// No description provided for @activityFormDiscardChangesMessage.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğiniz personel ve faaliyet bilgileri kaydedilmedi.'**
  String get activityFormDiscardChangesMessage;

  /// No description provided for @activityFormCompletePersonnelSelection.
  ///
  /// In tr, this message translates to:
  /// **'Personel seçimini tamamlayın'**
  String get activityFormCompletePersonnelSelection;

  /// No description provided for @activityFormCompleteActivityInfo.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet bilgilerini tamamlayın'**
  String get activityFormCompleteActivityInfo;

  /// No description provided for @activityFormSelectAtLeastOneDuty.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen en az bir personel için görev seçiniz.'**
  String get activityFormSelectAtLeastOneDuty;

  /// No description provided for @activityFormPreviewPrepareError.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme hazırlanamadı: {error}'**
  String activityFormPreviewPrepareError(String error);

  /// No description provided for @activityFormSavedAdminPending.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet Kaydedildi! Admin onayına gönderildi.'**
  String get activityFormSavedAdminPending;

  /// No description provided for @activityFormSavedConflictChecked.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet Çizelgesi Kaydedildi & Çakışma Denetimi Yapıldı!'**
  String get activityFormSavedConflictChecked;

  /// No description provided for @activityFormMergedSummary.
  ///
  /// In tr, this message translates to:
  /// **'{updated} güncellendi, {skipped} kayıt korundu.'**
  String activityFormMergedSummary(int updated, int skipped);

  /// No description provided for @activityFormBulkImportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Toplu metin içe aktar'**
  String get activityFormBulkImportTitle;

  /// No description provided for @activityFormBulkImportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Birden fazla faaliyet ve personel kaydını panodaki metinden hızlıca oluşturun.'**
  String get activityFormBulkImportSubtitle;

  /// No description provided for @activityFormBulkImportPasteAction.
  ///
  /// In tr, this message translates to:
  /// **'Metni yapıştır'**
  String get activityFormBulkImportPasteAction;

  /// No description provided for @rosterOutputRecordsChangedError.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlar değişti. Önizlemeyi yeniden açın.'**
  String get rosterOutputRecordsChangedError;

  /// No description provided for @rosterOutputSignedOutput.
  ///
  /// In tr, this message translates to:
  /// **'{date} • {count} personel • İmzalı çıktı'**
  String rosterOutputSignedOutput(String date, int count);

  /// No description provided for @rosterOutputSelectedCardsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen Kartlar'**
  String get rosterOutputSelectedCardsTitle;

  /// No description provided for @rosterOutputPreviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Birleşik Çıktı Önizlemesi'**
  String get rosterOutputPreviewTitle;

  /// No description provided for @rosterOutputPreviewDeduplicationNote.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel • Her kişi bir kez • Toplam baskıda gösterilmez'**
  String rosterOutputPreviewDeduplicationNote(int count);

  /// No description provided for @rosterOutputPreparing.
  ///
  /// In tr, this message translates to:
  /// **'Çıktı hazırlanıyor…'**
  String get rosterOutputPreparing;

  /// No description provided for @rosterOutputGetOutput.
  ///
  /// In tr, this message translates to:
  /// **'Çıktı Al'**
  String get rosterOutputGetOutput;

  /// No description provided for @rosterOutputExportError.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktarılamadı: {error}'**
  String rosterOutputExportError(String error);

  /// No description provided for @activityFormSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Personel veya birlik ara...'**
  String get activityFormSearchHint;

  /// No description provided for @activityFormFilterAll.
  ///
  /// In tr, this message translates to:
  /// **'Hepsi'**
  String get activityFormFilterAll;

  /// No description provided for @activityFormFilterUnassigned.
  ///
  /// In tr, this message translates to:
  /// **'Atanmayanlar'**
  String get activityFormFilterUnassigned;

  /// No description provided for @activityNoteAdded.
  ///
  /// In tr, this message translates to:
  /// **'Not eklendi'**
  String get activityNoteAdded;

  /// No description provided for @activitySquadCountBadge.
  ///
  /// In tr, this message translates to:
  /// **'{count} tim'**
  String activitySquadCountBadge(int count);

  /// No description provided for @activityAssignmentWillNotBeSaved.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilmeyecek'**
  String get activityAssignmentWillNotBeSaved;

  /// No description provided for @activityAssignmentWillBeSaved.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilecek'**
  String get activityAssignmentWillBeSaved;

  /// No description provided for @activityFormContinueButton.
  ///
  /// In tr, this message translates to:
  /// **'Devam ({count})'**
  String activityFormContinueButton(int count);

  /// No description provided for @commonExit.
  ///
  /// In tr, this message translates to:
  /// **'Çık'**
  String get commonExit;

  /// No description provided for @commonContinueRunning.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get commonContinueRunning;

  /// No description provided for @activityFormMergeDetailedSummary.
  ///
  /// In tr, this message translates to:
  /// **'{added} personel eklendi, {updated} güncellendi, {skipped} kayıt korundu.'**
  String activityFormMergeDetailedSummary(int added, int updated, int skipped);

  /// No description provided for @authSessionFailed.
  ///
  /// In tr, this message translates to:
  /// **'Oturum doğrulanamadı.'**
  String get authSessionFailed;

  /// No description provided for @authTeamPermissionExpired.
  ///
  /// In tr, this message translates to:
  /// **'Tim yetkiniz sona erdi.'**
  String get authTeamPermissionExpired;

  /// No description provided for @activityDetailUnknownSquadHistory.
  ///
  /// In tr, this message translates to:
  /// **'Tim geçmişi bilinmiyor'**
  String get activityDetailUnknownSquadHistory;

  /// No description provided for @activityDetailAddPersonnelButton.
  ///
  /// In tr, this message translates to:
  /// **'+ Personel Ekle'**
  String get activityDetailAddPersonnelButton;

  /// No description provided for @activityDetailAddSingleOption.
  ///
  /// In tr, this message translates to:
  /// **'Personel Seçerek Ekle'**
  String get activityDetailAddSingleOption;

  /// No description provided for @activityDetailAddSingleOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir veya birden fazla personel seçin'**
  String get activityDetailAddSingleOptionSubtitle;

  /// No description provided for @activityDetailAddBulkOption.
  ///
  /// In tr, this message translates to:
  /// **'Metinden Toplu Ekle'**
  String get activityDetailAddBulkOption;

  /// No description provided for @activityDetailAddBulkOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Listeyi tam önizleme ve hata kontrolüyle aktar'**
  String get activityDetailAddBulkOptionSubtitle;

  /// No description provided for @activityDetailAddImageOption.
  ///
  /// In tr, this message translates to:
  /// **'Görselden Toplu Ekle'**
  String get activityDetailAddImageOption;

  /// No description provided for @activityDetailAddImageOptionSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Personel listesini görselden okuyup bu karta ekle'**
  String get activityDetailAddImageOptionSubtitle;

  /// No description provided for @activityDetailImagePlatformWarning.
  ///
  /// In tr, this message translates to:
  /// **'Görselden aktarım Android ve iOS cihazlarda kullanılabilir.'**
  String get activityDetailImagePlatformWarning;

  /// No description provided for @activityDetailImageReadError.
  ///
  /// In tr, this message translates to:
  /// **'Görsel okunamadı: {error}'**
  String activityDetailImageReadError(String error);

  /// No description provided for @activityDetailPersonnelAdded.
  ///
  /// In tr, this message translates to:
  /// **'Personel faaliyete eklendi.'**
  String get activityDetailPersonnelAdded;

  /// No description provided for @activityDetailPersonnelAddedAdminPending.
  ///
  /// In tr, this message translates to:
  /// **'Personel eklendi, Admin onayına gönderildi.'**
  String get activityDetailPersonnelAddedAdminPending;

  /// No description provided for @activityDetailExportTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Bu Faaliyeti Dışa Aktar'**
  String get activityDetailExportTooltip;

  /// No description provided for @activityDetailExportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dışa Aktar'**
  String get activityDetailExportTitle;

  /// No description provided for @activityDetailExportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyet listesini paylaş veya yazdır'**
  String get activityDetailExportSubtitle;

  /// No description provided for @activityDetailCombineOutputTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kartları Birleştir ve Çıktı Al'**
  String get activityDetailCombineOutputTitle;

  /// No description provided for @activityDetailCombineOutputSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Aynı gün ve önceki gün kartlarını imzalı çıktıda birleştir'**
  String get activityDetailCombineOutputSubtitle;

  /// No description provided for @activityDetailExportExcel.
  ///
  /// In tr, this message translates to:
  /// **'Excel’e aktar'**
  String get activityDetailExportExcel;

  /// No description provided for @activityDetailExportExcelSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hesap tablosu olarak paylaş'**
  String get activityDetailExportExcelSubtitle;

  /// No description provided for @activityDetailExportPdf.
  ///
  /// In tr, this message translates to:
  /// **'PDF / Yazdır'**
  String get activityDetailExportPdf;

  /// No description provided for @activityDetailExportPdfSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'PDF oluştur veya doğrudan yazdır'**
  String get activityDetailExportPdfSubtitle;

  /// No description provided for @activityDetailExportText.
  ///
  /// In tr, this message translates to:
  /// **'Metin olarak paylaş'**
  String get activityDetailExportText;

  /// No description provided for @activityDetailExportTextSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Mesajlaşma uygulamaları için hazırla'**
  String get activityDetailExportTextSubtitle;

  /// No description provided for @activityDetailNoPersonnelAssigned.
  ///
  /// In tr, this message translates to:
  /// **'Bu faaliyette görevlendirilmiş personel bulunmuyor.'**
  String get activityDetailNoPersonnelAssigned;

  /// No description provided for @activityDetailNoPrintablePersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen timlerde yazdırılabilir personel bulunamadı.'**
  String get activityDetailNoPrintablePersonnel;

  /// No description provided for @activityDetailOutSquad.
  ///
  /// In tr, this message translates to:
  /// **'Tim Dışı'**
  String get activityDetailOutSquad;

  /// No description provided for @activityDetailUnknownSquad.
  ///
  /// In tr, this message translates to:
  /// **'Bilinmeyen Tim'**
  String get activityDetailUnknownSquad;

  /// No description provided for @activityDetailDeleteSquadsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Timleri Faaliyetten Sil'**
  String get activityDetailDeleteSquadsTitle;

  /// No description provided for @activityDetailDeleteSquadsConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{teamNames} timlerindeki {count} personel bu faaliyetten çıkarılacaktır. Emin misiniz?'**
  String activityDetailDeleteSquadsConfirm(String teamNames, int count);

  /// No description provided for @activityDetailDeleteSquadsAction.
  ///
  /// In tr, this message translates to:
  /// **'TİMLERİ SİL'**
  String get activityDetailDeleteSquadsAction;

  /// No description provided for @activityDetailPersonnelRemovedCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} personel faaliyetten çıkarıldı.'**
  String activityDetailPersonnelRemovedCount(int count);

  /// No description provided for @activityDetailDutyPending.
  ///
  /// In tr, this message translates to:
  /// **'{duty} • BEKLİYOR'**
  String activityDetailDutyPending(String duty);

  /// No description provided for @activityDetailNoteLabel.
  ///
  /// In tr, this message translates to:
  /// **'Not: {note}'**
  String activityDetailNoteLabel(String note);

  /// No description provided for @commonApproveTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get commonApproveTooltip;

  /// No description provided for @commonRejectTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get commonRejectTooltip;

  /// No description provided for @activityDetailApproveBlocked.
  ///
  /// In tr, this message translates to:
  /// **'Onaylanamadı: {reason}'**
  String activityDetailApproveBlocked(String reason);

  /// No description provided for @commonActionsTooltip.
  ///
  /// In tr, this message translates to:
  /// **'İşlemler'**
  String get commonActionsTooltip;

  /// No description provided for @activityDetailDutyUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Görev güncellendi.'**
  String get activityDetailDutyUpdated;

  /// No description provided for @activityDetailDutyUpdatePending.
  ///
  /// In tr, this message translates to:
  /// **'Görev değişikliği kaydedildi, Admin onayına gönderildi.'**
  String get activityDetailDutyUpdatePending;

  /// No description provided for @activityDetailRemovePersonnelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Personeli Görevden Çıkar'**
  String get activityDetailRemovePersonnelTitle;

  /// No description provided for @activityDetailRemovePersonnelConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{name} adlı personel {activity} faaliyetinden çıkarılacaktır. Emin misiniz?'**
  String activityDetailRemovePersonnelConfirm(String name, String activity);

  /// No description provided for @activityDetailRemoveAction.
  ///
  /// In tr, this message translates to:
  /// **'ÇIKAR'**
  String get activityDetailRemoveAction;

  /// No description provided for @activityDetailPersonnelRemoved.
  ///
  /// In tr, this message translates to:
  /// **'{name} faaliyetten çıkarıldı.'**
  String activityDetailPersonnelRemoved(String name);

  /// No description provided for @activityDetailAssignmentActions.
  ///
  /// In tr, this message translates to:
  /// **'Atama İşlemleri'**
  String get activityDetailAssignmentActions;

  /// No description provided for @activityDetailEditDutySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Görev veya izin bilgisini değiştir'**
  String get activityDetailEditDutySubtitle;

  /// No description provided for @activityDetailTransferCard.
  ///
  /// In tr, this message translates to:
  /// **'Başka karta taşı'**
  String get activityDetailTransferCard;

  /// No description provided for @activityDetailTransferCardSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Personeli farklı faaliyete aktar'**
  String get activityDetailTransferCardSubtitle;

  /// No description provided for @activityDetailRemoveFromActivity.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyetten çıkar'**
  String get activityDetailRemoveFromActivity;

  /// No description provided for @activityDetailRemoveFromActivitySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Personelin bu atamasını kaldır'**
  String get activityDetailRemoveFromActivitySubtitle;

  /// No description provided for @activitySelectedSquadCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} tim seçildi'**
  String activitySelectedSquadCount(int count);

  /// No description provided for @commonPrint.
  ///
  /// In tr, this message translates to:
  /// **'Yazdır'**
  String get commonPrint;

  /// No description provided for @activityDeleteSelectedSquadsTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen timleri faaliyetten sil'**
  String get activityDeleteSelectedSquadsTooltip;

  /// No description provided for @activitySquadCardTitle.
  ///
  /// In tr, this message translates to:
  /// **'{teamName} — {count} kişi'**
  String activitySquadCardTitle(String teamName, int count);

  /// No description provided for @activityTransferSquadTooltip.
  ///
  /// In tr, this message translates to:
  /// **'{teamName} timini başka karta taşı'**
  String activityTransferSquadTooltip(String teamName);

  /// No description provided for @activityDutyPickerTitleForPerson.
  ///
  /// In tr, this message translates to:
  /// **'{name} için görev'**
  String activityDutyPickerTitleForPerson(String name);

  /// No description provided for @bulkImportKeepAuditTextTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ham metni yerel denetim kaydında sakla'**
  String get bulkImportKeepAuditTextTitle;

  /// No description provided for @bulkImportSaveActivitiesButton.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyetleri Kaydet'**
  String get bulkImportSaveActivitiesButton;

  /// No description provided for @bulkImportOptionalReviewsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} isteğe bağlı inceleme'**
  String bulkImportOptionalReviewsCount(int count);

  /// No description provided for @bulkImportConfirmAllAction.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Onayla'**
  String get bulkImportConfirmAllAction;

  /// No description provided for @bulkImportConfirmAction.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get bulkImportConfirmAction;

  /// No description provided for @bulkImportNoCardsHint.
  ///
  /// In tr, this message translates to:
  /// **'Yapıştır adımına dönüp mesajı yapıştırın.'**
  String get bulkImportNoCardsHint;

  /// No description provided for @bulkImportProceedToSaveStep.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetme Adımına Geç'**
  String get bulkImportProceedToSaveStep;

  /// No description provided for @bulkImportSaveSummarySub.
  ///
  /// In tr, this message translates to:
  /// **'{blockCount} blok -> {dayCount} günlük faaliyet'**
  String bulkImportSaveSummarySub(int blockCount, int dayCount);

  /// No description provided for @bulkImportSaveWithCardCount.
  ///
  /// In tr, this message translates to:
  /// **'Faaliyetleri Kaydet ({count} Kart)'**
  String bulkImportSaveWithCardCount(int count);

  /// No description provided for @bulkImportActionsRemainingToSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydetmek için {count} işlem kaldı'**
  String bulkImportActionsRemainingToSave(int count);

  /// No description provided for @bulkImportUnresolvedIssuesError.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen önce çözülmemiş kart sorunlarını (tarih, tim veya görev türü) tamamlayın.'**
  String get bulkImportUnresolvedIssuesError;

  /// No description provided for @bulkImportClearPreviewConfirmDesc.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulan tüm kartlar ve ayrıştırma uyarıları kaldırılacak.'**
  String get bulkImportClearPreviewConfirmDesc;

  /// No description provided for @bulkImportPersonnelAddedAndMatched.
  ///
  /// In tr, this message translates to:
  /// **'{rank} {name} veritabanına ({timName}) eklendi ve eşleştirildi.'**
  String bulkImportPersonnelAddedAndMatched(
      String rank, String name, String timName);

  /// No description provided for @bulkImportIssueEmptyBlock.
  ///
  /// In tr, this message translates to:
  /// **'Kart #{number}: Personel bulunamadı.'**
  String bulkImportIssueEmptyBlock(int number);

  /// No description provided for @bulkImportIssueMissingDate.
  ///
  /// In tr, this message translates to:
  /// **'Kart #{number}: Bu personel grubu için geçerli bir tarih bulunamadı.'**
  String bulkImportIssueMissingDate(int number);

  /// No description provided for @bulkImportIssueUnknownTeam.
  ///
  /// In tr, this message translates to:
  /// **'Kart #{number}: Takım/tim adı belirtilmedi.'**
  String bulkImportIssueUnknownTeam(int number);

  /// No description provided for @bulkImportIssueUnknownActivity.
  ///
  /// In tr, this message translates to:
  /// **'Kart #{number}: Görev türü tanınamadı.'**
  String bulkImportIssueUnknownActivity(int number);

  /// No description provided for @bulkImportIssueUnmatchedPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'{rank} {name} için personel seçimi yapılmadı.'**
  String bulkImportIssueUnmatchedPersonnel(String rank, String name);

  /// No description provided for @bulkImportMobileSummaryReady.
  ///
  /// In tr, this message translates to:
  /// **'{cardCount} kart • {personnelCount} personel • Hazır'**
  String bulkImportMobileSummaryReady(int cardCount, int personnelCount);

  /// No description provided for @bulkImportMobileSummaryErrors.
  ///
  /// In tr, this message translates to:
  /// **'{cardCount} kart • {personnelCount} personel • {count} hata'**
  String bulkImportMobileSummaryErrors(
      int cardCount, int personnelCount, int count);

  /// No description provided for @bulkImportMobileSummaryReviews.
  ///
  /// In tr, this message translates to:
  /// **'{cardCount} kart • {personnelCount} personel • {count} inceleme'**
  String bulkImportMobileSummaryReviews(
      int cardCount, int personnelCount, int count);

  /// No description provided for @cancelSelectionTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Seçimi İptal Et'**
  String get cancelSelectionTooltip;

  /// No description provided for @bulkImportRegisteredTeamLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kayitli tim: {team}'**
  String bulkImportRegisteredTeamLabel(String team);

  /// No description provided for @bulkImportListTeamLabel.
  ///
  /// In tr, this message translates to:
  /// **'Liste timi: {team}'**
  String bulkImportListTeamLabel(String team);

  /// No description provided for @bulkImportNoTeamSpecified.
  ///
  /// In tr, this message translates to:
  /// **'Tim belirtilmedi'**
  String get bulkImportNoTeamSpecified;

  /// No description provided for @commonChange.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get commonChange;

  /// No description provided for @bulkImportSelectPersonnelButton.
  ///
  /// In tr, this message translates to:
  /// **'Personel Seç'**
  String get bulkImportSelectPersonnelButton;

  /// No description provided for @bulkImportAddToTeamAction.
  ///
  /// In tr, this message translates to:
  /// **'+ {team} Ekle'**
  String bulkImportAddToTeamAction(String team);

  /// No description provided for @bulkImportAliasDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'\'{alias}\' ➔ \'{target}\' öğrenilmiş takma ad eşleşmesi silinsin mi?'**
  String bulkImportAliasDeleteConfirm(String alias, String target);

  /// No description provided for @bulkImportAliasDeletedMessage.
  ///
  /// In tr, this message translates to:
  /// **'\'{alias}\' hafızadan silindi.'**
  String bulkImportAliasDeletedMessage(String alias);

  /// No description provided for @bulkImportLearnedAliasCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} Öğrenilmiş İsim Takma Adı'**
  String bulkImportLearnedAliasCount(int count);

  /// No description provided for @bulkImportSearchAliasShortHint.
  ///
  /// In tr, this message translates to:
  /// **'Yazım veya personel adı ara'**
  String get bulkImportSearchAliasShortHint;

  /// No description provided for @bulkImportSearchAliasHint.
  ///
  /// In tr, this message translates to:
  /// **'Metindeki yazım veya personel adıyla ara...'**
  String get bulkImportSearchAliasHint;

  /// No description provided for @bulkImportNoMatchingAliasFound.
  ///
  /// In tr, this message translates to:
  /// **'Aramanıza uygun takma ad bulunamadı.'**
  String get bulkImportNoMatchingAliasFound;

  /// No description provided for @bulkImportNoLearnedAliasesDesc.
  ///
  /// In tr, this message translates to:
  /// **'Henüz öğrenilmiş bir takma ad bulunmuyor.\nToplu aktarımlarda onayladığınız eşleşmeler otomatik hafızaya alınır.'**
  String get bulkImportNoLearnedAliasesDesc;

  /// No description provided for @bulkImportMatchedPersonnelLabel.
  ///
  /// In tr, this message translates to:
  /// **'Eşleştiği personel'**
  String get bulkImportMatchedPersonnelLabel;

  /// No description provided for @bulkImportUnassignedPersonnelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Timsiz / Diğer Personeller'**
  String get bulkImportUnassignedPersonnelTitle;

  /// No description provided for @bulkImportCustomTeamOption.
  ///
  /// In tr, this message translates to:
  /// **'DİĞER (Elle Yaz...)'**
  String get bulkImportCustomTeamOption;

  /// No description provided for @authPasswordPolicyMinLength.
  ///
  /// In tr, this message translates to:
  /// **'Parola en az {count} karakter olmalıdır.'**
  String authPasswordPolicyMinLength(int count);

  /// No description provided for @dashboardImageReadError.
  ///
  /// In tr, this message translates to:
  /// **'Görsel okunamadı: {error}'**
  String dashboardImageReadError(String error);

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @commonUser.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get commonUser;

  /// No description provided for @authUnsupportedRole.
  ///
  /// In tr, this message translates to:
  /// **'Desteklenmeyen kullanıcı rolü: {role}'**
  String authUnsupportedRole(String role);

  /// No description provided for @commonSessionNotVerified.
  ///
  /// In tr, this message translates to:
  /// **'Oturum doğrulanamadı.'**
  String get commonSessionNotVerified;

  /// No description provided for @conflictConflictingRecord.
  ///
  /// In tr, this message translates to:
  /// **'Çakışan kayıt'**
  String get conflictConflictingRecord;

  /// No description provided for @conflictAnotherActivityExists.
  ///
  /// In tr, this message translates to:
  /// **'Bu tarihte başka bir faaliyet kaydı bulunuyor.'**
  String get conflictAnotherActivityExists;

  /// No description provided for @matrixSelectDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih Seçin'**
  String get matrixSelectDate;

  /// No description provided for @matrixEmpty.
  ///
  /// In tr, this message translates to:
  /// **', boş'**
  String get matrixEmpty;

  /// No description provided for @matrixDayNumber.
  ///
  /// In tr, this message translates to:
  /// **'{day}. gün{status}'**
  String matrixDayNumber(int day, String status);

  /// No description provided for @matrixSearchPersonnelResult.
  ///
  /// In tr, this message translates to:
  /// **'“{query}” · {visible}/{total} kişi'**
  String matrixSearchPersonnelResult(String query, int visible, int total);

  /// No description provided for @matrixNoAuthorizedRecordsForExport.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktarılacak yetkili kayıt bulunamadı.'**
  String get matrixNoAuthorizedRecordsForExport;

  /// No description provided for @matrixTeamDutyCalendarTitle.
  ///
  /// In tr, this message translates to:
  /// **'{team} Görev Takvimi'**
  String matrixTeamDutyCalendarTitle(String team);

  /// No description provided for @matrixMonthlyOperationalView.
  ///
  /// In tr, this message translates to:
  /// **'{year} / {month} Ayı Operasyonel Görünüm'**
  String matrixMonthlyOperationalView(int year, String month);

  /// No description provided for @matrixMonthlyDailyDistribution.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Günlük Dağılım'**
  String get matrixMonthlyDailyDistribution;

  /// No description provided for @matrixClickDayForDetails.
  ///
  /// In tr, this message translates to:
  /// **'Detaylar için güne tıklayın'**
  String get matrixClickDayForDetails;

  /// No description provided for @matrixDutyDay.
  ///
  /// In tr, this message translates to:
  /// **'Görevli Gün'**
  String get matrixDutyDay;

  /// No description provided for @matrixDutyDayCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} Gün'**
  String matrixDutyDayCount(int count);

  /// No description provided for @matrixActivePersonnelCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} Kişi'**
  String matrixActivePersonnelCount(int count);

  /// No description provided for @matrixPersonnelDayRatio.
  ///
  /// In tr, this message translates to:
  /// **'Personel-gün oranı'**
  String get matrixPersonnelDayRatio;

  /// No description provided for @matrixUnknownSquadAssignmentsNotice.
  ///
  /// In tr, this message translates to:
  /// **'Bu ay tim geçmişi bilinmeyen {count} eski atama var; tim hesabına katılmadı.'**
  String matrixUnknownSquadAssignmentsNotice(int count);

  /// No description provided for @matrixNoDutyPersonnelOnDate.
  ///
  /// In tr, this message translates to:
  /// **'Bu tarihte görevli personel kaydı bulunmuyor.'**
  String get matrixNoDutyPersonnelOnDate;

  /// No description provided for @matrixApprovedStatus.
  ///
  /// In tr, this message translates to:
  /// **'Onaylı'**
  String get matrixApprovedStatus;

  /// No description provided for @matrixContinuingFromPreviousDay.
  ///
  /// In tr, this message translates to:
  /// **'Önceki günden devam eden {count} kişi'**
  String matrixContinuingFromPreviousDay(int count);

  /// No description provided for @temgundrapOutputPrepareError.
  ///
  /// In tr, this message translates to:
  /// **'Çıktı hazırlanamadı: {error}'**
  String temgundrapOutputPrepareError(String error);

  /// No description provided for @temgundrapPreviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'TEMGÜNDRAP Önizleme'**
  String get temgundrapPreviewTitle;

  /// No description provided for @temgundrapSharePdfAction.
  ///
  /// In tr, this message translates to:
  /// **'PDF Paylaş'**
  String get temgundrapSharePdfAction;

  /// No description provided for @temgundrapIssuingUnit.
  ///
  /// In tr, this message translates to:
  /// **'Çıkaran birlik'**
  String get temgundrapIssuingUnit;

  /// No description provided for @temgundrapDescription.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get temgundrapDescription;

  /// No description provided for @temgundrapSelectCommanderFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce operasyon komutanını seçin.'**
  String get temgundrapSelectCommanderFirst;

  /// No description provided for @temgundrapSelectNumberToUse.
  ///
  /// In tr, this message translates to:
  /// **'Kullanılacak numarayı seçin'**
  String get temgundrapSelectNumberToUse;

  /// No description provided for @temgundrapNoValidPhoneFound.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen kişide geçerli cep telefonu bulunamadı.'**
  String get temgundrapNoValidPhoneFound;

  /// No description provided for @temgundrapPhoneMatchedWithPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Telefon personelle eşleştirildi.'**
  String get temgundrapPhoneMatchedWithPersonnel;

  /// No description provided for @temgundrapOperationCommander.
  ///
  /// In tr, this message translates to:
  /// **'Operasyon Komutanı'**
  String get temgundrapOperationCommander;

  /// No description provided for @temgundrapSelectFromPersonnelList.
  ///
  /// In tr, this message translates to:
  /// **'Personel listesinden seçin'**
  String get temgundrapSelectFromPersonnelList;

  /// No description provided for @temgundrapPhoneToUse.
  ///
  /// In tr, this message translates to:
  /// **'Kullanılacak telefon'**
  String get temgundrapPhoneToUse;

  /// No description provided for @temgundrapPhoneAutoMatchesNextTime.
  ///
  /// In tr, this message translates to:
  /// **'Bir kez eşleştirilince sonraki seçimlerde otomatik gelir.'**
  String get temgundrapPhoneAutoMatchesNextTime;

  /// No description provided for @temgundrapSelectFromContacts.
  ///
  /// In tr, this message translates to:
  /// **'Telefon rehberinden seç'**
  String get temgundrapSelectFromContacts;

  /// No description provided for @temgundrapEnterValidPhone.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir cep telefonu girin.'**
  String get temgundrapEnterValidPhone;

  /// No description provided for @temgundrapOperationArea.
  ///
  /// In tr, this message translates to:
  /// **'Operasyon bölgesi'**
  String get temgundrapOperationArea;

  /// No description provided for @temgundrapOperationAreaRequired.
  ///
  /// In tr, this message translates to:
  /// **'Operasyon bölgesi zorunludur.'**
  String get temgundrapOperationAreaRequired;

  /// No description provided for @temgundrapEnterCustomOperationArea.
  ///
  /// In tr, this message translates to:
  /// **'Özel operasyon bölgesini girin.'**
  String get temgundrapEnterCustomOperationArea;

  /// No description provided for @temgundrapTypeOperationArea.
  ///
  /// In tr, this message translates to:
  /// **'Operasyon bölgesini yazın'**
  String get temgundrapTypeOperationArea;

  /// No description provided for @temgundrapEditOperationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Operasyonu Düzenle'**
  String get temgundrapEditOperationTitle;

  /// No description provided for @temgundrapOperationPurpose.
  ///
  /// In tr, this message translates to:
  /// **'Operasyon maksadı'**
  String get temgundrapOperationPurpose;

  /// No description provided for @temgundrapPersonnelListLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Personel listesi yüklenemedi: {error}'**
  String temgundrapPersonnelListLoadError(String error);

  /// No description provided for @temgundrapUpdateOperationAction.
  ///
  /// In tr, this message translates to:
  /// **'OPERASYONU GÜNCELLE'**
  String get temgundrapUpdateOperationAction;

  /// No description provided for @temgundrapStartTime.
  ///
  /// In tr, this message translates to:
  /// **'Başlama zamanı'**
  String get temgundrapStartTime;

  /// No description provided for @temgundrapEndTime.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş zamanı'**
  String get temgundrapEndTime;

  /// No description provided for @temgundrapVehicles.
  ///
  /// In tr, this message translates to:
  /// **'Araçlar'**
  String get temgundrapVehicles;

  /// No description provided for @temgundrapVehicleModel.
  ///
  /// In tr, this message translates to:
  /// **'Araç modeli'**
  String get temgundrapVehicleModel;

  /// No description provided for @temgundrapRegisteredPlates.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı plakalar:'**
  String get temgundrapRegisteredPlates;

  /// No description provided for @rosterOutputCommanderTeamRevoked.
  ///
  /// In tr, this message translates to:
  /// **'Tim yetkiniz sona erdi.'**
  String get rosterOutputCommanderTeamRevoked;

  /// No description provided for @statusApproved.
  ///
  /// In tr, this message translates to:
  /// **'Onaylı'**
  String get statusApproved;

  /// No description provided for @statusPending.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen'**
  String get statusPending;

  /// No description provided for @statusRejected.
  ///
  /// In tr, this message translates to:
  /// **'Reddedilen'**
  String get statusRejected;

  /// No description provided for @personnelUnitHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: 1\'inci Bl.'**
  String get personnelUnitHint;

  /// No description provided for @temgundrapAddOperationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Operasyon Ekle'**
  String get temgundrapAddOperationTitle;

  /// No description provided for @temgundrapAddOperationAction.
  ///
  /// In tr, this message translates to:
  /// **'OPERASYONU EKLE'**
  String get temgundrapAddOperationAction;

  /// No description provided for @commonUpdate.
  ///
  /// In tr, this message translates to:
  /// **'GÜNCELLE'**
  String get commonUpdate;

  /// No description provided for @confirmDiscardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Değişikliklerden vazgeçilsin mi?'**
  String get confirmDiscardTitle;

  /// No description provided for @confirmDiscardContent.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedilmeyen bilgiler kaybolacak.'**
  String get confirmDiscardContent;

  /// No description provided for @confirmDiscardContinue.
  ///
  /// In tr, this message translates to:
  /// **'DÜZENLEMEYE DEVAM ET'**
  String get confirmDiscardContinue;

  /// No description provided for @confirmDiscardExit.
  ///
  /// In tr, this message translates to:
  /// **'VAZGEÇ VE ÇIK'**
  String get confirmDiscardExit;

  /// No description provided for @authSessionUnverified.
  ///
  /// In tr, this message translates to:
  /// **'Oturum doğrulanamadı.'**
  String get authSessionUnverified;

  /// No description provided for @temgundrapUnitHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: KOVANCILAR J.KOMD.ÖZ.HRK.TB.K.LIĞI'**
  String get temgundrapUnitHint;

  /// No description provided for @temgundrapApproverNameHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: İhsan DAĞLI'**
  String get temgundrapApproverNameHint;

  /// No description provided for @temgundrapApproverRankHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: J.Ütğm.'**
  String get temgundrapApproverRankHint;

  /// No description provided for @temgundrapApproverDutyHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Tb. K. V.'**
  String get temgundrapApproverDutyHint;

  /// No description provided for @backupDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tam yedekleme ve geri yükleme'**
  String get backupDialogTitle;

  /// No description provided for @backupDialogSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bulut gerekmez; dosya sizin seçtiğiniz yerde kalır.'**
  String get backupDialogSubtitle;

  /// No description provided for @backupTabExport.
  ///
  /// In tr, this message translates to:
  /// **'Yedekle'**
  String get backupTabExport;

  /// No description provided for @backupTabImport.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükle'**
  String get backupTabImport;

  /// No description provided for @backupWhatsIncludedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedekte neler var?'**
  String get backupWhatsIncludedTitle;

  /// No description provided for @backupWhatsIncludedText.
  ///
  /// In tr, this message translates to:
  /// **'İsimler, timler, kullanıcılar, telefonlar, görevler, aylık matris, faaliyet arşivi, raporlar, takma adlar, toplu aktarım geçmişi ve TEMGÜNDRAP belgeleri.'**
  String get backupWhatsIncludedText;

  /// No description provided for @backupKeepSafeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama silinse de koruyun'**
  String get backupKeepSafeTitle;

  /// No description provided for @backupKeepSafeText.
  ///
  /// In tr, this message translates to:
  /// **'Açılan kaydet ekranından İndirilenler gibi cihazın yerel bir klasörünü seçin. Uygulamanın kendi klasörüne bırakmayın.'**
  String get backupKeepSafeText;

  /// No description provided for @backupSecurityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dosyayı güvenli tutun'**
  String get backupSecurityTitle;

  /// No description provided for @backupSecurityText.
  ///
  /// In tr, this message translates to:
  /// **'Yedek kişisel bilgiler içerir. Yalnızca güvenilir bir yerel klasörde saklayın ve başkalarıyla paylaşmayın.'**
  String get backupSecurityText;

  /// No description provided for @backupLegacyDateText.
  ///
  /// In tr, this message translates to:
  /// **'Eski yedek'**
  String get backupLegacyDateText;

  /// No description provided for @backupLegacyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Eski personel yedeği'**
  String get backupLegacyTitle;

  /// No description provided for @backupVerifiedFullTitle.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanmış tam yedek'**
  String get backupVerifiedFullTitle;

  /// No description provided for @backupPreviewStats.
  ///
  /// In tr, this message translates to:
  /// **'{date} • {personnel} personel • {activity} faaliyet • {assignment} görev kaydı • {temgundrap} TEMGÜNDRAP'**
  String backupPreviewStats(
      String date, int personnel, int activity, int assignment, int temgundrap);

  /// No description provided for @backupLegacyRestoreSuccess.
  ///
  /// In tr, this message translates to:
  /// **'{count} yeni personel eski yedekten aktarıldı.'**
  String backupLegacyRestoreSuccess(int count);

  /// No description provided for @backupConfirmOverwriteContent.
  ///
  /// In tr, this message translates to:
  /// **'Tam geri yükleme mevcut personel, görev, matris ve TEMGÜNDRAP kayıtlarının yerine yedekteki verileri koyar. Bu işlem geri alınamaz.'**
  String get backupConfirmOverwriteContent;

  /// No description provided for @bulkImportCriticalErrorsCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} kritik hata'**
  String bulkImportCriticalErrorsCount(int count);

  /// No description provided for @bulkImportLinePrefix.
  ///
  /// In tr, this message translates to:
  /// **'Satır {line}: '**
  String bulkImportLinePrefix(int line);

  /// No description provided for @bulkImportEmptySummaryHint.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen aşağıda vurgulanan kartlardaki eksik personelleri eşleştirin, tekrarları düzeltin veya boş kartları silin.'**
  String get bulkImportEmptySummaryHint;

  /// No description provided for @bulkParseEmptyInput.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıştırılacak metin boş.'**
  String get bulkParseEmptyInput;

  /// No description provided for @bulkParseMissingDate.
  ///
  /// In tr, this message translates to:
  /// **'Bu personel grubu için geçerli bir tarih bulunamadı.'**
  String get bulkParseMissingDate;

  /// No description provided for @bulkParseUnknownTeam.
  ///
  /// In tr, this message translates to:
  /// **'Takım/tim bilgisi tanınamadı.'**
  String get bulkParseUnknownTeam;

  /// No description provided for @bulkParseUnknownActivity.
  ///
  /// In tr, this message translates to:
  /// **'Görev türü tanınamadı.'**
  String get bulkParseUnknownActivity;

  /// No description provided for @bulkParseInvalidTime.
  ///
  /// In tr, this message translates to:
  /// **'Saat aralığı geçerli değil.'**
  String get bulkParseInvalidTime;

  /// No description provided for @bulkParseInvalidDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih geçerli değil.'**
  String get bulkParseInvalidDate;

  /// No description provided for @bulkParseInvalidPersonnel.
  ///
  /// In tr, this message translates to:
  /// **'Personel satırı çözümlenemedi.'**
  String get bulkParseInvalidPersonnel;

  /// No description provided for @bulkParseUnknownRank.
  ///
  /// In tr, this message translates to:
  /// **'Rütbe tanınamadı; ham personel adı korundu.'**
  String get bulkParseUnknownRank;

  /// No description provided for @bulkParseNoBlocks.
  ///
  /// In tr, this message translates to:
  /// **'Metinde aktarılabilecek personel bloğu bulunamadı.'**
  String get bulkParseNoBlocks;

  /// No description provided for @commonFix.
  ///
  /// In tr, this message translates to:
  /// **'Düzelt'**
  String get commonFix;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
