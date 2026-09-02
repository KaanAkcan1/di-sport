# di@sport v3.1 — Günlük Gerçeklik Katmanı

Tarih: 2026-09-02 · Durum: onaylandı (kullanıcı cihaz geri bildirimi)
Temel: v3 tasarımı (2026-09-01) — burada yazmayan her şey v3'te kaldığı
gibidir.

## 0. Neden

v3 planın *iskeletini* topluyor: profildeki tek düze saatler, sabit
davranışlar, haftalık pencereler. Cihaz kullanımında eksik çıkan şey
**günün gerçeğiydi**: dün gece kaçta yatıldı, bugün nasıl hissediliyor,
antrenman ne kadar zorladı. AI'a giden belge iskeleti biliyor ama
gerçeği bilmiyor; dönen planlar bu yüzden jenerik kalıyor.

v3.1 üç şey yapar:

1. **BMI'ı görünür kılar** — vardı ama veri eksikken sessizce
   gizleniyordu ve onboarding'den bilinçli çıkarılmıştı. Kullanıcı
   kararı ters yönde: ilk girişte ve Sağlık'ta her zaman görünecek.
2. **Günlük gerçeklik girişleri** ekler: uyku saatleri (yatış/kalkış/
   kestirme), his (1-5) + belirti notu + stres işareti, adım sayısı,
   öğün atlama nedeni, seans sonu zorlanma (RPE) + ağrı notu, tarihli
   doktor teşhisi.
3. **Hepsini AI belgesine akıtır** (context.md v2.1) — "Geçen dönem"
   bölümü gün gün gerçeği anlatır, medikal bölüm teşhisleri listeler.

Tek kullanıcı / tek cihaz / çevrimdışı ilkeleri değişmez.

## 1. BMI görünürlüğü

### 1.1 Sağlık → Tahliller satırı (`_BmiRow` düzeltmesi)

- **Kilo kaynağı sıralı:** önce `body_metrics`'teki son tartı, yoksa
  profildeki `currentWeightKg`. Bugünkü davranış yalnız tartıya
  bakıyor; hiç tartılmamış kullanıcıda satır kayboluyordu.
- **Eksik veri gizlenmez, yönlendirir.** Boy yoksa satır "Boy girilmemiş
  — Profil'den ekle" der ve dokunuş Profil'i açar. Kilo yoksa aynı
  kalıp. `SizedBox.shrink()` yalnız *ikisi de* yokken kalır (yeni
  kurulumda Sağlık sekmesi BMI temposuyla açılmasın).
- Sınıf eşikleri değişmez (`BmiClass`): <18.5 zayıf · 18.5-25 normal ·
  25-30 fazla kilolu · ≥30 obez. Renk + rozet + metin birlikte
  (erişilebilirlik kuralı).

### 1.2 Onboarding'de canlı BMI

Karşılama sihirbazının boy/kilo adımında, iki alan da doluysa altta
canlı bir satır belirir: değer + sınıf rozeti + tek cümle bağlam
("Hedefe giden yolda başlangıç noktan"). v3'ün "obez damgası kötü
karşılama" kararı **geri alındı** — kullanıcı bunu açıkça istedi.
Yumuşatma damgayı silerek değil cümleyle yapılır.

## 2. Günlük uyku gerçeği

### 2.1 Ayrım: şablon ↔ gerçek

- **Şablon** (değişmez): profildeki `wakeTime`/`sleepTime` ve Günlük
  Düzen. AI planı bu iskelete kurar.
- **Gerçek** (yeni): her günün kendi yatış/kalkış/kestirme kaydı.
  AI geçen dönemi bununla okur.

### 2.2 Veri

`daily_logs`'a üç sütun (v16):

| Sütun | Tip | Anlam |
|---|---|---|
| `bedTime` | Text? `HH:mm` | *Önceki gece* yatış saati — kayıt güne aittir, gece tarihi sorulmaz |
| `wakeTimeActual` | Text? `HH:mm` | O sabah kalkış |
| `napMinutes` | Int? | Gün içi kestirme, dakika |

Süre türetilir: `bedTime → wakeTimeActual` (gece yarısını aşarsa +24h)
+ `napMinutes`. Türetilen toplam **`body_metrics.sleepHours`'a da
yazılır** — mevcut grafikler, haftalık özet ve AI'ın kilo/uyku serisi
kırılmaz.

**Tek doğruluk kuralı: son yazan kazanır.** Blok içindeki "yalnız
süre" alanına elle değer girilirse saat alanları temizlenir (saatle
çelişen bir süre iki ekranda iki gerçek yaratırdı); saatler silinirse
o günün türetilmiş `sleepHours` kaydı da silinir.

