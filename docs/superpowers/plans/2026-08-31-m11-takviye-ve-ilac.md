# M11 — Takviye ve İlaç Takibi Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Vitamin/ilaç tanımlama, günlük alım takibi, saatli hatırlatma; Bugün omurgasında takviye satırları.

**Architecture:** Yeni feature `supplements` (domain/data/application/presentation). Plan slotu DEĞİL ayrı tablo — plandan bağımsız yaşar, plan değişince kaybolmaz (spec §7). Alarmlar mevcut `planWindow`'a altıncı bildirim türü olarak girer. M6'nın kullanıcı-tanımlı-veri kalıbı aynen: yerleşik tohum yok, yumuşak silme, geçmiş bozulmaz.

**Tech Stack:** Drift (şema v11) · Riverpod · mevcut reminders altyapısı

**Spec:** `docs/superpowers/specs/2026-08-31-disport-v2-saglikli-yasam.md` §7

## Global Constraints

- **Döngü TDD DEĞİL:** her görevde **kod → testler → `flutter analyze` + `flutter test` → review → commit**.
- Her tabloda `SyncColumns`. Şema v10 → **v11**; `onUpgrade`'e yeni `if (from < 11)` bloğu, eskiler değişmez.
- Metinler ARB'ye (M7 bitmiş olacak): yeni anahtarlar `supplement*` önekiyle iki dilde.
- Ekranlar Stream okur (`IndexedStack` kuralı). Widget testinde Drift yok — provider override.
- Görsel dil: M12 mürekkep dili bileşenleri (`AppSectionLabel`, kıl çizgili listeler).
- Tanım kullanıcının kendi metnidir — takviye adı çevrilmez (tek `name` alanı, `nameTr/nameEn` değil; spec §3.1 kullanıcı metni kuralı `supplements`'ın adına da uygulanır. Spec §7'deki `nameTr · nameEn` taslağı bu kararla daraltıldı: kimsenin vitamini uygulamanın çevirmesi gereken bir metin değil).

## Dosya Haritası

