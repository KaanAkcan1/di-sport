/// Bir takviye ya da ilaç tanımı — saf model.
class Supplement {
  const Supplement({
    required this.id,
    required this.name,
    this.dose = '',
    this.unit = '',
    this.times = const [],
    this.weekdays = const {},
    this.note = '',
  });

  final String id;

  /// Kullanıcının kendi metni — çevrilmez.
  final String name;

  final String dose;
  final String unit;

  /// `HH:mm`, sıralı. Boşsa hatırlatma kurulmaz ama takviye listede
  /// durur: kullanıcı "alıyorum ama saatini ben bilirim" diyebilmeli.
  final List<String> times;

  /// ISO hafta günü (1=Pazartesi … 7=Pazar). **Boş küme = her gün.**
  ///
  /// "Her gün"ü yedi elemanla göstermek de mümkündü ama o zaman
  /// kullanıcı bir günü kaldırdığında "her gün" mü "altı gün" mü
  /// olduğu veriden anlaşılmazdı.
  final Set<int> weekdays;

  final String note;

  /// Bu takviye verilen günde alınmalı mı.
  bool activeOn(DateTime day) =>
      weekdays.isEmpty || weekdays.contains(day.weekday);

  /// Ekranda gösterilen doz metni — "1000 IU", yalnız doz, ya da boş.
  String get doseLabel => [dose, unit].where((p) => p.isNotEmpty).join(' ');

  Supplement copyWith({
    String? name,
    String? dose,
    String? unit,
    List<String>? times,
    Set<int>? weekdays,
    String? note,
  }) => Supplement(
    id: id,
    name: name ?? this.name,
    dose: dose ?? this.dose,
    unit: unit ?? this.unit,
    times: times ?? this.times,
    weekdays: weekdays ?? this.weekdays,
    note: note ?? this.note,
  );
}

/// Bir takviyenin belirli gün ve saatteki durumu.
class SupplementDose {
  const SupplementDose({
    required this.supplement,
    required this.time,
    this.takenAt,
  });

  final Supplement supplement;

  /// Planlanan saat, `HH:mm`.
  final String time;

  /// İşaretlendiği an; `null` ise henüz alınmamış.
  final DateTime? takenAt;

  bool get isTaken => takenAt != null;
}
