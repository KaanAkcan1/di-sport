# Günlük Düzen v2 — güne göre özelleştirme (tasarım)

**Tarih:** 2026-09-04 · **Durum:** Kullanıcı onayı bekliyor ·
**Bağlantılar:** [Gün-kapsayıcı mimari kararı](2026-09-04-gun-kapsayici-mimari-karar.md) ·
[UI mockup](../mockups/2026-09-04-gunluk-duzen-mockup.html)

## Amaç

Günlük ritim (kalkış/uyku) ve öğünler haftanın günlerine göre
özelleştirilebilsin ("hafta içi 06:30, cumartesi 09:00"; "pazar
kahvaltısı 10:00'da ve serpme"). Öğünlere besin listesinden seçilen
**içerik şablonu** tanımlanabilsin; günlükte tek dokunuşla kayda
dönüşsün. Model **karma**: tek varsayılan + gün-seçimli istisnalar
(pencere ekleme akışındaki gün-çipi kalıbıyla).

Kapsam dışı: takviye/ilaç düzeni (kendi gün+saat sistemi zaten var),
plan günleri (tarihli program ayrı doğa — bkz. mimari karar).

## 1. Veri modeli (şema v17)

**Varsayılanlar yerinde kalır** (profil anahtarları + öğün başına tek
`meal_behaviors` satırı) — istisnasız kullanıcı için davranış bugünle
birebir aynı, göç gerekmez.

- **Yeni tablo `rhythm_overrides`** (SyncColumns + `weekday` 1-7,
  `wakeTime?`, `sleepTime?`; ikisi de `HH:mm`, null = o alanda
  varsayılan geçerli). Her satır tek günün istisnası; "Cmt-Paz 09:00"
  pencerelerdeki `addForDays` kalıbıyla iki satır yazılır. Aynı güne
  ikinci istisna öncekini günceller (öğün başına tek canlı satır
  kalıbı).
- **`meal_behaviors`'a `weekday` sütunu** (nullable int; null =
  varsayılan satır, dolu = o günün varyasyonu). Varyasyon satırı
  saat/davranış/şablonun üçünü de geçersiz kılabilir (satır bütün
  olarak kazanır; alan bazında birleştirme yok — kullanıcıya
  anlatılamayan birleşme kuralı hata kaynağıdır).
- **`fixedItemsJson` genelleşir → şablon içerik.** Ad değişmez (göç
  maliyeti), anlam genişler: her davranışta "bu öğünün varsayılan
  içeriği". Biçim aynı: `[{foodId, quantity, portionId?}]`.
- Göç: `schemaVersion` 16→17, `onUpgrade`'e yeni `if (from < 17)`
  bloğu (tablo + sütun ekleme; veri dönüştürme yok).

## 2. Çözücü (saf domain)

`settings/domain/rhythm_resolver.dart`:

```
resolveDay(weekday, {defaults, overrides, mealRows}) → DayRhythm
  DayRhythm: wakeTime, sleepTime, meals[ResolvedMeal]
  ResolvedMeal: mealKind, time?, behavior, templateItems, isVariant
```

Kurallar: istisna satırı alanı doluysa kazanır; öğünde o güne
varyasyon satırı varsa **satır bütün olarak** varsayılanın yerine
geçer. Alarm planlayıcı, Diyet günlüğü, hafta önizlemesi ve
context.md yalnız bu çözücüden okur — "salı sabahı ne olur" sorusu
emülatörsüz cevaplanır.

## 3. UI

