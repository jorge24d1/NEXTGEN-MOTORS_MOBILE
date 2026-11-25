import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'sesion_movil.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile_app/services/api_service.dart';

@pragma('vm:entry-point')
Future<void> _mensajeEnSegundoPlano(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  static StreamSubscription<RemoteMessage>? _enPrimerPlano;

  static void _informar(String mensaje) {
    if (kDebugMode) debugPrint('[Notificaciones] $mensaje');
  }

  static Future<void> activar(SesionMovil sesion) async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_mensajeEnSegundoPlano);
      await NotificationService()._initNotifications(sesion);
    } catch (error) {
      _informar('No se pudieron activar las notificaciones (${error.runtimeType}).');
    }
  }

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  Future<void> _initNotifications(SesionMovil sesion) async {
    // 0. Configurar Notificaciones Locales
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS (opcional, pero recomendada)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(initializationSettings);

    // 0.1 Crear Canal de Notificaciones (Importante para segundo plano en Android)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'Notificaciones Importantes', // title
      description:
          'Este canal se usa para notificaciones importantes.', // description
      importance: Importance.max,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
    }

    // 1. Pedir permiso (Firebase)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {

      // 2. Obtener Token
      final token = await _firebaseMessaging.getToken();
      if (token == null) {
        _informar('Firebase aún no ha asignado un token al dispositivo.');
      } else if (sesion.esCliente && sesion.vigente) {
        await _apiService.sendFcmToken(sesion, token);
        _informar('Dispositivo registrado en el servidor.');
      }

      // 3. Escuchar en primer plano
      _enPrimerPlano ??= FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _informar('Mensaje recibido en primer plano.');
        // Mostrar notificación local
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel', // id del canal
                'Notificaciones Importantes', // nombre del canal
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
              iOS: DarwinNotificationDetails(),
            ),
          );
        }
      });
    } else {
      _informar('Permiso del dispositivo: ${settings.authorizationStatus.name}.');
    }
  }
}
