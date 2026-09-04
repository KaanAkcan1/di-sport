# Mimari karar — "Gün kapsayıcıdır" modeli

**Tarih:** 2026-09-04 · **Durum:** Karar verildi ·
**Karar:** Veri dikeylerde kalır; günün kapsayıcılığı **deneyim
katmanında** kurulur (resmileştirilmiş today-port).

## Soru

Kullanıcı modeli: gün tek kapsayıcı olsun — içine öğünler, sporlar,
ilaç/takviyeler yerleşsin; her öğenin içeriği, alarm bayrağı ve
"AI dolduracak mı" bayrağı olsun; düzenleme bu hiyerarşiden yapılsın.

## Bulgular (kod incelemesi + bağımsız ajan review'u)

Mevcut yapı üç katmanda üç farklı cevap veriyor:

- **Plan** zaten gün-kapsayıcı: `plan_days → plan_slots → içerik`
  (öğün kalemleri). Sapmalar: egzersizler güne bağlı (slota değil),
  takviye slot türü yok, alarm tür bazında (slot bazında değil).
- **Gün ekranı** zaten birleştiriyor: `buildDayFlow` plan slotları +
  ilaç dozları + tartıyı tek zaman çizelgesinde topluyor.
- **Tanımlama** dağınık: rutin (öğün davranışları + profil +
  pencereler), takviyeler ve plan üç ayrı dikey; kullanıcı üç ayrı
  ekranda düzenliyor. Kullanıcının şikâyeti gerçek ve buradan doğuyor.

## Karar ve gerekçe

**Kullanıcı modelinin kazançları görünüm katmanında elde edilebilir;
maliyetleri yalnız depolama katmanına taşındığında doğar.**

Kazançlar (teslim edildi): tek yerden görme/düzenleme, tekdüze
alarm + AI bayrakları, tek-kullanıcı çevrimdışı üründe düşük maliyet.

Maliyetler (kaçınıldı):

1. **Kural vs kayıt ikilemi.** "Her salı 06:30" kuraldır, "12 Eylül"
   kayıttır. Kurallar günlere maddileştirilirse "ilaç saatimi
   değiştirdim" onlarca kaydı güncellemek olur ve snapshot ilkesiyle
   (kayıt anında donma) çelişir.
2. **İlaç güvenliği.** İlaçlar plan verisiyle aynı yazma yolunu
   paylaşırsa "AI planını içe al / aşıla" işleminin ilaca
   dokunmaması mimariyle değil dikkatli sorgularla garanti edilir
   hâle gelir. Bugünkü garanti yapısaldır: takviyeler planla hiçbir
   id ilişkisi taşımaz, AI şemasında ilaç türü yoktur, belge "ilaç
   önerisi yasak" sınırını basar.
3. **AI sözleşmesi + göç.** Karma ağaç sözleşmeyi ve dört kapılı
   doğrulamayı tür-bazlı istisnalarla doldurur; 7+ tabloya dokunan
   göç gerekir.

Takviye akışının doğru üçlüsü zaten mevcut ve korunur:
**tanım kuralı** (`supplements`) → **günün çözülmüş dozu**
(`todayDoses`, gün akışında görünür + alarm) → **alım kaydı**
(`supplement_logs`). AI'dan gelen gün verisi ilacı içermez; ilacın
günü uygulamanın kendi kuralından dolar, iki kaynak gün görünümünde
buluşur.

## Bu karardan doğan işler

1. **Today-port resmileştirmesi:** `today/domain`'e tipli akış öğesi
   (tür + içerik özeti + alarm bayrağı + AI-doldurma durumu + kaynak
   düzenleyiciye derin bağlantı) ve port arayüzleri; `day_providers`
   dikeylerin repository'lerine doğrudan inmek yerine adaptörlerden
   beslenir (ai_bridge `LogSource` deseninin ikizi).
2. **Akış satırından düzenlemeye derin bağlantı:** öğün satırı öğün
   şablonuna, doz satırı takviye düzenleyiciye, antrenman plan
   editörüne götürür.
3. **Slot başına alarm bayrağı:** `plan_slots.remind` (null = tür
   varsayılanı).
4. **Geçmiş günlerde doz satırları:** gün akışındaki "yalnız bugün"
   kısıtı gevşetilir (loglardan geriye dönük gösterim).
5. Bağımsız review'un ayrıca bulduğu borçlar (ayrı iş): MealBehaviors
   tek feature'da toplanmalı; CLAUDE.md ai_bridge kuralı gerçeğe
   eşitlenmeli; medical/supplements test açığı kapanmalı.

Kullanıcı modeline geçiş ancak "geçmiş günün tam snapshot'ı" gerçek
bir gereksinim olursa (senkron/denetim izi) yeniden değerlendirilir.