### 2.3 Arayüz

Gün ekranındaki "uyku (saat)" alanının yerine **uyku bloğu**: yatış ve
kalkış için saat seçici, kestirme için dakika alanı, **yalnız süre
girmek isteyene aynı blokta saat cinsinden tek alan** (eski davranış),
altta türetilmiş süre ("7 sa 20 dk"). Hiçbiri girilmemişse blok tek
satır kapalı durur. Gelecek günlerde gösterilmez (v3 kuralı), geçmiş
günlere girilebilir (düzeltme meşru).

Blok `sleepHours` **ölçüm tanımından bağımsızdır**: kullanıcı
`sleepHours` tanımını ölçüm listesinden silmişse blok yine görünür
(uyku artık gün kaydının parçası), yalnız türetilen değer
`body_metrics`'e yazılmaya devam eder — tanım satırı sadece ölçüm
editöründeki görünürlüğü yönetir.

## 3. Günlük his, belirti, stres

`daily_logs`'a üç sütun (v16):

| Sütun | Tip | Anlam |
|---|---|---|
| `moodScore` | Int? | 1-5; 1 çok kötü, 5 çok iyi |
| `symptoms` | Text `''` | Serbest metin — "baş ağrısı, halsizlik" |
| `stressedDay` | Bool `false` | Yoğun/stresli gün işareti |

Arayüz: gün ekranında not alanının üstünde **his bloğu** — beş yüz
(ikonlu, seçili olan dolu), "belirti" metin alanı, "yoğun gündü"
kutucuğu. Üçü de isteğe bağlı; boşken tek satır. Renk tek başına anlam
taşımaz: yüz ikonları + erişilebilirlik etiketi.

## 4. Adım sayısı

Yeni **yerleşik günlük ölçüm türü**: `MetricKinds.steps` ('steps',
'Adım', 'adım'). `metric_definitions`'a bootstrap tohumu — şema
değişikliği yok, mevcut kullanıcı tanımlı ölçüm kalıbı. Mekanizma:
`MetricKinds.labels`'a satır + `_dailyKinds`'a (gün ekranında çıksın)
+ `_wholeNumberKinds`'a (decimals 0) ekleme. Silinebilir/yeniden
adlandırılabilir; yerleşik kalıbının tüm kuralları geçerli (silinmiş
olan geri tohumlanmaz).

## 5. Öğün atlama nedeni

`daily_logs.skippedMealsJson` (Text `'{}'`, v16): `{"breakfast":
"mesai"}` — anahtar `MealKind.name`, değer serbest kısa neden.

**Sahiplik:** sütun `today`'in tablosunda ama okuma-yazma **nutrition
üstlenir** — atlama öğün-bazlı bir gerçek ve girişi Diyet ekranında.
Çapraz erişim mevcut kalıpla çözülür: `today`, atlama alanı için
**application katmanında** okuma/yazma sağlayıcıları açar, `nutrition`
bunları çağırır — repository doğrudan import edilmez ve
`EnergySource` örneğindeki yön buradaki gibi tek taraflı kalır. "Öğüne kayıt girilirse atlama
silinir" kuralını `nutrition`'ın öğün ekleme akışı uygular — atlama
işaretini koyan da kaldıran da aynı feature olur.

Arayüz: Diyet → Günlük'te plan-gerçek karşılaştırması zaten "planlı ama
boş" öğünü gösteriyor. O satıra "atlandı" eylemi eklenir: dokununca
neden çipleri (mesai · iştahsızlık · dışarıdaydım · diğer) + serbest
alan. Atlanmış öğün satırı soluk + "atlandı: mesai" alt yazısıyla
çizilir.

## 6. Seans sonu RPE + ağrı notu

`workout_sessions`'a iki sütun (v16):

| Sütun | Tip | Anlam |
|---|---|---|
| `rpe` | Int? | 1-10 zorlanma (Borg CR10 yaklaşık) |
| `painNote` | Text `''` | "hangi hareket rahatsız etti" serbest notu |

Arayüz: antrenman ekranında seans **bittiğinde** (son set işaretlenince
görünen tamamlama alanında) iki giriş: 1-10 kaydırıcı/çip dizisi +
metin alanı. Zorunlu değil; kapatılırsa null kalır. Geçmiş seansa
planlanan-yapılan ekranından da girilebilir/düzeltilebilir.

## 7. Tarihli doktor teşhisi

