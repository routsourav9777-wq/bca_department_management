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

  late AnimationController _entryController;
  late AnimationController _backgroundController;
  late AnimationController _floatingController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // MAIN SCREEN ANIMATION
    // ==========================================================

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    // ==========================================================
    // BACKGROUND CONTINUOUSLY MOVES
    // ==========================================================

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    // ==========================================================
    // CARDS FLOATING ANIMATION
    // ==========================================================

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );

    _loadStudent();

    Future.delayed(
      const Duration(milliseconds: 150),
      () {
        if (mounted) {
          _entryController.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _backgroundController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD STUDENT
  // ==========================================================

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

      final QuerySnapshot<Map<String, dynamic>> uidQuery = await _firestore
          .collection('students')
          .where(
            'uid',
            isEqualTo: user.uid,
          )
          .limit(1)
          .get();

      if (uidQuery.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _studentData = uidQuery.docs.first.data();
            _loadingStudent = false;
          });
        }
        return;
      }

      // --------------------------------------------------------
      // SEARCH BY EMAIL
      // --------------------------------------------------------

      if (user.email != null) {
        final QuerySnapshot<Map<String, dynamic>> emailQuery = await _firestore
            .collection('students')
            .where(
              'email',
              isEqualTo: user.email,
            )
            .limit(1)
            .get();

        if (emailQuery.docs.isNotEmpty) {
          if (mounted) {
            setState(() {
              _studentData = emailQuery.docs.first.data();
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
      debugPrint('Student load error: $e');

      if (mounted) {
        setState(() {
          _loadingStudent = false;
        });
      }
    }
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

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

  // ==========================================================
  // OPEN SETTINGS
  // ==========================================================

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  // ==========================================================
  // STUDENT VALUE
  // ==========================================================

  String _studentValue(
    String key,
    String fallback,
  ) {
    final dynamic value = _studentData?[key];

    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  // ==========================================================
  // NOTIFICATION STREAM
  // ==========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _notificationStream() {
    return _firestore
        .collection('notifications')
        .where(
          'department',
          isEqualTo: 'BCA',
        )
        .snapshots();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ====================================================
          // ANIMATED CODING BACKGROUND
          // ====================================================

          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _backgroundController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: CodingBackgroundPainter(
                      progress: _backgroundController.value,
                    ),
                  );
                },
              ),
            ),
          ),

          // ====================================================
          // CONTENT
          // ====================================================

          _loadingStudent
              ? const Center(
                  child: CircularProgressIndicator(
                    color: kPrimary,
                  ),
                )
              : RefreshIndicator(
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
                            _buildStudentCard(),

                            const SizedBox(height: 18),

                            // ==================================================
                            // ATTENDANCE + MARKS
                            // ==================================================

                            Row(
                              children: [
                                Expanded(
                                  child: _buildAttendanceCard(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildMarksCard(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // ==================================================
                            // TAKE ATTENDANCE
                            // ==================================================

                            _buildAttendanceButton(),

                            const SizedBox(height: 28),

                            // ==================================================
                            // STUDENT SERVICES TITLE
                            // ==================================================

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
                                const SizedBox(width: 9),
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

                            const SizedBox(height: 15),

                            // ==================================================
                            // SERVICES GRID
                            // ==================================================

                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.08,
                              children: [
                                // ============================================
                                // DOWNLOAD NOTES
                                // ============================================

                                _buildServiceCard(
                                  title: 'Download Notes',
                                  subtitle: 'PDF Study Materials',
                                  icon: Icons.menu_book_rounded,
                                  color: const Color(0xFF4F46E5),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const DownloadNotesScreen(),
                                      ),
                                    );
                                  },
                                ),

                                // ============================================
                                // VIEW NOTICES
                                // ============================================

                                _buildServiceCard(
                                  title: 'View Notices',
                                  subtitle: 'Department Updates',
                                  icon: Icons.campaign_rounded,
                                  color: const Color(0xFF9333EA),
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

                                // ============================================
                                // ATTENDANCE
                                // ============================================

                                _buildServiceCard(
                                  title: 'Attendance',
                                  subtitle: 'Subject-wise Percentage',
                                  icon: Icons.fact_check_rounded,
                                  color: const Color(0xFF059669),
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

                                // ============================================
                                // NOTIFICATIONS
                                // ============================================

                                _buildServiceCard(
                                  title: 'Notifications',
                                  subtitle: 'Important Alerts',
                                  icon: Icons.notifications_active_rounded,
                                  color: const Color(0xFFDC2626),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                ),

                                // ============================================
                                // SETTINGS
                                // ============================================

                                _buildServiceCard(
                                  title: 'Settings',
                                  subtitle: 'Account & App Settings',
                                  icon: Icons.settings_outlined,
                                  color: Colors.blueGrey,
                                  onTap: _openSettings,
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
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

  // ==========================================================
  // APP BAR
  // ==========================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.96),
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
          SizedBox(height: 2),
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
        // ========================================================
        // SETTINGS
        // ========================================================

        IconButton(
          tooltip: 'Settings',
          icon: const Icon(
            Icons.settings_outlined,
            color: kTextDark,
            size: 25,
          ),
          onPressed: _openSettings,
        ),

        // ========================================================
        // NOTIFICATIONS
        // ========================================================

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _notificationStream(),
          builder: (context, snapshot) {
            final int count = snapshot.data?.docs.length ?? 0;

            return Stack(
              children: [
                IconButton(
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

        // ========================================================
        // PROFILE
        // ========================================================

        IconButton(
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

        // ========================================================
        // LOGOUT
        // ========================================================

        Padding(
          padding: const EdgeInsets.only(
            right: 10,
          ),
          child: IconButton(
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

  // ==========================================================
  // STUDENT CARD
  // ==========================================================

  Widget _buildStudentCard() {
    final String name = _studentValue(
      'name',
      'Student',
    );

    final String roll = _studentValue(
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

    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        final double y = math.sin(
              _floatingController.value * math.pi,
            ) *
            2;

        return Transform.translate(
          offset: Offset(0, -y),
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2563EB),
              Color(0xFF1D4ED8),
              Color(0xFF0F2D6B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.30),
              blurRadius: 25,
              offset: const Offset(0, 12),
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
                  color: Colors.white.withValues(alpha: 0.09),
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
                  color: Colors.white.withValues(alpha: 0.06),
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
                        Color(0xFFDCE9FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: kPrimary,
                    size: 38,
                  ),
                ),
                const SizedBox(width: 16),
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
                      const SizedBox(height: 4),
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
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: [
                          _buildChip(
                            Icons.badge_outlined,
                            'Roll $roll',
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

  // ==========================================================
  // CHIP
  // ==========================================================

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
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
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
          const SizedBox(width: 4),
          Text(
            text,
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

  // ==========================================================
  // ATTENDANCE CARD
  // ==========================================================

  Widget _buildAttendanceCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _attendanceSessionsStream(),
      builder: (
        context,
        sessionSnapshot,
      ) {
        if (sessionSnapshot.connectionState == ConnectionState.waiting) {
          return _buildStatCard(
            title: 'Attendance',
            value: '--',
            subtitle: 'Overall',
            icon: Icons.pie_chart_rounded,
            color: const Color(0xFF059669),
            lightColor: const Color(0xFFECFDF5),
            progress: 0,
          );
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> sessions =
            sessionSnapshot.data?.docs ?? [];

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
                subtitle: 'Overall',
                icon: Icons.pie_chart_rounded,
                color: const Color(0xFF059669),
                lightColor: const Color(0xFFECFDF5),
                progress: 0,
              );
            }

            final List<QueryDocumentSnapshot<Map<String, dynamic>>> records =
                recordSnapshot.data?.docs ?? [];

            // --------------------------------------------------
            // GET ATTENDANCE COUNTS
            // --------------------------------------------------

            final Map<String, int> counts = _getAttendanceCounts(
              sessions: sessions,
              records: records,
            );

            final int totalClasses = counts['total'] ?? 0;

            final int attendedClasses = counts['attended'] ?? 0;

            // --------------------------------------------------
            // CALCULATE PERCENTAGE
            // --------------------------------------------------

            final double percentage = _calculateAttendanceFromSessions(
              sessions: sessions,
              records: records,
            );

            final bool hasData = totalClasses > 0;

            return _buildStatCard(
              title: 'Attendance',
              value: hasData ? '${percentage.toStringAsFixed(1)}%' : '--',
              subtitle: hasData
                  ? '$attendedClasses / $totalClasses classes'
                  : 'Overall',
              icon: Icons.pie_chart_rounded,
              color: const Color(0xFF059669),
              lightColor: const Color(0xFFECFDF5),
              progress: hasData ? (percentage / 100).clamp(0.0, 1.0) : 0,
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // MARKS CARD
  // ==========================================================

  Widget _buildMarksCard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _marksStream(),
      builder: (context, snapshot) {
        final double average = _calculateMarksAverage(
          snapshot.data?.docs ?? [],
        );

        final bool hasData = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return _buildStatCard(
          title: 'Mid-Sem Marks',
          value: hasData ? average.toStringAsFixed(1) : '--',
          subtitle: 'Average / 20',
          icon: Icons.star_rounded,
          color: const Color(0xFFD97706),
          lightColor: const Color(0xFFFFFBEB),
          progress: hasData ? (average / 20).clamp(0.0, 1.0) : 0,
        );
      },
    );
  }

  // ==========================================================
  // STAT CARD
  // ==========================================================

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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.more_horiz_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: kTextGrey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: kTextGrey,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
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

  // ==========================================================
  // ATTENDANCE BUTTON
  // ==========================================================

  Widget _buildAttendanceButton() {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
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
              Color(0xFF10B981),
              Color(0xFF047857),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.27),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ScanAttendanceScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Row(
                children: [
                  Container(
                    width: 57,
                    height: 57,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 31,
                    ),
                  ),
                  const SizedBox(width: 14),
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
                        SizedBox(height: 4),
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
                      color: Colors.white.withValues(alpha: 0.15),
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

  // ==========================================================
  // SERVICE CARD
  // ==========================================================

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
        padding: const EdgeInsets.all(14),
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
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
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
            const SizedBox(height: 13),
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
            const SizedBox(height: 4),
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

  // ==========================================================
  // ATTENDANCE SESSIONS STREAM
  // ==========================================================
  //
  // TOTAL CLASSES COME FROM attendance_sessions
  //
  // Example:
  //
  // attendance_sessions = 29
  //
  // ==========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _attendanceSessionsStream() {
    return _firestore.collection('attendance_sessions').snapshots();
  }

  // ==========================================================
  // ATTENDANCE RECORDS STREAM
  // ==========================================================
  //
  // PRESENT CLASSES COME FROM attendance_records
  //
  // ==========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _attendanceRecordsStream() {
    final String uid = _auth.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('attendance_records')
        .where(
          'studentUid',
          isEqualTo: uid,
        )
        .snapshots();
  }

  // ==========================================================
  // NORMALIZE VALUE
  // ==========================================================

  String _normalizeValue(dynamic value) {
    return value?.toString().trim().toLowerCase().replaceAll(
              RegExp(r'[\s\-_]+'),
              '',
            ) ??
        '';
  }

  // ==========================================================
  // CHECK SESSION FOR STUDENT
  // ==========================================================
  //
  // A session is counted only if it belongs to:
  //
  // Student Department
  // Student Semester
  //
  // ==========================================================

  bool _isSessionForStudent(
    Map<String, dynamic> session,
  ) {
    // --------------------------------------------------------
    // STUDENT DEPARTMENT
    // --------------------------------------------------------

    final String studentDepartment = _normalizeValue(
      _studentData?['department'] ?? _studentData?['dept'] ?? 'BCA',
    );

    final String sessionDepartment = _normalizeValue(
      session['department'] ?? 'BCA',
    );

    if (sessionDepartment.isNotEmpty &&
        studentDepartment.isNotEmpty &&
        sessionDepartment != studentDepartment) {
      return false;
    }

    // --------------------------------------------------------
    // STUDENT SEMESTER
    // --------------------------------------------------------

    final String studentSemester = _normalizeValue(
      _studentData?['semester'] ?? _studentData?['sem'] ?? '',
    );

    final String sessionSemester = _normalizeValue(
      session['semester'] ?? session['sem'] ?? '',
    );

    if (studentSemester.isNotEmpty &&
        sessionSemester.isNotEmpty &&
        sessionSemester != studentSemester) {
      return false;
    }

    return true;
  }

  // ==========================================================
  // GET ATTENDED SESSION IDS
  // ==========================================================

  Set<String> _getAttendedSessionIds(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> records,
  ) {
    final Set<String> attendedSessionIds = <String>{};

    final String uid = _auth.currentUser?.uid ?? '';

    for (final QueryDocumentSnapshot<Map<String, dynamic>> record in records) {
      final Map<String, dynamic> data = record.data();

      final String studentUid = (data['studentUid'] ?? '').toString().trim();

      // ------------------------------------------------------
      // SAFETY CHECK
      // ------------------------------------------------------

      if (studentUid.isNotEmpty && studentUid != uid) {
        continue;
      }

      // ------------------------------------------------------
      // SESSION ID FIELD
      // ------------------------------------------------------

      final String sessionId = (data['sessionId'] ?? '').toString().trim();

      if (sessionId.isNotEmpty) {
        attendedSessionIds.add(sessionId);
      }

      // ------------------------------------------------------
      // DOCUMENT ID FALLBACK
      // ------------------------------------------------------
      //
      // Scanner creates:
      //
      // ${sessionId}_${studentUid}
      //
      // ------------------------------------------------------

      if (sessionId.isEmpty && uid.isNotEmpty) {
        final String suffix = '_$uid';

        if (record.id.endsWith(suffix)) {
          final String extractedSessionId = record.id
              .substring(
                0,
                record.id.length - suffix.length,
              )
              .trim();

          if (extractedSessionId.isNotEmpty) {
            attendedSessionIds.add(
              extractedSessionId,
            );
          }
        }
      }
    }

    return attendedSessionIds;
  }

  // ==========================================================
  // ATTENDANCE CALCULATION
  // ==========================================================
  //
  // TOTAL = attendance_sessions
  //
  // PRESENT = attendance_records
  //
  // Example:
  //
  // Total     = 29
  // Attended  = 6
  //
  // 6 / 29 × 100
  //
  // = 20.7%
  //
  // ==========================================================

  double _calculateAttendanceFromSessions({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> sessions,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> records,
  }) {
    if (sessions.isEmpty) {
      return 0;
    }

    final Set<String> attendedSessionIds = _getAttendedSessionIds(records);

    int totalClasses = 0;
    int attendedClasses = 0;

    final Set<String> countedSessionIds = <String>{};

    // --------------------------------------------------------
    // LOOP THROUGH ALL ATTENDANCE SESSIONS
    // --------------------------------------------------------

    for (final QueryDocumentSnapshot<Map<String, dynamic>> sessionDoc
        in sessions) {
      final Map<String, dynamic> session = sessionDoc.data();

      // ------------------------------------------------------
      // FILTER BY STUDENT DEPARTMENT + SEMESTER
      // ------------------------------------------------------

      if (!_isSessionForStudent(session)) {
        continue;
      }

      // ------------------------------------------------------
      // GET SESSION ID
      // ------------------------------------------------------

      final String sessionId =
          (session['sessionId'] ?? sessionDoc.id).toString().trim();

      if (sessionId.isEmpty) {
        continue;
      }

      // ------------------------------------------------------
      // PREVENT DUPLICATE SESSION COUNT
      // ------------------------------------------------------

      if (!countedSessionIds.add(
        sessionId,
      )) {
        continue;
      }

      // ------------------------------------------------------
      // TOTAL CLASS +1
      // ------------------------------------------------------

      totalClasses++;

      // ------------------------------------------------------
      // STUDENT ATTENDED THIS SESSION?
      // ------------------------------------------------------

      if (attendedSessionIds.contains(
        sessionId,
      )) {
        attendedClasses++;
      }
    }

    // --------------------------------------------------------
    // NO CLASSES
    // --------------------------------------------------------

    if (totalClasses == 0) {
      return 0;
    }

    // --------------------------------------------------------
    // FINAL PERCENTAGE
    // --------------------------------------------------------

    return (attendedClasses / totalClasses) * 100;
  }

  // ==========================================================
  // ATTENDANCE COUNTS
  // ==========================================================

  Map<String, int> _getAttendanceCounts({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> sessions,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> records,
  }) {
    final Set<String> attendedSessionIds = _getAttendedSessionIds(records);

    int totalClasses = 0;
    int attendedClasses = 0;

    final Set<String> countedSessionIds = <String>{};

    // --------------------------------------------------------
    // COUNT SESSIONS
    // --------------------------------------------------------

    for (final QueryDocumentSnapshot<Map<String, dynamic>> sessionDoc
        in sessions) {
      final Map<String, dynamic> session = sessionDoc.data();

      if (!_isSessionForStudent(session)) {
        continue;
      }

      final String sessionId =
          (session['sessionId'] ?? sessionDoc.id).toString().trim();

      if (sessionId.isEmpty) {
        continue;
      }

      if (!countedSessionIds.add(
        sessionId,
      )) {
        continue;
      }

      totalClasses++;

      if (attendedSessionIds.contains(
        sessionId,
      )) {
        attendedClasses++;
      }
    }

    return <String, int>{
      'total': totalClasses,
      'attended': attendedClasses,
      'absent': totalClasses - attendedClasses,
    };
  }

  // ==========================================================
  // MARKS STREAM
  // ==========================================================

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

  // ==========================================================
  // MARKS CALCULATION
  // ==========================================================

  double _calculateMarksAverage(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) {
      return 0;
    }

    double totalObtained = 0;
    double totalMax = 0;

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in docs) {
      final Map<String, dynamic> data = doc.data();

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

    return (totalObtained / totalMax) * 20;
  }
}

// =================================================================
// 3D PRESSABLE CARD
// =================================================================

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
        duration: const Duration(milliseconds: 130),
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
          borderRadius: BorderRadius.circular(18),
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
            BoxShadow(
              color: widget.color.withValues(
                alpha: 0.04,
              ),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

// =================================================================
// ANIMATED CODING BACKGROUND
// =================================================================

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
    // ==========================================================
    // STRONGER BLUE GLOW
    // ==========================================================

    final Paint glowPaint = Paint()
      ..color = kPrimary.withValues(alpha: 0.075)
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

    // ==========================================================
    // CODE SYMBOLS
    // ==========================================================

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
            letterSpacing: 0.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final Offset position = Offset(
        x * size.width - textPainter.width / 2,
        y * size.height,
      );

      // ========================================================
      // 3D ROTATION
      // ========================================================

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

    // ==========================================================
    // MOVING DOTS
    // ==========================================================

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

    // ==========================================================
    // SMALL GRID / CODE LINES
    // ==========================================================

    final Paint linePaint = Paint()
      ..color = kPrimary.withValues(
        alpha: 0.035,
      )
      ..strokeWidth = 1;

    for (int i = 0; i < 12; i++) {
      final double y = ((i * 91) % 100) / 100 * size.height;

      canvas.drawLine(
        Offset(0, y),
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
