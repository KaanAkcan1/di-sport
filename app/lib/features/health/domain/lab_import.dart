/// Tahlil AI aktarımı (v3 §9.5) — plan köprüsünün ikizi, saf katman.
///
/// Uygulama PDF görmez: `tahlil-aktar.md` belgesi + PDF herhangi bir AI
/// sohbetine verilir, dönen JSON buraya yapıştırılır. Ayrıştırma
/// hataları AI'a geri yapıştırılabilir olmalı (`JsonReader` ilkesi).
library;

import 'dart:convert';

import 'package:disport/core/result/result.dart';
import 'package:disport/features/ai_bridge/domain/json_reader.dart';
import 'package:disport/features/health/data/lab_tables.dart';

/// Bilinen bir tahlil belirteci: kimlik, ad, beklenen birim, panel ve
/// fizyolojik aralık (şüphe eşiği için — referans aralığı değil).
class LabMarkerSpec {
  const LabMarkerSpec({
    required this.id,
    required this.label,
    required this.unit,
    required this.panel,
    required this.typicalLow,
    required this.typicalHigh,
  });

  final String id;
  final String label;
  final String unit;
  final String panel;

  /// Fizyolojik akla yatkınlık bandı. `10×` dışına düşen değer şüpheli
  /// işaretlenir — AI birim karıştırmış ya da satır kaydırmış olabilir.
  final double typicalLow;
  final double typicalHigh;
}

/// Sözlük — AI yalnız bu kimlikleri kullanmalı; bilinmeyen kimlik
/// şüpheli sayılır ama reddedilmez (laboratuvarlar sözlükte olmayan
/// şeyler de ölçer).
// l10n-exempt: belirteç adları tıbbi terim — laboratuvar kâğıdıyla
// birebir aynı görünmeliler, arayüz diline göre değişmezler.
const labMarkerSpecs = <LabMarkerSpec>[
  // l10n-exempt: tıbbi terim.
  LabMarkerSpec(id: 'glucose', label: 'Açlık Glukozu', unit: 'mg/dL', panel: LabPanels.metabolic, typicalLow: 50, typicalHigh: 400),
  LabMarkerSpec(id: 'hba1c', label: 'HbA1c', unit: '%', panel: LabPanels.metabolic, typicalLow: 3, typicalHigh: 15),
  // l10n-exempt: tıbbi terim.
  LabMarkerSpec(id: 'insulin', label: 'Açlık İnsülini', unit: 'µU/mL', panel: LabPanels.metabolic, typicalLow: 1, typicalHigh: 100),
  LabMarkerSpec(id: 'creatinine', label: 'Kreatinin', unit: 'mg/dL', panel: LabPanels.metabolic, typicalLow: 0.2, typicalHigh: 5),
  LabMarkerSpec(id: 'alt', label: 'ALT', unit: 'U/L', panel: LabPanels.liver, typicalLow: 3, typicalHigh: 500),
  LabMarkerSpec(id: 'ast', label: 'AST', unit: 'U/L', panel: LabPanels.liver, typicalLow: 3, typicalHigh: 500),
  LabMarkerSpec(id: 'ggt', label: 'GGT', unit: 'U/L', panel: LabPanels.liver, typicalLow: 3, typicalHigh: 500),
  LabMarkerSpec(id: 'tsh', label: 'TSH', unit: 'µIU/mL', panel: LabPanels.thyroid, typicalLow: 0.01, typicalHigh: 50),
  LabMarkerSpec(id: 'vitamin_d', label: 'D Vitamini (25-OH)', unit: 'ng/mL', panel: LabPanels.vitamin, typicalLow: 3, typicalHigh: 150),
  LabMarkerSpec(id: 'vitamin_b12', label: 'B12 Vitamini', unit: 'pg/mL', panel: LabPanels.vitamin, typicalLow: 50, typicalHigh: 2000),
  LabMarkerSpec(id: 'ferritin', label: 'Ferritin', unit: 'ng/mL', panel: LabPanels.other, typicalLow: 2, typicalHigh: 1500),
  LabMarkerSpec(id: 'total_cholesterol', label: 'Total Kolesterol', unit: 'mg/dL', panel: LabPanels.lipid, typicalLow: 80, typicalHigh: 500),
  LabMarkerSpec(id: 'ldl', label: 'LDL', unit: 'mg/dL', panel: LabPanels.lipid, typicalLow: 30, typicalHigh: 400),
  LabMarkerSpec(id: 'hdl', label: 'HDL', unit: 'mg/dL', panel: LabPanels.lipid, typicalLow: 10, typicalHigh: 150),
  LabMarkerSpec(id: 'triglycerides', label: 'Trigliserid', unit: 'mg/dL', panel: LabPanels.lipid, typicalLow: 20, typicalHigh: 2000),
];

LabMarkerSpec? specOf(String id) {
  for (final spec in labMarkerSpecs) {
    if (spec.id == id) return spec;
  }
  return null;
}

