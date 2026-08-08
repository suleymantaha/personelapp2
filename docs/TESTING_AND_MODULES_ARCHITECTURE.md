# PersonelApp2 - Widget Etkileşim ve Veri Akış Test Mimarisi

Bu doküman, uygulamadaki gerçek modüller (`personnel`, `matrix`, `temgundrap`, `dashboard`, `auth`, `activity`) arasındaki widget-widget etkileşimi, state paylaşımı ve veri akış test mimarisini açıklamaktadır.

---

## 🧪 Gerçek Modüller Arası Etkileşim Testleri (Widget Data Flow Suite)

Uygulamanın ana bileşenlerinin birbiriyle veri değiş tokuşunu ve arayüz etkileşimini doğrulayan test yapılandırması:

1. **Personel Yönetimi (`test/features/personnel/personnel_widget_interaction_test.dart`)**:
   - `PersonnelManagementScreen` <-> `PersonnelFormDialog` <-> `AppDatabase` etkileşimi.
   - Personel arama filtresi, veri yazma, form diyaloğu açma ve veri akış doğrulaması.

2. **Nöbet Matrisi (`test/features/matrix/matrix_widget_interaction_test.dart`)**:
   - `MonthlyMatrixScreen` <-> `TeamDutyCalendarModal` <-> `MatrixRepository` etkileşimi.
   - Takvim gün hücre etkileşimi, ay değiştirme ve nöbetçi atama veri değiş tokuşu.

3. **Temgundrap Raporu (`test/features/temgundrap/temgundrap_widget_interaction_test.dart`)**:
   - `TemgundrapScreen` <-> `TemgundrapCommanderPicker` <-> `TemgundrapVehicleEditor` etkileşimi.
   - Taslak rapor güncellemeleri, komutan seçimi ve araç listesi veri akışı.

4. **Ana Sayfa & Modül Yönlendirmeleri (`test/features/dashboard/dashboard_widget_interaction_test.dart`)**:
   - `DashboardScreen` <-> `DashboardGridLayout` <-> `DashboardMenuCard` etkileşimi.
   - Modül kartları ve menü navigasyon tıklama etkileşimleri.

5. **Giriş & Kimlik Doğrulama (`test/features/auth/login_widget_interaction_test.dart`)**:
   - `LoginScreen` <-> `PasswordHasher` <-> `SessionStorage` etkileşimi.
   - Form veri girişi, şifre doğrulama ve oturum başlatma akışı.

6. **Gerçek Cihaz Uçtan Uca Entegrasyon Testi (`integration_test/app_widget_interaction_user_journey_test.dart`)**:
   - Flutter Driver / Integration Test ortamında tüm gerçek modüllerin uçtan uca etkileşim testi.
