import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  User? get _currentUser => _auth.currentUser;

  String get _currentEmail {
    return _currentUser?.email ?? 'No email available';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAccountCard(),
              const SizedBox(height: 16),
              _buildSectionTitle('Account'),
              _buildSettingTile(
                icon: Icons.lock_outline,
                iconColor: Colors.orange,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: _isLoading ? null : _changePassword,
              ),
              _buildSettingTile(
                icon: Icons.email_outlined,
                iconColor: Colors.blue,
                title: 'Change Email',
                subtitle: 'Change your registered email address',
                onTap: _isLoading ? null : _changeEmail,
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Support'),
              _buildSettingTile(
                icon: Icons.help_outline,
                iconColor: Colors.green,
                title: 'Help & Support',
                subtitle: 'Contact support on WhatsApp',
                onTap: _openWhatsApp,
              ),
              _buildSettingTile(
                icon: Icons.info_outline,
                iconColor: Colors.indigo,
                title: 'About',
                subtitle: 'BCA Department Management App',
                onTap: _showAboutDialog,
              ),
              _buildSettingTile(
                icon: Icons.system_update_outlined,
                iconColor: Colors.purple,
                title: 'App Update',
                subtitle: 'Check app version',
                onTap: _showAppUpdate,
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'BCA Department Management App\nVersion 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Please wait...',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
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

  // ============================================================
  // ACCOUNT CARD
  // ============================================================

  Widget _buildAccountCard() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.blue.shade700,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BCA Department',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _currentEmail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  // ============================================================
  // SETTING TILE
  // ============================================================

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> _changePassword() async {
    final PasswordChangeData? data = await showDialog<PasswordChangeData>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const _ChangePasswordDialog();
      },
    );

    if (!mounted || data == null) {
      return;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'No signed-in user found.',
        error: true,
      );
      return;
    }

    final String currentEmail = user.email?.trim() ?? '';

    if (currentEmail.isEmpty) {
      _showMessage(
        'Your account does not have an email address.',
        error: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthCredential credential = EmailAuthProvider.credential(
        email: currentEmail,
        password: data.currentPassword,
      );

      final User? freshUser = _auth.currentUser;

      if (freshUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No signed-in user found.',
        );
      }

      await freshUser.reauthenticateWithCredential(credential).timeout(
            const Duration(seconds: 15),
          );

      final User? authenticatedUser = _auth.currentUser;

      if (authenticatedUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User session expired.',
        );
      }

      await authenticatedUser.updatePassword(data.newPassword).timeout(
            const Duration(seconds: 15),
          );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Password changed successfully.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      _showFirebaseError(
        e,
        isEmailChange: false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to change password. Please try again.',
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
  // CHANGE EMAIL
  // ============================================================

  Future<void> _changeEmail() async {
    final EmailChangeData? data = await showDialog<EmailChangeData>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const _ChangeEmailDialog();
      },
    );

    if (!mounted || data == null) {
      return;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      _showMessage(
        'No signed-in user found.',
        error: true,
      );
      return;
    }

    final String currentEmail = user.email?.trim() ?? '';

    if (currentEmail.isEmpty) {
      _showMessage(
        'Current email address is not available.',
        error: true,
      );
      return;
    }

    final String newEmail = data.newEmail.trim().toLowerCase();

    if (newEmail == currentEmail.toLowerCase()) {
      _showMessage(
        'New email must be different from your current email.',
        error: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ----------------------------------------------------------
      // Set email language
      // ----------------------------------------------------------

      await _auth.setLanguageCode('en');

      // ----------------------------------------------------------
      // Get latest Firebase user
      // ----------------------------------------------------------

      User? freshUser = _auth.currentUser;

      if (freshUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No signed-in user found.',
        );
      }

      // ----------------------------------------------------------
      // Re-authenticate using CURRENT email + CURRENT password
      // ----------------------------------------------------------

      final AuthCredential credential = EmailAuthProvider.credential(
        email: currentEmail,
        password: data.currentPassword,
      );

      await freshUser.reauthenticateWithCredential(credential).timeout(
            const Duration(seconds: 15),
          );

      // ----------------------------------------------------------
      // Get user again after re-authentication
      // ----------------------------------------------------------

      freshUser = _auth.currentUser;

      if (freshUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User session expired.',
        );
      }

      // ----------------------------------------------------------
      // IMPORTANT:
      //
      // verifyBeforeUpdateEmail sends a verification email
      // to the NEW EMAIL ADDRESS.
      //
      // The Firebase account email is changed only after the
      // verification link is completed.
      // ----------------------------------------------------------

      await freshUser.verifyBeforeUpdateEmail(newEmail).timeout(
            const Duration(seconds: 30),
          );

      if (!mounted) {
        return;
      }

      _showEmailVerificationSuccess(newEmail);
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }

      _showFirebaseError(
        e,
        isEmailChange: true,
      );
    } on FormatException {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Please enter a valid email address.',
        error: true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to send verification email. Please try again.',
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
  // EMAIL SUCCESS DIALOG
  // ============================================================

  void _showEmailVerificationSuccess(String newEmail) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Verification Email Sent',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'A verification email has been requested for:\n\n'
            '$newEmail\n\n'
            'Open that email and complete the verification. '
            'Your Firebase email address will change after the '
            'verification process is completed.\n\n'
            'Also check Spam, Promotions, Updates and All Mail '
            'if you do not see it in your Inbox.',
            style: const TextStyle(
              height: 1.5,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // FIREBASE ERROR HANDLER
  // ============================================================

  void _showFirebaseError(
    FirebaseAuthException e, {
    required bool isEmailChange,
  }) {
    debugPrint(
      'Firebase Auth Error: ${e.code} - ${e.message}',
    );

    String message;

    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
        message = isEmailChange
            ? 'Current password is incorrect.'
            : 'Current password is incorrect.';
        break;

      case 'invalid-email':
        message = 'Please enter a valid email address.';
        break;

      case 'email-already-in-use':
        message =
            'This email address is already registered with another account.';
        break;

      case 'requires-recent-login':
        message =
            'For security, please sign in again and then try this operation.';
        break;

      case 'user-not-found':
        message = 'User account was not found.';
        break;

      case 'user-disabled':
        message = 'This user account has been disabled.';
        break;

      case 'network-request-failed':
        message = 'Network error. Please check your internet connection.';
        break;

      case 'too-many-requests':
        message = 'Too many requests. Please wait for some time and try again.';
        break;

      case 'operation-not-allowed':
        message = 'Email/Password authentication is not enabled in Firebase.';
        break;

      case 'provider-already-linked':
        message = 'This account is already linked with this provider.';
        break;

      case 'credential-already-in-use':
        message =
            'This email credential is already being used by another account.';
        break;

      case 'weak-password':
        message = 'Password is too weak. Please use a stronger password.';
        break;

      case 'timeout':
        message =
            'Firebase request timed out. Please check your internet connection and try again.';
        break;

      default:
        message = e.message?.trim().isNotEmpty == true
            ? e.message!.trim()
            : 'Something went wrong. Please try again.';
    }

    _showMessage(
      message,
      error: true,
    );
  }

  // ============================================================
  // WHATSAPP
  // ============================================================

  Future<void> _openWhatsApp({
    String message =
        'Hello, I need help regarding the BCA Department Management App.',
  }) async {
    const String phoneNumber = '919861333487';

    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      final bool launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage(
          'WhatsApp could not be opened.',
          error: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Unable to open WhatsApp.',
          error: true,
        );
      }
    }
  }

  // ============================================================
  // ABOUT
  // ============================================================

  void _showAboutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'About App',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BCA Department Management App',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Designed for managing BCA Department '
                'academic activities, attendance, notices, '
                'students and faculty.',
                style: TextStyle(
                  height: 1.5,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Version: 1.0.0',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // APP UPDATE
  // ============================================================

  void _showAppUpdate() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.system_update_outlined,
                color: Colors.purple,
              ),
              SizedBox(width: 10),
              Text(
                'App Update',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'You are currently using version 1.0.0.\n\n'
            'No update information is available right now.',
            style: TextStyle(
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
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
          backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
  }
}

