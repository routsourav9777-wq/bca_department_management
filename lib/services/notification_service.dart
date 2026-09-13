import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

/// ============================================================
/// FIREBASE MESSAGING BACKGROUND HANDLER
/// ============================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('==========================================');
    debugPrint('🔔 BACKGROUND FCM NOTIFICATION RECEIVED');
    debugPrint('Message ID: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');
    debugPrint('==========================================');
  } catch (e, stackTrace) {
    debugPrint('❌ Background notification error: $e');
    debugPrint(stackTrace.toString());
  }
}

/// ============================================================
/// NOTIFICATION SERVICE
/// ============================================================

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
      NotificationService._();

  final FirebaseMessaging _fcm =
      FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin
      _localNotifications =
      FlutterLocalNotificationsPlugin();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _initialized = false;

  /// ==========================================================
  /// ANDROID NOTIFICATION CHANNEL
  /// ==========================================================

  static const String _channelId =
      'bca_department_high';

  static const String _channelName =
      'BCA Department Notifications';

  static const String _channelDescription =
      'Important notifications from BCA Department';

  /// ==========================================================
  /// INITIALIZE
  /// ==========================================================

  Future<void> initialize() async {
    if (_initialized) {
      debugPrint(
        'ℹ️ Notification service already initialized.',
      );
      return;
    }

    try {
      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '🔔 INITIALIZING NOTIFICATION SERVICE',
      );
      debugPrint(
        '==========================================',
      );

      /// ------------------------------------------------------
      /// REQUEST FCM PERMISSION
      /// ------------------------------------------------------

      final NotificationSettings settings =
          await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        '🔔 FCM permission status: '
        '${settings.authorizationStatus}',
      );

      /// ------------------------------------------------------
      /// ANDROID INITIALIZATION
      /// ------------------------------------------------------

      const AndroidInitializationSettings
          androidSettings =
          AndroidInitializationSettings(
        'notification_icon',
      );

      /// ------------------------------------------------------
      /// IOS INITIALIZATION
      /// ------------------------------------------------------

      const DarwinInitializationSettings
          iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      /// ------------------------------------------------------
      /// INITIALIZATION SETTINGS
      /// ------------------------------------------------------

      const InitializationSettings
          initializationSettings =
          InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      /// ------------------------------------------------------
      /// INITIALIZE LOCAL NOTIFICATIONS
      /// ------------------------------------------------------

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse:
            _onLocalNotificationTap,
      );

      debugPrint(
        '✅ Local notifications initialized.',
      );

      /// ------------------------------------------------------
      /// ANDROID NOTIFICATION CHANNEL
      /// ------------------------------------------------------

      final AndroidFlutterLocalNotificationsPlugin?
          androidPlugin =
          _localNotifications
              .resolvePlatformSpecificImplementation<
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

        /// Android 13+
        await androidPlugin
            .requestNotificationsPermission();

        debugPrint(
          '✅ Android notification permission requested.',
        );
      }

      /// ------------------------------------------------------
      /// FOREGROUND MESSAGE
      /// ------------------------------------------------------

      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) async {
          debugPrint('');
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
            '$error',
          );
        },
      );

      /// ------------------------------------------------------
      /// BACKGROUND NOTIFICATION TAP
      /// ------------------------------------------------------

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
            '$error',
          );
        },
      );

      /// ------------------------------------------------------
      /// TERMINATED APP NOTIFICATION TAP
      /// ------------------------------------------------------

      final RemoteMessage? initialMessage =
          await _fcm.getInitialMessage();

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

      /// ------------------------------------------------------
      /// GET FCM TOKEN
      /// ------------------------------------------------------

      try {
        final String? token =
            await _fcm.getToken();

        if (token != null &&
            token.isNotEmpty) {
          debugPrint('');
          debugPrint(
            '==========================================',
          );
          debugPrint(
            '🔥 FCM TOKEN',
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
          '❌ Unable to get FCM token: $e',
        );
      }

      /// ------------------------------------------------------
      /// TOKEN REFRESH
      /// ------------------------------------------------------

      _fcm.onTokenRefresh.listen(
        (String newToken) async {
          debugPrint('');
          debugPrint(
            '==========================================',
          );
          debugPrint(
            '🔄 FCM TOKEN REFRESHED',
          );
          debugPrint(newToken);
          debugPrint(
            '==========================================',
          );

          await _saveTokenForCurrentUser(
            newToken,
          );

          /// Re-register topics after token refresh.
          final User? user =
              FirebaseAuth.instance.currentUser;

          if (user != null) {
            await _subscribeUserToRoleTopics(
              user,
            );
          }
        },
        onError: (Object error) {
          debugPrint(
            '❌ FCM token refresh error: $error',
          );
        },
      );

      _initialized = true;

      debugPrint('');
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
      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '❌ NOTIFICATION SERVICE INITIALIZATION ERROR',
      );
      debugPrint(e.toString());
      debugPrint(
        stackTrace.toString(),
      );
      debugPrint(
        '==========================================',
      );
    }
  }

  /// ==========================================================
  /// REGISTER LOGGED-IN USER
  /// ==========================================================

  Future<void> registerLoggedInUser() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint(
          '⚠️ Notification registration skipped.',
        );
        debugPrint(
          'No logged-in Firebase user.',
        );
        return;
      }

      debugPrint('');
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

      /// Initialize if required.
      if (!_initialized) {
        await initialize();
      }

      /// ------------------------------------------------------
      /// GET TOKEN
      /// ------------------------------------------------------

      final String? token =
          await _fcm.getToken();

      if (token == null ||
          token.isEmpty) {
        debugPrint(
          '❌ FCM token is null/empty.',
        );
        return;
      }

      debugPrint('');
      debugPrint(
        '🔥 USER FCM TOKEN:',
      );
      debugPrint(token);

      /// ------------------------------------------------------
      /// SAVE TOKEN
      /// ------------------------------------------------------

      await _saveTokenForCurrentUser(
        token,
      );

      /// ------------------------------------------------------
      /// SUBSCRIBE ROLE TOPICS
      /// ------------------------------------------------------

      await _subscribeUserToRoleTopics(
        user,
      );

      debugPrint('');
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
      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '❌ NOTIFICATION REGISTRATION ERROR',
      );
      debugPrint(e.toString());
      debugPrint(
        stackTrace.toString(),
      );
      debugPrint(
        '==========================================',
      );
    }
  }

  /// ==========================================================
  /// SAVE TOKEN
  /// ==========================================================

  Future<void> _saveTokenForCurrentUser(
    String token,
  ) async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        debugPrint(
          '⚠️ Cannot save FCM token.',
        );
        return;
      }

      await _firestore
          .collection('fcm_tokens')
          .doc(user.uid)
          .set(
        {
          'uid': user.uid,
          'email': user.email,
          'token': token,
          'platform':
              defaultTargetPlatform.name,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      debugPrint(
        '✅ FCM token saved to Firestore.',
      );
    } catch (e) {
      debugPrint(
        '❌ Error saving FCM token: $e',
      );
    }
  }

  /// ==========================================================
  /// SUBSCRIBE USER TO ROLE TOPICS
  /// ==========================================================

  Future<void> _subscribeUserToRoleTopics(
    User user,
  ) async {
    try {
      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '🔎 CHECKING USER ROLE',
      );
      debugPrint(
        '==========================================',
      );

      /// ======================================================
      /// HOD
      /// ======================================================

      final QuerySnapshot<
              Map<String, dynamic>>
          hodSnapshot =
          await _firestore
              .collection('hod')
              .where(
                'email',
                isEqualTo: user.email,
              )
              .limit(1)
              .get();

      if (hodSnapshot.docs.isNotEmpty) {
        final Map<String, dynamic> data =
            hodSnapshot.docs.first.data();

        final String status =
            data['status']
                    ?.toString()
                    .toLowerCase() ??
                '';

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
            '✅ HOD subscribed to: hod',
          );

          debugPrint(
            '✅ HOD subscribed to: all_staff',
          );

          return;
        }
      }

      /// ======================================================
      /// FACULTY
      /// ======================================================

      final QuerySnapshot<
              Map<String, dynamic>>
          facultySnapshot =
          await _firestore
              .collection('faculty')
              .where(
                'email',
                isEqualTo: user.email,
              )
              .limit(1)
              .get();

      if (facultySnapshot.docs.isNotEmpty) {
        final Map<String, dynamic> data =
            facultySnapshot.docs.first.data();

        final String status =
            data['status']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final String role =
            data['role']
                    ?.toString()
                    .toLowerCase() ??
                '';

        debugPrint(
          'Faculty status: $status',
        );

        debugPrint(
          'Faculty role: $role',
        );

        if (status == 'active' &&
            role == 'faculty') {
          await _fcm.subscribeToTopic(
            'faculty',
          );

          await _fcm.subscribeToTopic(
            'all_staff',
          );

          debugPrint(
            '✅ Faculty subscribed to: faculty',
          );

          debugPrint(
            '✅ Faculty subscribed to: all_staff',
          );

          return;
        }
      }

      /// ======================================================
      /// STUDENT
      /// ======================================================

      final QuerySnapshot<
              Map<String, dynamic>>
          studentSnapshot =
          await _firestore
              .collection('students')
              .where(
                'email',
                isEqualTo: user.email,
              )
              .limit(1)
              .get();

      if (studentSnapshot.docs.isNotEmpty) {
        final Map<String, dynamic> data =
            studentSnapshot.docs.first.data();

        final String status =
            data['status']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final String rawSemester =
            data['semester']
                    ?.toString()
                    .trim() ??
                '';

        debugPrint('');
        debugPrint(
          '==========================================',
        );
        debugPrint(
          '🎓 STUDENT NOTIFICATION REGISTRATION',
        );
        debugPrint(
          'Student email: ${user.email}',
        );
        debugPrint(
          'Student status: $status',
        );
        debugPrint(
          'Student semester: $rawSemester',
        );
        debugPrint(
          '==========================================',
        );

        /// ----------------------------------------------------
        /// ONLY APPROVED STUDENTS
        /// ----------------------------------------------------

        if (status != 'approved') {
          debugPrint(
            '⚠️ Student is not approved.',
          );

          return;
        }

        /// ----------------------------------------------------
        /// ALL STUDENTS TOPIC
        /// ----------------------------------------------------

        await _fcm.subscribeToTopic(
          'all_students',
        );

        debugPrint(
          '✅ Student subscribed to: all_students',
        );

        /// ----------------------------------------------------
        /// SEMESTER TOPIC
        /// ----------------------------------------------------
        ///
        /// Supported examples:
        ///
        /// 1
        /// 2
        /// 3
        /// 4
        /// 5
        /// 6
        ///
        /// 1st Semester
        /// 2nd Semester
        /// 3rd Semester
        /// 4th Semester
        /// 5th Semester
        /// 6th Semester
        ///
        /// Semester 1
        /// Semester 2
        /// etc.
        ///
        /// Result:
        ///
        /// semester_1
        /// semester_2
        /// semester_3
        /// ...
        /// semester_6
        /// ----------------------------------------------------

        final RegExp semesterRegex =
            RegExp(r'[1-6]');

        final RegExpMatch? match =
            semesterRegex.firstMatch(
          rawSemester,
        );

        if (match == null) {
          debugPrint('');
          debugPrint(
            '❌ SEMESTER NUMBER NOT FOUND',
          );
          debugPrint(
            'Firestore semester value: $rawSemester',
          );

          return;
        }

        final String semesterNumber =
            match.group(0)!;

        final String semesterTopic =
            'semester_$semesterNumber';

        debugPrint('');
        debugPrint(
          '🔎 Semester detected: $semesterNumber',
        );

        debugPrint(
          '🔎 Topic to subscribe: $semesterTopic',
        );

        /// ----------------------------------------------------
        /// SUBSCRIBE SEMESTER TOPIC
        /// ----------------------------------------------------

        await _fcm.subscribeToTopic(
          semesterTopic,
        );

        debugPrint('');
        debugPrint(
          '==========================================',
        );
        debugPrint(
          '✅ STUDENT SEMESTER TOPIC SUBSCRIBED',
        );
        debugPrint(
          'Student semester: $rawSemester',
        );
        debugPrint(
          'FCM topic: $semesterTopic',
        );
        debugPrint(
          '==========================================',
        );

        return;
      }

      /// ======================================================
      /// NO USER ROLE FOUND
      /// ======================================================

      debugPrint(
        '⚠️ No active HOD/faculty or approved student found.',
      );
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '❌ TOPIC SUBSCRIPTION ERROR',
      );
      debugPrint(e.toString());
      debugPrint(
        stackTrace.toString(),
      );
      debugPrint(
        '==========================================',
      );
    }
  }

  /// ==========================================================
  /// FOREGROUND NOTIFICATION
  /// ==========================================================

  Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    try {
      final RemoteNotification? notification =
          message.notification;

      final String title =
          notification?.title ??
              message.data['title']
                  ?.toString() ??
              'BCA Department';

      final String body =
          notification?.body ??
              message.data['body']
                  ?.toString() ??
              'You have a new notification.';

      const AndroidNotificationDetails
          androidDetails =
          AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription:
            _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: 'notification_icon',
        playSound: true,
        enableVibration: true,
        ticker: 'BCA Department',
      );

      const DarwinNotificationDetails
          iosDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails
          notificationDetails =
          NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final int notificationId =
          DateTime.now()
              .millisecondsSinceEpoch
              .remainder(2147483647);

      await _localNotifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails:
            notificationDetails,
        payload:
            message.data['route']
                    ?.toString() ??
                '',
      );

      debugPrint(
        '✅ Foreground local notification shown.',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Failed to show foreground notification: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );
    }
  }

  /// ==========================================================
  /// LOCAL NOTIFICATION TAP
  /// ==========================================================

  void _onLocalNotificationTap(
    NotificationResponse response,
  ) {
    debugPrint(
      '🔔 Local notification tapped.',
    );

    debugPrint(
      'Payload: ${response.payload}',
    );

    final String? payload =
        response.payload;

    if (payload != null &&
        payload.isNotEmpty) {
      _handleRoute(payload);
    }
  }

  /// ==========================================================
  /// FCM NOTIFICATION TAP
  /// ==========================================================

  void _handleNotificationTap(
    Map<String, dynamic> data,
  ) {
    try {
      final String? route =
          data['route']?.toString();

      if (route == null ||
          route.isEmpty) {
        debugPrint(
          '⚠️ Notification has no route.',
        );

        return;
      }

      _handleRoute(route);
    } catch (e) {
      debugPrint(
        '❌ Notification tap handling error: $e',
      );
    }
  }

  /// ==========================================================
  /// HANDLE ROUTE
  /// ==========================================================

  void _handleRoute(
    String route,
  ) {
    debugPrint(
      '📍 Notification route: $route',
    );

    /// Future me Navigator logic add kar sakte ho.
  }

  /// ==========================================================
  /// MANUAL SUBSCRIBE
  /// ==========================================================

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
        '$topic: $e',
      );
    }
  }

  /// ==========================================================
  /// UNSUBSCRIBE
  /// ==========================================================

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
        '$topic: $e',
      );
    }
  }

  /// ==========================================================
  /// GET TOKEN
  /// ==========================================================

  Future<String?> getToken() async {
    try {
      final String? token =
          await _fcm.getToken();

      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '🔥 CURRENT FCM TOKEN',
      );
      debugPrint(token);
      debugPrint(
        '==========================================',
      );

      return token;
    } catch (e) {
      debugPrint(
        '❌ Failed to get FCM token: $e',
      );

      return null;
    }
  }

  /// ==========================================================
  /// DELETE TOKEN
  /// ==========================================================

  Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();

      debugPrint(
        '🗑️ FCM token deleted.',
      );
    } catch (e) {
      debugPrint(
        '❌ Failed to delete FCM token: $e',
      );
    }
  }
}