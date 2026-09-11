import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;

  // ============================================================
  // SEND RESET LINK
  // ============================================================

  Future<void> _sendResetLink() async {
    final String email = _emailController.text.trim().toLowerCase();

    // ----------------------------------------------------------
    // EMAIL VALIDATION
    // ----------------------------------------------------------

    if (email.isEmpty) {
      _showMessage(
        'Please enter your email address.',
        error: true,
      );
      return;
    }

    final RegExp emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      _showMessage(
        'Please enter a valid email address.',
        error: true,
      );
      return;
    }

    if (_isLoading) {
      return;
    }

    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint(
        'Password reset requested for: $email',
      );

      // --------------------------------------------------------
      // FIREBASE EMAIL LANGUAGE
      // --------------------------------------------------------

      await _auth.setLanguageCode('en');

      // --------------------------------------------------------
      // SEND PASSWORD RESET EMAIL
      // --------------------------------------------------------

      await _auth
          .sendPasswordResetEmail(
            email: email,
          )
          .timeout(
            const Duration(seconds: 30),
          );

      debugPrint(
        'Password reset request completed.',
      );

      if (!mounted) {
        return;
      }

      _showSuccessDialog(email);
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase Auth Error: '
        '${e.code} - ${e.message}',
      );

      if (!mounted) {
        return;
      }

      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'user-not-found':
          message = 'No account found with this email address.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'too-many-requests':
          message = 'Too many reset requests. '
              'Please try again later.';
          break;

        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;

        case 'operation-not-allowed':
          message = 'Email/Password authentication is not enabled in Firebase.';
          break;

        default:
          message = e.message?.trim().isNotEmpty == true
              ? e.message!.trim()
              : 'Unable to send reset link.';
      }

      _showMessage(
        message,
        error: true,
      );
    } on Exception catch (e) {
      debugPrint(
        'Password reset exception: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Request timed out. Please check your internet connection and try again.',
        error: true,
      );
    } catch (e) {
      debugPrint(
        'Password reset error: $e',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Something went wrong. Please try again.',
        error: true,
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
  // SUCCESS DIALOG
  // ============================================================

  void _showSuccessDialog(String email) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                color: Colors.green,
                size: 30,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Reset Link Sent',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'A password reset link has been sent to:\n\n'
            '$email\n\n'
            'Open your email and click the reset link '
            'to create a new password.\n\n'
            'If you cannot find the email, please check '
            'Spam, Promotions, Updates and All Mail.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // Go back to Login Screen
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Back to Login',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 5,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==================================================
                    // ICON
                    // ==================================================

                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: 42,
                        color: Colors.blue.shade700,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==================================================
                    // TITLE
                    // ==================================================

                    const Text(
                      'Reset Your Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ==================================================
                    // DESCRIPTION
                    // ==================================================

                    Text(
                      'Enter your registered email address. '
                      'We will send you a password reset link.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    // ==================================================
                    // EMAIL
                    // ==================================================

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      onSubmitted: (_) {
                        if (!_isLoading) {
                          _sendResetLink();
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'example@gmail.com',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ==================================================
                    // SEND BUTTON
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _sendResetLink,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                              ),
                        label: Text(
                          _isLoading ? 'Sending...' : 'Send Reset Link',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    // ==================================================
                    // BACK TO LOGIN
                    // ==================================================

                    TextButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                              );
                            },
                      icon: const Icon(
                        Icons.arrow_back,
                      ),
                      label: const Text(
                        'Back to Login',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
