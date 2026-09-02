import 'package:disport/features/catalog/domain/equipment_impact.dart';
import 'package:disport/features/catalog/domain/equipment_kind.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

import '../exercise_fixtures.dart';

void main() {
  final catalog = [
    // Ekipmansız ev hareketi — her zaman yapılabilir.
    fixtureExercise(id: 'pushup', nameTr: 'Şınav', nameEn: 'Push-Up'),
    // Dambıl isteyen, iki yerde de yapılabilen hareket.
    fixtureExercise(
      id: 'db-press',
      nameTr: 'Dambıl Pres',
      nameEn: 'Dumbbell Press',
      equipment: [EquipmentKind.dumbbell],
      location: ExerciseLocation.both,
    ),
    // Dambıl + bench isteyen salon hareketi.
    fixtureExercise(
      id: 'bench-row',
      nameTr: 'Sehpa Kürek',
      nameEn: 'Bench Row',
      equipment: [EquipmentKind.dumbbell, EquipmentKind.bench],
      location: ExerciseLocation.gym,
    ),
    // Sandalye isteyen ev hareketi (v3: sandalye artık soruluyor).
    fixtureExercise(
      id: 'chair-squat',
      nameTr: 'Sandalyeli Çömelme',
      nameEn: 'Chair Squat',
      equipment: [EquipmentKind.chair],
    ),
  ];

  group('doableCount', () {
    test('boş envanter: yalnız ekipmansızlar', () {
      expect(doableCount(catalog, const {}, ExerciseLocation.home), 1);
    });

    test('dambıl evde iki hareket demek — salon hareketi sayılmaz', () {
      expect(
        doableCount(catalog, {EquipmentKind.dumbbell}, ExerciseLocation.home),
        2, // pushup + db-press (both)
      );
    });

    test('salonda both hareketleri de sayılır', () {
      expect(
        doableCount(
          catalog,
          {EquipmentKind.dumbbell, EquipmentKind.bench},
          ExerciseLocation.gym,
        ),
        2, // db-press + bench-row (pushup evde)
      );
    });
  });

  group('unlockCount', () {
    test('işaret yeni hareketleri sayar, mevcutları saymaz', () {
      expect(
        unlockCount(
          catalog,
          const {},
          ExerciseLocation.home,
          EquipmentKind.dumbbell,
        ),
        1, // db-press; pushup zaten yapılabiliyor
      );
    });

    test('iki ekipmanlı hareket tek işaretle açılmaz', () {
      // bench-row dambıl + sehpa istiyor; yalnız sehpa işaretlemek
      // onu açmaz.
      expect(
        unlockCount(
          catalog,
          const {},
          ExerciseLocation.gym,
          EquipmentKind.bench,
        ),
        0,
      );
      // Dambıl zaten varsa sehpa bench-row'u açar.
      expect(
        unlockCount(
          catalog,
          {EquipmentKind.dumbbell},
          ExerciseLocation.gym,
          EquipmentKind.bench,
        ),
        1,
      );
    });

    test('zaten işaretli ekipman hiçbir şey açmaz', () {
      expect(
        unlockCount(
          catalog,
          {EquipmentKind.dumbbell},
          ExerciseLocation.home,
          EquipmentKind.dumbbell,
        ),
        0,
      );
    });

    test('sandalye ev hareketini açar', () {
      expect(
        unlockCount(
          catalog,
          const {},
          ExerciseLocation.home,
          EquipmentKind.chair,
        ),
        1,
      );
    });
  });
}
