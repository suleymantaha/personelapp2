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
  /// **'KAYDEDİLİYOR…'**
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
  /// **'Faaliyet Kartını Düzenle'**
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
