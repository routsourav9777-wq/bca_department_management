import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/welcome_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint(
      'Firebase initialized successfully.',
    );
  } catch (e) {
    debugPrint(
      'Firebase initialization error: $e',
    );
  }

  /// Register background FCM handler
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  try {
    await NotificationService.instance.initialize();

    debugPrint(
      'Notification service initialized.',
    );
  } catch (e) {
    debugPrint(
      'Notification service error: $e',
    );
  }

  runApp(
    const BCADeptApp(),
  );
}

class BCADeptApp extends StatelessWidget {
  const BCADeptApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const WelcomeScreen(),
    );
  }
}