// =================================================================
// PASSWORD CHANGE DATA
// =================================================================

class PasswordChangeData {
  final String currentPassword;
  final String newPassword;

  const PasswordChangeData({
    required this.currentPassword,
    required this.newPassword,
  });
}

// =================================================================
// EMAIL CHANGE DATA
// =================================================================

class EmailChangeData {
  final String newEmail;
  final String currentPassword;

  const EmailChangeData({
    required this.newEmail,
    required this.currentPassword,
  });
}

// =================================================================
// CHANGE PASSWORD DIALOG
// =================================================================

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    _currentPasswordController = TextEditingController();

    _newPasswordController = TextEditingController();

    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      PasswordChangeData(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: const Text(
        'Change Password',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _hideCurrentPassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _hideCurrentPassword = !_hideCurrentPassword;
                      });
                    },
                    icon: Icon(
                      _hideCurrentPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _hideNewPassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(
                    Icons.lock_reset_outlined,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _hideNewPassword = !_hideNewPassword;
                      });
                    },
                    icon: Icon(
                      _hideNewPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter new password';
                  }

                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _hideConfirmPassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(
                    Icons.password_outlined,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _hideConfirmPassword = !_hideConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _hideConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm new password';
                  }

                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Change Password'),
        ),
      ],
    );
  }
}

// =================================================================
// CHANGE EMAIL DIALOG
// =================================================================

class _ChangeEmailDialog extends StatefulWidget {
  const _ChangeEmailDialog();

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _newEmailController;
  late final TextEditingController _currentPasswordController;

  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();

    _newEmailController = TextEditingController();

    _currentPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _newEmailController.dispose();
    _currentPasswordController.dispose();

    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String newEmail = _newEmailController.text.trim().toLowerCase();

    final String currentPassword = _currentPasswordController.text;

    Navigator.pop(
      context,
      EmailChangeData(
        newEmail: newEmail,
        currentPassword: currentPassword,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      title: const Text(
        'Change Email',
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your new email address. '
                'A verification link will be sent to the new email.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newEmailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'New Email Address',
                  hintText: 'example@gmail.com',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                  ),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final String email = value?.trim() ?? '';

                  if (email.isEmpty) {
                    return 'Enter new email address';
                  }

                  final RegExp emailRegex = RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  );

                  if (!emailRegex.hasMatch(email)) {
                    return 'Enter a valid email address';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _hidePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _hidePassword = !_hidePassword;
                      });
                    },
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter current password';
                  }

                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Send Verification'),
        ),
      ],
    );
  }
}
