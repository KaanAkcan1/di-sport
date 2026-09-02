import 'dart:io';

import 'package:disport/core/notifications/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Bildirime dokunulduğunda taşınan sekme yükü.
///
/// `ValueNotifier` çünkü bildirim geri çağrısı widget ağacının dışından
/// geliyor — uygulama kapalıyken de tetiklenebiliyor. Kabuk bunu
/// dinliyor ve değiştiğinde sekme değiştiriyor.
final pendingNotificationPayload = ValueNotifier<String?>(null);

/// `flutter_local_notifications` üstüne gerçek implementasyon.
class LocalNotificationService implements NotificationService {
  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  var _initialized = false;

  /// Kanal tanımı Android 8+ için zorunlu; önem seviyesi kullanıcının
  /// ayarlarından sonradan düşürülebilir ama yükseltilemez, o yüzden
  /// baştan `high`.
  static const _androidChannel = AndroidNotificationDetails(
    'disport_reminders',
    'Antrenman ve sağlık hatırlatmaları',
    channelDescription:
        'Programdaki öğün ve antrenman saatleri, sabah tartısı, '
        'tahlil vadesi ve plan bitişi.',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _details = NotificationDetails(
    android: _androidChannel,
    iOS: DarwinNotificationDetails(),
  );

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    // Cihazın yerel saat dilimi: `tz.local` varsayılan olarak UTC'dir.
    // Ayarlanmazsa 06:30 alarmı Türkiye'de 09:30'da çalar.
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // İzin ayrı isteniyor (`requestPermissions`); açılışta sormak
          // kullanıcıya neden sorulduğunu anlatma fırsatı bırakmaz.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          pendingNotificationPayload.value = response.payload,
    );

    // Uygulama bildirime dokunularak açıldıysa geri çağrı çalışmaz;
    // başlangıç yükü ayrıca sorulur.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      pendingNotificationPayload.value =
          launch!.notificationResponse?.payload;
    }

    _initialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    await _ensureInitialized();

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<bool> canScheduleExact() async {
    await _ensureInitialized();
    if (!Platform.isAndroid) return true;

    // Sorgulayan çağrı: kullanıcıya hiçbir şey göstermez.
    return await _android?.canScheduleExactNotifications() ?? false;
  }

  @override
  Future<bool> requestExactPermission() async {
    await _ensureInitialized();
    if (!Platform.isAndroid) return true;

    // Bu çağrı sistem ayarları sayfasını açar ve kullanıcı geri
    // dönene kadar sonuç kesinleşmez; döndüğünde durum yeniden
    // sorgulanıyor.
    await _android?.requestExactAlarmsPermission();
    return canScheduleExact();
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> replaceAll(List<PendingReminder> reminders) async {
    await _ensureInitialized();
    await _plugin.cancelAll();

    final mode = await canScheduleExact()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.fireAt, tz.local),
        notificationDetails: _details,
        androidScheduleMode: mode,
        payload: reminder.payload,
      );
    }
  }

  @override
  Future<int> pendingCount() async {
    await _ensureInitialized();
    return (await _plugin.pendingNotificationRequests()).length;
  }
}