`MedicalFactKind`'a **`diagnosis`** eklenir; `medical_facts`'e
`factDate` (Text? `yyyy-MM-dd`, v16) — yalnız teşhis için anlamlı ama
sütun genel (ameliyat tarihi gibi ileriye açık). Medikal ekranında
teşhis bölümü: etiket ("İnsülin direnci tanısı"), tarih, not
(doktorun söyledikleri). Kısıt eşleme motoru (`restriction_match`)
teşhisleri **koşul olarak da** değerlendirir: `conditionId` doluysa
check-up motoru ve kısıt eşlemesi condition'la aynı yoldan okur.

**Condition/diagnosis ikiliği:** teşhis de öneri çiplerini kullanır
(aynı `conditionSuggestions` havuzu, `conditionId` dolar). Aynı
`conditionId`'li bir *condition* zaten varsa yeni teşhis kaydı açılmaz
— mevcut kayıt teşhise dönüştürülür (`kind = diagnosis`, tarih
eklenir): aynı gerçek iki satır olamaz ve context.md §3'te çift
listelenmez. Serbest metinli teşhiste `conditionId` null kalır; o
zaman yalnız §3'te listelenir, motorlara girmez.

## 8. context.md v2.1

Bölüm yapısı ve numaralar değişmez; içerik zenginleşir:

- **§3 Medikal:** teşhisler tarihleriyle ayrı alt liste ("### Tanılar").
  Sınır cümlesi (ilaç önerisi yasak) aynen kalır.
- **§7 Geçen dönem:** gün satırına yeni alanlar eklenir — uyku
  (yatış-kalkış + kestirme ya da yalnız süre), his (1-5), belirti,
  stres işareti, adım, atlanan öğünler nedenleriyle. Veri olmayan alan
  yazılmaz (bugünkü "belirtilmedi" kalabalığı büyütülmez).
- **§7'ye seans satırı:** yapılan antrenmanlara RPE ve ağrı notu
  iliştirilir ("Salı üst gövde · RPE 8 · 'omuz pres rahatsız etti'").
- **Görev bölümüne** tek cümle eklenir: "RPE 8+ seanslar ve ağrı
  notları yük ilerletmesinde dikkate alınmalı."

Bölüm anahtarları (`ctx.off.*`) değişmez — yeni veriler mevcut
bölümlerin içine aktığı için yeni anahtar açılmaz. Veri toplama
portlarla genişler, `ai_bridge` feature'ların yalnız domain'ini
görmeye devam eder:

- `LogSource`: gün dökümüne uyku saatleri/kestirme, his, belirti,
  stres, atlanan öğünler eklenir; ayrıca yeni **`sessions({lastDays})`**
  dökümü (tarih, süre, RPE, ağrı notu) — seans kavramı bugün hiçbir
  portta yok.
- `MedicalSource`: `MedicalFactDump`'a `kind: 'diagnosis'` değeri ve
  `factDate` alanı eklenir (teşhisler §3'ü buradan besler).
- Adım için port değişmez: `steps` bir `body_metrics` serisi ve
  `HealthSource.bodyMetrics()` onu olduğu gibi taşır; §7 gün satırına
  oradan yazılır.

Ayrıca `context_md_builder.dart` başındaki bayat "yedi bölümlü" sınıf
yorumu bu işte "dokuz bölümlü"ye düzeltilir.

## 9. Şema v16 — özet

| Tablo | Eklenen |
|---|---|
| `daily_logs` | `bedTime`, `wakeTimeActual`, `napMinutes`, `moodScore`, `symptoms`, `stressedDay`, `skippedMealsJson` |
| `workout_sessions` | `rpe`, `painNote` |
| `medical_facts` | `factDate` |

`metric_definitions`'a `steps` tohumu (şema değişikliği değil).
Tek `if (from < 16)` bloğu; eski bloklar dokunulmaz.

## 10. Kapsam dışı

- Uyku/adım verisini sensörden/sağlık platformundan otomatik çekmek
  (çevrimdışı-tek-cihaz ilkesi; elle giriş yeter).
- His/belirti için grafik ya da trend ekranı — veri önce birikecek.
- Teşhis belgesi fotoğrafından AI ile aktarım — tahlil akışının kopyası
  olurdu, istenirse v3.2.
- RPE'nin set bazına inmesi — seans bazı yeterli, set bazı giriş yükü
  antrenmanı bölüyor.

## 11. Başarı ölçütü

Kullanıcı bir haftayı gerçek veriyle doldurup "Yeni plan iste"
dediğinde `context.md` §7'de yedi günün uykusu, hisleri, adımları,
atlanan öğünleri ve seans RPE'leri gün gün okunuyor; AI'ın dönüşü bu
verilere atıf yapabiliyor. Profil ekranı açılıyor; BMI hem
onboarding'de hem Sağlık'ta görünüyor.
