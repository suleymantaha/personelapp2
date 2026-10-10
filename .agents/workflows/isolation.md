# Git çalışma alanı ayrımı — Universal Agent Kit 1.0

Paket sürümü: 1.0 · 10 Ekim 2026.

Worktree aynı deponun farklı çalışma dizinlerini sağlar. Ortak Git metaverisi, işletim sistemi, ağ, dosya izinleri ve sırlar paylaşılabilir. Bu yöntem güvenlik sandbox'ı veya çakışmasız merge garantisi değildir.

## 1. Başlangıç envanteri

Gerçek repo yolunda git status --short, git branch --show-current, git rev-parse HEAD ve git worktree list ile durumu oku. Var olan kullanıcı değişikliğini kaydet. Kullanıcı ağacını temizlemek için otomatik stash, reset veya toplu stage yapma.

Native ortamın izole checkout özelliği varsa onu kullan; yoksa worktree uygundur. Salt doküman veya küçük tek yazarlı işte gereksiz Git depo kurma.

## 2. İşçi alanı

Aşağıdaki örnek Bash içindir. Yollar örnektir; mevcut hedef yokluğu ve doğru repo kontrol edilmeden çalıştırılmaz. Kaynak repo dışındaki görev alanı tercih edilir. İçeride .worktrees kullanılacaksa repo politikasına göre ignore kontrolü gerekir.

~~~bash
repo_dir='/absolute/path/to/repo'
worker_dir='/absolute/path/to/task-worktrees/job-001-worker'
base_revision=$(git -C "$repo_dir" rev-parse HEAD)
git -C "$repo_dir" worktree add -b task/job-001 "$worker_dir" "$base_revision"
~~~

İşçi yalnız worker_dir içinde çalışır. Gerekli yerel kullanıcı değişiklikleri base commit'te yoksa sessizce unutulmaz; etkisi belirlenir ve görev kapsamındaki değişiklikler izlenebilir yöntemle taşınır.

Ortak lockfile/schema için tek sahip gerekir. Port, test DB adı, bucket/prefix, cache ve çıktı dizinleri görev bazında ayrılır. Secret dosyaları otomatik kopyalanmaz.

## 3. Checkpoint

İşçi yalnız kendi yollarını stage eder; git add -A ile bilinmeyen değişiklikleri toplamaz. Commit yapmadan staged diff ve isim listesini inceler. Checkpoint commit'i bağımsız denetim öncesinde mümkündür ve yayın anlamına gelmez.

Teslim: tam SHA, base SHA, değişen yollar ve test kanıtı. Commit yoksa sabit diff ve dosya hash manifesti sağlanır.

## 4. Bağımsız denetçi

İşçi worktree'sinde kullanılan dalı başka dizinde checkout etmeye çalışma. Sabit commit için ayrı detached alan aç:

~~~bash
review_dir='/absolute/path/to/task-worktrees/job-001-review'
candidate_revision=$(git -C "$worker_dir" rev-parse HEAD)
git -C "$repo_dir" worktree add --detach "$review_dir" "$candidate_revision"
git -C "$review_dir" rev-parse HEAD
~~~

Denetçi bu SHA'yı beklenen SHA ile karşılaştırır; projede tanımlı kontrolleri review_dir içinde çalıştırır. Hareket eden worker dalına test sırasında yeni commit gelmesi incelenen snapshot'ı değiştirmez.

## 5. Entegrasyon

Koordinatör yetkili entegrasyon dalını ve temiz/task-owned durumunu doğrular. Onaylanan revizyonu projenin merge/cherry-pick politikasıyla alır. Ortaya çıkan yeni SHA üzerinde ilgili entegrasyon testleri çalışır.

Main'e otomatik merge varsayılmaz. Kullanıcı merge'i zaten istemişse tekrar yetki sorma; gerekli kanıtları tamamla. Çakışmada başkasının değişikliğini seçip atma; anlamlı birleşimi incele ve test et.

## 6. Temizlik

Göreve ait süreçlerin durduğunu; kanıtın, commit/patch'in ve istenen teslimin korunduğunu doğrula. Worktree içinde kullanıcı verisi, secret veya saklanması gereken izlenmeyen dosya kalmadığından emin ol.

Yalnız doğrulanmış görev alanı için normal git worktree remove kullan. Komut kirli durum nedeniyle reddederse force veya recursive silmeye geçme; kalanları incele ve koru. Dal kaldırma projenin politikasına ve mevcut yetkiye bağlıdır; sırf görev bitti diye bütün task dalları silinmez.

Başarısız worktree hata kanıtı içerir; hata alınca silinmez. [Devre kesici](recovery.md) izlenir.

Ortak varsayılanlar [framework.json](../framework.json) dosyasındadır; üst düzey talimatlar ve ortam kapasitesi önceliklidir.
