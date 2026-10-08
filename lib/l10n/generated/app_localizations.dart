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
  /// **'Vazgeç'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get commonClose;

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
  /// **'Giriş'**
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
