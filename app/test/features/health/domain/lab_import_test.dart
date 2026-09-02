import 'package:disport/core/result/result.dart';
import 'package:disport/features/health/data/lab_repository.dart';
import 'package:disport/features/health/domain/lab_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tahlil-aktar.md', () {
    test('şema, sözlük ve uydurma yasağını içerir', () {
      final doc = buildLabImportDoc();
      expect(doc, contains('markerId'));
      expect(doc, contains('yyyy-MM-dd'));
      expect(doc, contains('uydurma'));
      // Sözlüğün tamamı tabloda.
      for (final spec in labMarkerSpecs) {
        expect(doc, contains('| ${spec.id} |'));
      }
    });
  });

  group('ayrıştırma', () {
    test('geçerli belge satırlara çözülür, panel sözlükten gelir', () {
      final result = parseLabImport('''
        {"date": "2026-08-15", "results": [
          {"markerId": "glucose", "value": 95, "unit": "mg/dL",
           "refLow": 70, "refHigh": 100},
          {"markerId": "vitamin_d", "value": 24.5, "unit": "ng/mL"}
        ]}
      ''');

      final rows = (result as Ok<List<LabImportRow>>).value;
      expect(rows, hasLength(2));
      expect(rows.first.marker, 'Açlık Glukozu');
      expect(rows.first.panel, LabPanels.metabolic);
      expect(rows.first.refLow, 70);
      expect(rows.first.suspect, isFalse);
      expect(rows.last.date, '2026-08-15');
    });

    test('bozuk JSON yapıştırılabilir hata döner', () {
      final result = parseLabImport('bu json değil');
      expect(result.isOk, isFalse);
      expect(
        (result as Err<List<LabImportRow>>).failure.message,
        contains('JSON'),
      );
    });

    test('eksik alan hatası alan yolunu söyler — AI düzeltebilsin', () {
      final result = parseLabImport(
        '{"date": "2026-08-15", "results": [{"markerId": "glucose"}]}',
      );
      expect(
        (result as Err<List<LabImportRow>>).failure.message,
        contains('results[0].value'),
      );
    });
  });

  group('şüphe sınıflandırması', () {
    test('sözlükte olmayan kimlik şüpheli ama reddedilmez', () {
      final rows =
          (parseLabImport(
                    '{"date": "2026-08-15", "results": ['
                    '{"markerLabel": "Çinko", "value": 90, "unit": "µg/dL"}]}',
                  )
                  as Ok<List<LabImportRow>>)
              .value;
      expect(rows.single.marker, 'Çinko');
      expect(rows.single.suspicions, [LabSuspicion.unknownMarker]);
      expect(rows.single.panel, LabPanels.other);
    });

    test('beklenmeyen birim şüpheli', () {
      final rows =
          (parseLabImport(
                    '{"date": "2026-08-15", "results": ['
                    '{"markerId": "glucose", "value": 5.2, "unit": "mmol/L"}]}',
                  )
                  as Ok<List<LabImportRow>>)
              .value;
      expect(
        rows.single.suspicions,
        contains(LabSuspicion.unexpectedUnit),
      );
    });

    test('fizyolojik aralığın 10 katı dışı şüpheli', () {
      final rows =
          (parseLabImport(
                    '{"date": "2026-08-15", "results": ['
                    '{"markerId": "glucose", "value": 9500, "unit": "mg/dL"}]}',
                  )
                  as Ok<List<LabImportRow>>)
              .value;
      expect(
        rows.single.suspicions,
        contains(LabSuspicion.implausibleValue),
      );
    });

    test('düzeltilen satır güvenilir sayılır', () {
      const row = LabImportRow(
        marker: 'X',
        value: 1,
        unit: 'u',
        date: '2026-08-15',
        panel: LabPanels.other,
        suspicions: [LabSuspicion.unknownMarker],
      );
      expect(row.copyWith(value: 2).suspect, isFalse);
    });
  });
}
