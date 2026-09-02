import 'package:disport/app/app.dart';
import 'package:disport/features/medical/data/medical_repository.dart';
import 'package:disport/features/medical/domain/medical_fact.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'medical_providers.g.dart';

@riverpod
MedicalRepository medicalRepository(Ref ref) =>
    MedicalRepository(ref.watch(appDatabaseProvider));

@riverpod
Stream<List<MedicalFact>> medicalFacts(Ref ref) =>
    ref.watch(medicalRepositoryProvider).watchAll();