`WeeklyScheduleScreen` yeniden düzenlenir (mockup'taki "kural listesi
+ gün önizleme" kurgusu):

- **RİTİM**: varsayılan satır + altında istisna satırları (yeşil
  çizgili girinti, ✕ ile yumuşak silme).
- **ÖĞÜNLER**: öğün başına kart (saat · davranış · şablon özeti) +
  altında gün varyasyonları.
- **PENCERELER**: mevcut bölüm aynen.
- **HAFTA ÖNİZLEME**: 7 gün kartı çözücüden beslenir ("06:30 kalk ·
  3 öğün · mesai"); istisnalı gün vurgulanır. Güne dokunmak o günün
  çözülmüş dökümünü açar.
- **Tek FAB → birleşik ekleme sayfası**: tür seçimi (Mesai · Yasaklı
  saat · Kalkış/uyku istisnası · Öğün varyasyonu) → ortak gün-çipi
  ızgarası → türe göre alan seti. Gün-çipi ızgarası `_WindowSheet`
  içinden settings-içi ortak widget'a çıkarılır (tek feature
  kullandığı için core'a girmez — CLAUDE.md kural 8).
- **Şablon düzenleme**: Diyet'teki mevcut besin arama + porsiyon
  seçici yeniden kullanılır; kalem listesi ≈kcal toplamı gösterir.
- Boş gün seçimi satır-altı hata; kaydet alarmları hemen yeniden
  kurar (`rescheduleQuietly`, mevcut kural).

## 4. Etkilenen sistemler

- **Alarmlar:** `planWindow`'a tek `wakeTime` yerine gün→saat çözümü
  taşınır: `MealTimeFact` ve tartı üretimi `weekday` farkındalı olur.
  Pencere zaten 7 güni tek tek ürettiği için değişiklik üretim
  döngüsünde saat seçiminden ibaret. Yasaklı pencere kuralları
  değişmez.
- **Diyet günlüğü (`day_meals_card`):** `mealBehaviorsProvider`
  yerine o günün çözülmüş öğün satırları kullanılır. "Şablondan
  kaydet" eylemi: şablon kalemleri `addResolvedItems` ile
  snapshot'lanır (kcal kayıt anında donar — mevcut ilke).
- **context.md:** §1 satırı istisnalarla genişler ("Kalkış 06:30;
  Cmt-Paz 09:00"), öğün tablosu varyasyon satırlarını içerir. AI
  gerçek ritmi görür; sözleşme (dönen plan şeması) değişmez.
- **Bugün ekranı:** hafta önizleme ve akıştaki öğün satır saatleri
  çözücüden gelir.

## 5. Deneyim katmanı (mimari karardan doğan, bu milestone'da)

- `today/domain`'e tipli akış öğesi: tür + içerik özeti + alarm
  bayrağı + AI-doldurma durumu + **kaynak düzenleyiciye derin
  bağlantı**. Akış satırına uzun basış ilgili düzenleyiciyi açar
  (öğün → şablon/varyasyon, doz → takviye, antrenman → plan editörü;
  dokunma işaretlemeye ait — mevcut kural).
- `plan_slots.remind` sütunu (nullable bool; null = tür varsayılanı):
  slot başına alarm kapatma/açma. `planWindow` süzgecine girer.
- Gün akışında geçmiş günlerde doz satırları loglardan gösterilir
  ("yalnız bugün" kısıtı kalkar; gelecek günlerde kural gösterimi,
  işaretleme alanı yok — düzenlenebilirlik kurallarıyla uyumlu).

## 6. Test

- Çözücü birim testleri: istisna önceliği, varyasyon bütün-satır
  kuralı, istisnasız kullanıcıda birebir eski davranış.
- Repository: v17 göçü, `addForDays` kalıbıyla istisna yazımı,
  öğün+gün başına tek canlı satır.
- Planner: "cumartesi tartı alarmı 09:00'da kurulur mu",
  "pazar kahvaltı alarmı 10:00'da mı", `remind=false` slot alarmı
  üretmiyor mu — emülatörsüz.
- Widget: `day_meals_card` çözülmüş öğünle (provider override),
  şablondan kayıt snapshot değerleri, birleşik ekleme sayfası boş gün
  hatası.
- Deneyim katmanı: akış öğesi derin bağlantı hedefleri, geçmiş gün
  doz satırlarının logdan gelmesi.
