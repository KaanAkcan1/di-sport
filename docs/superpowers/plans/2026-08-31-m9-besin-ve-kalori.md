# M9 — Besin ve Kalori Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Besin veritabanı (küratörlü + USDA), porsiyonlu öğün kaydı, günlük kalori bütçesi/dengesi, egzersiz enerjisi (MET/ACSM), serbest aktivite kaydı; Bugün'de kalori kahramanı, takvimde kalori tonlaması, İlerleme'de haftalık çubuklar.

**Architecture:** Yeni feature `nutrition` (foods, portions, meal_entries) + `workout` içinde saf `energy_estimator` + hafif `activities` çifti. Kalori/protein kayıt anında dondurulur (snapshot). `nutrition`, antrenman enerjisini port üzerinden okur (`EnergySource`) — `ai_bridge` deseninin aynısı.

**Tech Stack:** Drift (şema v13) · Riverpod · Python (besin derleme aracı) · USDA SR Legacy CSV · 2024 Adult Compendium

**Spec:** `docs/superpowers/specs/2026-08-31-disport-v2-saglikli-yasam.md` §5

## Global Constraints

- **Döngü TDD DEĞİL:** her görevde **kod → testler → çalıştır → review → commit**.
- Şema v12 → **v13**: `foods`, `food_portions`, `meal_entries`, `activities`, `activity_logs` + `exercise_logs`'a şiddet sütunları. Tek `if (from < 13)` bloğu.
- Her tabloda `SyncColumns`. Metinler ARB'ye. Stream okuma kuralı. Widget testinde Drift yok.
- Tahmin her yerde `≈` ile gösterilir. Plan yoksa bütçe yok — yalnız toplam (spec §5.4).
- Sayı biçimi `NumberFormat` (M7): TR'de virgül.

## Dosya Haritası

| Dosya | Sorumluluk |
|---|---|
| `app/lib/features/nutrition/domain/food.dart` | `Food`, `FoodPortion`, `FoodCategory`, `MealKind` |
| `app/lib/features/nutrition/domain/meal_math.dart` | Saf hesap: porsiyon×çarpan→gram→kcal/protein |
| `app/lib/features/nutrition/domain/calorie_budget.dart` | Saf: hedef − yenen + egzersiz |
| `app/lib/features/nutrition/data/nutrition_tables.dart` + `nutrition_repository.dart` | Drift |
| `app/lib/features/nutrition/application/...` | Provider'lar, `EnergySource` bağlanışı |
| `app/lib/features/nutrition/presentation/food_picker_screen.dart` | Arama + türler + SIK/şablon |
| `app/lib/features/nutrition/presentation/portion_sheet.dart` | Porsiyon çarpanı alt sayfası |
| `app/lib/features/workout/domain/energy_estimator.dart` | Saf MET/ACSM hesabı |
| `app/lib/features/workout/domain/ports.dart` ya da nutrition/domain/ports.dart | `EnergySource` arayüzü (tüketen tanımlar: nutrition) |
| `app/assets/foods.json` | ~400 kayıt |
| `tools/build_foods.py` | Küratörlü + USDA birleştirme |

---

### Task 1: Şema v13 + domain modelleri

**Files:**
- Create: `nutrition_tables.dart`, `domain/food.dart`
- Modify: `app_database.dart` (v13); `workout/data/exercise_log_table.dart` (+`speedKmh REAL?`, `gradePct REAL?`, `effort TEXT?`)
- Test: `migration_v13_test.dart`, `food_test.dart`

**Interfaces:**
- Produces:

```dart
enum FoodCategory { yemek, corba, kahvaltilik, meyve, sebze, kuruyemis,
    icecek, tahil, etBalik, sutUrunu, atistirmalik, diger }
// Not: ekran türü kartlarında 8'i öne çıkar (M12 taslağı); kategori
// kümesi veri tarafında geniş tutulur — USDA kayıtları etBalik/sutUrunu
// ister. Kart listesi arayüz kararı, enum veri kararı.

enum MealKind { kahvalti, araOgun, ogle, ikindi, aksam, gece }

class Food { id; nameTr?; nameEn; category; kcal100; protein100;
  carb100; fat100; source('curated'|'usda'|'user'); sourceRef?; }
class FoodPortion { id; foodId; labelTr; labelEn; grams; isDefault; }
```

Tablolar spec §5.2 + `activities`/`activity_logs` (spec §5.6). `meal_entries`: `date, mealKind, slotId?, foodId, quantity REAL, portionId?, grams REAL, kcalSnapshot REAL, proteinSnapshot REAL`.

