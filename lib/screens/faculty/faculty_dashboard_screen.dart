import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../hod/approve_registrations_screen.dart';
import '../hod/upload_notice_screen.dart';
import '../hod/upload_notes_screen.dart';
import '../hod/view_attendance_reports_screen.dart';
import '../settings/settings_screen.dart';

import 'mark_attendance_screen.dart';
import 'view_students_screen.dart';
import 'view_notices_screen.dart';

class FacultyDashboardScreen extends StatelessWidget {
  const FacultyDashboardScreen({super.key});

  // ============================================================
  // GET CURRENT FACULTY DATA
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>> _getFacultyData() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'Faculty is not logged in.',
      );
    }

    return FirebaseFirestore.instance.collection('faculty').doc(user.uid).get();
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(
    BuildContext context,
  ) async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // NOTIFICATION STREAM
  // HOD -> ALL FACULTY
  // HOD -> FACULTY ONLY
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _facultyNotifications() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where(
          'department',
          isEqualTo: 'BCA',
        )
        .where(
      'target',
      whereIn: [
        'all',
        'faculty',
      ],
    ).snapshots();
  }

  // ============================================================
  // OPEN SETTINGS
  // ============================================================

  void _openSettings(
    BuildContext context,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Faculty Portal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Salipur Autonomous College - BCA',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          // ======================================================
          // SETTINGS
          // ======================================================

          IconButton(
            tooltip: 'Settings',
            icon: const Icon(
              Icons.settings_outlined,
              size: 26,
            ),
            onPressed: () => _openSettings(context),
          ),

          // ======================================================
          // NOTIFICATION BELL
          // ======================================================

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _facultyNotifications(),
            builder: (
              context,
              snapshot,
            ) {
              final int count = snapshot.data?.docs.length ?? 0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    icon: const Icon(
                      Icons.notifications_none,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FacultyNotificationsScreen(),
                        ),
                      );
                    },
                  ),

                  // ==================================================
                  // RED BADGE
                  // ==================================================

                  if (count > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 17,
                          minHeight: 17,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryBlue,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // ======================================================
          // LOGOUT
          // ======================================================

          IconButton(
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout,
            ),
            onPressed: () => _logout(context),
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _getFacultyData(),
        builder: (
          context,
          snapshot,
        ) {
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
            return _buildErrorView(
              context,
              'Unable to load faculty profile.',
              snapshot.error.toString(),
            );
          }

          // ======================================================
          // NO DATA
          // ======================================================

          if (!snapshot.hasData) {
            return _buildErrorView(
              context,
              'Faculty profile not available.',
              'Please try again.',
            );
          }

          // ======================================================
          // DOCUMENT NOT FOUND
          // ======================================================

          if (!snapshot.data!.exists) {
            return _buildErrorView(
              context,
              'Faculty profile not found.',
              'Please ask HOD to add this faculty account.',
            );
          }

          // ======================================================
          // FIRESTORE DATA
          // ======================================================

          final Map<String, dynamic> data =
              snapshot.data!.data() ?? <String, dynamic>{};

          final String name = data['name']?.toString() ?? 'Faculty';

          final String designation =
              data['designation']?.toString() ?? 'Faculty';

          final String email = data['email']?.toString() ??
              FirebaseAuth.instance.currentUser?.email ??
              '';

          final String department = data['department']?.toString() ?? 'BCA';

          final String employeeId = data['employeeId']?.toString() ??
              data['empId']?.toString() ??
              data['facultyId']?.toString() ??
              'Faculty ID';

          final String status = data['status']?.toString() ?? 'active';

          // ======================================================
          // ACTIVE CHECK
          // ======================================================

          if (status != 'active') {
            return _buildErrorView(
              context,
              'Faculty account is inactive.',
              'Please contact HOD.',
            );
          }

          // ======================================================
          // DASHBOARD
          // ======================================================

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // PROFILE
                // ==================================================

                _buildProfileCard(
                  name: name,
                  designation: designation,
                  employeeId: employeeId,
                  email: email,
                  department: department,
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // SECTION TITLE
                // ==================================================

                const Text(
                  'Faculty Tasks & Management',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==================================================
                // ACTION GRID
                // ==================================================

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    // ==============================================
                    // 1. MARK ATTENDANCE
                    // ==============================================

                    _buildActionCard(
                      title: 'Mark Attendance',
                      subtitle: 'Daily Student Attendance',
                      icon: Icons.checklist,
                      color: AppTheme.primaryBlue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MarkAttendanceScreen(),
                          ),
                        );
                      },
                    ),

                    // ==============================================
                    // 2. UPLOAD PDF NOTES
                    // ==============================================

                    _buildActionCard(
                      title: 'Upload PDF Notes',
                      subtitle: 'Study Material for Students',
                      icon: Icons.picture_as_pdf,
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UploadNotesScreen(),
                          ),
                        );
                      },
                    ),

                    // ==============================================
                    // 3. UPLOAD NOTICE
                    // ==============================================

                    _buildActionCard(
                      title: 'Upload Notice',
                      subtitle: 'Department Announcements',
                      icon: Icons.campaign,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UploadNoticeScreen(),
                          ),
                        );
                      },
                    ),

                    // ==============================================
                    // 4. STUDENT VERIFY
                    // ==============================================

                    _buildActionCard(
                      title: 'Student Verify',
                      subtitle: 'Approve Registrations',
                      icon: Icons.how_to_reg,
                      color: Colors.amber.shade800,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ApproveRegistrationsScreen(),
                          ),
                        );
                      },
                    ),

                    // ==============================================
                    // 5. VIEW STUDENT LIST
                    // ==============================================

                    _buildActionCard(
                      title: 'View Student List',
                      subtitle: 'Semester-wise Roster',
                      icon: Icons.groups,
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ViewStudentsScreen(),
                          ),
                        );
                      },
                    ),

                    // ==============================================
                    // 6. VIEW NOTICES
                    // ==============================================

                    _buildActionCard(
                      title: 'View Dept Notices',
                      subtitle: 'HOD Announcements',
                      icon: Icons.notifications_active,
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FacultyViewNoticesScreen(),
                          ),
                        );
                      },
                    ),

                    // ==============================================
                    // 7. VIEW ATTENDANCE REPORT
                    // ==============================================

                    _buildActionCard(
                      title: 'View Attendance',
                      subtitle: 'Attendance Reports',
                      icon: Icons.assessment,
                      color: Colors.deepPurple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ViewAttendanceReportsScreen(),
                          ),
                        );
                      },
                    ),

                    // ==============================================
                    // 8. SETTINGS
                    // ==============================================

                    _buildActionCard(
                      title: 'Settings',
                      subtitle: 'Account & App Settings',
                      icon: Icons.settings_outlined,
                      color: Colors.blueGrey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard({
    required String name,
    required String designation,
    required String employeeId,
    required String email,
    required String department,
  }) {
    return Card(
      color: AppTheme.secondaryTeal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // PROFILE ICON
            // ====================================================

            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              child: Icon(
                Icons.person,
                size: 36,
                color: Colors.white,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            // ====================================================
            // DETAILS
            // ====================================================

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    '$designation • $employeeId',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    'Department: $department',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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
  // ERROR VIEW
  // ============================================================

  Widget _buildErrorView(
    BuildContext context,
    String title,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(
              height: 14,
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FacultyDashboardScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Retry',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // ICON
              // ==================================================

              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const SizedBox(
                height: 7,
              ),

              // ==================================================
              // TITLE
              // ==================================================

              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              // ==================================================
              // SUBTITLE
              // ==================================================

              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// FACULTY NOTIFICATIONS SCREEN
// =================================================================

class FacultyNotificationsScreen extends StatelessWidget {
  const FacultyNotificationsScreen({
    super.key,
  });

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(
    Timestamp? timestamp,
  ) {
    if (timestamp == null) {
      return 'Just now';
    }

    final DateTime date = timestamp.toDate();

    final DateTime now = DateTime.now();

    final Duration difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hour'
          '${difference.inHours == 1 ? '' : 's'} ago';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} day'
          '${difference.inDays == 1 ? '' : 's'} ago';
    }

    final String day = date.day.toString().padLeft(
          2,
          '0',
        );

    final String month = date.month.toString().padLeft(
          2,
          '0',
        );

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(
              'notifications',
            )
            .where(
              'department',
              isEqualTo: 'BCA',
            )
            .where(
          'target',
          whereIn: [
            'all',
            'faculty',
          ],
        ).snapshots(),
        builder: (
          context,
          snapshot,
        ) {
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
                padding: const EdgeInsets.all(
                  24,
                ),
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
                      'Unable to load notifications',
                      textAlign: TextAlign.center,
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
          // EMPTY
          // ======================================================

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Text(
                    'No Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 6,
                  ),
                  Text(
                    'HOD notifications will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // ======================================================
          // SORT
          // ======================================================

          final notifications =
              List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
            snapshot.data!.docs,
          );

          notifications.sort(
            (
              a,
              b,
            ) {
              final dynamic aTime = a.data()['createdAt'];

              final dynamic bTime = b.data()['createdAt'];

              if (aTime is Timestamp && bTime is Timestamp) {
                return bTime.compareTo(
                  aTime,
                );
              }

              return 0;
            },
          );

          // ======================================================
          // LIST
          // ======================================================

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (
              context,
              index,
            ) {
              final data = notifications[index].data();

              final String title = data['title']?.toString() ?? 'Notification';

              final String body = data['body']?.toString() ?? '';

              final String targetLabel =
                  data['targetLabel']?.toString() ?? 'Faculty';

              final String role = data['createdByRole']?.toString() ?? 'HOD';

              final Timestamp? createdAt = data['createdAt'] is Timestamp
                  ? data['createdAt'] as Timestamp
                  : null;

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 12,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    16,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Icon(
                          Icons.notifications,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              body,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(
                                      6,
                                    ),
                                  ),
                                  child: Text(
                                    targetLabel,
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  role.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatTime(
                                    createdAt,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
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
