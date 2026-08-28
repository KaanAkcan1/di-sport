import 'package:disport/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Uygulamanın gerçek giriş noktası.
///
/// `main.dart` yerine ayrı bir dosyada durmasının nedeni: ileride
/// açılış sırasında yapılacak işler (katalog tohumu — M2, alarm
/// penceresinin kaydırılması — M5) buraya girecek ve `main` tek
/// satır kalacak.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DisportApp()));
}
