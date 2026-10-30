# Future task team implementation plan

> **For agentic workers:** Use superpowers:executing-plans to implement this single bounded task with TDD and final independent review.

**Goal:** Bugün/gelecek görevleri mevcut timle kesintisiz kaydet; belirsiz geçmişi doğrulat.
**Architecture:** Ortak ActivityRepositoryTaskTeams resolver tarih dalı değiştirilir;
confirmTaskTeams aynı resolver'ı kullanmaya devam eder, otomatik sonucu override'a çevirmez.
**Tech Stack:** Flutter 3.47.2, Dart 3.13.2, Drift 2.34.2.
**Spec:** ../specs/2026-10-30-future-task-team-design.md

## Global constraints

Mevcut kullanıcı diff'i ve arşiv korunur. Şema/dependency değişimi, commit/push/yayın yok.

## Task: Resolver ve tüketici regresyonu

- [x] Mevcut tarih koşulu, çağrı zinciri, testler ve Git durumunu incele.
- [x] Widget regresyonları: bugün, yarın, 365 gün sonrası, bilinen/bilinmeyen geçmiş.
- [x] Repository regresyonları: geçmişsiz/çelişkili geçmişli gelecek kayıt,
  snapshot korunması, açık seçim, Tim dışı ve tim komutanı yetkisi.
- [x] RED: mevcut kodda pencere açılması ve TaskTeamRequiredException gözlendi.
- [x] Bugün koşulunu geçerli ISO tarihler için bugün-ve-sonrası yap.
- [x] Format; 30 dar test PASS; değişen dosyalarda analyze temiz;
  genel analyze exit 0, mevcut output dosyalarında 14 avoid_print info;
  flutter test: 898 PASS, 1 SKIP.
- [x] Bağımsız salt okunur inceleme: bulgu yok; son diff/status kontrol edildi.

## Review focus

Geçmişe otomatik doldurma olmamalı; açık seçim öncelikli kalmalı; yetki aşılmamalı;
snapshotlar sonradan değişmemeli; otomatik önizleme kayıt anında tekrar doğrulanmalı.