- [ ] **Step 1: Kodu yaz** (+ build_runner)
- [ ] **Step 2: Testleri yaz** — göç v12→v13 (beş tablo + üç sütun); `Food.fromJson` gidiş-dönüş; bilinmeyen kategori hata.
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/core/db/ test/features/nutrition/`
- [ ] **Step 4: Commit** — `git commit -m "feat: nutrition and activity schema v13"`

---

### Task 2: Saf hesaplar — meal_math, calorie_budget, energy_estimator

**Files:**
- Create: `nutrition/domain/meal_math.dart`, `nutrition/domain/calorie_budget.dart`, `workout/domain/energy_estimator.dart`
- Test: üçüne birer test dosyası (saf birim testleri — planın en yoğun test görevi)

**Interfaces:**
- Produces:

```dart
// meal_math.dart
({double grams, double kcal, double protein}) mealValues({
  required Food food, required double quantity, FoodPortion? portion,
  double? customGrams});   // portion?×quantity ya da customGrams

// calorie_budget.dart
class DayEnergy { final double eaten; final double burned; }
double? remainingBudget({int? goalKcal, required DayEnergy day});
// goalKcal null → null (bütçe yok); kalan = goal − eaten + burned

// energy_estimator.dart  (spec §4.4 + §5.5)
double metFor({required double met, required MetModel model,
  double? speedKmh, double? gradePct, Effort? effort});
// treadmill: ACSM — hız<7 km/h yürüyüş, ≥7 koşu denklemi; MET=VO2/3.5
// cycling: effort → 5.0 / 7.0 / 10.5 ; fixed: met
double kcalFor({required double met, required double weightKg,
  required Duration duration}); // met × kg × saat
