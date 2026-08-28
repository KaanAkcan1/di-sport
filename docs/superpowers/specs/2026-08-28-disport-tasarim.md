# di@sport — Tasarım Dokümanı

**Tarih:** 28 Ağustos 2026
**Durum:** Onaylandı, implementasyon planına hazır

---

## 1. Amaç

Kişisel sağlık ve antrenman takip uygulaması. Bugün kâğıt üzerinde tutulan
4 haftalık çizelgenin (`kaan-eylul-2026-cizelge.pdf`) dijital karşılığı,
üstüne üç şey ekler:

1. **Egzersiz kataloğu** — evde malzemesiz kalistenik ve salon antrenmanlarının
   detaylı nasıl-yapılır bilgisi
2. **Yapay zeka köprüsü** — uygulama bağlam dosyası üretir, kullanıcı bunu
   herhangi bir AI'a verir, dönen planı uygulama içeri alır ve görselleştirir
3. **Ölçüm takibi** — kilo, vücut ölçüleri, performans ve kan tahlilleri

## 2. Kapsam

**v1 kapsamında:**
- Tek kullanıcı, tek cihaz, tamamen çevrimdışı
- Hesap yok, bulut yok, senkron yok, mağaza yayını yok
- AI entegrasyonu kopyala-yapıştır yoluyla (Seviye 0), isteğe bağlı BYOK (Seviye 1)

**v1 dışında, ama mimarinin tıkamayacağı:**
- Google ile giriş, bulut senkronu, çok cihaz
- KVKK/GDPR uyumu, App Store / Play Store yayını
- MCP connector (kullanıcının kendi AI aboneliğiyle doğrudan konuşması)

Bu ayrımın mimarideki bedeli iki şey: her tabloda `userId`/`updatedAt`/`deletedAt`
alanları, ve tüm veri erişiminin tek bir repository katmanından geçmesi.

## 3. Teknoloji

| Katman | Seçim | Gerekçe |
|---|---|---|
| Çatı | Flutter 3.44 / Dart 3.10+ | Tek kod tabanı, iOS + Android; kullanıcının öğrenme hedefi |
| Durum | Riverpod 3 | 2026 standardı, derleme-zamanı güvenlik, düşük şablon kod |
| Veritabanı | Drift (SQLite) | Tip güvenli, reaktif sorgular, göç desteği |
| Grafik | fl_chart | Kilo trendi, tahlil serileri |
| Bildirim | flutter_local_notifications + timezone | Yerel alarmlar |
| Mimari | Katmanlı: presentation → domain → data | Repository katmanı faz-2 senkronunun tek değişecek yeri |

**Geliştirme:** Windows üzerinde Android hedefiyle yapılır. macOS yalnızca
iOS derlemesi ve imzalama aşamasında gerekir.

