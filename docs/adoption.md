# Kurulum ve projeler arasında kullanım

## Proje başına kurulum

1. Mevcut AGENTS.md/README.md ve kullanıcı değişikliklerini incele.
2. Ortak .agents/ içeriğini bir kopya veya inceleme dalında yerleştir.
3. AGENTS.md kurallarını mevcut kurallarla anlamlı biçimde birleştir; dosyayı körlemesine ezme.
4. PROJECT.md ve CHECKS.md dosyalarını o projeye göre doldur.
5. Gereken görev şablonunu kullan; önceki projeden geçmiş görev veya başarı raporu taşıma.
6. Bağlantıları ve gerçek proje kontrollerini doğrula. Sonucu kapsamıyla raporla.

Ortak kit aynı kalır; bir proje farklı framework kullandığında kuralları yeniden yazmak gerekmez.
Mevcut CI veya klasör düzeni sırf bu pakete uymak için yeniden tasarlanmaz.

## Bilgisayar genelinde otomatik kullanım

Taşınabilir kaynak paket ayrı tutulur. Bu kurulu kopya Codex global AGENTS.md üzerinden etkinleştirildi; [GLOBAL.md](../GLOBAL.md) kullanılır.
Otomatik kullanım için kullanılan asistanın desteklediği global talimat konumu ve okuma davranışı
ayrıca doğrulanmalı; mevcut kişisel kurallarla birleştirilmelidir.
Farklı asistanların aynı rol dosyasını kendiliğinden ajan kaydı saydığı varsayılmaz.
Global talimatın içinde projeye özgü ürün hedefi, geçmiş görev veya teknoloji seçimi tutulmaz.

## Yükseltme

Ortak kit sürümünü .agents/framework.json içindeki kit_version ile takip et.
Yeni sürümü önce diff ve kontrolle incele; yerel proje bağlamını ve görev kayıtlarını koru.
Teknolojiye veya ürüne özel ek kural gerekiyorsa PROJECT.md üzerinden ilgili belgeye bağla.
