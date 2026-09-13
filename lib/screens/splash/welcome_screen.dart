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
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // LOCAL AUTHENTICATION
  // ============================================================

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _authenticationInProgress = false;

  bool _checkingAccount = false;

  bool _showUnlockScreen = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _timer = Timer(
      const Duration(seconds: 3),
      _checkLoginStatus,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ============================================================
  // CHECK LOGIN STATUS
  // ============================================================

  Future<void> _checkLoginStatus() async {
    if (!mounted) return;

    if (_checkingAccount) return;

    final User? user = _auth.currentUser;

    debugPrint('');
    debugPrint(
      '==========================================',
    );
    debugPrint(
      '🔐 CHECKING FIREBASE SESSION',
    );
    debugPrint(
      'Email: ${user?.email}',
    );
    debugPrint(
      'UID: ${user?.uid}',
    );
    debugPrint(
      '==========================================',
    );

    // ==========================================================
    // NO USER
    // ==========================================================

    if (user == null) {
      debugPrint(
        'No Firebase session found.',
      );

      _openLogin();

      return;
    }

    // ==========================================================
    // GET UID
    // ==========================================================

    final String uid = user.uid;

    if (uid.trim().isEmpty) {
      debugPrint(
        'Firebase user UID is empty.',
      );

      await _auth.signOut();

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
    // AUTHENTICATION FAILED
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
    );
  }

  // ============================================================
  // PHONE AUTHENTICATION
  // ============================================================

  Future<bool> _authenticateWithPhone() async {
    if (_authenticationInProgress) {
      return false;
    }

    _authenticationInProgress = true;

    try {
      // ========================================================
      // DEVICE SUPPORT
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
      // NO AUTHENTICATION SUPPORT
      // ========================================================

      if (!isDeviceSupported && !canCheckBiometrics) {
        debugPrint(
          'Device authentication not supported.',
        );

        // Device authentication unavailable.
        // Allow the app to continue.
        return true;
      }

      // ========================================================
      // REAL DEVICE AUTHENTICATION
      // ========================================================

      final bool authenticated = await _localAuth.authenticate(
        localizedReason:
            'Use your fingerprint, Face ID, PIN or phone lock to open the BCA Department Management App.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
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
  ) async {
    if (_checkingAccount) return;

    _checkingAccount = true;

    try {
      final String uid = user.uid;

      final String email = (user.email ?? '').trim().toLowerCase();

      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '🔎 CHECKING ACCOUNT USING UID',
      );
      debugPrint(
        'UID: $uid',
      );
      debugPrint(
        'Email: $email',
      );
      debugPrint(
        '==========================================',
      );

      // ========================================================
      // 1. CHECK HOD USING UID
      // ========================================================

      debugPrint(
        'Checking HOD/$uid ...',
      );

      final DocumentSnapshot<Map<String, dynamic>> hodDocument =
          await _firestore.collection('hod').doc(uid).get();

      if (hodDocument.exists) {
        final Map<String, dynamic> data = hodDocument.data() ?? {};

        final String role = data['role']?.toString().trim().toLowerCase() ?? '';

        final String status =
            data['status']?.toString().trim().toLowerCase() ?? '';

        final String department =
            data['department']?.toString().trim().toUpperCase() ?? '';

        debugPrint('');
        debugPrint(
          '========== HOD DATA ==========',
        );
        debugPrint(
          'Role: $role',
        );
        debugPrint(
          'Status: $status',
        );
        debugPrint(
          'Department: $department',
        );
        debugPrint(
          '==============================',
        );

        if (role == 'hod' && status == 'active' && department == 'BCA') {
          debugPrint(
            '✅ HOD account authorized.',
          );

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HODDashboardScreen(),
            ),
          );

          return;
        }
      } else {
        debugPrint(
          'HOD document not found.',
        );
      }

      // ========================================================
      // 2. CHECK FACULTY USING UID
      // ========================================================

      debugPrint(
        'Checking faculty/$uid ...',
      );

      final DocumentSnapshot<Map<String, dynamic>> facultyDocument =
          await _firestore.collection('faculty').doc(uid).get();

      if (facultyDocument.exists) {
        final Map<String, dynamic> data = facultyDocument.data() ?? {};

        final String role = data['role']?.toString().trim().toLowerCase() ?? '';

        final String status =
            data['status']?.toString().trim().toLowerCase() ?? '';

        final String department =
            data['department']?.toString().trim().toUpperCase() ?? '';

        debugPrint('');
        debugPrint(
          '========== FACULTY DATA ==========',
        );
        debugPrint(
          'Role: $role',
        );
        debugPrint(
          'Status: $status',
        );
        debugPrint(
          'Department: $department',
        );
        debugPrint(
          '==================================',
        );

        if (role == 'faculty' && status == 'active' && department == 'BCA') {
          debugPrint(
            '✅ Faculty account authorized.',
          );

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const FacultyDashboardScreen(),
            ),
          );

          return;
        }
      } else {
        debugPrint(
          'Faculty document not found.',
        );
      }

      // ========================================================
      // 3. CHECK STUDENT USING UID
      // ========================================================

      debugPrint(
        'Checking students/$uid ...',
      );

      final DocumentSnapshot<Map<String, dynamic>> studentDocument =
          await _firestore.collection('students').doc(uid).get();

      if (studentDocument.exists) {
        final Map<String, dynamic> data = studentDocument.data() ?? {};

        final String role = data['role']?.toString().trim().toLowerCase() ?? '';

        final String status =
            data['status']?.toString().trim().toLowerCase() ?? '';

        final String department =
            data['department']?.toString().trim().toUpperCase() ?? '';

        final String semester = data['semester']?.toString().trim() ?? '';

        debugPrint('');
        debugPrint(
          '========== STUDENT DATA ==========',
        );
        debugPrint(
          'Role: $role',
        );
        debugPrint(
          'Status: $status',
        );
        debugPrint(
          'Department: $department',
        );
        debugPrint(
          'Semester: $semester',
        );
        debugPrint(
          '==================================',
        );

        // ======================================================
        // STUDENT APPROVED
        // ======================================================

        if (role == 'student' && department == 'BCA' && status == 'approved') {
          debugPrint(
            '✅ Student account authorized.',
          );

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const StudentDashboardScreen(),
            ),
          );

          return;
        }

        // ======================================================
        // STUDENT PENDING
        // ======================================================

        if (status == 'pending') {
          debugPrint(
            '⏳ Student account pending.',
          );

          await _auth.signOut();

          if (!mounted) return;

          _showMessage(
            'Your registration is still pending.\n'
            'Please wait for HOD approval.',
            Colors.orange,
          );

          _openLogin();

          return;
        }

        // ======================================================
        // STUDENT REJECTED
        // ======================================================

        if (status == 'rejected') {
          debugPrint(
            '❌ Student account rejected.',
          );

          await _auth.signOut();

          if (!mounted) return;

          _showMessage(
            'Your registration has been rejected by the HOD.',
            Colors.red,
          );

          _openLogin();

          return;
        }

        // ======================================================
        // INVALID STUDENT STATUS
        // ======================================================

        await _auth.signOut();

        if (!mounted) return;

        _showMessage(
          'Your student account is not active.',
          Colors.red,
        );

        _openLogin();

        return;
      } else {
        debugPrint(
          'Student document not found.',
        );
      }

      // ========================================================
      // ACCOUNT NOT FOUND
      // ========================================================

      debugPrint('');
      debugPrint(
        '❌ No valid HOD, Faculty or Student account found.',
      );

      await _auth.signOut();

      if (!mounted) return;

      _showMessage(
        'Account not authorized for this portal.',
        Colors.red,
      );

      _openLogin();
    } on FirebaseException catch (e) {
      // ========================================================
      // FIREBASE / FIRESTORE ERROR
      // ========================================================

      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '❌ FIRESTORE ERROR',
      );
      debugPrint(
        'Code: ${e.code}',
      );
      debugPrint(
        'Message: ${e.message}',
      );
      debugPrint(
        '==========================================',
      );

      if (!mounted) return;

      _showFirestoreError(
        e,
      );
    } catch (e) {
      // ========================================================
      // OTHER ERROR
      // ========================================================

      debugPrint(
        'Account verification error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Unable to verify your account right now.',
        Colors.red,
      );
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

  void _showFirestoreError(
    FirebaseException error,
  ) {
    if (!mounted) return;

    String message = 'Unable to verify your account right now.\n\n'
        'Please check your internet connection and try again.';

    if (error.code == 'permission-denied') {
      message =
          'Account verification was blocked by Firestore security rules.\n\n'
          'Please try again.';
    } else if (error.code == 'unavailable') {
      message = 'Firebase is temporarily unavailable.\n\n'
          'Please check your internet connection and try again.';
    }

    showDialog<void>(
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
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

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

    showDialog<void>(
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
                Navigator.pop(
                  dialogContext,
                );

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
                Navigator.pop(
                  dialogContext,
                );

                await _auth.signOut();

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

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
  }

  // ============================================================
  // BUILD UI
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
            'assets/images/college_building.jpeg',
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
                      tag: 'logo',
                      child: Image.asset(
                        'assets/images/department_logo.png',
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
                      'WELCOME TO',
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
                      'Department of\nComputer Applications',
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
                      'Salipur Autonomous College',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 19,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Text(
                      'Salipur, Odisha',
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
                      'Empowering Future IT Professionals',
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
                    // AUTHENTICATION
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
                            'Authentication Required',
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
                              'UNLOCK',
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
                'Version 1.0',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: .7,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
