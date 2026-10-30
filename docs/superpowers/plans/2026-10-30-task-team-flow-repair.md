# Task team flow repair implementation plan

> **For agentic workers:** Use superpowers:executing-plans; independent test ownership and final read-only review.

**Goal:** Snapshot esaslı arşiv ve güvenli, tutarlı tarih değiştirme.
**Architecture:** Kart görünürlüğü doğrudan assignment snapshotını kullanır;
tarih değişikliği aynı resolver ile kontrol edilir; belirsiz/farklı sonuçlarda
mevcut tim seçimi diyaloğu açık override üretir; tüm yazım transaction içindedir.
**Tech Stack:** Flutter, Dart, Drift, Riverpod; mevcut sürümler.
**Spec:** ../specs/2026-10-30-task-team-flow-repair-design.md

## Constraints

İlgisiz dirty matrix/METİ dosyaları ve önceki future-task-team değişiklikleri korunur.
Yeni dependency, schema, canlı veri kullanımı veya yayın yok.

## İş paketleri

- [x] Root: tarih değiştirme hatasını sentetik testle RED olarak yakala.
- [x] Worker: yalnız activity_archive_team_filter_test.dart; 4 RED, 1 PASS.
- [x] Root: arşiv kartını snapshot filtresine geçir.
- [x] Root: preview confirmation IDs, admin actor ve stale tarih koruması;
  eşleşen timi koruyan, açık seçimleri atomik uygulayan tarih yazımı.
- [x] Root: UI tarih değişiminde tim seçimi ve iptal/hata yönetimi;
  worker aynı tim/iptal/açık seçim için 3 widget testini doğruladı.
- [x] Dar testler; format; lib/test analyze temiz; tam suite 924 PASS, 1 SKIP.
- [x] Bağımsız inceleme; sabit 7 source hash'i eşleşti; son diff/status temiz kapsamlı.

## Sonuç

Reviewer'ın same-person delete/readd stale adayı testle doğrulandı; sadece ID
kümesi yerine immutable full-row snapshot karşılaştırmasıyla kapatıldı.
Same-ID note değişikliği de reddedilir. Commit/push/APK/yayın yapılmadı.

## Review focus

Geçmiş kayıt filtreleri tim transferi/soft-delete sonrası sabit;
güncel timden geçmişe sessiz doldurma yok; iptal/başka görev etkisi yok;
stale tarih ve yeni eklenen atama reddi; admin dışı yazım yok.
