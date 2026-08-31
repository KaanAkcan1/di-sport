import 'package:disport/features/ai_bridge/domain/ports.dart';
import 'package:disport/features/settings/data/weekly_windows_repository.dart';

/// `settings` feature'ının `ai_bridge`'e verdiği uygunluk kaynağı.
class AvailabilitySourceAdapter implements AvailabilitySource {
  const AvailabilitySourceAdapter(this._windows);

  final WeeklyWindowsRepository _windows;

  @override
  Future<List<WindowDump>> windows() async {
    final all = await _windows.all();
    return [
      for (final window in all)
        WindowDump(
          weekday: window.weekday,
          startTime: window.startTime,
          endTime: window.endTime,
          kind: window.kind,
          label: window.label,
        ),
    ];
  }
}
