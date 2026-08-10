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

    if (user == null) {
      return null;
    }

    // First search by UID
    final uidResult = await _firestore
        .collection('students')
        .where(
          'uid',
          isEqualTo: user.uid,
        )
        .limit(1)
        .get();

    if (uidResult.docs.isNotEmpty) {
      return uidResult.docs.first;
    }

    // Then search by email
    if (user.email != null) {
      final emailResult = await _firestore
          .collection('students')
          .where(
            'email',
            isEqualTo: user.email,
          )
          .limit(1)
          .get();

      if (emailResult.docs.isNotEmpty) {
        return emailResult.docs.first;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Profile',
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
        future: _getStudent(),
        builder: (context, snapshot) {
          // ======================================================
          // LOADING
          // ======================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ======================================================
          // ERROR
          // ======================================================

          if (snapshot.hasError) {
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
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

          // ======================================================
          // PROFILE NOT FOUND
          // ======================================================

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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Text(
                      'Your student profile is not available in Firebase.',
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

          final Map<String, dynamic> student = snapshot.data!.data() ?? {};

          // ======================================================
          // FIREBASE DATA
          // ======================================================

          final String name = student['name']?.toString() ?? 'Student';

          final String rollNo = student['rollNo']?.toString() ??
              student['rollNumber']?.toString() ??
              'Not Available';

          final String semester =
              student['semester']?.toString() ?? 'Not Available';

          final String department = student['department']?.toString() ?? 'BCA';

          final String email = student['email']?.toString() ??
              _auth.currentUser?.email ??
              'Not Available';

          final String phone = student['phone']?.toString() ??
              student['phoneNumber']?.toString() ??
              'Not Available';

          final String status = student['status']?.toString() ?? 'pending';

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
                  height: 5,
                ),

                // ==================================================
                // ROLL + SEMESTER
                // ==================================================

                Text(
                  'Roll No: $rollNo • '
                  'Semester $semester',
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
                    padding: const EdgeInsets.all(
                      16,
                    ),
                    child: Column(
                      children: [
                        // =========================================
                        // COLLEGE
                        // =========================================

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

                        // =========================================
                        // DEPARTMENT
                        // =========================================

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

                        // =========================================
                        // EMAIL
                        // =========================================

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

                        // =========================================
                        // PHONE
                        // =========================================

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

                        // =========================================
                        // SEMESTER
                        // =========================================

                        ListTile(
                          leading: const Icon(
                            Icons.menu_book,
                            color: AppTheme.primaryBlue,
                          ),
                          title: const Text(
                            'Current Semester',
                          ),
                          subtitle: Text(
                            'Semester $semester',
                          ),
                        ),

                        const Divider(),

                        // =========================================
                        // APPROVAL STATUS
                        // =========================================

                        ListTile(
                          leading: Icon(
                            status.toLowerCase() == 'active' ||
                                    status.toLowerCase() == 'approved'
                                ? Icons.check_circle
                                : Icons.pending,
                            color: status.toLowerCase() == 'active' ||
                                    status.toLowerCase() == 'approved'
                                ? Colors.green
                                : Colors.orange,
                          ),
                          title: const Text(
                            'HOD Approval Status',
                          ),
                          subtitle: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: status.toLowerCase() == 'active' ||
                                      status.toLowerCase() == 'approved'
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