```

- [ ] **Step 1: Kodu yaz** — ACSM: `hızMdk = kmh*1000/60`; yürüyüş `0.1v+1.8vg+3.5`, koşu `0.2v+0.9vg+3.5`.
- [ ] **Step 2: Testleri yaz** — bilinen değer doğrulamaları:

```dart
  test('ACSM yürüyüş 5 km/h düz ≈ 3.7 MET', () =>
      expect(metFor(met: 0, model: MetModel.treadmill, speedKmh: 5,
          gradePct: 0), closeTo(3.4, 0.5)));
  test('ACSM koşu 8 km/h %8 ≈ 11 MET', () =>
      expect(metFor(..., speedKmh: 8, gradePct: 8), closeTo(11, 1)));
  test('7 km/h sınırında yürüyüş→koşu geçişi süreklidir olmayabilir —
      seçilen denklem belgelenir', ...);
  test('kcal: 8 MET × 100 kg × 1 saat = 800', () =>
      expect(kcalFor(met: 8, weightKg: 100,
          duration: const Duration(hours: 1)), closeTo(800, 1)));
  test('bütçe: hedef yoksa null', () =>
      expect(remainingBudget(goalKcal: null,
          day: DayEnergy(eaten: 500, burned: 0)), isNull));
  test('porsiyon 250g × 3 → 750g ve oranlı kcal', ...);
```

- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/nutrition/ test/features/workout/`
- [ ] **Step 4: Commit** — `git commit -m "feat: pure meal, budget and energy estimation math"`

---

### Task 3: foods.json — küratörlü liste + USDA boru hattı

**Files:**
- Create: `tools/build_foods.py`, `tools/foods_curated.json`, `app/assets/foods.json`
- Test: `app/test/assets/foods_seed_test.dart`

Boru hattı (spec §5.1):
1. `foods_curated.json` — elle: Türk ev yemekleri (~150: etli kuru fasulye, mercimek çorbası, menemen…), kahvaltılıklar, yaygın içecek/atıştırmalık. Her kayıtta TR+EN ad, 100g değerleri, ≥1 ev ölçüsü porsiyonu (`1 kase=250g`, `1 dilim=30g`), `source:'curated'`, `sourceRef` (değerin dayandığı kaynak notu).
2. USDA SR Legacy CSV'den seçme ham besinler (~250: meyve, sebze, et, süt, tahıl, kuruyemiş) — `--usda` modu CSV'yi okur, seçim listesi `tools/foods_usda_selection.txt`; TR adı çeviri tablosundan (`elma`, `tavuk göğsü, pişmiş`…), yoksa boş kalır → arayüz EN gösterir. `source:'usda'`, `sourceRef: NDB no`.
3. Çıktı determinist; kayıt sayısı hedefi **≥350**.

- [ ] **Step 1: Aracı + ilk küratörlü partiyi yaz** (~50 kayıt) — porsiyon zorunluluğu: her curated kayıtta `isDefault` porsiyon şart; USDA'da 100g varsayılan.
- [ ] **Step 2: Testi yaz** — `foods_seed_test.dart`: tüm kayıtlar çözülür; kcal100 ∈ (0, 900]; protein100 ∈ [0, 100]; curated kayıtta default porsiyon var; id benzersiz; taban sayısı (ilk partide ≥50, son partide ≥350'ye çekilir).
- [ ] **Step 3: Partiler** — curated 3 parti + usda 2 parti, her parti commit:
  - `"feat: curated turkish foods batch 1/2/3"`
  - `"feat: usda staple foods batch 1/2"`
- [ ] **Step 4: Çalıştır + Commit** her partide.

---

### Task 4: Repository + tohum + SIK/şablon sorguları

**Files:**
- Create: `nutrition_repository.dart`, `application/nutrition_providers.dart`
- Modify: `bootstrap.dart` (foods tohumu — katalog deseniyle: sürüm damgalı, silinmiş geri gelmez)
- Test: `nutrition_repository_test.dart` (gerçek DB)

**Interfaces:**
- Produces:

```dart
Stream<List<Food>> search(String query);        // LocaleText.matchesAnyLocale
Stream<List<Food>> byCategory(FoodCategory c);
Stream<List<MealEntry>> watchDay(DateTime day);
Future<void> addEntry({required Food food, required MealKind kind,
  required DateTime day, String? slotId, required double quantity,
  FoodPortion? portion, double? customGrams});
  // kcal/protein SNAPSHOT burada hesaplanıp yazılır (spec §5.2)
Future<void> removeEntry(String id);            // yumuşak silme
Stream<List<Food>> frequent({int limit = 8});   // son 30 günde en sık
Stream<double> dayKcal(DateTime day);           // Σ kcalSnapshot
Stream<double> dayProtein(DateTime day);
```

Şablonlar (M12 taslağı "Kahvaltım"): `meal_templates` tablosu **açılmaz** — YAGNI; şablon = son 30 günde aynı `mealKind`de birlikte girilen kalem kümesi önerisi yerine **basit çözüm**: "dünü kopyala" eylemi (`copyMeal(from: day-1, kind)`). Gerçek şablon tablosu kullanıcı isterse sonra. Bu sapma spec'e işlenecek (review notu).

- [ ] **Step 1: Kodu yaz**
- [ ] **Step 2: Testleri yaz** — snapshot donması: besin değeri güncellenince eski entry değişmez (planın kritik testi); `frequent` sıralaması; `copyMeal` dünkü üç kalemi bugüne kopyalar, snapshot yeniden hesaplanmaz (kopya da donuk).
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/nutrition/`
- [ ] **Step 4: Commit** — `git commit -m "feat: nutrition repository with frozen snapshots and frequents"`

---

### Task 5: Öğün kaydı arayüzü — seçici + porsiyon sayfası

**Files:**
- Create: `food_picker_screen.dart`, `portion_sheet.dart`
- Modify: Bugün omurgası: öğün slotu dokununca seçici açılır; `+ Öğün` hızlı eylemi
- Test: ekran testleri (provider override)

M12 taslağı birebir: arama (boş açılmaz — SIK YEDİKLERİN + dünü kopyala), tür kartları (8 öne çıkan), sonuç satırı iki adlı; porsiyon sayfası: porsiyon seçici + `− n +` çarpan + canlı `gram · kcal · protein` + "Öğüne ekle". Plan editörü entegrasyonu M10'da — seçici parametreyle çağrılabilir yazılır (`onPicked` callback, doğrudan kayıt değil).

- [ ] **Step 1: Kodu yaz**
- [ ] **Step 2: Testleri yaz** — çarpan 3 → 750g/810kcal canlı; SIK bölümü boş geçmişte görünmez; arama iki dilde tutar.
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/nutrition/`
- [ ] **Step 4: Commit** — `git commit -m "feat: food picker and portion sheet"`

---

### Task 6: Serbest aktiviteler — tohum + kayıt + Dışarıda sekmesi

**Files:**
- Create: `assets/activities.json` (~70, Compendium: kod+MET; basketbol maç 8.0, boks ring 12.3, koşu 9.8…)
- Create: `nutrition/data/activities_repository.dart` (ya da ayrı `activities` feature değil — nutrition içinde: enerji hattının parçası)
- Create: `presentation/activity_log_sheet.dart` (aktivite seç → süre gir → ≈kcal)
- Modify: katalog ekranı — **Dışarıda sekmesi** aktiviteleri listeler (M12'de yeri işaretlenmişti)
- Modify: Bugün `+ Aktivite` hızlı eylemi görünür olur (M12'de gizliydi)
- Test: `activities_seed_test.dart`, repository + ekran testleri

**Interfaces:**
- Produces: `Activity{ id; nameTr; nameEn; category; met; source }`, `ActivityLog{ date; activityId; minutes; kcalSnapshot }`; kullanıcı tanımlı aktivite (M6 kalıbı): ad + MET ya da üç seviye (3.0/6.0/9.0)

- [ ] **Step 1: Kodu yaz** — tohum + kayıt akışı tek adım; `kcalSnapshot = kcalFor(met, kilo, süre)` kayıtta donar (kilo değişince geçmiş değişmez).
- [ ] **Step 2: Testleri yaz** — tohum şeması + MET aralığı (1.0–15.0); snapshot donması; Dışarıda sekmesi aktiviteleri basar.
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test`
- [ ] **Step 4: Commit** — `git commit -m "feat: free activities with compendium seed and outdoor tab"`

---

### Task 7: Enerji portu + antrenman kalorisi

**Files:**
- Create: `nutrition/domain/ports.dart` → `abstract interface class EnergySource { Stream<double> burnedOn(DateTime day); }`
- Create: `workout/application/energy_source_adapter.dart` — `exercise_logs` (süre+şiddet+katalog met) + `activity_logs` toplamı
- Modify: antrenman ekranı: seans sonunda `≈ NNN kcal`; kardiyo setinde hız/eğim/effort girişi (plandan önceden dolu — `plan_exercises` şiddet alanları M10 editöründe düzenlenir; buraya dek AI/örnek plandan gelir, `intensity` serbest metni ayrıştırılmaz, kullanıcı girer)
- Test: adaptör testi (gerçek DB), ekran testi

- [ ] **Step 1: Kodu yaz** — kuvvet: seans süresi × sabit MET (spec §5.5: set başına değil); kardiyo: girilen şiddetle ACSM.
- [ ] **Step 2: Testleri yaz** — 52 dk kuvvet @3.5 MET, 109 kg → ≈331 kcal; kardiyo eğim değişince kcal değişir; `burnedOn` iki kaynağı toplar.
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/workout/`
- [ ] **Step 4: Commit** — `git commit -m "feat: energy source port and workout calorie estimate"`

---

### Task 8: Kahraman ve tonlar veriye bağlanır

**Files:**
- Modify: Bugün — kahraman kilodan **kalan kaloriye** döner (`AppHeroNumber(gaugeFraction: eaten/goal)`); metrik şeridine PROTEİN ve SPOR(≈) girer; plan yoksa kahraman toplam yenen (bütçesiz, spec §5.4)
- Modify: Takvim — `DayCellState` kalori dengesine bağlanır: `remaining>0`→successSurface, `<0`→dangerSurface + fark rakamı hücrede; serbest gün değer girildiyse hesaplanır (spec §2a); veri yoksa M12 doluluk tonu sürer
- Modify: İlerleme — haftalık kalori çubukları (7 gün × hedef çizgisi; fl_chart BarChart); çubuğa dokun → gün dökümü alt sayfası (öğün listesi + spor)
- Test: üç ekranın testleri + `progress_reactivity_test` deseninde bir kalori-reaktivite testi (öğün eklenince Bugün kahramanı güncellenir — gerçek DB akış testi, widget değil)

- [ ] **Step 1: Kodu yaz**
- [ ] **Step 2: Testleri yaz** — bütçe yokken gauge yok; aşımda gauge danger; takvim serbest+değerli gün hesaplı; reaktivite.
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test` (tam paket)
- [ ] **Step 4: Cihaz doğrulaması** — uçtan uca: öğün gir → kahraman düşer → antrenman yap → geri gelir → takvim tonlanır.
- [ ] **Step 5: Commit** — `git commit -m "feat: calorie hero, calendar tones and weekly bars bound to data"`

---

### Task 9: Süpürme + dokümantasyon

- [ ] `CLAUDE.md`: nutrition feature, v13, foods boru hattı, snapshot ilkesi, EnergySource portu. Spec'e Task 4 sapması işlenir ("şablon yerine dünü kopyala"). `git commit -m "docs: record nutrition architecture"`

---

## Öz-değerlendirme notları

- Spec §5 kapsaması: 5.1→T3, 5.2→T1+T4 (snapshot), 5.3→T5, 5.4→T2+T8, 5.5→T2+T7, 5.6→T6, 5.7→T5 (Bugün'den açılır, sekme yok).
- `context.md`'ye besin/kalori bölümü **eklenmiyor** — AI köprüsü kapsamı spec'te değişmedi; plan isteyen AI'a kalori hedefi zaten `goals` ile gidiyor.
- Kritik test çifti: snapshot donması (T4) + kalori reaktivitesi (T8) — biri geçmişi, biri bugünü korur.
- MealKind ile M10 slot editörü arası bağ: `slotId?` şimdiden nullable — plansız kayıt serbest (spec §5.2).
