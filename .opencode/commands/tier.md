---
description: Girilen işi beş risk sorusuyla sınıflandırıp Tier 1/2/3 kademesini ve gerekçesini çıkarır; kod yazmaz.
subagent: false
---

Aşağıdaki işi sınıflandır. Kod yazma, dosya değiştirme, komut çalıştırma, git işlemi yapma.

GİRDİ İŞİ:
$ARGUMENTS

Şu beş soruyu sırayla sor ve her birine tek satırda "evet / hayır / bilinmiyor" cevabı ver:
1. Kullanıcı verisi, sır veya dosya silinebilir, açığa çıkabilir ya da yanlış kişiye verilebilir mi?
2. Para, hak, kota veya hesap yetkisi değişiyor mu?
3. API veya şema tüketicileri, dosya veya belge ayrıştırıcıları, migration, asenkron iş durumu etkileniyor mi?
4. Yanlışlık üretimde geri alınamaz sonuç doğurur mu?
5. Kök neden ilk bakışta belirsiz mi veya birden fazla alt sistem etkileniyor mu?

Kural:
- 1 veya 2 evet ise Tier 3.
- 3 veya 5 evet ise en az Tier 2.
- Beşi de hayır ise Tier 1.
- Bir cevap "bilinmiyor" ise riskli tarafı seç ve hangi bilgiyle netleşeceğini yaz.

ÇIKTI — şu başlıkları bu sırayla kullan:
- Tier: `native_fast` | `orchestrated_research_worker_verifier` | `full_army_with_security_audit`
- Gerekçe: hangi soru hangi cevap, hangi kademeye götürdü.
- Etkilenen alan: hangi dosya, modül, servis veya veri.
- Ajan planı: Tier 1 ise "doğrudan çöz"; Tier 2 ise "researcher → worker → verifier"; Tier 3 ise "researcher → worker → verifier + security-auditor". Her rolün neden gerektiğini tek satırla yaz.
- Görev kaydı: Tier 3 ise görev dosyası ve indeks zorunlu; Tier 1 ve Tier 2'de oturum içinde izlenir.
- Sıradaki somut adım: tek eylem.
- Kademe yükseltme tetikçisi: hangi bulgu hangi kademeye çıkarır.
- Emin olmadığın nokta: varsa yaz, yoksa bu satırı "yok" ile geç.

Kanıtsız cevap verme. Emin olmadığın yeri "bilinmiyor" olarak işaretle ve hangi ek bilgiyle netleşeceğini yaz. Çıktının sonuna yorum veya başka bölüm ekleme.