| Dosya | Sorumluluk |
|---|---|
| `app/lib/features/supplements/domain/supplement.dart` | Saf modeller |
| `app/lib/features/supplements/data/supplement_tables.dart` | `Supplements`, `SupplementLogs` Drift tabloları |
| `app/lib/features/supplements/data/supplements_repository.dart` | CRUD + akışlar |
| `app/lib/features/supplements/application/supplement_providers.dart` | Riverpod |
| `app/lib/features/supplements/presentation/supplements_screen.dart` | Liste + ekle/düzenle (Ayarlar'dan girilir) |
| `app/lib/features/supplements/presentation/supplement_form_sheet.dart` | Form |
| `app/lib/core/db/app_database.dart` | Tablolar kaydolur, v11 göçü |
| `app/lib/features/reminders/domain/reminder_planner.dart` | `supplement` bildirim türü |
| `app/lib/features/today/presentation/...` | Omurgada takviye satırları + işaretleme |

---

### Task 1: Şema v11 — tablolar ve göç

**Files:**
- Create: `app/lib/features/supplements/data/supplement_tables.dart`
- Modify: `app/lib/core/db/app_database.dart`
- Test: `app/test/core/db/migration_v11_test.dart`

**Interfaces:**
- Produces:

```dart
class Supplements extends Table with SyncColumns {
  TextColumn get name => text()();            // kullanıcı metni, çevrilmez
  TextColumn get dose => text()();            // "1000", "2" — serbest
  TextColumn get unit => text()();            // "IU", "tablet", "mg"
  TextColumn get timesJson => text()();       // ["08:00","21:30"] HH:mm
  TextColumn get weekdaysJson => text()();    // [1..7] ISO; boş = her gün
  TextColumn get note => text().withDefault(const Constant(''))();
}

class SupplementLogs extends Table with SyncColumns {
  TextColumn get supplementId => text()();
  TextColumn get date => text()();            // yyyy-MM-dd
  TextColumn get time => text()();            // planlanan HH:mm
  DateTimeColumn get takenAt => dateTime().nullable()(); // null = alınmadı
}
```

- [ ] **Step 1: Kodu yaz** — tablolar + `@DriftDatabase(tables: [...])` + `schemaVersion = 11` + göç bloğu:

```dart
        if (from < 11) {
          await m.createTable(supplements);
          await m.createTable(supplementLogs);
        }
```

`dart run build_runner build` çalıştırılır.

- [ ] **Step 2: Testleri yaz** — mevcut göç testi desenine v11 eklenir: v10 dosyası açılır → tablolar oluşur, eski veriler durur; taze kurulum v11 açılır.
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/core/db/`
- [ ] **Step 4: Commit** — `git commit -m "feat: supplements schema v11"`

---

### Task 2: Domain + repository

**Files:**
- Create: `app/lib/features/supplements/domain/supplement.dart`
- Create: `app/lib/features/supplements/data/supplements_repository.dart`
- Test: `app/test/features/supplements/supplements_repository_test.dart` (gerçek bellek-içi DB)

**Interfaces:**
- Produces:

```dart
class Supplement {
  final String id; final String name; final String dose; final String unit;
  final List<String> times;      // HH:mm, sıralı
  final Set<int> weekdays;       // boş küme = her gün
  final String note;
  bool activeOn(DateTime day);   // weekdays kuralı
}

class SupplementsRepository {
  Stream<List<Supplement>> watchAll();               // silinmişler hariç, ada göre
  Future<void> upsert(Supplement s);
  Future<void> softDelete(String id);                // deletedAt damgalanır
  Stream<List<SupplementLogEntry>> watchDay(DateTime day);
  Future<void> markTaken({required String supplementId,
      required DateTime day, required String time, DateTime? takenAt});
  // takenAt null geçilirse işaret kaldırılır (yanlış dokunuş geri alınır)
}
```

- [ ] **Step 1: Kodu yaz** — M6 kalıbı: silme yumuşak, `watchAll` `deletedAt IS NULL` süzer; `markTaken` aynı (supplementId, date, time) için upsert.
- [ ] **Step 2: Testleri yaz** — ekle/oku; yumuşak silme listeden düşürür ama log satırı durur; `markTaken` idempotent; `activeOn` hafta günü süzer; `watchDay` yalnız o günün kayıtlarını verir.
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/supplements/`
- [ ] **Step 4: Commit** — `git commit -m "feat: supplement domain model and repository"`

---

### Task 3: Yönetim ekranı — Ayarlar'dan liste + form

**Files:**
- Create: `presentation/supplements_screen.dart`, `presentation/supplement_form_sheet.dart`
- Modify: `settings_screen.dart` (satır: "Takviye ve ilaçlar")
- Modify: ARB'ler (`supplementTitle`, `supplementAdd`, `supplementDose`, `supplementTimes`, `supplementDeleteWarning`…)
- Test: `app/test/features/supplements/supplements_screen_test.dart`

- [ ] **Step 1: Kodu yaz** — liste `AppSectionLabel` + kıl çizgili satırlar (ad · doz birim · saatler); boş durum `AppEmptyState` ("Takviye ekle — vitamin, ilaç, ne alıyorsan"); form: ad, doz, birim, saat ekle/çıkar (`showTimePicker`), hafta günü çipleri, not. Silme onayı **geçmişin bozulmayacağını söyler** (M6 kalıbı 3): "Geçmiş kayıtların durur, yalnız hatırlatma ve liste kaydı silinir."
- [ ] **Step 2: Testleri yaz** — provider override: liste basar; form doğrulaması (ad boşsa kaydetmez); silme diyaloğu uyarı metnini içerir.
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/supplements/`
- [ ] **Step 4: Commit** — `git commit -m "feat: supplements management screen"`

---

### Task 4: Bugün omurgasına takviye satırları

**Files:**
- Modify: `app/lib/features/today/presentation/today_screen.dart` / `slot_list.dart` (omurga birleşimi)
- Create: `app/lib/features/today/application/today_supplements_provider.dart`
- Test: `app/test/features/today/today_supplements_test.dart`

**Interfaces:**
- Consumes: `SupplementsRepository.watchDay`, `watchAll`
- Produces: omurga satırı — `💊` ikonlu (M12 `slotKindIcon`'a `supplement` girişi eklenir; `SlotKind` enum'una **dokunulmaz**, takviye satırı plan slotu değil ayrı satır türü), saat + ad + doz; dokununca `takenAt` işaretlenir (✓), tekrar dokununca geri alınır

- [ ] **Step 1: Kodu yaz** — günün takviye saatleri plan slotlarıyla **saat sırasına göre harmanlanır**; gün `activeOn` süzgecinden geçer. İşaretleme optimistic: satır anında ✓, yazım arkada.
- [ ] **Step 2: Testleri yaz** — 08:00 takviyesi 07:00 kahvaltısından sonra listelenir; dokunuş `markTaken` çağırır; hafta günü uymayan takviye görünmez.
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/today/`
- [ ] **Step 4: Commit** — `git commit -m "feat: supplement rows in today spine with tap-to-take"`

---

### Task 5: Hatırlatmalar — altıncı bildirim türü

**Files:**
- Modify: `app/lib/features/reminders/domain/reminder_planner.dart` (`ReminderKind.supplement`; determinist id şemasına yeni tür)
- Modify: `app/lib/features/reminders/application/reminder_scheduler.dart` (kaynaklara takviye listesi eklenir)
- Modify: `app/lib/features/reminders/application/reminder_providers.dart` (takviye değişince `rescheduleQuietly` — M6 kuralı: pencere hemen kurulur)
- Test: `app/test/features/reminders/supplement_reminders_test.dart`

**Interfaces:**
- Consumes: `Supplement.times`, `activeOn`
- Produces: `planWindow`'a giren `PlannedNotification(kind: supplement, at: gün+saat, title: ad, body: "doz birim")` — 7 günlük pencere, yasaklı saat penceresi (M6 `weekly_windows`) takviyeye **uygulanmaz** (ilaç saati mesaiye kurban edilmez; bilinçli ayrım, teste yazılır)

- [ ] **Step 1: Kodu yaz** — planner saf kalır: takviye listesi parametre olarak girer; id `hash(kind, supplementId, date, time)` determinist.
- [ ] **Step 2: Testleri yaz** — 2 saatli takviye × 7 gün = 14 bildirim; hafta günü süzgeci; yasaklı pencere takviyeyi **eleMEZ**; determinist id çakışmaz; takviye silinince yeniden kurulan pencerede bildirimi yok.
- [ ] **Step 3: Çalıştır** — `flutter analyze && flutter test test/features/reminders/`
- [ ] **Step 4: Cihaz doğrulaması** — emülatörde takviye ekle → `adb shell dumpsys alarm | grep disport` ile pencere kontrolü (CLAUDE.md tuzağı: Türkçe karakterli ad girme, ASCII test verisi kullan).
- [ ] **Step 5: Commit** — `git commit -m "feat: supplement reminders in 7-day window"`

---

### Task 6: Süpürme + dokümantasyon

- [ ] **Step 1:** `CLAUDE.md` güncelle — feature tablosuna `supplements`, şema tablosuna v11, bilinen boşluklara bir şey eklendiyse yaz.
- [ ] **Step 2:** Tam paket: `flutter analyze && flutter test`; emülatörde uçtan uca: tanımla → Bugün'de gör → işaretle → bildirimi doğrula → sil → geçmişin durduğunu gör.
- [ ] **Step 3:** `git commit -m "docs: record supplements feature in project guide"`

---

## Öz-değerlendirme notları

- Spec §7 kapsaması: tablolar → Task 1 (spec'teki `nameTr/nameEn` yerine tek `name` — gerekçe Global Constraints'te), alarm → Task 5, Bugün kartı → Task 4 (kart değil omurga satırı: M12 taslağında takviye omurgada, spec §7 bu taslakla güncel; "günün kuralları yanında kart" ifadesi taslakla eskidi).
- Yasaklı pencerenin takviyeye uygulanmaması spec'te açık değildi — burada karar verildi ve test ediliyor; review'de işaretlenecek bilinçli sapma.
- v11 numarası spec §2 tablosuyla uyumlu (M11 ikinci sırada yürüyor).


---

## Review düzeltmeleri (2026-08-31) — BAĞLAYICI

1. **[T4] İkon çakışması çözümü.** `SlotKind`'a ve `slotKindIcon`'a dokunulmaz; takviye satırının ikonu `today` feature'ında ayrı sabittir (`supplementIcon = Icons.medication_outlined`). M12'nin "6 tür" testi değişmez.
2. **[T4] SIRADA kuralı.** Takviye satırı spot karta terfi etmez, `nextIndex` hesabına girmez — yalnız satır. Testle sabitlenir.
3. **[T5] Gerçek tipler.** `ReminderKind`/`PlannedNotification` diye tipler yok; gerçek tip `PendingReminder{id, fireAt, title, body, payload}`. Takviye için `ReminderPayloads`'a `supplement` girişi + sekme eşlemesi (Bugün) eklenir. (M7 düzeltmesi 4'ten sonra tür+parametre modeli geçerli.)
4. **[T5] Determinist id.** Yeni şema icat edilmez; mevcut FNV-1a `_idFor(fireAt, 'supplement:id:time')` kullanılır.
5. **[T5] Yasaklı pencere mekanizması somut.** `planWindow` süzgeci birleşik listeye uygulanıyor; muafiyet için takviye adayları **süzgeç sonrası** eklenir ve sıralama/limitlere yeniden sokulur. "İlaç saati mesaiye kurban edilmez" testi bu mekanizmayı sınar.
6. **[T5] Bildirim tercihi.** `notifiableKinds` zaten `'supplement'` içeriyor — takviye hatırlatmaları bu tercihe bağlanır; tercih kapalıysa kurulmaz (bugüne dek işlevsiz anahtar canlanır; yeni anahtar açılmaz).
7. **[T1] Göç testi altyapısı yoktu.** Task 1 genişler: önce göç test altyapısı kurulur (v10 şemasını elle SQL ile oluşturup açan yardımcı), sonra v11 testi yazılır.
8. **[T2] İmza uyumu.** `watchDay(String isoDate)` — mevcut `TodayRepository` deseni; `DateTime` alınmaz.
9. **[öz-değerlendirme] Sıra.** M11 üçüncü sırada yürür (M12→M7→M11); v11 doğru çünkü önündeki iki taş şemaya dokunmuyor.
