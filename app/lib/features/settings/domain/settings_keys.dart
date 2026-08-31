/// Görünüm ve davranış tercihleri — profil tablosunda saklanan anahtarlar.
///
/// `ProfileKeys`'ten ayrı bir sınıf, çünkü ikisi farklı şeyler:
/// `ProfileKeys` **kullanıcı hakkındaki veriyi** tutuyor (yaş, boy, uyanma
/// saati) ve `context.md` üzerinden AI'a gidiyor. Buradakiler ise
/// uygulamanın nasıl görüneceğine dair tercihler — AI'ı ilgilendirmez,
/// yedeklemede de anlamları farklıdır.
///
/// Ayrıca `ProfileKeys` `ai_bridge/domain` içinde yaşıyor; bir tema
/// tercihini oraya eklemek AI bağlam üreticisinin dosyasını görünüm
/// koduna bağlardı.
abstract final class SettingsKeys {
  /// `'system' | 'dark' | 'light'` — tanımsızsa koyu.
  static const themeMode = 'gorunum.tema';

  /// `'system' | 'tr' | 'en'` — tanımsızsa sistem (M7'de kullanılacak).
  static const locale = 'gorunum.dil';
}