/// AI'a verilecek `tahlil-aktar.md` belgesi.
String buildLabImportDoc() {
  final buffer = StringBuffer('''
# Tahlil aktarımı — di@sport

Ekteki tahlil belgesindeki (PDF/görsel) değerleri aşağıdaki JSON
biçiminde çıkar. **Yalnız belgede gördüğün değerleri yaz; uydurma,
tahmin etme, tamamlama.** Belgede olmayan alanı boş bırak.

## Kurallar

- `markerId` aşağıdaki sözlükten seçilir. Sözlükte yoksa `markerId`
  yerine `markerLabel` alanına belgedeki adı olduğu gibi yaz.
- `unit` belgede yazan birimdir; **çevirme**. Sözlükteki birimden
  farklıysa yine belgedekini yaz.
- `date` zorunlu ve `yyyy-MM-dd` biçiminde (raporun tarihi).
- `refLow`/`refHigh` belgede referans aralığı yazıyorsa eklenir.
- Sayılar nokta ondalıklı yazılır (12.5).

## JSON şeması

```json
{
  "date": "2026-08-15",
  "results": [
    {"markerId": "glucose", "value": 95, "unit": "mg/dL",
     "refLow": 70, "refHigh": 100},
    {"markerLabel": "Belgede yazan ad", "value": 1.2, "unit": "..."}
  ]
}
```

## Belirteç sözlüğü

| markerId | Ad | Beklenen birim |
|---|---|---|
''');
  for (final spec in labMarkerSpecs) {
    buffer.writeln('| ${spec.id} | ${spec.label} | ${spec.unit} |');
  }
  buffer.writeln(
    // l10n-exempt: AI belgesinin metni — arayüz metni değil.
    '\nYalnız JSON döndür; açıklama metni ekleme.',
  );
  return buffer.toString();
}

/// Şüphe nedenleri — önizlemede amber satırın açıklaması.
enum LabSuspicion { unknownMarker, unexpectedUnit, implausibleValue }

/// Ayrıştırılmış tek sonuç satırı.
class LabImportRow {
  const LabImportRow({
    required this.marker,
    required this.value,
    required this.unit,
    required this.date,
    required this.panel,
    this.refLow,
    this.refHigh,
    this.suspicions = const [],
  });

  /// Ekranda ve kayıtta görünen ad (sözlük etiketi ya da belgedeki ad).
  final String marker;

  final double value;
  final String unit;
  final String date;
  final String panel;
  final double? refLow;
  final double? refHigh;
  final List<LabSuspicion> suspicions;

  bool get suspect => suspicions.isNotEmpty;

  LabImportRow copyWith({double? value, String? unit, String? marker}) =>
      LabImportRow(
        marker: marker ?? this.marker,
        value: value ?? this.value,
        unit: unit ?? this.unit,
        date: date,
        panel: panel,
        refLow: refLow,
        refHigh: refHigh,
        // Düzeltilen satır güvenilir sayılır: kullanıcı baktı ve yazdı.
        suspicions: const [],
      );
}

/// Yapıştırılan JSON'u satırlara çevirir.
///
/// Hata mesajları alan yolunu taşır — kullanıcı mesajı AI'a geri
/// yapıştırıp düzeltilmiş belge isteyebilmeli.
Result<List<LabImportRow>> parseLabImport(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw.trim());
  } on FormatException catch (error) {
    return Err(
      Failure(
        // l10n-exempt: AI'a geri yapıştırılan hata metni.
        message: 'JSON çözülemedi: ${error.message}',
      ),
    );
  }
  final root = JsonReader.root(decoded);

  try {
    final date = root['date'].asString;
    if (DateTime.tryParse(date) == null) {
      return Err(
        // l10n-exempt: AI'a geri yapıştırılan hata metni.
        Failure(message: 'date alanı yyyy-MM-dd olmalı, gelen: $date'),
      );
    }

    final rows = <LabImportRow>[];
    for (final item in root['results'].asList) {
      final markerId = item['markerId'].asStringOrNull;
      final markerLabel = item['markerLabel'].asStringOrNull;
      final value = item['value'].asDouble;
      final unit = item['unit'].asString;

      final spec = markerId == null ? null : specOf(markerId);
      final suspicions = <LabSuspicion>[
        if (spec == null) LabSuspicion.unknownMarker,
        if (spec != null &&
            unit.toLowerCase().replaceAll(' ', '') !=
                spec.unit.toLowerCase().replaceAll(' ', ''))
          LabSuspicion.unexpectedUnit,
        if (spec != null &&
            (value < spec.typicalLow / 10 || value > spec.typicalHigh * 10))
          LabSuspicion.implausibleValue,
      ];

      rows.add(
        LabImportRow(
          marker: spec?.label ?? markerLabel ?? markerId ?? '',
          value: value,
          unit: unit,
          date: item['date'].asStringOrNull ?? date,
          panel: spec?.panel ?? LabPanels.other,
          refLow: item['refLow'].exists ? item['refLow'].asDouble : null,
          refHigh: item['refHigh'].exists ? item['refHigh'].asDouble : null,
          suspicions: suspicions,
        ),
      );
    }

    if (rows.isEmpty) {
      // l10n-exempt: AI'a geri yapıştırılan hata metni.
      return Err(Failure(message: 'results listesi boş.'));
    }
    for (final row in rows) {
      if (row.marker.isEmpty) {
        return Err(
          Failure(
            // l10n-exempt: AI'a geri yapıştırılan hata metni.
            message:
                'Her sonuçta markerId ya da markerLabel bulunmalı.',
          ),
        );
      }
    }
    return Ok(rows);
  } on JsonFieldError catch (error) {
    return Err(Failure(message: error.toString()));
  }
}
