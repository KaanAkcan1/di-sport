import 'package:disport/core/utils/turkish_text.dart';

/// Ekipman türü — tipli, sabit liste.
///
/// **Neden enum:** v1'de ekipman serbest metindi (`'vücut ağırlığı'`,
/// `'dambıl'`) ve karşılaştırma katlanmış dizgiyle yapılıyordu. Bu iki
/// sorun doğurdu: "bu hareket ne gerektiriyor" rozeti üretilemiyordu
/// (dizgi neyi temsil ettiğini bilmiyor), ve bir yazım farkı filtreyi
/// sessizce bozuyordu — nitekim bozdu da (`bodyweightEquipment` ham
/// yazıldığı için hiç eşleşmiyordu, testte yakalandı).
///
/// Değerler [free-exercise-db](https://github.com/yuhonas/free-exercise-db)
/// kaynağının 13 değerlik sabit listesinden alındı; katalog içeriği de
/// oradan geliyor, ikisinin aynı sözlüğü konuşması eşleme işini
/// tamamen ortadan kaldırıyor.
enum EquipmentKind {
  bodyOnly,
  barbell,
  dumbbell,
  kettlebell,
  cable,
  machine,
  bands,
  medicineBall,
  exerciseBall,
  foamRoll,
  ezCurlBar,

  /// Kaynakta karşılığı olmayan ya da eve özgü eşya (sandalye, duvar,
  /// basamak). Envanter kontrolünden **muaf** — herkeste bir sandalye
  /// var, kullanıcıyı "sandalyem yok" demeye zorlamak saçma olurdu.
  other,

  /// Hiçbir şey gerekmiyor. `bodyOnly`'den farkı yok gibi görünüyor ama
  /// kaynak ikisini ayırıyor ve veriyi kaynağa sadık tutmak, ileride
  /// yeniden içe aktarırken eşleme kaybı yaşamamak demek.
  none;

  /// free-exercise-db değerinden enum'a.
  ///
  /// Bilinmeyen değer [other]'a düşüyor, hata fırlatmıyor: kaynak
  /// güncellenip yeni bir ekipman türü eklendiğinde içe aktarma
  /// tamamen durmamalı.
  static EquipmentKind fromSource(String? raw) => switch (raw?.trim()) {
    'body only' => bodyOnly,
    'barbell' => barbell,
    'dumbbell' => dumbbell,
    'kettlebells' || 'kettlebell' => kettlebell,
    'cable' => cable,
    'machine' => machine,
    'bands' => bands,
    'medicine ball' => medicineBall,
    'exercise ball' => exerciseBall,
    'foam roll' => foamRoll,
    'e-z curl bar' => ezCurlBar,
    null || '' => none,
    _ => other,
  };

  /// JSON'daki enum adından — `catalog.json` bu adları yazıyor.
  ///
  /// Eski Türkçe değerler [fromLegacyTr] ile çevriliyor; burada
  /// bilinmeyen ad **hata veriyor** çünkü kendi ürettiğimiz dosyada
  /// tanımadığımız bir değer bir yazım hatasıdır, sessizce
  /// `other`'a düşmesi o hatayı gizlerdi.
  static EquipmentKind fromName(String name) => EquipmentKind.values
      .firstWhere(
        (kind) => kind.name == name,
        orElse: () => throw ArgumentError.value(
          name,
          'equipment',
          // l10n-exempt: geliştiriciye giden hata metni.
          'bilinmeyen ekipman; beklenen: '
              '${EquipmentKind.values.map((k) => k.name).join(' | ')}',
        ),
      );

  /// v9 envanterindeki Türkçe etiketten enum'a — göç için.
  ///
  /// Ev eşyaları ([other]) bilinçli olarak envanter kontrolünden muaf
  /// bir türe düşüyor: kullanıcıdan "sandalyem var" diye işaretlemesini
  /// beklemek gereksiz sürtünme.
  static EquipmentKind fromLegacyTr(String label) =>
      switch (TurkishText.fold(label)) {
        'vucut agirligi' => bodyOnly,
        'yok' || 'ekipman yok' => none,
        'dambil' => dumbbell,
        'barbell' || 'halter' => barbell,
        'kettlebell' => kettlebell,
        'direnc bandi' => bands,
        'kablo' || 'kablo makinesi' => cable,
        // Kardiyo makineleri tek türde toplanıyor: koşu bandı ile
        // kondisyon bisikleti envanter açısından aynı soruyu soruyor
        // ("salonda makine var mı"), ayrı türler filtreye bir şey
        // katmazdı.
        'kosu bandi' || 'kondisyon bisikleti' || 'makine' => machine,
        'saglik topu' => medicineBall,
        'pilates topu' => exerciseBall,
        'kopuk rulo' => foamRoll,
        _ => other,
      };

  /// Envanterde işaretlenmesi anlamlı mı.
  ///
  /// Vücut ağırlığı herkeste var, ev eşyası da öyle sayılıyor; ikisi
  /// için onay kutusu göstermek kullanıcıya hiçbir şey sormaz.
  bool get needsInventory =>
      this != bodyOnly && this != none && this != other;
}
