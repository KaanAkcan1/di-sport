/// Medikal gerçeğin türü.
enum MedicalFactKind {
  /// Kronik durum — insülin direnci, hipertansiyon.
  condition,

  /// Tarihli doktor teşhisi (v3.1 §7). Kimlikliyse (`conditionId`)
  /// check-up ve kısıt motorlarına condition gibi girer; aynı kimlikli
  /// condition varsa yenisi açılmaz, mevcut kayıt teşhise dönüştürülür.
  diagnosis,

  /// Hareket kısıtı — diz hassasiyeti, bel fıtığı. Plan doğrulaması ve
  /// hareket detayındaki güvenlik vurgusu bunları okur.
  restriction,

  /// Besin alerjisi/intoleransı.
  allergy,

  /// Kan grubu — tek kayıt beklenir.
  bloodType;

  static MedicalFactKind fromName(String name) =>
      MedicalFactKind.values.firstWhere(
        (kind) => kind.name == name,
        orElse: () => throw ArgumentError.value(
          name,
          'kind',
          // l10n-exempt: geliştiriciye giden hata metni.
          'bilinmeyen medikal tür; beklenen: '
              '${MedicalFactKind.values.map((k) => k.name).join(' | ')}',
        ),
      );
}

/// Tek bir medikal gerçek.
class MedicalFact {
  const MedicalFact({
    required this.id,
    required this.kind,
    required this.label,
    this.note,
    this.conditionId,
    this.factDate,
  });

  final String id;
  final MedicalFactKind kind;

  /// Kullanıcıya görünen metin — serbest.
  final String label;

  final String? note;

  /// Öneri çipinden geldiyse makine kimliği; serbest kayıtta null.
  /// Check-up motoru yalnız kimlikli kayıtları koşullarda kullanır.
  final String? conditionId;

  /// `yyyy-MM-dd` — bugün yalnız teşhiste dolu (v3.1 §7).
  final String? factDate;
}

/// Öneri çipleri — makine kimlikli yaygın değerler.
///
/// Etiketler ARB'den gelir (`conditionId` üzerinden eşlenir); burada
/// yalnız kimlik + tür var. Serbest ekleme her zaman mümkün, o zaman
/// kimlik boş kalır.
const conditionSuggestions = <(MedicalFactKind, String)>[
  (MedicalFactKind.condition, 'insulinResistance'),
  (MedicalFactKind.condition, 'type2Diabetes'),
  (MedicalFactKind.condition, 'hypertension'),
  (MedicalFactKind.condition, 'thyroid'),
  (MedicalFactKind.restriction, 'kneeIssue'),
  (MedicalFactKind.restriction, 'backIssue'),
  (MedicalFactKind.restriction, 'shoulderIssue'),
  (MedicalFactKind.allergy, 'lactose'),
  (MedicalFactKind.allergy, 'gluten'),
  (MedicalFactKind.allergy, 'nuts'),
];
