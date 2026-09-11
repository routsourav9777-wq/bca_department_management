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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // ============================================================
  // REGISTER FOR NOTIFICATIONS
  // ============================================================

  Future<void> _registerNotifications() async {
    try {
      await NotificationService.instance.registerLoggedInUser().timeout(
            const Duration(seconds: 10),
          );

      debugPrint(
        'Notification registration completed.',
      );
    } catch (e) {
      // Notification error should NEVER stop login.
      debugPrint(
        'Notification registration failed: $e',
      );
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter email and password",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text.trim().toLowerCase();

    final String password = _passwordController.text;

    try {
      // ========================================================
      // FIREBASE AUTHENTICATION
      // ========================================================

      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;

      if (user == null) {
        throw Exception(
          "Firebase user not found after login.",
        );
      }

      debugPrint(
        "Firebase login successful: ${user.email}",
      );

      // ========================================================
      // 1. CHECK HOD
      // ========================================================

      final QuerySnapshot<Map<String, dynamic>> hodQuery = await _firestore
          .collection('hod')
          .where(
            'email',
            isEqualTo: email,
          )
          .limit(1)
          .get();

      if (hodQuery.docs.isNotEmpty) {
        final Map<String, dynamic> data = hodQuery.docs.first.data();

        final String status = data['status']?.toString().toLowerCase() ?? '';

        if (status == 'active') {
          debugPrint(
            'HOD login authorized.',
          );

          // ----------------------------------------------------
          // REGISTER FCM TOKEN
          // ----------------------------------------------------

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
      }

      // ========================================================
      // 2. CHECK STUDENT
      // ========================================================

      final QuerySnapshot<Map<String, dynamic>> studentQuery = await _firestore
          .collection('students')
          .where(
            'email',
            isEqualTo: email,
          )
          .limit(1)
          .get();

      if (studentQuery.docs.isNotEmpty) {
        final Map<String, dynamic> studentData = studentQuery.docs.first.data();

        final String status =
            studentData['status']?.toString().toLowerCase() ?? '';

        // ------------------------------------------------------
        // STUDENT APPROVED
        // ------------------------------------------------------

        if (status == 'approved') {
          debugPrint(
            'Student login authorized.',
          );

          // ----------------------------------------------------
          // REGISTER FCM TOKEN
          // ----------------------------------------------------

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

        // ------------------------------------------------------
        // STUDENT PENDING
        // ------------------------------------------------------

        if (status == 'pending') {
          await _auth.signOut();

          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Your registration is still pending.\n"
                "Please wait for HOD approval.",
              ),
              backgroundColor: Colors.orange,
            ),
          );

          return;
        }

        // ------------------------------------------------------
        // STUDENT REJECTED
        // ------------------------------------------------------

        if (status == 'rejected') {
          await _auth.signOut();

          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Your registration has been rejected by the HOD.",
              ),
              backgroundColor: Colors.red,
            ),
          );

          return;
        }
      }

      // ========================================================
      // 3. CHECK FACULTY
      // ========================================================

      final QuerySnapshot<Map<String, dynamic>> facultyQuery = await _firestore
          .collection('faculty')
          .where(
            'email',
            isEqualTo: email,
          )
          .limit(1)
          .get();

      if (facultyQuery.docs.isNotEmpty) {
        final Map<String, dynamic> facultyData = facultyQuery.docs.first.data();

        final String status =
            facultyData['status']?.toString().toLowerCase() ?? '';

        final String role = facultyData['role']?.toString().toLowerCase() ?? '';

        if (status == 'active' && role == 'faculty') {
          debugPrint(
            'Faculty login authorized.',
          );

          // ----------------------------------------------------
          // REGISTER FCM TOKEN
          // ----------------------------------------------------

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
      }

      // ========================================================
      // ACCESS DENIED
      // ========================================================

      await _auth.signOut();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Account not authorized for this portal.",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        "Firebase Auth Error: "
        "${e.code} - ${e.message}",
      );

      String message = "Login Failed";

      if (e.code == 'user-not-found') {
        message = "No account found with this email.";
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = "Invalid email or password.";
      } else if (e.code == 'user-disabled') {
        message = "This account has been disabled.";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address.";
      } else if (e.code == 'too-many-requests') {
        message = "Too many login attempts. Please try again later.";
      } else if (e.code == 'network-request-failed') {
        message = "Network error. Please check your internet connection.";
      } else if (e.code == 'operation-not-allowed') {
        message = "Email/Password authentication is not enabled.";
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint(
        "Login error: $e",
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Something went wrong: $e",
          ),
          backgroundColor: Colors.red,
        ),
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
              "assets/images/college_building.jpeg",
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
                        // ========================================
                        // LOGO
                        // ========================================

                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.asset(
                            "assets/images/department_logo.png",
                            width: 170,
                            height: 170,
                            fit: BoxFit.cover,
                          ),
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        // ========================================
                        // DEPARTMENT NAME
                        // ========================================

                        const Text(
                          "Department of Computer Applications",
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
                          "Salipur Autonomous College",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        // ========================================
                        // EMAIL
                        // ========================================

                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: "Enter your Email",
                            prefixIcon: Icon(
                              Icons.email_outlined,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        // ========================================
                        // PASSWORD
                        // ========================================

                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_isLoading) {
                              _login();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
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

                        // ========================================
                        // FORGOT PASSWORD
                        // ========================================

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
                              "Forgot Password?",
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 25,
                        ),

                        // ========================================
                        // SIGN IN BUTTON
                        // ========================================

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
                                    "SIGN IN",
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(
                          height: 25,
                        ),

                        // ========================================
                        // REGISTER
                        // ========================================

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "New Student? ",
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Register Here",
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
