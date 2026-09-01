import 'package:disport/app/theme/app_theme.dart';
import 'package:disport/core/utils/l10n_ext.dart';
import 'package:disport/features/catalog/application/catalog_providers.dart';
import 'package:disport/features/catalog/domain/exercise.dart';
import 'package:disport/features/catalog/presentation/exercise_detail_screen.dart';
import 'package:disport/features/medical/application/medical_providers.dart';
import 'package:disport/features/medical/domain/medical_fact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../exercise_fixtures.dart';

void main() {
  final pushup = fixtureExercise(
    id: 'incline_pushup',
    nameTr: 'Eğimli Şınav',
    nameEn: 'Incline Push-Up',
    regressions: ['wall_pushup'],
    progressions: ['pushup'],
  );

  final variants = {
    'wall_pushup': fixtureExercise(
      id: 'wall_pushup',
      nameTr: 'Duvar Şınavı',
      nameEn: 'Wall Push-Up',
      difficulty: 1,
    ),
    'pushup': fixtureExercise(
      id: 'pushup',
      nameTr: 'Nizami Şınav',
      nameEn: 'Push-Up',
      difficulty: 4,
    ),
  };

  Widget wrap({Exercise? exercise, bool withVariants = true}) => ProviderScope(
    overrides: [
      exerciseByIdProvider(
        'incline_pushup',
      ).overrideWith((ref) async => exercise),
      exerciseVariantsProvider(
        'incline_pushup',
      ).overrideWith((ref) async => withVariants ? variants : {}),
      // v3: NASIL sekmesi kısıt eşleşmesi için medikal kayıtları
      // okuyor; Drift akışına bağlanmasın.
      medicalFactsProvider.overrideWith(
        (ref) => Stream.value(const <MedicalFact>[]),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: const ExerciseDetailScreen(exerciseId: 'incline_pushup'),
    ),
  );

  testWidgets('dört sekme başlığı görünür', (tester) async {
    await tester.pumpWidget(wrap(exercise: pushup));
    await tester.pumpAndSettle();

    expect(find.text('Incline Push-Up (Eğimli Şınav)'), findsOneWidget);
    for (final tab in [
      'Adımlar',
      'Hatalar',
      'Varyantlar',
      'Güvenlik',
    ]) {
      expect(find.text(tab), findsOneWidget, reason: tab);
    }
  });

  testWidgets('nasıl yapılır sekmesi adımları numaralı gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(exercise: pushup));
    await tester.pumpAndSettle();

    expect(find.text('Başlangıç'), findsOneWidget);

    // Görünen sekmenin listesini kaydır. `scrollUntilVisible` burada
    // kullanılamıyor: dört sekmenin dördü de kaydırılabilir olduğu için
    // hangisini kaydıracağını bilemiyor.
    final list = find.byType(ListView).first;

    await tester.drag(list, const Offset(0, -400));
    await tester.pumpAndSettle();

    // Adımlar numaralandırılmış olarak listeleniyor.
    expect(find.text('Birinci adım.'), findsOneWidget);
    expect(find.text('Üçüncü adım.'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await tester.drag(list, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Nefes ve tempo'), findsOneWidget);
    expect(find.text('İnerken al, çıkarken ver.'), findsOneWidget);
  });

  testWidgets('hata sekmesi hata, neden ve düzeltmeyi birlikte verir', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(exercise: pushup));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hatalar'));
    await tester.pumpAndSettle();

    expect(find.text('Kalça düşüyor'), findsOneWidget);
    expect(find.text('Neden sorun'), findsNWidgets(2));
    expect(find.text('Düzeltmesi'), findsNWidgets(2));
    expect(find.text('Bel yüklenir.'), findsOneWidget);
    expect(find.text('Karnı sık.'), findsOneWidget);
  });

  testWidgets('varyant sekmesi id yerine okunabilir ad gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(exercise: pushup));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Varyantlar'));
    await tester.pumpAndSettle();

    expect(find.text('Duvar Şınavı'), findsOneWidget);
    expect(find.text('Nizami Şınav'), findsOneWidget);
    expect(find.text('wall_pushup'), findsNothing);
    expect(find.text('Zorluk 1/5'), findsOneWidget);
  });

  testWidgets('güvenlik sekmesi uyarıyı ve sorumluluk notunu gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(exercise: pushup));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Güvenlik'));
    await tester.pumpAndSettle();

    expect(find.text('Ağrı hissedersen dur.'), findsOneWidget);
    expect(find.textContaining('hekim ya da fizyoterapist'), findsOneWidget);
  });

  testWidgets('varyantı olmayan hareket boş durum gösterir', (tester) async {
    final plain = fixtureExercise(
      id: 'incline_pushup',
      nameTr: 'Eğimli Şınav',
      nameEn: 'Incline Push-Up',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exerciseByIdProvider(
            'incline_pushup',
          ).overrideWith((ref) async => plain),
          exerciseVariantsProvider(
            'incline_pushup',
          ).overrideWith((ref) async => const <String, Exercise>{}),
          medicalFactsProvider.overrideWith(
            (ref) => Stream.value(const <MedicalFact>[]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: const ExerciseDetailScreen(exerciseId: 'incline_pushup'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Varyantlar'));
    await tester.pumpAndSettle();

    expect(find.text('Varyant tanımlı değil'), findsOneWidget);
  });

  testWidgets('hareket bulunamazsa açıklayıcı boş durum', (tester) async {
    await tester.pumpWidget(wrap(exercise: null));
    await tester.pumpAndSettle();

    expect(find.text('Hareket bulunamadı'), findsOneWidget);
  });
}
