import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

/// Firebase Messaging background handler.
/// Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('🔔 Background notification received');
    debugPrint('Message ID: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');
  } catch (e) {
    debugPrint(
      '❌ Background notification error: ${e.toString()}',
    );
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;

  // ===============================================================
  // ANDROID NOTIFICATION CHANNEL
  // ===============================================================

  static const String _channelId = 'bca_department_high';

  static const String _channelName = 'BCA Department Notifications';

  static const String _channelDescription =
      'Important notifications from BCA Department';

  // ===============================================================
  // INITIALIZE NOTIFICATION SERVICE
  // ===============================================================

  Future<void> initialize() async {
    if (_initialized) {
      debugPrint(
        'ℹ️ Notification service already initialized.',
      );
      return;
    }

    try {
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '🔔 INITIALIZING NOTIFICATION SERVICE',
      );
      debugPrint(
        '==========================================',
      );

      // -----------------------------------------------------------
      // 1. REQUEST FCM NOTIFICATION PERMISSION
      // -----------------------------------------------------------

      final NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        '🔔 FCM permission status: '
        '${settings.authorizationStatus}',
      );

      // -----------------------------------------------------------
      // 2. INITIALIZE LOCAL NOTIFICATIONS
      // -----------------------------------------------------------

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings(
        'notification_icon',
      );

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );

      debugPrint(
        '✅ Local notifications initialized.',
      );

      // -----------------------------------------------------------
      // 3. CREATE ANDROID NOTIFICATION CHANNEL
      // -----------------------------------------------------------

      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        debugPrint(
          '✅ Android notification channel created.',
        );

        // Android 13+
        await androidPlugin.requestNotificationsPermission();

        debugPrint(
          '✅ Android notification permission requested.',
        );
      }

      // -----------------------------------------------------------
      // 4. FOREGROUND MESSAGE LISTENER
      // -----------------------------------------------------------

      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) async {
          debugPrint(
            '==========================================',
          );
          debugPrint(
            '🔔 FOREGROUND NOTIFICATION RECEIVED',
          );
          debugPrint(
            'Message ID: ${message.messageId}',
          );
          debugPrint(
            'Title: ${message.notification?.title}',
          );
          debugPrint(
            'Body: ${message.notification?.body}',
          );
          debugPrint(
            'Data: ${message.data}',
          );
          debugPrint(
            '==========================================',
          );

          await _showForegroundNotification(
            message,
          );
        },
        onError: (Object error) {
          debugPrint(
            '❌ Foreground notification listener error: '
            '${error.toString()}',
          );
        },
      );

      // -----------------------------------------------------------
      // 5. NOTIFICATION OPENED FROM BACKGROUND
      // -----------------------------------------------------------

      FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) {
          debugPrint(
            '🔔 Notification opened from background.',
          );

          debugPrint(
            'Data: ${message.data}',
          );

          _handleNotificationTap(
            message.data,
          );
        },
        onError: (Object error) {
          debugPrint(
            '❌ Notification opened listener error: '
            '${error.toString()}',
          );
        },
      );

      // -----------------------------------------------------------
      // 6. NOTIFICATION OPENED FROM TERMINATED STATE
      // -----------------------------------------------------------

      final RemoteMessage? initialMessage = await _fcm.getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          '🔔 App opened from terminated notification.',
        );

        debugPrint(
          'Data: ${initialMessage.data}',
        );

        _handleNotificationTap(
          initialMessage.data,
        );
      }

      // -----------------------------------------------------------
      // 7. GET FCM TOKEN
      // -----------------------------------------------------------

      try {
        final String? token = await _fcm.getToken();

        if (token != null && token.isNotEmpty) {
          debugPrint(
            '==========================================',
          );
          debugPrint(
            '🔥 FCM TOKEN:',
          );
          debugPrint(token);
          debugPrint(
            '==========================================',
          );
        } else {
          debugPrint(
            '⚠️ FCM token is null.',
          );
        }
      } catch (e) {
        debugPrint(
          '❌ Unable to get FCM token: '
          '${e.toString()}',
        );
      }

      // -----------------------------------------------------------
      // 8. FCM TOKEN REFRESH LISTENER
      // -----------------------------------------------------------

      _fcm.onTokenRefresh.listen(
        (String newToken) async {
          debugPrint(
            '🔄 FCM token refreshed:',
          );
          debugPrint(newToken);

          await _saveTokenForCurrentUser(
            newToken,
          );
        },
        onError: (Object error) {
          debugPrint(
            '❌ FCM token refresh error: '
            '${error.toString()}',
          );
        },
      );

      _initialized = true;

      debugPrint(
        '==========================================',
      );
      debugPrint(
        '✅ NOTIFICATION SERVICE INITIALIZED',
      );
      debugPrint(
        '==========================================',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '❌ NOTIFICATION SERVICE INITIALIZATION ERROR',
      );
      debugPrint(
        e.toString(),
      );
      debugPrint(
        stackTrace.toString(),
      );
      debugPrint(
        '==========================================',
      );

      // Notification failure should not stop app login.
    }
  }

  // ===============================================================
  // REGISTER LOGGED-IN USER
  // ===============================================================

  Future<void> registerLoggedInUser() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint(
          '⚠️ Notification registration skipped.',
        );
        debugPrint(
          'No logged-in Firebase user.',
        );
        return;
      }

      debugPrint(
        '==========================================',
      );
      debugPrint(
        '🔔 REGISTERING LOGGED-IN USER',
      );
      debugPrint(
        'Email: ${user.email}',
      );
      debugPrint(
        'UID: ${user.uid}',
      );
      debugPrint(
        '==========================================',
      );

      // Make sure notification service is initialized.
      if (!_initialized) {
        await initialize();
      }

      // -----------------------------------------------------------
      // GET FCM TOKEN
      // -----------------------------------------------------------

      final String? token = await _fcm.getToken();

      if (token == null || token.isEmpty) {
        debugPrint(
          '❌ FCM token is null/empty.',
        );
        return;
      }

      debugPrint(
        '🔥 USER FCM TOKEN:',
      );
      debugPrint(token);

      // -----------------------------------------------------------
      // SAVE TOKEN
      // -----------------------------------------------------------

      await _saveTokenForCurrentUser(
        token,
      );

      // -----------------------------------------------------------
      // SUBSCRIBE USER TO ROLE TOPICS
      // -----------------------------------------------------------

      await _subscribeUserToRoleTopics(
        user,
      );

      debugPrint(
        '==========================================',
      );
      debugPrint(
        '✅ NOTIFICATION REGISTRATION COMPLETED',
      );
      debugPrint(
        '==========================================',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '❌ NOTIFICATION REGISTRATION ERROR',
      );
      debugPrint(
        e.toString(),
      );
      debugPrint(
        stackTrace.toString(),
      );
      debugPrint(
        '==========================================',
      );
    }
  }

  // ===============================================================
  // SAVE FCM TOKEN TO FIRESTORE
  // ===============================================================

  Future<void> _saveTokenForCurrentUser(
    String token,
  ) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint(
          '⚠️ Cannot save FCM token.',
        );
        return;
      }

      await _firestore.collection('fcm_tokens').doc(user.uid).set(
        {
          'uid': user.uid,
          'email': user.email,
          'token': token,
          'platform': defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint(
        '✅ FCM token saved to Firestore.',
      );
    } catch (e) {
      debugPrint(
        '❌ Error saving FCM token: '
        '${e.toString()}',
      );
    }
  }

  // ===============================================================
  // SUBSCRIBE USER TO ROLE TOPICS
  // ===============================================================

  Future<void> _subscribeUserToRoleTopics(
    User user,
  ) async {
    try {
      debugPrint(
        '🔎 Checking user role...',
      );

      // ===========================================================
      // HOD
      // ===========================================================

      final QuerySnapshot<Map<String, dynamic>> hodSnapshot = await _firestore
          .collection('hod')
          .where(
            'email',
            isEqualTo: user.email,
          )
          .limit(1)
          .get();

      if (hodSnapshot.docs.isNotEmpty) {
        final Map<String, dynamic> data = hodSnapshot.docs.first.data();

        final String status = data['status']?.toString().toLowerCase() ?? '';

        debugPrint(
          'HOD status: $status',
        );

        if (status == 'active') {
          await _fcm.subscribeToTopic(
            'hod',
          );

          await _fcm.subscribeToTopic(
            'all_staff',
          );

          debugPrint(
            '==========================================',
          );
          debugPrint(
            '✅ HOD TOPIC SUBSCRIBED',
          );
          debugPrint(
            'Topic: hod',
          );
          debugPrint(
            'Topic: all_staff',
          );
          debugPrint(
            '==========================================',
          );

          return;
        }
      }

      // ===========================================================
      // FACULTY
      // ===========================================================

      final QuerySnapshot<Map<String, dynamic>> facultySnapshot =
          await _firestore
              .collection('faculty')
              .where(
                'email',
                isEqualTo: user.email,
              )
              .limit(1)
              .get();

      if (facultySnapshot.docs.isNotEmpty) {
        final Map<String, dynamic> data = facultySnapshot.docs.first.data();

        final String status = data['status']?.toString().toLowerCase() ?? '';

        final String role = data['role']?.toString().toLowerCase() ?? '';

        debugPrint(
          'Faculty status: $status',
        );

        debugPrint(
          'Faculty role: $role',
        );

        if (status == 'active' && role == 'faculty') {
          await _fcm.subscribeToTopic(
            'faculty',
          );

          await _fcm.subscribeToTopic(
            'all_staff',
          );

          debugPrint(
            '==========================================',
          );
          debugPrint(
            '✅ FACULTY TOPIC SUBSCRIBED',
          );
          debugPrint(
            'Topic: faculty',
          );
          debugPrint(
            'Topic: all_staff',
          );
          debugPrint(
            '==========================================',
          );

          return;
        }
      }

      // ===========================================================
      // STUDENT
      // ===========================================================

      final QuerySnapshot<Map<String, dynamic>> studentSnapshot =
          await _firestore
              .collection('students')
              .where(
                'email',
                isEqualTo: user.email,
              )
              .limit(1)
              .get();

      if (studentSnapshot.docs.isNotEmpty) {
        final Map<String, dynamic> data = studentSnapshot.docs.first.data();

        final String status = data['status']?.toString().toLowerCase() ?? '';

        final String? semester = data['semester']?.toString();

        debugPrint(
          'Student status: $status',
        );

        if (status == 'approved') {
          await _fcm.subscribeToTopic(
            'all_students',
          );

          debugPrint(
            '✅ Topic subscribed: all_students',
          );

          if (semester != null && semester.isNotEmpty) {
            final String semesterTopic =
                'semester_${semester.toLowerCase().replaceAll(' ', '_')}';

            await _fcm.subscribeToTopic(
              semesterTopic,
            );

            debugPrint(
              '✅ Semester topic subscribed: '
              '$semesterTopic',
            );
          }

          debugPrint(
            '==========================================',
          );
          debugPrint(
            '✅ STUDENT TOPIC SUBSCRIBED',
          );
          debugPrint(
            '==========================================',
          );

          return;
        }
      }

      debugPrint(
        '⚠️ No active HOD/faculty or approved student found.',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Topic subscription error: '
        '${e.toString()}',
      );
      debugPrint(
        stackTrace.toString(),
      );
    }
  }

  // ===============================================================
  // SHOW FOREGROUND NOTIFICATION
  // ===============================================================

  Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    try {
      final RemoteNotification? notification = message.notification;

      final String title = notification?.title ??
          message.data['title']?.toString() ??
          'BCA Department';

      final String body = notification?.body ??
          message.data['body']?.toString() ??
          'You have a new notification.';

      // -----------------------------------------------------------
      // ANDROID NOTIFICATION DETAILS
      // -----------------------------------------------------------

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: 'notification_icon',
        playSound: true,
        enableVibration: true,
        ticker: 'BCA Department',
      );

      // IMPORTANT:
      // NotificationDetails must NOT be const here.
      // androidDetails is a runtime/reference value.

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      final int notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

      await _localNotifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: message.data['route']?.toString() ?? '',
      );

      debugPrint(
        '✅ Foreground local notification shown.',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Failed to show foreground notification: '
        '${e.toString()}',
      );
      debugPrint(
        stackTrace.toString(),
      );
    }
  }

  // ===============================================================
  // LOCAL NOTIFICATION TAP
  // ===============================================================

  void _onLocalNotificationTap(
    NotificationResponse response,
  ) {
    debugPrint(
      '🔔 Local notification tapped.',
    );

    debugPrint(
      'Payload: ${response.payload}',
    );

    final String? payload = response.payload;

    if (payload != null && payload.isNotEmpty) {
      _handleRoute(payload);
    }
  }

  // ===============================================================
  // HANDLE FCM NOTIFICATION TAP
  // ===============================================================

  void _handleNotificationTap(
    Map<String, dynamic> data,
  ) {
    try {
      final String? route = data['route']?.toString();

      if (route == null || route.isEmpty) {
        debugPrint(
          '⚠️ Notification has no route.',
        );
        return;
      }

      _handleRoute(route);
    } catch (e) {
      debugPrint(
        '❌ Notification tap handling error: '
        '${e.toString()}',
      );
    }
  }

  // ===============================================================
  // HANDLE ROUTE
  // ===============================================================

  void _handleRoute(
    String route,
  ) {
    debugPrint(
      '📍 Notification route: $route',
    );

    // Navigation can be connected here later.
    //
    // Example:
    //
    // if (route == 'pending_students') {
    //   navigatorKey.currentState?.push(
    //     MaterialPageRoute(
    //       builder: (_) =>
    //           const PendingStudentsScreen(),
    //     ),
    //   );
    // }
  }

  // ===============================================================
  // MANUAL TOPIC SUBSCRIBE
  // ===============================================================

  Future<void> subscribeToTopic(
    String topic,
  ) async {
    try {
      await _fcm.subscribeToTopic(
        topic,
      );

      debugPrint(
        '✅ Subscribed to topic: $topic',
      );
    } catch (e) {
      debugPrint(
        '❌ Failed to subscribe to topic '
        '$topic: ${e.toString()}',
      );
    }
  }

  // ===============================================================
  // MANUAL TOPIC UNSUBSCRIBE
  // ===============================================================

  Future<void> unsubscribeFromTopic(
    String topic,
  ) async {
    try {
      await _fcm.unsubscribeFromTopic(
        topic,
      );

      debugPrint(
        '✅ Unsubscribed from topic: $topic',
      );
    } catch (e) {
      debugPrint(
        '❌ Failed to unsubscribe from topic '
        '$topic: ${e.toString()}',
      );
    }
  }

  // ===============================================================
  // GET FCM TOKEN
  // ===============================================================

  Future<String?> getToken() async {
    try {
      final String? token = await _fcm.getToken();

      debugPrint(
        '🔥 Current FCM Token:',
      );
      debugPrint(token);

      return token;
    } catch (e) {
      debugPrint(
        '❌ Failed to get FCM token: '
        '${e.toString()}',
      );

      return null;
    }
  }

  // ===============================================================
  // DELETE FCM TOKEN
  // ===============================================================

  Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();

      debugPrint(
        '🗑️ FCM token deleted.',
      );
    } catch (e) {
      debugPrint(
        '❌ Failed to delete FCM token: '
        '${e.toString()}',
      );
    }
  }
}
