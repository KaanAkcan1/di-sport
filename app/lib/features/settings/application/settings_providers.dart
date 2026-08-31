import 'package:disport/app/app.dart';
import 'package:disport/features/settings/data/weekly_windows_repository.dart';
import 'package:disport/features/settings/domain/weekly_window.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

@riverpod
WeeklyWindowsRepository weeklyWindowsRepository(Ref ref) =>
    WeeklyWindowsRepository(ref.watch(appDatabaseProvider));

/// Haftalık mesai ve yasaklı saat pencereleri.
@riverpod
Stream<List<WeeklyWindow>> weeklyWindows(Ref ref) =>
    ref.watch(weeklyWindowsRepositoryProvider).watchAll();
