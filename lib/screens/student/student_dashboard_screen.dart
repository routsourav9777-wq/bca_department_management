import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import 'student_profile_screen.dart';
import 'download_notes_screen.dart';
import 'view_notices_screen.dart';
import 'view_attendance_screen.dart';
import 'notifications_screen.dart';
import 'scan_attendance_screen.dart';

// ============================================================
// COLORS
// ============================================================

const Color kPrimary = Color(0xFF2563EB);
const Color kDarkBlue = Color(0xFF0F2D6B);
const Color kBackground = Color(0xFFF4F7FC);
const Color kTextDark = Color(0xFF111827);
const Color kTextGrey = Color(0xFF6B7280);

// ============================================================
// STUDENT DASHBOARD
// ============================================================

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _studentData;

  bool _loadingStudent = true;

  String? _studentLoadError;

  late AnimationController _entryController;
  late AnimationController _backgroundController;
  late AnimationController _floatingController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 850,
      ),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 18,
      ),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 3,
      ),
    )..repeat(
        reverse: true,
      );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(
        0,
        0.06,
      ),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );

    _loadStudent();

    Future.delayed(
      const Duration(
        milliseconds: 150,
      ),
      () {
        if (mounted) {
          _entryController.forward();
        }
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _entryController.dispose();
    _backgroundController.dispose();
    _floatingController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD STUDENT
  // ============================================================

  Future<void> _loadStudent() async {
    if (mounted) {
      setState(() {
        _loadingStudent = true;
        _studentLoadError = null;
      });
    }

    try {
      final User? user = _auth.currentUser;

      // ========================================================
      // AUTH USER CHECK
      // ========================================================

      if (user == null) {
        debugPrint(
          '❌ FirebaseAuth currentUser is NULL',
        );

        if (mounted) {
          setState(() {
            _loadingStudent = false;
            _studentLoadError = 'User is not logged in.';
          });
        }

        return;
      }

      final String uid = user.uid;

      debugPrint('');
      debugPrint(
        '==========================================',
      );
      debugPrint(
        'STUDENT DASHBOARD - LOADING PROFILE',
      );
      debugPrint(
        'Auth UID: $uid',
      );
      debugPrint(
        'Auth Email: ${user.email}',
      );
      debugPrint(
        'Firestore Path: students/$uid',
      );
      debugPrint(
        '==========================================',
      );

      // ========================================================
      // DIRECT UID DOCUMENT READ
      // ========================================================
      //
      // Firebase structure:
      //
      // students
      //   └── Y1wBtEEF7dXdW39DJxf7I6x0tMC3
      //
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>> studentDoc =
          await _firestore.collection('students').doc(uid).get(
                const GetOptions(
                  source: Source.server,
                ),
              );

      // ========================================================
      // DOCUMENT NOT FOUND
      // ========================================================

      if (!studentDoc.exists || studentDoc.data() == null) {
        debugPrint(
          '❌ STUDENT DOCUMENT DOES NOT EXIST',
        );

        debugPrint(
          'Expected path:',
        );

        debugPrint(
          'students/$uid',
        );

        if (mounted) {
          setState(() {
            _studentData = null;
            _loadingStudent = false;
            _studentLoadError = 'Student profile not found.\n\n'
                'Expected document:\n'
                'students/$uid';
          });
        }

        return;
      }

      // ========================================================
      // GET DATA
      // ========================================================

      final Map<String, dynamic> data = studentDoc.data()!;

      // ========================================================
      // DEBUG ALL DATA
      // ========================================================

      debugPrint(
        '==========================================',
      );
      debugPrint(
        '✅ STUDENT PROFILE FOUND',
      );
      debugPrint(
        'Document ID: ${studentDoc.id}',
      );
      debugPrint(
        'uid: ${data['uid']}',
      );
      debugPrint(
        'name: ${data['name']}',
      );
      debugPrint(
        'rollNo: ${data['rollNo']}',
      );
      debugPrint(
        'semester: ${data['semester']}',
      );
      debugPrint(
        'department: ${data['department']}',
      );
      debugPrint(
        'email: ${data['email']}',
      );
      debugPrint(
        'role: ${data['role']}',
      );
      debugPrint(
        'status: ${data['status']}',
      );
      debugPrint(
        '==========================================',
      );

      // ========================================================
      // VALIDATE UID
      // ========================================================

      final String storedUid = (data['uid'] ?? '').toString().trim();

      if (storedUid.isNotEmpty && storedUid != uid) {
        debugPrint(
          '⚠️ UID mismatch!',
        );

        debugPrint(
          'Auth UID: $uid',
        );

        debugPrint(
          'Firestore UID: $storedUid',
        );
      }

      // ========================================================
      // SET DATA
      // ========================================================

      if (mounted) {
        setState(() {
          _studentData = data;
          _loadingStudent = false;
          _studentLoadError = null;
        });
      }
    } on FirebaseException catch (e) {
      debugPrint(
        '==========================================',
      );

      debugPrint(
        '❌ FIREBASE ERROR',
      );

      debugPrint(
        'Code: ${e.code}',
      );

      debugPrint(
        'Message: ${e.message}',
      );

      debugPrint(
        '==========================================',
      );

      if (mounted) {
        setState(() {
          _loadingStudent = false;
          _studentLoadError = 'Firebase error: ${e.code}\n\n'
              '${e.message ?? 'Unable to load profile.'}';
        });
      }
    } catch (e) {
      debugPrint(
        '❌ STUDENT PROFILE ERROR: $e',
      );

      if (mounted) {
        setState(() {
          _loadingStudent = false;
          _studentLoadError = e.toString();
        });
      }
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint(
        'Logout error: $e',
      );
    }

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
  // SETTINGS
  // ============================================================

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  // ============================================================
  // STUDENT VALUE
  // ============================================================

  String _studentValue(
    List<String> keys,
    String fallback,
  ) {
    final Map<String, dynamic>? data = _studentData;

    if (data == null) {
      return fallback;
    }

    for (final String key in keys) {
      final dynamic value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }

  // ============================================================
  // NOTIFICATION STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _notificationStream() {
    return _firestore
        .collection(
          'notifications',
        )
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
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ======================================================
          // BACKGROUND
          // ======================================================

          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (
                  context,
                  child,
                ) {
                  return CustomPaint(
                    painter: CodingBackgroundPainter(
                      progress: _backgroundController.value,
                    ),
                  );
                },
              ),
            ),
          ),

          // ======================================================
          // LOADING
          // ======================================================

          if (_loadingStudent)
            const Center(
              child: CircularProgressIndicator(
                color: kPrimary,
              ),
            )

          // ======================================================
          // ERROR
          // ======================================================

          else if (_studentLoadError != null)
            _buildProfileError()

          // ======================================================
          // DASHBOARD
          // ======================================================

          else
            RefreshIndicator(
              color: kPrimary,
              onRefresh: _loadStudent,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  30,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ======================================
                        // STUDENT CARD
                        // ======================================

                        _buildStudentCard(),

                        const SizedBox(
                          height: 18,
                        ),

                        // ======================================
                        // ATTENDANCE
                        // ======================================

                        _buildAttendanceCard(),

                        const SizedBox(
                          height: 18,
                        ),

                        // ======================================
                        // TAKE ATTENDANCE
                        // ======================================

                        _buildAttendanceButton(),

                        const SizedBox(
                          height: 28,
                        ),

                        // ======================================
                        // SERVICES
                        // ======================================

                        Row(
                          children: [
                            Container(
                              width: 5,
                              height: 24,
                              decoration: BoxDecoration(
                                color: kPrimary,
                                borderRadius: BorderRadius.circular(
                                  10,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 9,
                            ),
                            const Text(
                              'Student Services',
                              style: TextStyle(
                                color: kTextDark,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.only(
                            left: 14,
                            top: 3,
                          ),
                          child: Text(
                            'Everything you need in one place',
                            style: TextStyle(
                              color: kTextGrey,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.08,
                          children: [
                            // ==================================
                            // NOTES
                            // ==================================

                            _buildServiceCard(
                              title: 'Download Notes',
                              subtitle: 'PDF Study Materials',
                              icon: Icons.menu_book_rounded,
                              color: const Color(
                                0xFF4F46E5,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const DownloadNotesScreen(),
                                  ),
                                );
                              },
                            ),

                            // ==================================
                            // NOTICES
                            // ==================================

                            _buildServiceCard(
                              title: 'View Notices',
                              subtitle: 'Department Updates',
                              icon: Icons.campaign_rounded,
                              color: const Color(
                                0xFF9333EA,
                              ),
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

                            // ==================================
                            // ATTENDANCE
                            // ==================================

                            _buildServiceCard(
                              title: 'Attendance',
                              subtitle: 'Subject-wise Percentage',
                              icon: Icons.fact_check_rounded,
                              color: const Color(
                                0xFF059669,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ViewAttendanceScreen(),
                                  ),
                                );
                              },
                            ),

                            // ==================================
                            // NOTIFICATIONS
                            // ==================================

                            _buildServiceCard(
                              title: 'Notifications',
                              subtitle: 'Important Alerts',
                              icon: Icons.notifications_active_rounded,
                              color: const Color(
                                0xFFDC2626,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                );
                              },
                            ),

                            // ==================================
                            // SETTINGS
                            // ==================================

                            _buildServiceCard(
                              title: 'Settings',
                              subtitle: 'Account & App Settings',
                              icon: Icons.settings_outlined,
                              color: Colors.blueGrey,
                              onTap: _openSettings,
                            ),
                          ],
                        ),
                      ],
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
  // ERROR PROFILE
  // ============================================================

  Widget _buildProfileError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              22,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.08,
                ),
                blurRadius: 20,
                offset: const Offset(
                  0,
                  10,
                ),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_off_rounded,
                  color: Colors.redAccent,
                  size: 34,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              const Text(
                'Unable to Load Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                _studentLoadError ?? 'Unable to load student profile.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: kTextGrey,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadStudent,
                  icon: const Icon(
                    Icons.refresh_rounded,
                  ),
                  label: const Text(
                    'Try Again',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(
        alpha: 0.96,
      ),
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Portal',
            style: TextStyle(
              color: kTextDark,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(
            height: 2,
          ),
          Text(
            'BCA • Salipur Autonomous College',
            style: TextStyle(
              color: kTextGrey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        // SETTINGS
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(
            Icons.settings_outlined,
            color: kTextDark,
            size: 25,
          ),
          onPressed: _openSettings,
        ),

        // NOTIFICATIONS
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _notificationStream(),
          builder: (
            context,
            snapshot,
          ) {
            final int count = snapshot.data?.docs.length ?? 0;

            return Stack(
              children: [
                IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: kTextDark,
                    size: 25,
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
                      constraints: const BoxConstraints(
                        minWidth: 17,
                        minHeight: 17,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        // PROFILE
        IconButton(
          tooltip: 'Profile',
          icon: const Icon(
            Icons.account_circle_outlined,
            color: kTextDark,
            size: 27,
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

        // LOGOUT
        Padding(
          padding: const EdgeInsets.only(
            right: 10,
          ),
          child: IconButton(
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
              size: 23,
            ),
            onPressed: _logout,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STUDENT CARD
  // ============================================================

  Widget _buildStudentCard() {
    final String name = _studentValue(
      [
        'name',
        'studentName',
        'fullName',
      ],
      'Student',
    );

    final String rollNo = _studentValue(
      [
        'rollNo',
        'rollNumber',
        'roll',
      ],
      'Roll Not Available',
    );

    final String semester = _studentValue(
      [
        'semester',
        'sem',
        'Semester',
      ],
      'Semester Not Available',
    );

    return AnimatedBuilder(
      animation: _floatingController,
      builder: (
        context,
        child,
      ) {
        final double y = math.sin(
              _floatingController.value * math.pi,
            ) *
            2;

        return Transform.translate(
          offset: Offset(
            0,
            -y,
          ),
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          20,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(
                0xFF2563EB,
              ),
              Color(
                0xFF1D4ED8,
              ),
              Color(
                0xFF0F2D6B,
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(
            24,
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(
                alpha: 0.30,
              ),
              blurRadius: 25,
              offset: const Offset(
                0,
                12,
              ),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -35,
              top: -50,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.09,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 35,
              bottom: -80,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: 0.06,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Colors.white,
                        Color(
                          0xFFDCE9FF,
                        ),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: kPrimary,
                    size: 38,
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WELCOME BACK 👋',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          _buildChip(
                            Icons.badge_outlined,
                            rollNo,
                          ),
                          _buildChip(
                            Icons.school_outlined,
                            semester,
                          ),
                        ],
                      ),
                    ],
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
  // CHIP
  // ============================================================

  Widget _buildChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.14,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.white70,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ATTENDANCE CARD
  // ============================================================

  Widget _buildAttendanceCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection(
            'attendance_sessions',
          )
          .snapshots(),
      builder: (
        context,
        sessionSnapshot,
      ) {
        if (sessionSnapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard(
            title: 'Attendance',
            value: '--',
            subtitle: 'Loading...',
            icon: Icons.pie_chart_rounded,
            color: const Color(
              0xFF059669,
            ),
            lightColor: const Color(
              0xFFECFDF5,
            ),
            progress: 0,
          );
        }

        final sessions = sessionSnapshot.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _attendanceRecordsStream(),
          builder: (
            context,
            recordSnapshot,
          ) {
            if (recordSnapshot.connectionState == ConnectionState.waiting &&
                !recordSnapshot.hasData) {
              return _buildStatCard(
                title: 'Attendance',
                value: '--',
                subtitle: 'Loading...',
                icon: Icons.pie_chart_rounded,
                color: const Color(
                  0xFF059669,
                ),
                lightColor: const Color(
                  0xFFECFDF5,
                ),
                progress: 0,
              );
            }

            final records = recordSnapshot.data?.docs ?? [];

            final Map<String, int> counts = _getAttendanceCounts(
              sessions: sessions,
              records: records,
            );

            final int total = counts['total'] ?? 0;

            final int attended = counts['attended'] ?? 0;

            final double percentage = _calculateAttendance(
              sessions: sessions,
              records: records,
            );

            return _buildStatCard(
              title: 'Attendance',
              value: '${percentage.toStringAsFixed(1)}%',
              subtitle: '$attended / $total classes',
              icon: Icons.pie_chart_rounded,
              color: const Color(
                0xFF059669,
              ),
              lightColor: const Color(
                0xFFECFDF5,
              ),
              progress: (percentage / 100).clamp(
                0.0,
                1.0,
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ATTENDANCE RECORD STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _attendanceRecordsStream() {
    final String? uid = _auth.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection(
          'attendance_records',
        )
        .where(
          'studentUid',
          isEqualTo: uid,
        )
        .snapshots();
  }

  // ============================================================
  // NORMALIZE
  // ============================================================

  String _normalize(
    dynamic value,
  ) {
    return (value ?? '').toString().trim().toLowerCase().replaceAll(
          RegExp(
            r'[\s\-_]+',
          ),
          '',
        );
  }

  // ============================================================
  // SEMESTER NORMALIZE
  // ============================================================

  String _normalizeSemester(
    dynamic value,
  ) {
    return (value ?? '').toString().replaceAll(
          RegExp(
            r'[^0-9]',
          ),
          '',
        );
  }

  // ============================================================
  // SESSION FILTER
  // ============================================================

  bool _isSessionForStudent(
    Map<String, dynamic> session,
  ) {
    final String studentDepartment = _normalize(
      _studentData?['department'] ?? 'BCA',
    );

    final String sessionDepartment = _normalize(
      session['department'] ?? 'BCA',
    );

    if (sessionDepartment.isNotEmpty &&
        studentDepartment.isNotEmpty &&
        sessionDepartment != studentDepartment) {
      return false;
    }

    final String studentSemester = _normalizeSemester(
      _studentData?['semester'],
    );

    final String sessionSemester = _normalizeSemester(
      session['semester'],
    );

    if (studentSemester.isNotEmpty &&
        sessionSemester.isNotEmpty &&
        studentSemester != sessionSemester) {
      return false;
    }

    return true;
  }

  // ============================================================
  // ATTENDED SESSION IDS
  // ============================================================

  Set<String> _getAttendedSessionIds(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> records,
  ) {
    final Set<String> ids = <String>{};

    final String uid = _auth.currentUser?.uid ?? '';

    for (final record in records) {
      final data = record.data();

      final String studentUid = (data['studentUid'] ?? '').toString().trim();

      if (studentUid.isNotEmpty && studentUid != uid) {
        continue;
      }

      final String sessionId = (data['sessionId'] ?? '').toString().trim();

      if (sessionId.isNotEmpty) {
        ids.add(
          sessionId,
        );
      }
    }

    return ids;
  }

  // ============================================================
  // CALCULATE ATTENDANCE
  // ============================================================

  double _calculateAttendance({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> sessions,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> records,
  }) {
    final Set<String> attendedIds = _getAttendedSessionIds(
      records,
    );

    int total = 0;

    int attended = 0;

    final Set<String> counted = <String>{};

    for (final sessionDoc in sessions) {
      final Map<String, dynamic> session = sessionDoc.data();

      if (!_isSessionForStudent(
        session,
      )) {
        continue;
      }

      final String sessionId =
          (session['sessionId'] ?? sessionDoc.id).toString().trim();

      if (sessionId.isEmpty ||
          !counted.add(
            sessionId,
          )) {
        continue;
      }

      total++;

      if (attendedIds.contains(
        sessionId,
      )) {
        attended++;
      }
    }

    if (total == 0) {
      return 0;
    }

    return (attended / total) * 100;
  }

  // ============================================================
  // ATTENDANCE COUNTS
  // ============================================================

  Map<String, int> _getAttendanceCounts({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> sessions,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> records,
  }) {
    final Set<String> attendedIds = _getAttendedSessionIds(
      records,
    );

    int total = 0;

    int attended = 0;

    final Set<String> counted = <String>{};

    for (final sessionDoc in sessions) {
      final Map<String, dynamic> session = sessionDoc.data();

      if (!_isSessionForStudent(
        session,
      )) {
        continue;
      }

      final String sessionId =
          (session['sessionId'] ?? sessionDoc.id).toString().trim();

      if (sessionId.isEmpty ||
          !counted.add(
            sessionId,
          )) {
        continue;
      }

      total++;

      if (attendedIds.contains(
        sessionId,
      )) {
        attended++;
      }
    }

    return {
      'total': total,
      'attended': attended,
      'absent': total - attended,
    };
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color lightColor,
    required double progress,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.07,
            ),
            blurRadius: 14,
            offset: const Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            title,
            style: const TextStyle(
              color: kTextGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: kTextGrey,
              fontSize: 11,
            ),
          ),
          const SizedBox(
            height: 11,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              10,
            ),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAKE ATTENDANCE
  // ============================================================

  Widget _buildAttendanceButton() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (
        context,
        child,
      ) {
        final double scale = 1 + (_floatingController.value * 0.012);

        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(
                0xFF10B981,
              ),
              Color(
                0xFF047857,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(
            20,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(
                alpha: 0.27,
              ),
              blurRadius: 18,
              offset: const Offset(
                0,
                9,
              ),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              20,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ScanAttendanceScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(
                17,
              ),
              child: Row(
                children: [
                  Container(
                    width: 57,
                    height: 57,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.16,
                      ),
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 31,
                    ),
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Take Attendance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(
                          height: 4,
                        ),
                        Text(
                          'Scan Faculty / HOD QR Code',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.15,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SERVICE CARD
  // ============================================================

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Pressable3DCard(
      color: color,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(
          14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    color: Colors.grey.shade500,
                    size: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 13,
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: kTextDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                height: 1.25,
                color: kTextGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PRESSABLE CARD
// ============================================================

class Pressable3DCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color color;

  const Pressable3DCard({
    super.key,
    required this.child,
    required this.onTap,
    required this.color,
  });

  @override
  State<Pressable3DCard> createState() => _Pressable3DCardState();
}

class _Pressable3DCardState extends State<Pressable3DCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _pressed = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _pressed = false;
        });

        widget.onTap();
      },
      onTapCancel: () {
        setState(() {
          _pressed = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 130,
        ),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..translate(
            0.0,
            _pressed ? 4.0 : 0.0,
          )
          ..scale(
            _pressed ? 0.97 : 1.0,
          ),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: _pressed ? 0.03 : 0.07,
              ),
              blurRadius: _pressed ? 5 : 14,
              offset: Offset(
                0,
                _pressed ? 2 : 7,
              ),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

// ============================================================
// BACKGROUND PAINTER
// ============================================================

class CodingBackgroundPainter extends CustomPainter {
  final double progress;

  CodingBackgroundPainter({
    required this.progress,
  });

  final List<String> symbols = const [
    '</>',
    '{ }',
    'C',
    'C++',
    'Flutter',
    'Dart',
    '01',
    '10',
    ';',
    '()',
    '[]',
    '=>',
    'if',
    'for',
    'while',
    'void',
    'class',
    'int',
    '&&',
    '||',
    '< >',
    'return',
    'main()',
    'const',
    'final',
    'Future',
  ];

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Paint glowPaint = Paint()
      ..color = kPrimary.withValues(
        alpha: 0.075,
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        30,
      );

    canvas.drawCircle(
      Offset(
        size.width * 0.10,
        size.height * 0.16,
      ),
      120,
      glowPaint,
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.90,
        size.height * 0.48,
      ),
      145,
      glowPaint,
    );

    canvas.drawCircle(
      Offset(
        size.width * 0.30,
        size.height * 0.90,
      ),
      115,
      glowPaint,
    );

    // ========================================================
    // SYMBOLS
    // ========================================================

    for (int i = 0; i < symbols.length; i++) {
      final String symbol = symbols[i];

      final double baseX = ((i * 73) % 100) / 100;

      final double baseY = ((i * 137) % 100) / 100;

      final double speed = 0.35 + ((i % 5) * 0.08);

      double y = baseY - ((progress * speed) % 1.15);

      if (y < -0.12) {
        y += 1.15;
      }

      final double x = baseX +
          math.sin(
                (progress * math.pi * 2) + i,
              ) *
              0.018;

      final double opacity = 0.10 + ((i % 4) * 0.025);

      final double fontSize = 12 + (i % 4) * 2;

      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: symbol,
          style: TextStyle(
            color: kPrimary.withValues(
              alpha: opacity,
            ),
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final Offset position = Offset(
        x * size.width - textPainter.width / 2,
        y * size.height,
      );

      canvas.save();

      canvas.translate(
        position.dx + textPainter.width / 2,
        position.dy + textPainter.height / 2,
      );

      canvas.rotate(
        math.sin(
              progress * math.pi * 2 + i,
            ) *
            0.04,
      );

      canvas.translate(
        -textPainter.width / 2,
        -textPainter.height / 2,
      );

      textPainter.paint(
        canvas,
        Offset.zero,
      );

      canvas.restore();
    }

    // ========================================================
    // DOTS
    // ========================================================

    final Paint dotPaint = Paint()
      ..color = kPrimary.withValues(
        alpha: 0.16,
      );

    for (int i = 0; i < 45; i++) {
      final double x = ((i * 47) % 100) / 100;

      double y = (((i * 83) % 100) / 100) - (progress * 0.25);

      if (y < 0) {
        y += 1;
      }

      final double radius = 1.0 + (i % 3) * 0.7;

      canvas.drawCircle(
        Offset(
          x * size.width,
          y * size.height,
        ),
        radius,
        dotPaint,
      );
    }

    // ========================================================
    // GRID
    // ========================================================

    final Paint linePaint = Paint()
      ..color = kPrimary.withValues(
        alpha: 0.035,
      )
      ..strokeWidth = 1;

    for (int i = 0; i < 12; i++) {
      final double y = ((i * 91) % 100) / 100 * size.height;

      canvas.drawLine(
        Offset(
          0,
          y,
        ),
        Offset(
          size.width,
          y,
        ),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CodingBackgroundPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}
