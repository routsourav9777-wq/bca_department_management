import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../auth/login_screen.dart';
import '../hod/hod_dashboard_screen.dart';
import '../faculty/faculty_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Timer? _timer;

  // ============================================================
  // ACTUAL DEVICE AUTHENTICATION
  // ============================================================

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _authenticationInProgress = false;
  bool _checkingAccount = false;
  bool _showUnlockScreen = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer(
      const Duration(seconds: 3),
      _checkLoginStatus,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // CHECK FIREBASE LOGIN SESSION
  // ============================================================

  Future<void> _checkLoginStatus() async {
    if (!mounted) return;

    if (_checkingAccount) return;

    final FirebaseAuth auth = FirebaseAuth.instance;

    final User? user = auth.currentUser;

    debugPrint(
      '=========================================',
    );

    debugPrint(
      'Firebase current user: ${user?.email}',
    );

    debugPrint(
      'Firebase UID: ${user?.uid}',
    );

    debugPrint(
      '=========================================',
    );

    // ==========================================================
    // NO FIREBASE USER
    // ==========================================================

    if (user == null) {
      debugPrint(
        'No Firebase session found.',
      );

      _openLogin();
      return;
    }

    // ==========================================================
    // GET EMAIL
    // ==========================================================

    final String email = (user.email ?? '').trim().toLowerCase();

    if (email.isEmpty) {
      debugPrint(
        'Firebase user has no email.',
      );

      await auth.signOut();

      if (!mounted) return;

      _openLogin();
      return;
    }

    // ==========================================================
    // PHONE AUTHENTICATION
    // ==========================================================

    final bool authenticated = await _authenticateWithPhone();

    if (!mounted) return;

    // ==========================================================
    // AUTHENTICATION FAILED / CANCELLED
    // ==========================================================

    if (!authenticated) {
      setState(() {
        _showUnlockScreen = true;
      });

      return;
    }

    // ==========================================================
    // AUTHENTICATION SUCCESS
    // ==========================================================

    setState(() {
      _showUnlockScreen = false;
    });

    await _openCorrectDashboard(
      user,
      email,
    );
  }

  // ============================================================
  // ACTUAL PHONE AUTHENTICATION
  // ============================================================

  Future<bool> _authenticateWithPhone() async {
    if (_authenticationInProgress) {
      return false;
    }

    _authenticationInProgress = true;

    try {
      // ========================================================
      // CHECK DEVICE SUPPORT
      // ========================================================

      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

      debugPrint(
        'Device supported: $isDeviceSupported',
      );

      debugPrint(
        'Can check biometrics: $canCheckBiometrics',
      );

      // ========================================================
      // DEVICE DOES NOT SUPPORT AUTHENTICATION
      // ========================================================

      if (!isDeviceSupported && !canCheckBiometrics) {
        debugPrint(
          'Device authentication not supported.',
        );

        return false;
      }

      // ========================================================
      // OPEN REAL PHONE AUTHENTICATION
      // ========================================================

      final bool authenticated = await _localAuth.authenticate(
        localizedReason:
            'Use your fingerprint, Face ID, PIN or phone lock to open the BCA Department Management App.',
        options: const AuthenticationOptions(
          // false means:
          // Fingerprint + PIN + Pattern + Passcode
          // can be used according to device support.
          biometricOnly: false,

          // Keep authentication working properly
          // if app goes temporarily into background.
          stickyAuth: true,

          // Allow Android system authentication dialogs.
          useErrorDialogs: true,
        ),
      );

      debugPrint(
        'Phone authentication result: $authenticated',
      );

      return authenticated;
    } catch (e) {
      debugPrint(
        'Phone authentication error: $e',
      );

      return false;
    } finally {
      _authenticationInProgress = false;
    }
  }

  // ============================================================
  // OPEN CORRECT DASHBOARD
  // ============================================================

  Future<void> _openCorrectDashboard(
    User user,
    String email,
  ) async {
    if (_checkingAccount) return;

    _checkingAccount = true;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final FirebaseAuth auth = FirebaseAuth.instance;

      // ========================================================
      // 1. CHECK HOD
      // ========================================================

      debugPrint(
        'Checking HOD account...',
      );

      final QuerySnapshot<Map<String, dynamic>> hodQuery = await firestore
          .collection('hod')
          .where(
            'email',
            isEqualTo: email,
          )
          .limit(1)
          .get();

      if (hodQuery.docs.isNotEmpty) {
        final Map<String, dynamic> data = hodQuery.docs.first.data();

        final String status =
            data['status']?.toString().trim().toLowerCase() ?? '';

        debugPrint(
          'HOD status: $status',
        );

        if (status == 'active') {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HODDashboardScreen(),
            ),
          );

          return;
        }
      }

      // ========================================================
      // 2. CHECK FACULTY
      // ========================================================

      debugPrint(
        'Checking Faculty account...',
      );

      final QuerySnapshot<Map<String, dynamic>> facultyQuery = await firestore
          .collection('faculty')
          .where(
            'email',
            isEqualTo: email,
          )
          .limit(1)
          .get();

      if (facultyQuery.docs.isNotEmpty) {
        final Map<String, dynamic> data = facultyQuery.docs.first.data();

        final String status =
            data['status']?.toString().trim().toLowerCase() ?? '';

        final String role = data['role']?.toString().trim().toLowerCase() ?? '';

        debugPrint(
          'Faculty status: $status',
        );

        debugPrint(
          'Faculty role: $role',
        );

        if (status == 'active' && role == 'faculty') {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const FacultyDashboardScreen(),
            ),
          );

          return;
        }
      }

      // ========================================================
      // 3. CHECK STUDENT
      // ========================================================

      debugPrint(
        'Checking Student account...',
      );

      final QuerySnapshot<Map<String, dynamic>> studentQuery = await firestore
          .collection('students')
          .where(
            'email',
            isEqualTo: email,
          )
          .limit(1)
          .get();

      if (studentQuery.docs.isNotEmpty) {
        final Map<String, dynamic> data = studentQuery.docs.first.data();

        final String status =
            data['status']?.toString().trim().toLowerCase() ?? '';

        debugPrint(
          'Student status: $status',
        );

        // ------------------------------------------------------
        // STUDENT APPROVED
        // ------------------------------------------------------

        if (status == 'approved') {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const StudentDashboardScreen(),
            ),
          );

          return;
        }

        // ------------------------------------------------------
        // STUDENT PENDING
        // ------------------------------------------------------

        if (status == 'pending') {
          await auth.signOut();

          if (!mounted) return;

          _showMessage(
            'Your registration is still pending.\n'
            'Please wait for HOD approval.',
            Colors.orange,
          );

          _openLogin();

          return;
        }

        // ------------------------------------------------------
        // STUDENT REJECTED
        // ------------------------------------------------------

        if (status == 'rejected') {
          await auth.signOut();

          if (!mounted) return;

          _showMessage(
            'Your registration has been rejected by the HOD.',
            Colors.red,
          );

          _openLogin();

          return;
        }

        // ------------------------------------------------------
        // OTHER STUDENT STATUS
        // ------------------------------------------------------

        await auth.signOut();

        if (!mounted) return;

        _showMessage(
          'Your student account is not active.',
          Colors.red,
        );

        _openLogin();

        return;
      }

      // ========================================================
      // ACCOUNT NOT FOUND
      // ========================================================

      debugPrint(
        'No HOD, Faculty or Student account found.',
      );

      await auth.signOut();

      if (!mounted) return;

      _showMessage(
        'Account not authorized for this portal.',
        Colors.red,
      );

      _openLogin();
    } catch (e) {
      // ========================================================
      // FIRESTORE ERROR
      // ========================================================

      debugPrint(
        'Account verification error: $e',
      );

      if (!mounted) return;

      // IMPORTANT:
      // Firebase user ko signOut nahi kar rahe.
      // Session safe rahegi.

      _showFirestoreError();
    } finally {
      _checkingAccount = false;
    }
  }

  // ============================================================
  // OPEN LOGIN
  // ============================================================

  void _openLogin() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  // ============================================================
  // FIRESTORE ERROR
  // ============================================================

  void _showFirestoreError() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.cloud_off,
            size: 50,
            color: Colors.orange,
          ),
          title: const Text(
            'Connection Problem',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Unable to verify your account right now.\n\n'
            'Please check your internet connection and try again.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                _checkLoginStatus();
              },
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'TRY AGAIN',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // AUTHENTICATION REQUIRED
  // ============================================================

  void _showUnlockRequired() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.fingerprint,
            size: 55,
            color: Colors.amber,
          ),
          title: const Text(
            'Authentication Required',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Use your fingerprint, Face ID, PIN or Pattern '
            'to open the BCA Department Management App.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            // ==================================================
            // TRY AGAIN
            // ==================================================

            TextButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  _showUnlockScreen = false;
                });

                _checkLoginStatus();
              },
              icon: const Icon(
                Icons.fingerprint,
              ),
              label: const Text(
                'TRY AGAIN',
              ),
            ),

            // ==================================================
            // LOGIN WITH PASSWORD
            // ==================================================

            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                // User intentionally chooses password login.
                await FirebaseAuth.instance.signOut();

                if (!mounted) return;

                _openLogin();
              },
              child: const Text(
                'LOGIN WITH PASSWORD',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(
    String message,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ======================================================
          // COLLEGE BACKGROUND
          // ======================================================

          Image.asset(
            "assets/images/college_building.jpeg",
            fit: BoxFit.cover,
          ),

          // ======================================================
          // DARK OVERLAY
          // ======================================================

          Container(
            color: Colors.black.withValues(
              alpha: .70,
            ),
          ),

          // ======================================================
          // MAIN CONTENT
          // ======================================================

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ==================================================
                    // LOGO
                    // ==================================================

                    Hero(
                      tag: "logo",
                      child: Image.asset(
                        "assets/images/department_logo.png",
                        width: 170,
                      ),
                    ),

                    const SizedBox(
                      height: 35,
                    ),

                    // ==================================================
                    // WELCOME
                    // ==================================================

                    const Text(
                      "WELCOME TO",
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // DEPARTMENT
                    // ==================================================

                    const Text(
                      "Department of\nComputer Applications",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // COLLEGE
                    // ==================================================

                    const Text(
                      "Salipur Autonomous College",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 19,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Text(
                      "Salipur, Odisha",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(
                      height: 40,
                    ),

                    // ==================================================
                    // TAGLINE
                    // ==================================================

                    const Text(
                      "Empowering Future IT Professionals",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(
                      height: 50,
                    ),

                    // ==================================================
                    // AUTHENTICATION ICON / LOADING
                    // ==================================================

                    if (_showUnlockScreen)
                      Column(
                        children: [
                          const Icon(
                            Icons.fingerprint,
                            color: Colors.amber,
                            size: 65,
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          const Text(
                            "Authentication Required",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          ElevatedButton.icon(
                            onPressed: _checkLoginStatus,
                            icon: const Icon(
                              Icons.fingerprint,
                            ),
                            label: const Text(
                              "UNLOCK",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  30,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      const CircularProgressIndicator(
                        color: Colors.amber,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ========================================================
          // VERSION
          // ========================================================

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Version 1.0",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
