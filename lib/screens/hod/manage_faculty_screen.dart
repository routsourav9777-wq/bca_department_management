import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';

class ManageFacultyScreen extends StatefulWidget {
  const ManageFacultyScreen({super.key});

  @override
  State<ManageFacultyScreen> createState() => _ManageFacultyScreenState();
}

class _ManageFacultyScreenState extends State<ManageFacultyScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSaving = false;

  // ============================================================
  // ADD / EDIT FACULTY
  // ============================================================

  void _showAddEditDialog({
    DocumentSnapshot<Map<String, dynamic>>? faculty,
  }) {
    final data = faculty?.data();

    final nameCtrl = TextEditingController(
      text: data?['name']?.toString() ?? '',
    );

    final desigCtrl = TextEditingController(
      text: data?['designation']?.toString() ?? '',
    );

    final emailCtrl = TextEditingController(
      text: data?['email']?.toString() ?? '',
    );

    final passwordCtrl = TextEditingController();

    final confirmPasswordCtrl = TextEditingController();

    bool obscurePassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                faculty == null ? 'Add New Faculty' : 'Edit Faculty Details',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ================= NAME =================

                    TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ================= DESIGNATION =================

                    TextField(
                      controller: desigCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Designation',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ================= EMAIL =================

                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      enabled: faculty == null,
                      decoration: const InputDecoration(
                        labelText: 'College Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),

                    // Password only required when adding
                    if (faculty == null) ...[
                      const SizedBox(height: 12),

                      // ================= PASSWORD =================

                      TextField(
                        controller: passwordCtrl,
                        obscureText: obscurePassword,
                        onChanged: (_) {
                          setDialogState(() {});
                        },
                        decoration: InputDecoration(
                          labelText: 'Create Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ================= CONFIRM PASSWORD =================

                      TextField(
                        controller: confirmPasswordCtrl,
                        obscureText: obscureConfirmPassword,
                        onChanged: (_) {
                          setDialogState(() {});
                        },
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureConfirmPassword =
                                    !obscureConfirmPassword;
                              });
                            },
                          ),
                          errorText: confirmPasswordCtrl.text.isEmpty
                              ? null
                              : passwordCtrl.text != confirmPasswordCtrl.text
                                  ? 'Passwords do not match'
                                  : null,
                        ),
                      ),
                    ],

                    if (faculty != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Password is managed through Firebase Authentication.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ========================================================
              // BUTTONS
              // ========================================================

              actions: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          // ================= VALIDATION =================

                          if (nameCtrl.text.trim().isEmpty ||
                              desigCtrl.text.trim().isEmpty ||
                              emailCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // ================= ADD FACULTY =================

                          if (faculty == null) {
                            if (passwordCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please create a password'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (confirmPasswordCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please confirm the password'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (passwordCtrl.text.length < 6) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Password must be at least 6 characters',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (passwordCtrl.text != confirmPasswordCtrl.text) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Passwords do not match'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            await _addFaculty(
                              name: nameCtrl.text.trim(),
                              designation: desigCtrl.text.trim(),
                              email: emailCtrl.text.trim().toLowerCase(),
                              password: passwordCtrl.text,
                              dialogContext: dialogContext,
                            );

                            return;
                          }

                          // ================= EDIT FACULTY =================

                          await _editFaculty(
                            documentId: faculty.id,
                            name: nameCtrl.text.trim(),
                            designation: desigCtrl.text.trim(),
                            dialogContext: dialogContext,
                          );
                        },
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          faculty == null ? 'Add Faculty' : 'Save Changes',
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ADD FACULTY
  // ============================================================

  Future<void> _addFaculty({
    required String name,
    required String designation,
    required String email,
    required String password,
    required BuildContext dialogContext,
  }) async {
    setState(() => _isSaving = true);

    try {
      // Create Firebase Authentication account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Save faculty profile in Firestore
      await _firestore.collection('faculty').doc(uid).set({
        'uid': uid,
        'name': name,
        'designation': designation,
        'email': email,
        'role': 'faculty',
        'status': 'active',
        'department': 'BCA',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // IMPORTANT:
      // The current Firebase Auth user becomes the newly created faculty.
      // We sign out so the HOD session does not remain logged in as faculty.
      await _auth.signOut();

      if (!mounted) return;

      setState(() => _isSaving = false);

      Navigator.pop(dialogContext);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faculty added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      String message = 'Failed to add faculty';

      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak. Use at least 6 characters.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add faculty: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // EDIT FACULTY
  // ============================================================

  Future<void> _editFaculty({
    required String documentId,
    required String name,
    required String designation,
    required BuildContext dialogContext,
  }) async {
    setState(() => _isSaving = true);

    try {
      await _firestore.collection('faculty').doc(documentId).update({
        'name': name,
        'designation': designation,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() => _isSaving = false);

      Navigator.pop(dialogContext);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faculty updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update faculty: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // DELETE FACULTY
  // ============================================================

  Future<void> _deleteFaculty(
    String documentId,
    String name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to remove $name?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _firestore.collection('faculty').doc(documentId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faculty removed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete faculty: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Faculty Members'),
      ),

      // ================= ADD FACULTY BUTTON =================

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : () => _showAddEditDialog(),
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        label: const Text(
          'Add Faculty',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      // ================= FIRESTORE FACULTY LIST =================

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('faculty')
            .where('department', isEqualTo: 'BCA')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error loading faculty:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }

          final faculties = snapshot.data?.docs ?? [];

          if (faculties.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No faculty members found.',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: faculties.length,
            itemBuilder: (context, index) {
              final faculty = faculties[index];
              final data = faculty.data();

              final name = data['name']?.toString() ?? 'Unknown';

              final designation = data['designation']?.toString() ?? '';

              final email = data['email']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    child: Text(
                      name
                          .split(' ')
                          .where((e) => e.isNotEmpty)
                          .map((e) => e[0])
                          .take(2)
                          .join(''),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        designation,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('📧 $email'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddEditDialog(
                          faculty: faculty,
                        );
                      }

                      if (value == 'delete') {
                        _deleteFaculty(
                          faculty.id,
                          name,
                        );
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
