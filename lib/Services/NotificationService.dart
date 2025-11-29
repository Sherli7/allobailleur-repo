import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
    'high_importance_channel', // id
    'Notifications Importantes', // title
    description:
        'Ce canal est utilisé pour les notifications importantes.', // description
    importance: Importance.max,
  );

  Future<void> initialize() async {
    if (kIsWeb) return; // Skip initialization on web

    // 1. Demander la permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('Permission de notification accordée');
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('Permission de notification provisoire accordée');
      }
    } else {
      if (kDebugMode) {
        print('Permission de notification refusée');
      }
      return;
    }

    // 2. Initialiser les notifications locales
    // Assurez-vous que l'icône @mipmap/ic_launcher existe, sinon utilisez une autre icône par défaut
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Gérer le clic sur la notification locale
        if (kDebugMode) {
          print("Notification cliquée: ${details.payload}");
        }
      },
    );

    // Créer le canal Android pour les notifications haute priorité
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Activer l'affichage des notifications en premier plan pour iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Écouter les messages au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Afficher une notification locale si on est sur Android (iOS le fait automatiquement si configuré ci-dessus)
      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: android
                  .smallIcon, // Utilise l'icône de la notification push ou celle par défaut
              // Autres personnalisations visuelles possibles ici
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // 4. Obtenir le token FCM
    String? token = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print("FCM Token: $token");
    }
    // Le token est maintenant géré par AuthService pour être stocké dans Supabase
  }

  // Handler pour les messages en arrière-plan
  static Future<void> backgroundHandler(RemoteMessage message) async {
    if (kIsWeb) return;
    if (kDebugMode) {
      print("Message en arrière-plan reçu: ${message.messageId}");
    }
  }

  /// Envoie une notification push via Cloud Functions
  /// (nécessite une fonction déployée sur Firebase 'sendNotification')
  Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (fcmToken.isEmpty) return;

    try {
      // Appel à la Cloud Function
      // Si vous n'avez pas encore de Cloud Functions, vous pouvez aussi utiliser l'API FCM directement
      // (mais déconseillé de mettre la clé serveur dans l'app mobile pour sécurité)

      /* 
       * Pour ce prototype sans backend, nous ne pouvons pas appeler l'API FCM HTTP v1 directement
       * car cela nécessite une authentification OAuth2 côté serveur.
       * 
       * La méthode recommandée est d'avoir une Cloud Function 'sendNotification'.
       * Voici comment on l'appellerait :
       */

      final HttpsCallable callable =
          _functions.httpsCallable('sendNotification');
      await callable.call(<String, dynamic>{
        'token': fcmToken,
        'title': title,
        'body': body,
        'data': data ?? {},
      });

      debugPrint("Notification envoyée à $fcmToken");
    } catch (e) {
      debugPrint("Erreur lors de l'envoi de la notification: $e");
    }
  }
}
