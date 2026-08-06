import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _fcm.getToken();
      // FCM Token initialized for Salipur BCA Push Notifications
      print('FCM Token: $token');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got FCM message in foreground: ${message.notification?.title}');
    });
  }

  // Send Push Notification Topic Broadcast (For HOD)
  Future<void> sendPushNotification({
    required String title,
    required String body,
    required String topic, // e.g., 'all_students', 'faculty', 'semester_1'
  }) async {
    // Triggers Cloud Function / FCM Topic API
    print('Sending Push Notification to topic $topic: $title - $body');
  }

  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }
}
