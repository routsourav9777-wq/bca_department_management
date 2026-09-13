import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../services/notification_service.dart';

import '../hod/hod_dashboard_screen.dart';
import '../faculty/faculty_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';

import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = false;

  bool _obscurePassword = true;

  // ============================================================
  // REGISTER NOTIFICATIONS
  // ============================================================

  Future<void> _registerNotifications() async {
    try {
      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '🔔 STARTING NOTIFICATION REGISTRATION',
      );
      debugPrint(
        '==========================================',
      );

      await NotificationService.instance.registerLoggedInUser().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint(
            '⚠️ Notification registration timed out.',
          );
        },
      );

      debugPrint(
        '✅ Notification registration completed.',
      );
    } catch (e, stackTrace) {
      // Notification failure must NEVER block login.
      debugPrint(
        '❌ Notification registration failed: $e',
      );

      debugPrint(
        stackTrace.toString(),
      );
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    // ==========================================================
    // VALIDATION
    // ==========================================================

    final String email = _emailController.text.trim().toLowerCase();

    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage(
        'Please enter email and password.',
        Colors.red,
      );

      return;
    }

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ========================================================
      // 1. FIREBASE AUTHENTICATION
      // ========================================================

      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '🔐 STARTING FIREBASE LOGIN',
      );
      debugPrint(
        'Email: $email',
      );
      debugPrint(
        '==========================================',
      );

      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        throw Exception(
          'Firebase user not found after login.',
        );
      }

      final String uid = user.uid;

      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '✅ FIREBASE LOGIN SUCCESSFUL',
      );
      debugPrint(
        'Email: ${user.email}',
      );
      debugPrint(
        'UID: $uid',
      );
      debugPrint(
        '==========================================',
      );

      // ========================================================
      // 2. CHECK HOD USING UID
      // ========================================================

      debugPrint(
        '🔎 Checking HOD document: hod/$uid',
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

        final String firestoreUid = data['uid']?.toString().trim() ?? '';

        debugPrint('');
        debugPrint(
          '========== HOD DATA ==========',
        );
        debugPrint(
          'Auth UID      : $uid',
        );
        debugPrint(
          'Firestore UID : $firestoreUid',
        );
        debugPrint(
          'Role          : $role',
        );
        debugPrint(
          'Status        : $status',
        );
        debugPrint(
          'Department    : $department',
        );
        debugPrint(
          'Document ID   : ${hodDocument.id}',
        );
        debugPrint(
          '==============================',
        );

        if (role == 'hod' && status == 'active' && department == 'BCA') {
          debugPrint(
            '✅ HOD LOGIN AUTHORIZED',
          );

          await _registerNotifications();

          if (!mounted) {
            return;
          }

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
          'ℹ️ No HOD document found for UID: $uid',
        );
      }

      // ========================================================
      // 3. CHECK STUDENT USING UID
      // ========================================================

      debugPrint(
        '🔎 Checking Student document: students/$uid',
      );

      final DocumentSnapshot<Map<String, dynamic>> studentDocument =
          await _firestore.collection('students').doc(uid).get();

      if (studentDocument.exists) {
        final Map<String, dynamic> studentData = studentDocument.data() ?? {};

        final String role =
            studentData['role']?.toString().trim().toLowerCase() ?? '';

        final String status =
            studentData['status']?.toString().trim().toLowerCase() ?? '';

        final String department =
            studentData['department']?.toString().trim().toUpperCase() ?? '';

        final String firestoreUid = studentData['uid']?.toString().trim() ?? '';

        final String semester =
            studentData['semester']?.toString().trim() ?? '';

        final String name = studentData['name']?.toString().trim() ?? '';

        final String rollNo = studentData['rollNo']?.toString().trim() ?? '';

        debugPrint('');
        debugPrint(
          '==========================================',
        );
        debugPrint(
          '🎓 STUDENT FIRESTORE DATA',
        );
        debugPrint(
          '==========================================',
        );
        debugPrint(
          'Auth UID       : $uid',
        );
        debugPrint(
          'Firestore UID  : $firestoreUid',
        );
        debugPrint(
          'Document ID    : ${studentDocument.id}',
        );
        debugPrint(
          'Name           : $name',
        );
        debugPrint(
          'Roll No        : $rollNo',
        );
        debugPrint(
          'Role           : $role',
        );
        debugPrint(
          'Status         : $status',
        );
        debugPrint(
          'Department     : $department',
        );
        debugPrint(
          'Semester       : $semester',
        );
        debugPrint(
          '==========================================',
        );

        // ======================================================
        // UID CHECK
        // ======================================================

        if (firestoreUid.isNotEmpty && firestoreUid != uid) {
          debugPrint(
            '❌ UID MISMATCH',
          );

          debugPrint(
            'Auth UID      : $uid',
          );

          debugPrint(
            'Firestore UID : $firestoreUid',
          );

          await _auth.signOut();

          if (!mounted) {
            return;
          }

          _showMessage(
            'Student account UID mismatch.\n'
            'Please contact HOD.',
            Colors.red,
          );

          return;
        }

        // ======================================================
        // STUDENT APPROVED
        // ======================================================

        if (role == 'student' && department == 'BCA' && status == 'approved') {
          debugPrint(
            '==========================================',
          );
          debugPrint(
            '✅ STUDENT LOGIN AUTHORIZED',
          );
          debugPrint(
            '==========================================',
          );

          // Register FCM token.
          // Notification failure will not block login.
          await _registerNotifications();

          if (!mounted) {
            return;
          }

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
            '⚠️ STUDENT ACCOUNT PENDING',
          );

          await _auth.signOut();

          if (!mounted) {
            return;
          }

          _showMessage(
            'Your registration is still pending.\n'
            'Please wait for HOD approval.',
            Colors.orange,
          );

          return;
        }

        // ======================================================
        // STUDENT REJECTED
        // ======================================================

        if (status == 'rejected') {
          debugPrint(
            '❌ STUDENT ACCOUNT REJECTED',
          );

          await _auth.signOut();

          if (!mounted) {
            return;
          }

          _showMessage(
            'Your registration has been rejected by the HOD.',
            Colors.red,
          );

          return;
        }

        // ======================================================
        // STUDENT INVALID DATA
        // ======================================================

        debugPrint(
          '❌ STUDENT DATA IS NOT VALID',
        );

        debugPrint(
          'Required:',
        );

        debugPrint(
          'role = student',
        );

        debugPrint(
          'department = BCA',
        );

        debugPrint(
          'status = approved',
        );

        await _auth.signOut();

        if (!mounted) {
          return;
        }

        _showMessage(
          'Student account is not active.\n\n'
          'Role: $role\n'
          'Department: $department\n'
          'Status: $status',
          Colors.red,
        );

        return;
      } else {
        debugPrint(
          'ℹ️ No Student document found for UID: $uid',
        );
      }

      // ========================================================
      // 4. CHECK FACULTY USING UID
      // ========================================================

      debugPrint(
        '🔎 Checking Faculty document: faculty/$uid',
      );

      final DocumentSnapshot<Map<String, dynamic>> facultyDocument =
          await _firestore.collection('faculty').doc(uid).get();

      if (facultyDocument.exists) {
        final Map<String, dynamic> facultyData = facultyDocument.data() ?? {};

        final String role =
            facultyData['role']?.toString().trim().toLowerCase() ?? '';

        final String status =
            facultyData['status']?.toString().trim().toLowerCase() ?? '';

        final String department =
            facultyData['department']?.toString().trim().toUpperCase() ?? '';

        final String firestoreUid = facultyData['uid']?.toString().trim() ?? '';

        debugPrint('');
        debugPrint(
          '========== FACULTY DATA ==========',
        );
        debugPrint(
          'Auth UID      : $uid',
        );
        debugPrint(
          'Firestore UID : $firestoreUid',
        );
        debugPrint(
          'Document ID   : ${facultyDocument.id}',
        );
        debugPrint(
          'Role          : $role',
        );
        debugPrint(
          'Status        : $status',
        );
        debugPrint(
          'Department    : $department',
        );
        debugPrint(
          '==================================',
        );

        // ======================================================
        // FACULTY UID CHECK
        // ======================================================

        if (firestoreUid.isNotEmpty && firestoreUid != uid) {
          debugPrint(
            '❌ FACULTY UID MISMATCH',
          );

          await _auth.signOut();

          if (!mounted) {
            return;
          }

          _showMessage(
            'Faculty account UID mismatch.\n'
            'Please contact HOD.',
            Colors.red,
          );

          return;
        }

        // ======================================================
        // FACULTY APPROVED
        // ======================================================

        if (role == 'faculty' && status == 'active' && department == 'BCA') {
          debugPrint(
            '==========================================',
          );
          debugPrint(
            '✅ FACULTY LOGIN AUTHORIZED',
          );
          debugPrint(
            '==========================================',
          );

          await _registerNotifications();

          if (!mounted) {
            return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const FacultyDashboardScreen(),
            ),
          );

          return;
        }

        // ======================================================
        // FACULTY INVALID DATA
        // ======================================================

        debugPrint(
          '❌ FACULTY DATA IS NOT VALID',
        );

        await _auth.signOut();

        if (!mounted) {
          return;
        }

        _showMessage(
          'Faculty account is not active.\n\n'
          'Role: $role\n'
          'Department: $department\n'
          'Status: $status',
          Colors.red,
        );

        return;
      } else {
        debugPrint(
          'ℹ️ No Faculty document found for UID: $uid',
        );
      }

      // ========================================================
      // 5. NOTHING FOUND
      // ========================================================

      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '❌ ACCOUNT NOT AUTHORIZED',
      );
      debugPrint(
        '==========================================',
      );
      debugPrint(
        'UID checked: $uid',
      );
      debugPrint(
        'Collections checked:',
      );
      debugPrint(
        'hod/$uid',
      );
      debugPrint(
        'students/$uid',
      );
      debugPrint(
        'faculty/$uid',
      );
      debugPrint(
        '==========================================',
      );

      await _auth.signOut();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Account not authorized for this portal.',
        Colors.red,
      );
    } on FirebaseAuthException catch (e) {
      // ========================================================
      // FIREBASE AUTH ERROR
      // ========================================================

      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '❌ FIREBASE AUTH ERROR',
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

      String message = 'Login failed.';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many login attempts. Please try again later.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Please check your internet connection.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/Password authentication is not enabled.';
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        message,
        Colors.red,
      );
    } on FirebaseException catch (e) {
      // ========================================================
      // FIRESTORE ERROR
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

      if (!mounted) {
        return;
      }

      if (e.code == 'permission-denied') {
        _showMessage(
          'Firestore permission denied.\n'
          'Please check your production rules.',
          Colors.red,
        );
      } else if (e.code == 'unavailable') {
        _showMessage(
          'Firestore is temporarily unavailable.\n'
          'Please check your internet connection.',
          Colors.orange,
        );
      } else {
        _showMessage(
          'Unable to verify your account.\n'
          'Firestore error: ${e.code}',
          Colors.red,
        );
      }
    } catch (e, stackTrace) {
      // ========================================================
      // GENERAL ERROR
      // ========================================================

      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        '❌ LOGIN ERROR',
      );
      debugPrint(
        '$e',
      );
      debugPrint(
        '==========================================',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Something went wrong.\n'
        'Please try again.',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(
    String message,
    Color color,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(
            seconds: 4,
          ),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ======================================================
          // BACKGROUND
          // ======================================================

          Positioned.fill(
            child: Image.asset(
              'assets/images/college_building.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          // ======================================================
          // DARK OVERLAY
          // ======================================================

          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(
                alpha: 0.65,
              ),
            ),
          ),

          // ======================================================
          // LOGIN CARD
          // ======================================================

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  color: Colors.white.withValues(
                    alpha: 0.93,
                  ),
                  elevation: 15,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ======================================
                        // LOGO
                        // ======================================

                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            'assets/images/department_logo.png',
                            width: 170,
                            height: 170,
                            fit: BoxFit.cover,
                          ),
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        // ======================================
                        // DEPARTMENT NAME
                        // ======================================

                        const Text(
                          'Department of Computer Applications',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        const Text(
                          'Salipur Autonomous College',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        // ======================================
                        // EMAIL
                        // ======================================

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enabled: !_isLoading,
                          decoration: const InputDecoration(
                            labelText: 'Enter your Email',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        // ======================================
                        // PASSWORD
                        // ======================================

                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !_isLoading,
                          onSubmitted: (_) {
                            if (!_isLoading) {
                              _login();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        // ======================================
                        // FORGOT PASSWORD
                        // ======================================

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                            child: const Text(
                              'Forgot Password?',
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 25,
                        ),

                        // ======================================
                        // SIGN IN BUTTON
                        // ======================================

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(
                          height: 25,
                        ),

                        // ======================================
                        // REGISTER
                        // ======================================

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'New Student? ',
                            ),
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen(),
                                        ),
                                      );
                                    },
                              child: const Text(
                                'Register Here',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
