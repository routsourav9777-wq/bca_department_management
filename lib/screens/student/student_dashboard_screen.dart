import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'student_profile_screen.dart';
import 'download_notes_screen.dart';
import 'view_notices_screen.dart';
import 'submit_assignments_screen.dart';
import 'view_attendance_screen.dart';
import 'view_internal_marks_screen.dart';
import 'notifications_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _studentData;

  bool _loadingStudent = true;

  String? _studentDocumentId;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  // ============================================================
  // LOAD CURRENT STUDENT
  // ============================================================

  Future<void> _loadStudent() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            _loadingStudent = false;
          });
        }
        return;
      }

      // --------------------------------------------------------
      // SEARCH BY UID
      // --------------------------------------------------------

      final uidQuery = await _firestore
          .collection('students')
          .where(
            'uid',
            isEqualTo: user.uid,
          )
          .limit(1)
          .get();

      if (uidQuery.docs.isNotEmpty) {
        final doc = uidQuery.docs.first;

        if (mounted) {
          setState(() {
            _studentDocumentId = doc.id;

            _studentData = doc.data();

            _loadingStudent = false;
          });
        }

        return;
      }

      // --------------------------------------------------------
      // SEARCH BY EMAIL
      // --------------------------------------------------------

      if (user.email != null) {
        final emailQuery = await _firestore
            .collection('students')
            .where(
              'email',
              isEqualTo: user.email,
            )
            .limit(1)
            .get();

        if (emailQuery.docs.isNotEmpty) {
          final doc = emailQuery.docs.first;

          if (mounted) {
            setState(() {
              _studentDocumentId = doc.id;

              _studentData = doc.data();

              _loadingStudent = false;
            });
          }

          return;
        }
      }

      if (mounted) {
        setState(() {
          _studentData = null;
          _loadingStudent = false;
        });
      }
    } catch (e) {
      debugPrint(
        'Student load error: $e',
      );

      if (mounted) {
        setState(() {
          _loadingStudent = false;
        });
      }
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // STUDENT VALUE
  // ============================================================

  String _studentValue(
    String key,
    String fallback,
  ) {
    final value = _studentData?[key];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  // ============================================================
  // NOTIFICATION COUNT
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _notificationStream() {
    return _firestore
        .collection('notifications')
        .where(
          'department',
          isEqualTo: 'BCA',
        )
        .snapshots();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Portal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Salipur Autonomous College',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          // ======================================================
          // NOTIFICATIONS
          // ======================================================

          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _notificationStream(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
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
          // PROFILE
          // ======================================================

          IconButton(
            icon: const Icon(
              Icons.person_outline,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudentProfileScreen(),
                ),
              );
            },
          ),

          // ======================================================
          // LOGOUT
          // ======================================================

          IconButton(
            icon: const Icon(
              Icons.logout,
            ),
            onPressed: _logout,
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: _loadingStudent
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadStudent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // STUDENT BANNER
                    // ==========================================

                    _buildStudentBanner(),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==========================================
                    // QUICK BAR
                    // ==========================================

                    Row(
                      children: [
                        Expanded(
                          child: _buildAttendanceQuickCard(),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: _buildMarksQuickCard(),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // ==========================================
                    // SERVICES
                    // ==========================================

                    const Text(
                      'Student Services & Modules',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.25,
                      children: [
                        // ======================================
                        // NOTES
                        // ======================================

                        _buildActionCard(
                          title: 'Download Notes',
                          subtitle: 'PDF Study Materials',
                          icon: Icons.file_download,
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DownloadNotesScreen(),
                              ),
                            );
                          },
                        ),

                        // ======================================
                        // NOTICES
                        // ======================================

                        _buildActionCard(
                          title: 'View Notices',
                          subtitle: 'Dept Announcements',
                          icon: Icons.campaign,
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const StudentViewNoticesScreen(),
                              ),
                            );
                          },
                        ),

                        // ======================================
                        // ASSIGNMENTS
                        // ======================================

                        _buildActionCard(
                          title: 'Submit Assignments',
                          subtitle: 'Upload Homework & PDF',
                          icon: Icons.upload_file,
                          color: Colors.orange.shade800,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SubmitAssignmentsScreen(),
                              ),
                            );
                          },
                        ),

                        // ======================================
                        // ATTENDANCE
                        // ======================================

                        _buildActionCard(
                          title: 'View Attendance %',
                          subtitle: 'Subject-wise Percentage',
                          icon: Icons.fact_check_outlined,
                          color: Colors.green.shade700,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ViewAttendanceScreen(),
                              ),
                            );
                          },
                        ),

                        // ======================================
                        // INTERNAL MARKS
                        // ======================================

                        _buildActionCard(
                          title: 'View Internal Marks',
                          subtitle: 'Mid-Sem Results',
                          icon: Icons.analytics_outlined,
                          color: AppTheme.secondaryTeal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const StudentViewInternalMarksScreen(),
                              ),
                            );
                          },
                        ),

                        // ======================================
                        // NOTIFICATIONS
                        // ======================================

                        _buildActionCard(
                          title: 'Push Notifications',
                          subtitle: 'Lock-screen Alerts',
                          icon: Icons.circle_notifications,
                          color: Colors.redAccent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
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
              ),
            ),
    );
  }

  // ============================================================
  // STUDENT BANNER
  // ============================================================

  Widget _buildStudentBanner() {
    final String name = _studentValue(
      'name',
      'Student',
    );

    final String rollNo = _studentValue(
      'rollNo',
      _studentValue(
        'rollNumber',
        'Not Available',
      ),
    );

    final String semester = _studentValue(
      'semester',
      'Not Available',
    );

    final String department = _studentValue(
      'department',
      'BCA',
    );

    return Card(
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
                Icons.school,
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
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    'Roll No: $rollNo • '
                    'Semester $semester',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '$department • '
                    'Salipur Autonomous College',
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
  // ATTENDANCE QUICK CARD
  // ============================================================

  Widget _buildAttendanceQuickCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _attendanceStream(),
      builder: (
        context,
        snapshot,
      ) {
        final double percentage = _calculateAttendance(
          snapshot.data?.docs ?? [],
        );

        final bool hasData = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.pie_chart,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(
                  hasData ? '${percentage.toStringAsFixed(1)}%' : '--',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'Overall Attendance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MARKS QUICK CARD
  // ============================================================

  Widget _buildMarksQuickCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _marksStream(),
      builder: (
        context,
        snapshot,
      ) {
        final double average = _calculateMarksAverage(
          snapshot.data?.docs ?? [],
        );

        final bool hasData = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppTheme.primaryBlue,
                  size: 28,
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(
                  hasData ? '${average.toStringAsFixed(1)} / 20' : '--',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const Text(
                  'Mid-Sem Average',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ATTENDANCE FIRESTORE STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _attendanceStream() {
    final String uid = _auth.currentUser?.uid ?? '';

    return _firestore
        .collection('attendance')
        .where(
          'studentUid',
          isEqualTo: uid,
        )
        .snapshots();
  }

  // ============================================================
  // MARKS FIRESTORE STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _marksStream() {
    final String uid = _auth.currentUser?.uid ?? '';

    return _firestore
        .collection('internal_marks')
        .where(
          'studentUid',
          isEqualTo: uid,
        )
        .snapshots();
  }

  // ============================================================
  // CALCULATE ATTENDANCE
  // ============================================================

  double _calculateAttendance(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) {
      return 0;
    }

    double totalClasses = 0;
    double attendedClasses = 0;

    for (final doc in docs) {
      final data = doc.data();

      final dynamic total = data['total'] ?? data['totalClasses'];

      final dynamic attended = data['attended'] ?? data['attendedClasses'];

      if (total is num && attended is num) {
        totalClasses += total.toDouble();

        attendedClasses += attended.toDouble();
      }
    }

    if (totalClasses == 0) {
      return 0;
    }

    return (attendedClasses / totalClasses) * 100;
  }

  // ============================================================
  // CALCULATE MARKS
  // ============================================================

  double _calculateMarksAverage(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) {
      return 0;
    }

    double totalObtained = 0;
    double totalMax = 0;

    for (final doc in docs) {
      final data = doc.data();

      final dynamic obtained =
          data['obtained'] ?? data['marks'] ?? data['obtainedMarks'];

      final dynamic max = data['max'] ?? data['maxMarks'] ?? 20;

      if (obtained is num && max is num) {
        totalObtained += obtained.toDouble();

        totalMax += max.toDouble();
      }
    }

    if (totalMax == 0) {
      return 0;
    }

    // Convert overall percentage
    // to a value out of 20.
    return (totalObtained / totalMax) * 20;
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(
                height: 10,
              ),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
