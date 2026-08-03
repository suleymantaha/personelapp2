/// Belirli bir timin aylık görev özeti ve analitik verileri DTO'su.
class TeamDutySummaryDto {
  final int timId;
  final String timAdi;
  final String? timKomutaniAdi;
  final int toplamGorevGunSayisi;
  final double toplamGorevSaati;
  final int aktifPersonelSayisi;
  final double ortalamaYukYuzdesi; // % yorgunluk/yoğunluk indeksi
  final Map<String, int> gorevTuruDagilimi; // {'GÜLÜŞKÜR': 12, 'HAZIR KITA': 5}

  const TeamDutySummaryDto({
    required this.timId,
    required this.timAdi,
    this.timKomutaniAdi,
    required this.toplamGorevGunSayisi,
    required this.toplamGorevSaati,
    required this.aktifPersonelSayisi,
    required this.ortalamaYukYuzdesi,
    required this.gorevTuruDagilimi,
  });
}

/// Timin aylık takviminde tek bir güne ait görev detaylarını temsil eden DTO.
class TeamDayDutyDto {
  final String tarih; // YYYY-AA-DD
  final int gunIndex; // 1 - 31
  final String gorevKodu; // 'Gş', 'H.K', 'Nbt'
  final String gorevTamAdi; // 'GÜLÜŞKÜR'
  final List<String> gorevliPersonelAdlari;
  final bool isYogunGorev;

  const TeamDayDutyDto({
    required this.tarih,
    required this.gunIndex,
    required this.gorevKodu,
    required this.gorevTamAdi,
    required this.gorevliPersonelAdlari,
    this.isYogunGorev = false,
  });
}

/// Tim Görev Takvimi Ekranı / Modalı için Veri Bağlamı (Context) DTO'su.
class TeamMonthlyCalendarDto {
  final int timId;
  final String timAdi;
  final int yil;
  final int ay;
  final List<TeamDayDutyDto> gunler;
  final TeamDutySummaryDto ozet;

  const TeamMonthlyCalendarDto({
    required this.timId,
    required this.timAdi,
    required this.yil,
    required this.ay,
    required this.gunler,
    required this.ozet,
  });
}
