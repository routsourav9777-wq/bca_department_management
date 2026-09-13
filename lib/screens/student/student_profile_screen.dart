import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // GET CURRENT STUDENT
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?> _getStudent() async {
    final User? user = _auth.currentUser;

    // ----------------------------------------------------------
    // USER NOT LOGGED IN
    // ----------------------------------------------------------

    if (user == null) {
      return null;
    }

    final String uid = user.uid;

    debugPrint(
      '=========================================',
    );

    debugPrint(
      'STUDENT PROFILE',
    );

    debugPrint(
      'Firebase UID: $uid',
    );

    debugPrint(
      'Firebase Email: ${user.email}',
    );

    debugPrint(
      '=========================================',
    );

    // ==========================================================
    // IMPORTANT
    // ==========================================================
    //
    // Student document ID = Firebase Auth UID
    //
    // students/{uid}
    //
    // This matches the production Firestore rule:
    //
    // request.auth.uid == userId
    //
    // DO NOT use .where('email', ...)
    // DO NOT use .where('uid', ...)
    //
    // ==========================================================

    final DocumentSnapshot<Map<String, dynamic>> studentDocument =
        await _firestore.collection('students').doc(uid).get();

    // ==========================================================
    // DOCUMENT NOT FOUND
    // ==========================================================

    if (!studentDocument.exists) {
      debugPrint(
        '❌ Student document not found.',
      );

      debugPrint(
        'Expected document: students/$uid',
      );

      return null;
    }

    // ==========================================================
    // DOCUMENT FOUND
    // ==========================================================

    debugPrint(
      '✅ Student profile found.',
    );

    debugPrint(
      'Document ID: ${studentDocument.id}',
    );

    debugPrint(
      'Student data: ${studentDocument.data()}',
    );

    return studentDocument;
  }

  // ============================================================
  // NORMALIZE SEMESTER
  // ============================================================

  String _formatSemester(String semester) {
    final String value = semester.trim();

    if (value.isEmpty) {
      return 'Not Available';
    }

    // If Firebase already contains:
    // Semester 1
    // Semester 2
    // etc.
    if (value.toLowerCase().startsWith('semester')) {
      return value;
    }

    // If Firebase contains only:
    // 1
    // 2
    // etc.
    return 'Semester $value';
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(String status) {
    final String value = status.trim().toLowerCase();

    if (value == 'approved' || value == 'active') {
      return Colors.green;
    }

    if (value == 'pending') {
      return Colors.orange;
    }

    if (value == 'rejected') {
      return Colors.red;
    }

    return Colors.grey;
  }

  // ============================================================
  // STATUS ICON
  // ============================================================

  IconData _statusIcon(String status) {
    final String value = status.trim().toLowerCase();

    if (value == 'approved' || value == 'active') {
      return Icons.check_circle;
    }

    if (value == 'pending') {
      return Icons.pending;
    }

    if (value == 'rejected') {
      return Icons.cancel;
    }

    return Icons.info;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Profile',
        ),
      ),

      // ========================================================
      // PROFILE
      // ========================================================

      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        future: _getStudent(),
        builder: (context, snapshot) {
          // ====================================================
          // LOADING
          // ====================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ====================================================
          // ERROR
          // ====================================================

          if (snapshot.hasError) {
            debugPrint(
              '❌ Student Profile Error: ${snapshot.error}',
            );

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 55,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    const Text(
                      'Unable to load profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ====================================================
          // PROFILE NOT FOUND
          // ====================================================

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_search,
                      size: 65,
                      color: Colors.grey,
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Text(
                      'Student Profile Not Found',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Text(
                      'Your student profile could not be found in Firebase.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ====================================================
          // FIRESTORE DATA
          // ====================================================

          final Map<String, dynamic> student = snapshot.data!.data() ?? {};

          // ====================================================
          // STUDENT DETAILS
          // ====================================================

          final String name =
              student['name']?.toString().trim().isNotEmpty == true
                  ? student['name'].toString().trim()
                  : 'Student';

          final String rollNo =
              student['rollNo']?.toString().trim().isNotEmpty == true
                  ? student['rollNo'].toString().trim()
                  : student['rollNumber']?.toString().trim().isNotEmpty == true
                      ? student['rollNumber'].toString().trim()
                      : 'Not Available';

          final String semester = _formatSemester(
            student['semester']?.toString() ?? '',
          );

          final String department =
              student['department']?.toString().trim().isNotEmpty == true
                  ? student['department'].toString().trim()
                  : 'BCA';

          final String email =
              student['email']?.toString().trim().isNotEmpty == true
                  ? student['email'].toString().trim()
                  : _auth.currentUser?.email ?? 'Not Available';

          final String phone =
              student['phone']?.toString().trim().isNotEmpty == true
                  ? student['phone'].toString().trim()
                  : student['phoneNumber']?.toString().trim().isNotEmpty == true
                      ? student['phoneNumber'].toString().trim()
                      : 'Not Available';

          final String status =
              student['status']?.toString().trim().isNotEmpty == true
                  ? student['status'].toString().trim()
                  : 'pending';

          final Color statusColor = _statusColor(status);

          final IconData statusIcon = _statusIcon(status);

          // ====================================================
          // UI
          // ====================================================

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ==================================================
                // PROFILE ICON
                // ==================================================

                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // ==================================================
                // NAME
                // ==================================================

                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                // ==================================================
                // ROLL + SEMESTER
                // ==================================================

                Text(
                  'Roll No: $rollNo • $semester',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                // ==================================================
                // DETAILS CARD
                // ==================================================

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // ==========================================
                        // COLLEGE
                        // ==========================================

                        ListTile(
                          leading: const Icon(
                            Icons.school,
                            color: AppTheme.primaryBlue,
                          ),
                          title: const Text(
                            'College Name',
                          ),
                          subtitle: const Text(
                            AppConstants.collegeName,
                          ),
                        ),

                        const Divider(),

                        // ==========================================
                        // DEPARTMENT
                        // ==========================================

                        ListTile(
                          leading: const Icon(
                            Icons.business,
                            color: AppTheme.primaryBlue,
                          ),
                          title: const Text(
                            'Department',
                          ),
                          subtitle: Text(
                            department,
                          ),
                        ),

                        const Divider(),

                        // ==========================================
                        // EMAIL
                        // ==========================================

                        ListTile(
                          leading: const Icon(
                            Icons.email,
                            color: AppTheme.primaryBlue,
                          ),
                          title: const Text(
                            'Email Address',
                          ),
                          subtitle: Text(
                            email,
                          ),
                        ),

                        const Divider(),

                        // ==========================================
                        // PHONE
                        // ==========================================

                        ListTile(
                          leading: const Icon(
                            Icons.phone,
                            color: AppTheme.primaryBlue,
                          ),
                          title: const Text(
                            'Phone Number',
                          ),
                          subtitle: Text(
                            phone,
                          ),
                        ),

                        const Divider(),

                        // ==========================================
                        // SEMESTER
                        // ==========================================

                        ListTile(
                          leading: const Icon(
                            Icons.menu_book,
                            color: AppTheme.primaryBlue,
                          ),
                          title: const Text(
                            'Current Semester',
                          ),
                          subtitle: Text(
                            semester,
                          ),
                        ),

                        const Divider(),

                        // ==========================================
                        // ROLL NUMBER
                        // ==========================================

                        ListTile(
                          leading: const Icon(
                            Icons.badge,
                            color: AppTheme.primaryBlue,
                          ),
                          title: const Text(
                            'College Roll Number',
                          ),
                          subtitle: Text(
                            rollNo,
                          ),
                        ),

                        const Divider(),

                        // ==========================================
                        // APPROVAL STATUS
                        // ==========================================

                        ListTile(
                          leading: Icon(
                            statusIcon,
                            color: statusColor,
                          ),
                          title: const Text(
                            'HOD Approval Status',
                          ),
                          subtitle: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // UID INFORMATION
                // ==================================================

                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.fingerprint,
                      color: AppTheme.primaryBlue,
                    ),
                    title: const Text(
                      'Student UID',
                    ),
                    subtitle: Text(
                      _auth.currentUser?.uid ?? 'Not Available',
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
