# Teslim kaydı

- Kaynak commit: `0dc6ad61a1297b83380f8aef921a1a135657d270`.
- Dal: [fix/audit-hardening-apk-2026-11-01](https://github.com/suleymantaha/personelapp2/tree/fix/audit-hardening-apk-2026-11-01).
- 2026-11-01T07:20:27Z `git ls-remote` kontrolünde kaynak commit remote ile eşleşti.
- Bu kapanış kaydı ayrı docs commit'iyle aynı dala gönderilir; APK/source byte'ları değişmez.
- Yerel/uzak main hâlâ `9517d9464b702a22407be7c515e38e418bdb7032`; merge yapılmadı.
- APK: `F:/personelapp2/build/releases/Nizam-1.0.13+10328.apk`,118931171 byte.
- SHA-256: `F4219BEA03F0AD4739A8A6D11452353AB16AA898221DF7DAE527CD2970F26F8A`.
- SHA dosyası aynı konumda `.apk.sha256` uzantısıyla bulunur.
- İmzalı10327→10328, gerçek native dosya sınırı ve kayıt/ayar kontrolleri PASS.
- Kaynak/artifact bağımsız incelemesi kabul edildi; fiziksel cihaz NOT_RUN.
- Host1026 PASS/1SKIP, Android20+4 PASS, native13 PASS, root analyze PASS.
- Feature dalı push'unda workflow tetiklenmez; bu teslimde canlı CI/store/release/Drive upload yok.
- Önceden var olan untracked .playwright-cli/, .serena/, output/ korundu.

[Rapor](REPORT.md) · [Doğrulama](verification.json) · [Upgrade](upgrade-verification.json).