**Bilinçli olarak kullanılmayanlar:** Mevcut `tulpar-ui` tasarım sistemi
(TypeScript, Dart'ta kullanılamaz). Flutter'ın kendi bileşenleri üzerine
proje içi bir tema katmanı kurulacak.

## 4. Modüller

Her modül tek bir sorumluluk taşır ve arayüzü üzerinden konuşur.

| Modül | Sorumluluk | Bağımlılık |
|---|---|---|
| `catalog` | Egzersiz kütüphanesi; salt-okunur çekirdek + kullanıcı tanımlı ekler | `repo` |
| `plan` | 28 günlük program; katalog id'lerine referans verir | `repo`, `catalog` |
| `log` | Günlük kayıt: işaretler, notlar, gerçekleşen setler | `repo` |
| `health` | Vücut ölçümleri, tahliller, tahlil takvimi | `repo` |
| `ai_bridge` | ÇIKIŞ: `context.md` üretimi · GİRİŞ: `plan.json` doğrulama ve içe alma | `repo`, `catalog`, `plan`, `log`, `health` |
| `reminder` | Alarm zamanlama, 7 günlük kaydırmalı pencere | `plan`, `log`, `health` |
| `repo` | Tüm veri erişimi; Drift'i sarar | — |

`ai_bridge` ve `repo`'nun ayrı olması iki faz-2 talebini karşılar: MCP eklemek
`ai_bridge`'e bir adaptör, Google girişi `repo`'nun arkasına bir katmandır.

## 5. Veri modeli

Her tabloda ortak: `id TEXT (uuid)`, `userId TEXT` (v1'de sabit `'local'`),
`updatedAt INTEGER`, `deletedAt INTEGER?` (soft delete).

### 5.1 Katalog

**`exercises`**

| Alan | Tip | Açıklama |
|---|---|---|
| `nameTr`, `nameEn` | TEXT | Hareket adı |
| `category` | ENUM | `strength` \| `cardio` \| `mobility` \| `core` |
| `location` | ENUM | `home` \| `gym` \| `both` |
| `equipment` | JSON[] | Gerekli ekipman; boş dizi = malzemesiz |
| `primaryMuscles`, `secondaryMuscles` | JSON[] | Hedef kas grupları |
| `difficulty` | INT 1-5 | |
| `summary` | TEXT | Bir-iki cümle: ne işe yarar |
| `setup` | JSON[] | Başlangıç pozisyonu, adım adım |
| `execution` | JSON[] | Hareketin kendisi, numaralı adımlar |
| `breathing` | TEXT | Nefes düzeni |
| `tempo` | TEXT | Örn. "2 sn iniş · 1 sn duraklama · 1 sn çıkış" |
| `cues` | JSON[] | Antrenman kartında görünen kısa hatırlatmalar |
| `commonMistakes` | JSON[] | `{ mistake, why, fix }` üçlüsü |
| `safety` | TEXT | Kimler yapmamalı, ne zaman durmalı |
| `regressions`, `progressions` | JSON[] | Kolay/zor varyantlar (katalog id'si veya metin) |
| `imagePath` | TEXT? | Uygulama içi görsel yolu |
| `videoQuery` | TEXT? | Harici arama için anahtar kelime |
| `isUserDefined` | BOOL | AI önerisiyle sonradan eklendi mi |

### 5.2 Plan

**`plans`** — `title`, `startDate`, `endDate`, `weeks`, `isActive`,
`goalsJson` (kcal, protein, su, haftalık salon/ev, hedef kilo kaybı),
`rulesJson` (yasak liste, serbest liste), `sourceRaw` (AI'ın ham çıktısı),
`schemaVersion`, `createdAt`.

`sourceRaw` bilinçli fazlalıktır: import sonrası sorun çıkarsa veya sonradan
"AI bunu neden böyle demiş" sorusu doğarsa orijinal elde kalır.

**`plan_days`** — `planId`, `date`, `type` (`gym` \| `home` \| `rest`),
`weekIndex`, `headline`, `dinnerSuggestion`.

**`plan_slots`** — `planDayId`, `time`, `kind`
(`meal` \| `workout` \| `sleep` \| `measurement` \| `lab` \| `other`),
`label`, `note`, `orderIndex`.

Saatler AI tarafından, kullanıcının yaşam tarzına göre belirlenir; sabit şablon
yoktur. Ölçüm ve tahlil hatırlatmaları da birer slot olarak plana gömülür.

**`plan_exercises`** — `planDayId`, `exerciseId` (FK), `orderIndex`, `sets`,
`reps`, `durationSec`, `restSec`, `intensity` (direnç/eğim), `note`.

### 5.3 Kayıt

**`daily_logs`** — `date` (UNIQUE), `checkedSlotsJson`, `workoutDone`,
`waterTargetMet`, `noAlcoholSugar`, `note`.

Sayısal ölçüm içermez; yalnızca işaretler ve serbest metin.

**`exercise_logs`** — `date`, `planExerciseId?`, `exerciseId`, `setIndex`,
`reps?`, `weightKg?`, `durationSec?`.

### 5.4 Sağlık

**`body_metrics`** — `date`, `kind`, `value`, `unit`, `note?`.
`kind`: `weight` \| `waist` \| `belly` \| `sleepHours` \| `pushupMax` \|
`plankSec` \| `treadmillIncline`.

**`lab_results`** — `date`, `marker`, `value`, `unit`, `refLow?`, `refHigh?`,
`panel`, `labName?`, `note?`, `attachmentPath?`.
`panel`: `liver` \| `metabolic` \| `vitamin` \| `thyroid` \| `lipid` \| `other`.

Tahliller vücut ölçümlerinden ayrıdır: referans aralığı, laboratuvar adı, panel
grubu ve ek dosya alanları yalnızca tahlile aittir; tek tabloda birleştirilseydi
satırların yarısı boş kalırdı.

**`lab_schedules`** — `marker` veya `panel`, `lastDate`, `intervalMonths`,
`nextDue` (türetilmiş).

**`profile`** — anahtar-değer. Boy, doğum yılı, başlangıç ve hedef kilo,
yaşam tarzı (uyanma/uyku saati, iş saatleri ve vardiya, salona erişilebilen
saatler, aile yemeği saati, sabit sorumluluklar, mutfakta bulunanlar),
sağlık kısıtları, AI sağlayıcı tercihi, API anahtarı.

### 5.5 Türetilen, saklanmayan değerler

Haftalık özet (ortalama kilo, geçen haftaya fark, salon 3/3, ev 4/4, kaçak gün),
ay sonu ölçüm tablosu ve geçiş kriteri (105 kg altı **ve** 8 nizami şınav **ve**
koşu sonrası ağrı yok) sorguyla hesaplanır; ayrı tablo tutulmaz.

## 6. Ekranlar

Alt gezinme beş sekme: **Bugün · Plan · İlerleme · Sağlık · Katalog**.
Ayarlar üst çubukta ikon.

**Bugün** (varsayılan) — Günün slot listesi saat sırasıyla, tek dokunuşla
işaretlenir. Üstte tek alanlı tartı girişi ve uyku süresi girişi; bu ikisi
`daily_logs`'a değil `body_metrics`'e (`kind = weight` / `sleepHours`) yazılır.
Günün üç kutucuğu: 3 L su, alkol/şeker yok, antrenman — bunlar `daily_logs`'a
yazılır. Altta serbest not alanı; bu metin `context.md`'ye düzenlenmeden
aktarılır. Antrenman slotu karttır, Antrenman ekranını açar.

**Antrenman** (sekme değil, Bugün'den açılır) — Hareketler sırayla; her satırda
hedef (3 × 10) ve yanında geçen seferki gerçekleşen değer gri olarak. Set sayacı,
setler arası geri sayım. Hareket adına dokunmak katalog detayını açar. Kardiyo
günü tek büyük sayaç + direnç/eğim gösterir.

**Plan** — 28 günün takvim görünümü; dolu/eksik/kaçak günler renkle ayrışır.
İki eylem: "Yeni plan iste", "Planı içeri al".

**İlerleme** — Kilo trendi: günlük noktalar + 7 günlük hareketli ortalama çizgisi.
Haftalık özet kartları. Ay sonu ölçüm tablosu, üç tarih yan yana. Geçiş kriteri
kartı: üç koşuldan kaçı sağlandı.

**Sağlık** — Tahliller panel başlığına göre gruplu kartlarda. Her değer referans
aralığına göre renkli, trend oku ile. Yaklaşan tahlil uyarısı üstte.

**Katalog** — Arama ve filtre (ev/salon, kas grubu, ekipman). Detay sayfası
sekmeli: `Nasıl yapılır` · `Sık hatalar` · `Kolaylaştır / Zorlaştır` · `Güvenlik`.

**İlk açılış** — Plan yoksa: profil ve yaşam tarzı sorulur, ardından
"İlk planını al" adımı `context.md` üretir. Boş ekran gösterilmez.

**Detay katmanlaması:** Aynı hareket iki derinlikte sunulur. Antrenman sırasında
görsel + 3-4 ipucu + tempo; katalogda tam anlatım. Detay vardır ama antrenman
akışını kesmez.

## 7. AI sözleşmesi

Uygulama AI sağlayıcısını bilmez. İki port üzerinden çalışır.

### 7.1 ÇIKIŞ — `context.md`

Tek dosya. Kopyalanır veya paylaş menüsünden doğrudan bir AI uygulamasına
gönderilir. Yedi bölüm:

1. **Kim** — yaş, boy, mevcut kilo, yaşam tarzı
2. **Hedef** — hedef kilo, tempo, kcal/protein/su hedefleri
3. **Kısıtlar** — sağlık durumu, yasak liste, serbest liste, eldeki ekipman
4. **Geçen dönem** — makine-okunur JSON bloğu: gün gün uyum, kilo serisi,
   kaçırılan günler, gerçekleşen set/tekrarlar
5. **Kendi sözlerin** — kullanıcının serbest notları, aynen
6. **Son tahliller** — değer, referans aralığı, tarih
7. **Görev ve format** — istenen çıktı, JSON şeması, kısa örnek, uyulacak kurallar

Katalog bölümü tam liste değildir: kullanıcının ekipmanına ve gün tiplerine uyan
alt küme (~60-80 hareket) `id · ad · ev/salon · ekipman` olarak listelenir.

### 7.2 GİRİŞ — `plan.json`

```json
{
  "schemaVersion": 1,
  "meta": { "title": "...", "startDate": "2026-09-01", "weeks": 4 },
  "goals": { "dailyKcal": 2400, "proteinG": 170, "waterL": 3,
             "weeklyGym": 3, "weeklyHome": 4, "targetLossKg": 3.5 },
  "rules": { "forbidden": ["..."], "free": ["..."] },
  "days": [{
    "date": "2026-09-01", "type": "gym", "weekIndex": 1,
    "headline": "...",
    "slots": [{ "time": "06:30", "kind": "meal", "label": "..." }],
    "exercises": [{ "exerciseId": "incline_pushup",
                    "sets": 3, "reps": 10, "restSec": 60 }]
  }],
  "newExercises": []
}
```

AI düzyazı üretmez; id, sayı ve saat üretir. Hareketin nasıl-yapılır bilgisi
katalogdan gelir, her planda yeniden yazılmaz.

### 7.3 Doğrulama — dört kapı

1. **Ayrıştırma** — geçersiz JSON reddedilir
2. **Şema** — alanlar, tipler, zorunluluklar
3. **Anlam** — tarihler ardışık mı; gün sayısı beyan edilen hafta sayısıyla
   tutarlı mı; her `exerciseId` katalogda var mı; salon günü ev hareketi
   içeriyor mu; kcal ve protein makul aralıkta mı; aynı güne iki antrenman
   düşmüş mü
4. **Önizleme** — geçen plan ekranda gösterilir; kullanıcı onayladığında tek
   transaction ile yazılır. Kısmi yazma olmaz.

Hata mesajları AI'a geri yapıştırılabilir biçimdedir:

> `3. gün: "barbell_squat" katalogda yok. O gün ev günü. Uygun alternatifler: chair_squat, step_up, wall_sit.`

### 7.4 Yeni hareket önerileri (esnek mod)

AI, katalogda olmayan hareketleri `newExercises[]` bloğunda tam tanımıyla
önerebilir. Uygulama bunları kullanıcının onayına sunar; kabul edilenler
`isUserDefined = true` ile kataloğa kalıcı olarak eklenir.

Asgari çıta — sağlanmazsa doğrulama reddeder:
- `execution` en az 3 adım
- `commonMistakes` en az 2 kayıt, üç alanı da dolu
- `breathing`, `safety`, `primaryMuscles`, `equipment` boş olamaz

Bu kural `context.md`'nin görev bölümünde AI'a açıkça bildirilir.

Kullanıcı tanımlı hareketlerin görseli olmaz; yer tutucu ikon ve isteğe bağlı
harici arama bağlantısı gösterilir. Bağlantı tarayıcıda açılır, içerik uygulamaya
gömülmez.

### 7.5 İsteğe bağlı BYOK (Seviye 1)

Ayarlarda kullanıcı kendi API anahtarını girebilir; uygulama `context.md`'yi
doğrudan gönderip `plan.json` alır. Gemini ücretsiz katmanı (Flash / Flash-Lite,
günde ~1.500 istek, kredi kartı gerektirmez) bu kullanım için yeterlidir.

Kişisel sağlık verisi üçüncü tarafa gönderileceği için, bu özellik açılmadan önce
ne gönderileceğini açıkça belirten bir onay ekranı gösterilir. Onay verilmedikçe
hiçbir veri cihazdan çıkmaz.

## 8. Alarmlar

Kaynak `plan_slots`. Bildirim türleri:

| Tür | Tetikleyici |
|---|---|
| Slot hatırlatması | Öğün, antrenman, uyku saatleri |
| Sabah tartısı | Uyanma saatinden 15 dk sonra |
| Kaçak uyarısı | İki gün üst üste `workoutDone = false` → ikinci günün akşamı |
| Tahlil vadesi | `lab_schedules.nextDue` geldiğinde, gün başında |
| Plan bitiyor | Planın son 3 günü |

**iOS sınırı:** Sistem en fazla 64 bekleyen bildirim tutar. 28 günün tamamı
zamanlanırsa sessizce taşar. Çözüm: yalnızca önümüzdeki 7 gün zamanlanır
(≈ 49 bildirim); uygulama her açıldığında pencere ileri kaydırılır. Uygulama bir
hafta boyunca hiç açılmazsa alarmlar tükenir — bu bilinçli olarak kabul edilmiştir.

**Android 14+ sınırı:** Tam zamanlı alarm için `SCHEDULE_EXACT_ALARM` izni
çalışma anında istenir. `USE_EXACT_ALARM` kullanılmaz; o izin mağaza denetimine
tabidir ve bu uygulama bir alarm/takvim uygulaması değildir. İzin verilmezse
yaklaşık zamanlamaya düşülür; uygulama çalışmaya devam eder.

Saat dilimi `timezone` paketiyle yönetilir. Bildirime dokunmak ilgili ekranı açar.
Bildirimler slot tipine göre tek tek kapatılabilir; kapatılsa bile ilgili öğe
Bugün ekranında görünmeye devam eder.

## 9. Egzersiz içeriği

Kaynak: [free-exercise-db](https://github.com/yuhonas/free-exercise-db) —
800+ hareket, JSON, görselli, kamu malı. Ticari kullanımda lisans engeli yoktur.
[wger](https://github.com/wger-project/wger) AGPL-3.0 lisanslıdır ve uygulamaya
gömülmeyecektir.

Hazırlık adımları:
1. Programa uyan ~60-80 hareket seçilir (ev kalistenik, salon kardiyo, temel kuvvet)
2. Görsel, kas grubu ve ekipman verisi free-exercise-db'den alınır
3. Detaylı Türkçe anlatım AI yardımıyla üretilir ve **elle gözden geçirilir**
4. Sonuç `assets/catalog.json` olarak uygulamaya gömülür

Bu iş uygulama geliştirmesinden bağımsızdır ve paralel yürütülebilir.

## 10. Hata yönetimi

| Durum | Davranış |
|---|---|
| Bozuk/eksik `plan.json` | Dört kapıdan hangisinde takıldığı, AI'a geri yapıştırılabilir mesajla bildirilir. Mevcut plan bozulmaz. |
| Import yarıda kalırsa | Tek transaction; ya tamamı yazılır ya hiçbiri. |
| Katalogda olmayan `exerciseId` | Reddedilir, uygun alternatifler önerilir. |
| Çıtayı geçmeyen `newExercises` kaydı | O kayıt reddedilir, gerekçesi belirtilir; planın kalanı geçerliyse yazılabilir. |
| Alarm izni yok (Android) | Yaklaşık zamanlamaya düşülür, kullanıcıya bir kez bilgilendirme gösterilir. |
| Bildirim kotası dolu (iOS) | 7 günlük pencere zaten sınırın altında tutar; taşma olursa en yakın tarihliler önceliklidir. |
| BYOK isteği başarısız | Hata gösterilir, kopyala-yapıştır yoluna düşülür. |
| Şema sürümü uyumsuz | `schemaVersion` beklenenden büyükse "uygulamayı güncelle", küçükse göç uygulanır. |

## 11. Test yaklaşımı

- **Doğrulama katmanı** — en yoğun test edilen bölüm. Geçerli plan, her kapıda
  takılan bozuk planlar, sınır durumlar (28 gün yerine 27, çakışan slotlar,
  bilinmeyen id, çıtayı geçmeyen `newExercises`).
- **Türetilen değerler** — haftalık özet, hareketli ortalama, geçiş kriteri;
  bilinen girdi kümeleriyle beklenen çıktı.
- **Repository** — bellek içi Drift veritabanı üzerinde CRUD ve soft delete.
- **Alarm zamanlama** — 7 günlük pencere sınırı, kaydırma davranışı, saat dilimi
  değişimi; bildirim katmanı sahte (fake) uygulama ile izole edilir.
- **`context.md` üretimi** — sabit bir profil ve kayıt kümesinden üretilen çıktı
  anlık görüntü (golden file) testiyle karşılaştırılır.
- **Widget testleri** — Bugün ve Antrenman ekranlarının temel etkileşimleri.

## 12. v1 kilometre taşları

v1 tek seferde değil, çalışır durumda kalan beş adımda kurulur. Her adımın
sonunda uygulama telefonda açılır ve bir önceki adımdan fazlasını yapar.

| # | Kapsam | Sonunda ne çalışır |
|---|---|---|
| M1 | Proje iskeleti, tema, `repo` + Drift şeması, gezinme | Boş ama gezilebilir uygulama; veritabanı ayakta |
| M2 | `catalog` modülü + tohum veri (`assets/catalog.json`) + Katalog ekranı | Hareketler aranabilir, detay sayfası tam okunur |
| M3 | `plan` + `log` + Bugün ve Antrenman ekranları; plan elle girilebilir | Günlük takip baştan sona kullanılabilir |
| M4 | `ai_bridge`: `context.md` üretimi, `plan.json` doğrulama ve içe alma | AI döngüsü kapanır; plan artık elle girilmiyor |
| M5 | `health` + İlerleme ve Sağlık ekranları + `reminder` (alarmlar) | Grafikler, tahliller ve alarmlar devrede |

M3 sonunda uygulama günlük kullanıma girebilir; M4 ve M5 üstüne biner.
Egzersiz içeriğinin hazırlanması (bölüm 9) M2'ye girdi olur ve ondan önce
başlatılabilir.

## 13. Sonraki fazlar

**Faz 2 — Hesap ve senkron.** Google ile giriş; `userId` gerçek değer alır.
Repository katmanının arkasına uzak veri kaynağı ve `updatedAt` tabanlı
çakışma çözümü eklenir. Veri modeli değişmez.

**Faz 3 — MCP connector.** Uygulama verisini uzak MCP sunucusu olarak yayınlar;
kullanıcı bunu AI hesabına bir kez ekler ve telefonundan doğrudan verisiyle
konuşur. `plan.json` şemasının aynısı servis edilir; `ai_bridge`'e bir adaptör
eklenmesi yeterlidir.

2026 Ağustos itibarıyla bu yetenek pratikte yalnızca Claude'da (ücretsiz dahil
tüm planlarda, mobil dahil) çalışır. ChatGPT'de Plus/Pro ile yalnızca web
üzerinde ve kısıtlı yazma yetkisiyle; Gemini'nin tüketici uygulamasında hiç yok.
Bu nedenle çekirdek özellik değil, ek özellik olarak konumlanır.

**Faz 4 — Yayın.** KVKK/GDPR uyumu (sağlık verisi özel niteliklidir),
gizlilik politikası, App Store ve Play Store gereksinimleri.
