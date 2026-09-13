import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _semester = AppConstants.semesters[0];

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _idController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // ============================================================
  // REGISTER STUDENT
  // ============================================================

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    // ============================================================
    // GET VALUES
    // ============================================================

    final String name = _nameController.text.trim();

    final String email = _emailController.text.trim().toLowerCase();

    final String phone = _phoneController.text.trim();

    final String rollNo = _idController.text.trim().toUpperCase();

    final String password = _passwordController.text;

    final String confirmPassword = _confirmPasswordController.text;

    // ============================================================
    // VALIDATION
    // ============================================================

    if (name.isEmpty) {
      _showError('Please enter your Full Name');
      return;
    }

    if (email.isEmpty) {
      _showError('Please enter your Email');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Please enter a valid Email Address');
      return;
    }

    if (phone.isEmpty) {
      _showError('Please enter your Phone Number');
      return;
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      _showError('Please enter a valid 10 digit Phone Number');
      return;
    }

    if (rollNo.isEmpty) {
      _showError('Please enter your College Roll Number');
      return;
    }

    if (password.isEmpty) {
      _showError('Please create a Password');
      return;
    }

    if (password.length < 6) {
      _showError(
        'Password should be at least 6 characters',
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      _showError('Please confirm your Password');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
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
      // STEP 1
      // CREATE FIREBASE AUTH ACCOUNT
      // ========================================================

      debugPrint('');
      debugPrint('=========================================');
      debugPrint('🎓 STUDENT REGISTRATION STARTED');
      debugPrint('=========================================');
      debugPrint('Name: $name');
      debugPrint('Email: $email');
      debugPrint('Phone: $phone');
      debugPrint('Roll No: $rollNo');
      debugPrint('Semester: $_semester');
      debugPrint('Department: BCA');
      debugPrint('=========================================');

      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception(
          'Unable to create Firebase Authentication account.',
        );
      }

      final String studentUid = user.uid;

      debugPrint(
        '✅ Firebase Auth account created.',
      );

      debugPrint(
        'Student UID: $studentUid',
      );

      // ========================================================
      // STEP 2
      // SAVE STUDENT DATA
      // ========================================================

      await _firestore.collection('students').doc(studentUid).set({
        // ------------------------------------------------------
        // IDENTITY
        // ------------------------------------------------------

        'uid': studentUid,

        'name': name,

        'email': email,

        'phone': phone,

        'rollNo': rollNo,

        // ------------------------------------------------------
        // ACADEMIC
        // ------------------------------------------------------

        'semester': _semester,

        // ------------------------------------------------------
        // SECURITY / ROLE
        // ------------------------------------------------------

        'role': 'student',

        'status': 'pending',

        // ------------------------------------------------------
        // IMPORTANT
        // DEPARTMENT IS REQUIRED BY FIRESTORE RULES
        // ------------------------------------------------------

        'department': 'BCA',

        // ------------------------------------------------------
        // TIMESTAMP
        // ------------------------------------------------------

        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('');
      debugPrint('=========================================');

      debugPrint(
        '✅ STUDENT DATA SAVED TO FIRESTORE',
      );

      debugPrint(
        'Department: BCA',
      );

      debugPrint(
        'Status: pending',
      );

      debugPrint(
        'Role: student',
      );

      debugPrint('=========================================');

      // ========================================================
      // STEP 3
      // SIGN OUT
      // ========================================================

      await _auth.signOut();

      debugPrint(
        '✅ Student Firebase session signed out.',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      // ========================================================
      // STEP 4
      // SUCCESS MESSAGE
      // ========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration Successful!\n'
            'Your registration is waiting for HOD approval.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // ========================================================
      // GO BACK TO LOGIN
      // ========================================================

      Navigator.pop(context);
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      debugPrint(
        '❌ Firebase Auth Error: ${e.code}',
      );

      try {
        await _auth.signOut();
      } catch (_) {}

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      String message = 'Registration Failed';

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered.';
          break;

        case 'weak-password':
          message = 'Password should be at least 6 characters.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'operation-not-allowed':
          message = 'Email/Password sign-in is not enabled in Firebase.';
          break;

        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;

        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;

        default:
          message = e.message ?? 'Registration Failed';
      }

      _showError(message);
    }

    // ==========================================================
    // FIREBASE FIRESTORE ERROR
    // ==========================================================

    on FirebaseException catch (e) {
      debugPrint(
        '❌ Firestore Error: ${e.code}',
      );

      debugPrint(
        'Firestore Message: ${e.message}',
      );

      try {
        await _auth.signOut();
      } catch (_) {}

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      String message = 'Unable to complete registration.';

      if (e.code == 'permission-denied') {
        message = 'Registration permission denied. '
            'Please check your account information.';
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }

      _showError(message);
    }

    // ==========================================================
    // OTHER ERROR
    // ==========================================================

    catch (e) {
      debugPrint(
        '❌ Registration Error: $e',
      );

      try {
        await _auth.signOut();
      } catch (_) {}

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showError(
        'Registration failed. Please try again.',
      );
    }
  }

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(email);
  }

  // ============================================================
  // SHOW ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Registration',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              const Text(
                'Salipur Autonomous College - BCA Dept',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryBlue,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              const Text(
                'Please fill in the details below to register '
                'as a new student.',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // FORM CARD
              // ==================================================

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // =========================================
                      // ROLE
                      // =========================================

                      TextFormField(
                        initialValue: 'Student',
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'I am a',
                          prefixIcon: Icon(Icons.school),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // =========================================
                      // DEPARTMENT
                      // =========================================

                      TextFormField(
                        initialValue:
                            'BCA - Department of Computer Applications',
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Department',
                          prefixIcon: Icon(Icons.computer),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // =========================================
                      // NAME
                      // =========================================

                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(
                            Icons.person_outline,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // =========================================
                      // EMAIL
                      // =========================================

                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          hintText: 'Enter your email',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // =========================================
                      // PHONE
                      // =========================================

                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter 10 digit phone number',
                          prefixIcon: Icon(
                            Icons.phone_outlined,
                          ),
                          border: OutlineInputBorder(),
                          counterText: '',
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // =========================================
                      // ROLL NUMBER
                      // =========================================

                      TextField(
                        controller: _idController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'College Roll Number',
                          hintText: 'e.g. BS25-007',
                          prefixIcon: Icon(
                            Icons.badge_outlined,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // =========================================
                      // SEMESTER
                      // =========================================

                      DropdownButtonFormField<String>(
                        initialValue: _semester,
                        decoration: const InputDecoration(
                          labelText: 'Current Semester',
                          prefixIcon: Icon(
                            Icons.school_outlined,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        items: AppConstants.semesters
                            .map(
                              (semester) => DropdownMenuItem<String>(
                                value: semester,
                                child: Text(
                                  semester,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _semester = value;
                                  });
                                }
                              },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // =========================================
                      // PASSWORD
                      // =========================================

                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Create Password',
                          hintText: 'Minimum 6 characters',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                          ),
                          border: const OutlineInputBorder(),
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
                        height: 16,
                      ),

                      // =========================================
                      // CONFIRM PASSWORD
                      // =========================================

                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        onChanged: (_) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(
                            Icons.lock_reset_outlined,
                          ),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                          ),
                          errorText: _confirmPasswordController.text.isEmpty
                              ? null
                              : _passwordController.text ==
                                      _confirmPasswordController.text
                                  ? null
                                  : 'Passwords do not match',
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // =========================================
                      // SUBMIT
                      // =========================================

                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'SUBMIT REGISTRATION',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // NOTE
              // ==================================================

              const Text(
                'Note: Your account will remain pending until '
                'approved by the HOD.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
