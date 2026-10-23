---
description: Bu kiti bir hedef projeye alıcı (adopt) kurar. Mevcut AGENTS.md ve README.md'yi ezmeden çakışan kuralları listeler, birleşik taslak önerir ve onay sonrası kopyalar.
subagent: false
---

Bu ajan kitini bir hedef projeye alıcı (adopt) olarak kur.

HEDEF PROJE:
$ARGUMENTS

ADIM 1 — MEVCUT TALİMATLARI OKU, EZME.
Hedefte `AGENTS.md`, varsa `CLAUDE.md`, `CONTRIBUTING.md`, `.cursorrules`, `README.md` ve benzeri talimat dosyalarını oku. Mevcut mimari kurallarını, DI ve state yapısını, isimlendirmeyi, klasör düzenini not et.
Hiçbirini silme, taşıma veya körlemesine değiştirme. Orkestra kuralları mevcut mimariyle harmanlanır; mimari hafıza korunur. Bir hedefin `AGENTS.md` dosyasını kullanıcı onayı olmadan yazma.

ADIM 2 — ÇAKIŞMALARI LİSTELE.
| Çakışma | Mevcut kural | Orkestra kuralı | Önerilen harman |
Gerçek çakışma yoksa tabloyu boş bırak ve bunu açıkça yaz.
Kararsız kalırsan en az yetki ilkesini seç, gerekçeni yaz ve kullanıcıdan onay iste.

ADIM 3 — BİRLEŞİK TASLAK ÖNER, HEMEN YAZMA.
Tek parça bir `AGENTS.md` taslağını kullanıcıya göster. İçinde orkestra akışı, Tier seçimi, kanıt kapısı, devre kesici, tek yazarlı sahiplik, mimari hafıza koruma ve motor seviyesi izin notu, hedef projeye uyarlanmış hâliyle bulunsun.
Kullanıcı onayını almadan hiçbir dosyayı yazma.

ADIM 4 — KOPYALANACAK DOSYALAR.
- `.opencode/opencode.jsonc`
- `.opencode/agents/orchestra-coordinator.md`
- `.opencode/agents/orchestra-researcher.md`
- `.opencode/agents/orchestra-worker.md`
- `.opencode/agents/orchestra-verifier.md`
- `.opencode/agents/orchestra-security-auditor.md`
- `.opencode/skills/umaf/SKILL.md`
- `.opencode/commands/tier.md`
- `.opencode/commands/verify.md`
- `.opencode/commands/selftest.md`
- `.opencode/commands/adopt.md`

`.agents/` klasörünü kopyalama. Depoyu kirletir ve iki kaynak oluşturur. Gerekirse tek bir `AGENTS.md` bloğu ile `umaf` becerisi yeterlidir; `.agents/` yalnız bu kitin kaynak ve derin referansı olarak kalır.

ADIM 4b — `default_agent` KARARINI AYRI AL.
`.opencode/opencode.jsonc` içindeki `default_agent` satırı, hedef projede **her oturumun varsayılan ajanını değiştirir**. Bu, hedefin günlük çalışma biçimini etkiler ve geri alınabilir olsa da karar kullanıcıya aittir. Kopyalamadan önce şu üç seçeneği sun ve **onay al**:
1. `default_agent` ekle → hedef tam orkestrasyonla çalışır.
2. `default_agent` ekleme → hedefin mevcut davranışı korunur, kurallar elle seçilen ajanla uygulanır.
3. Ekle, ama geri alınabilirliği belirt → oturum başında ajan seçilebilir.
Seçtiğin seçeneği ve gerekçesini hedefin `PROJECT.md` dosyasına yaz. Kararı kendin verme.

ADIM 5 — HEDEFE ÖZGÜ ALANLARI DOLDUR.
`PROJECT.md`: proje adı, kullanıcı ve ihtiyaç, hedef ve kabul ölçütü, mevcut durum, teknoloji ve gerçek sürüm kanıtı, repo ve mimari düzen, sahiplik, kapsam dışı, veri ve güven sınırları, ortamlar.
`CHECKS.md`: yalnız GERÇEKTEN çalışan komutlar. Her komut için cwd, araç sürümü ve beklenen çıktı yaz. Olmayan bir script'i yazma; o kontrolün karşılığına `NOT_RUN` koy.
Teknoloji önerisini gerçek sürüm kanıtından ayır; öneriyi kanıt gibi sunma.

ADIM 6 — DOĞRULA VE RAPORLA.
Kopyaladığın dosyaların tam listesini yaz. Hedefe göre değiştirmen gereken alan olduysa hangi dosyada hangi satırı neden değiştirdiğini belirt.
Kullanıcıya **ilk çalıştırma kontrolünü** de ver: yeni oturum açıldığında beş `orchestra-*` ajanın listede göründüğünü, `orchestra-verifier` için kaynak düzenleme izninin reddedildiğini ve `orchestra-worker` için kökteki `AGENTS.md` düzenleme izninin reddedildiğini doğrulatması gerekir. Ajanlar yapılandırma yüklenirken tanımlandığı için yeni dosyalar **oturum yeniden başlatılmadan** listeye girmez.
Doğrulamadığın kontrolü `NOT_RUN` yaz. Gerçekleştiremediğin adımı saklama; adımı ve engeli açıkça bildir.

GÜVENLİK:
Hiçbir sırrı, token'ı veya hedef projenin gizli içeriğini kopyalama. Hedef projeye yazmadan önce kullanıcı talimat dosyalarını değiştirmediğini doğrula.