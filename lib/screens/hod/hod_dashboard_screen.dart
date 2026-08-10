import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

import '../auth/login_screen.dart';
import '../faculty/view_students_screen.dart';

import 'approve_registrations_screen.dart';
import 'manage_faculty_screen.dart';
import 'manage_subjects_screen.dart';
import 'upload_notice_screen.dart';
import 'upload_notes_screen.dart';
import 'view_attendance_reports_screen.dart';
import 'view_internal_marks_screen.dart';
import 'send_push_notifications_screen.dart';
import '../faculty/mark_attendance_screen.dart';

class HODDashboardScreen extends StatelessWidget {
  const HODDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HOD Portal - Admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              AppConstants.collegeName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          // PUSH NOTIFICATION
          IconButton(
            icon: const Icon(
              Icons.notifications_active_outlined,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SendPushNotificationsScreen(),
                ),
              );
            },
          ),

          // LOGOUT
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // WELCOME HEADER
            // ====================================================

            Card(
              color: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
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
                      width: 16,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Head of Department (BCA)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: 4,
                          ),
                          Text(
                            'Salipur Autonomous College',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ====================================================
            // QUICK STATS
            // ====================================================

            Row(
              children: [
                // =================================================
                // PENDING STUDENTS
                // =================================================

                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .where(
                          'status',
                          isEqualTo: 'pending',
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      final pendingCount = snapshot.data?.docs.length ?? 0;

                      return _buildStatTile(
                        title: 'Pending student',
                        value: '$pendingCount',
                        icon: Icons.pending_actions,
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ApproveRegistrationsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                // =================================================
                // TOTAL FACULTY
                // =================================================

                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('faculty')
                        .where(
                          'department',
                          isEqualTo: 'BCA',
                        )
                        .where(
                          'status',
                          isEqualTo: 'active',
                        )
                        .snapshots(),
                    builder: (context, snapshot) {
                      final facultyCount = snapshot.data?.docs.length ?? 0;

                      return _buildStatTile(
                        title: 'Total Faculty',
                        value: '$facultyCount',
                        icon: Icons.group,
                        color: AppTheme.secondaryTeal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageFacultyScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                // =================================================
                // BCA STUDENTS
                // =================================================

                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final studentCount = snapshot.data?.docs.length ?? 0;

                      return _buildStatTile(
                        title: 'BCA Students',

                        value: '$studentCount',

                        icon: Icons.school,

                        color: AppTheme.primaryBlue,

                        // =======================================
                        // CLICK → VIEW STUDENT LIST
                        // =======================================

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ViewStudentsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),

            // ====================================================
            // HOD MANAGEMENT CONTROLS
            // ====================================================

            const Text(
              'HOD Management Controls',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ====================================================
            // MANAGEMENT GRID
            // ====================================================

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                // =================================================
                // MANAGE SUBJECTS
                // =================================================

                _buildActionCard(
                  context: context,
                  title: 'Manage Subjects',
                  subtitle: 'Semester 1 to 6',
                  icon: Icons.menu_book,
                  color: AppTheme.secondaryTeal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageSubjectsScreen(),
                    ),
                  ),
                ),

                // =================================================
                // UPLOAD NOTICES
                // =================================================

                _buildActionCard(
                  context: context,
                  title: 'Upload Notices',
                  subtitle: 'Dept Announcements',
                  icon: Icons.campaign,
                  color: Colors.deepPurple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UploadNoticeScreen(),
                    ),
                  ),
                ),

                // =================================================
                // UPLOAD PDF NOTES
                // =================================================

                _buildActionCard(
                  context: context,
                  title: 'Upload PDF Notes',
                  subtitle: 'Department Study Materials',
                  icon: Icons.file_upload,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UploadNotesScreen(),
                    ),
                  ),
                ),

                // =================================================
                // ATTENDANCE REPORTS
                // =================================================

                _buildActionCard(
                  context: context,
                  title: 'Attendance Reports',
                  subtitle: 'Sem 1-6 Overview',
                  icon: Icons.fact_check,
                  color: Colors.green.shade700,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ViewAttendanceReportsScreen(),
                    ),
                  ),
                ),

                // =================================================
                // INTERNAL MARKS
                // =================================================

                _buildActionCard(
                  context: context,
                  title: 'Mark Attendance',
                  subtitle: 'Take Student Attendance',
                  icon: Icons.fact_check,
                  color: Colors.green.shade700,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MarkAttendanceScreen(),
                    ),
                  ),
                ),

                // =================================================
                // PUSH NOTIFICATIONS
                // =================================================

                _buildActionCard(
                  context: context,
                  title: 'Push Notifications',
                  subtitle: 'Broadcast to Mobile',
                  icon: Icons.send,
                  color: Colors.redAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SendPushNotificationsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STAT TILE
  // ============================================================

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(
                        0.12,
                      ),
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
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
