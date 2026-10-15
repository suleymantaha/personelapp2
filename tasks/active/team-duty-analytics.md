# team-duty-analytics

- Durum: IN_REVIEW; Tier 2, native, tek yazar root.
- Base: e56a9754fb13cb716dbd2f72290184f14ecba624.
- Dal: feat/team-duty-analytics; ayrı worktree, başlangıç temiz.
- Yetki: analytics, dashboard, testler, gerekirse PR; main korunur.
- Kapsam dışı: migration, veri değişikliği, veri giriş ekranı, merge/deploy.
- Plan: docs/superpowers/plans/2026-10-15-team-duty-analytics.md.
- Kanıt: build/analytics-verification/ (git ignored); final sonuçlar buraya eklenir.
- Kontroller: unit/widget/integration, flutter analyze, tam flutter test, APK, CI.
- Yerel kontrol: 645 test PASS; analyze PASS; analytics Android integration PASS; release build PASS (yerel APK imzasız).
- Bağımsız statik inceleme: P2 görev seçenekleri bulgusu giderildi; tekrar incelemede blocker yok.
- Detaylı kanıt/entegrasyon: docs/verification/team-duty-analytics.md.
- PR/CI ve tüm Android integration sonucu dış kapılardır; main merge edilmedi.
- Geri dönüş: feature dalını kullanmamak; uygulama verisi etkilenmez.
