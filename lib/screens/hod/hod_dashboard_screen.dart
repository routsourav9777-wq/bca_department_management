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

import 'send_push_notifications_screen.dart';
import '../faculty/mark_attendance_screen.dart';
import '../settings/settings_screen.dart';

class HODDashboardScreen extends StatefulWidget {
  const HODDashboardScreen({super.key});

  @override
  State<HODDashboardScreen> createState() => _HODDashboardScreenState();
}

class _HODDashboardScreenState extends State<HODDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _statsController;
  late AnimationController _menuController;

  @override
  void initState() {
    super.initState();

    // ============================================================
    // HEADER ANIMATION
    // ============================================================

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // ============================================================
    // STATS ANIMATION
    // ============================================================

    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    // ============================================================
    // MENU ANIMATION
    // ============================================================

    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerController.forward();

    Future.delayed(
      const Duration(milliseconds: 180),
      () {
        if (mounted) {
          _statsController.forward();
        }
      },
    );

    Future.delayed(
      const Duration(milliseconds: 300),
      () {
        if (mounted) {
          _menuController.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    _statsController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  // ============================================================
  // SAFE ANIMATED ITEM
  // ============================================================

  Widget _safeAnimatedItem({
    required Widget child,
    required int index,
  }) {
    final double start = (index * 0.08).clamp(0.0, 0.55);

    final animation = CurvedAnimation(
      parent: _menuController,
      curve: Interval(
        start,
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final double value = animation.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              25 * (1 - value),
              0,
            ),
            child: child,
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryBlue,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HOD Portal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              AppConstants.collegeName,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),

        // ========================================================
        // TOP RIGHT BUTTONS
        // ========================================================

        actions: [
          // ======================================================
          // PUSH NOTIFICATION
          // ======================================================

          IconButton(
            tooltip: 'Push Notifications',
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

          // ======================================================
          // SETTINGS
          // ======================================================

          IconButton(
            tooltip: 'Settings',
            icon: const Icon(
              Icons.settings_outlined,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
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
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
          ),

          const SizedBox(
            width: 4,
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // WELCOME HEADER
            // ====================================================

            FadeTransition(
              opacity: CurvedAnimation(
                parent: _headerController,
                curve: Curves.easeOutCubic,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: _headerController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: _buildWelcomeHeader(),
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            // ====================================================
            // DASHBOARD OVERVIEW
            // ====================================================

            _buildSectionTitle(
              icon: Icons.dashboard_rounded,
              title: 'Dashboard Overview',
              subtitle: 'Department statistics at a glance',
            ),

            const SizedBox(
              height: 12,
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
                  child: _animatedStat(
                    index: 0,
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
                          title: 'Pending',
                          value: '$pendingCount',
                          icon: Icons.pending_actions_rounded,
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
                ),

                const SizedBox(
                  width: 10,
                ),

                // =================================================
                // FACULTY
                // =================================================

                Expanded(
                  child: _animatedStat(
                    index: 1,
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
                          title: 'Faculty',
                          value: '$facultyCount',
                          icon: Icons.groups_rounded,
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
                ),

                const SizedBox(
                  width: 10,
                ),

                // =================================================
                // STUDENTS
                // =================================================

                Expanded(
                  child: _animatedStat(
                    index: 2,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('students')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final studentCount = snapshot.data?.docs.length ?? 0;

                        return _buildStatTile(
                          title: 'Students',
                          value: '$studentCount',
                          icon: Icons.school_rounded,
                          color: AppTheme.primaryBlue,
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
                ),
              ],
            ),

            const SizedBox(
              height: 28,
            ),

            // ====================================================
            // MANAGEMENT TITLE
            // ====================================================

            _buildSectionTitle(
              icon: Icons.apps_rounded,
              title: 'HOD Management',
              subtitle: 'Swipe to access all department tools',
            ),

            const SizedBox(
              height: 12,
            ),

            // ====================================================
            // HORIZONTAL MANAGEMENT BAR
            // ====================================================

            Container(
              height: 155,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  children: [
                    // ==================================================
                    // MANAGE SUBJECTS
                    // ==================================================

                    _safeAnimatedItem(
                      index: 0,
                      child: _buildHorizontalCard(
                        title: 'Subjects',
                        subtitle: 'Manage Subjects',
                        icon: Icons.menu_book_rounded,
                        color: AppTheme.secondaryTeal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ManageSubjectsScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    // ==================================================
                    // UPLOAD NOTICES
                    // ==================================================

                    _safeAnimatedItem(
                      index: 1,
                      child: _buildHorizontalCard(
                        title: 'Notices',
                        subtitle: 'Upload Notices',
                        icon: Icons.campaign_rounded,
                        color: Colors.deepPurple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UploadNoticeScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    // ==================================================
                    // PDF NOTES
                    // ==================================================

                    _safeAnimatedItem(
                      index: 2,
                      child: _buildHorizontalCard(
                        title: 'PDF Notes',
                        subtitle: 'Study Materials',
                        icon: Icons.picture_as_pdf_rounded,
                        color: Colors.indigo,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UploadNotesScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    // ==================================================
                    // ATTENDANCE REPORTS
                    // ==================================================

                    _safeAnimatedItem(
                      index: 3,
                      child: _buildHorizontalCard(
                        title: 'Attendance',
                        subtitle: 'View Reports',
                        icon: Icons.fact_check_rounded,
                        color: Colors.green.shade700,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ViewAttendanceReportsScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    // ==================================================
                    // MARK ATTENDANCE
                    // ==================================================

                    _safeAnimatedItem(
                      index: 4,
                      child: _buildHorizontalCard(
                        title: 'Mark',
                        subtitle: 'Mark Attendance',
                        icon: Icons.how_to_reg_rounded,
                        color: Colors.teal.shade700,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MarkAttendanceScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    // ==================================================
                    // PUSH NOTIFICATIONS
                    // ==================================================

                    _safeAnimatedItem(
                      index: 5,
                      child: _buildHorizontalCard(
                        title: 'Push',
                        subtitle: 'Notifications',
                        icon: Icons.send_rounded,
                        color: Colors.redAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const SendPushNotificationsScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(
                      width: 4,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // ====================================================
            // SWIPE HINT
            // ====================================================

            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.swipe_rounded,
                    size: 17,
                    color: Colors.grey,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(
                    'Swipe left/right for more options',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ====================================================
            // BOTTOM INFO
            // ====================================================

            _buildBottomInfo(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ANIMATED STATS
  // ============================================================

  Widget _animatedStat({
    required int index,
    required Widget child,
  }) {
    final double start = (index * 0.12).clamp(0.0, 0.45);

    final animation = CurvedAnimation(
      parent: _statsController,
      curve: Interval(
        start,
        1.0,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final double value = animation.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              0,
              20 * (1 - value),
            ),
            child: child,
          ),
        );
      },
    );
  }

  // ============================================================
  // WELCOME HEADER
  // ============================================================

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue,
            AppTheme.secondaryTeal,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ==================================================
            // DECORATIVE CIRCLE 1
            // ==================================================

            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),

            // ==================================================
            // DECORATIVE CIRCLE 2
            // ==================================================

            Positioned(
              right: 35,
              bottom: -60,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 35,
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
                          'Welcome, Mohanty Sir 👋',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        const Text(
                          'Head of Department • BCA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          AppConstants.collegeName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
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

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 7,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
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
  // HORIZONTAL MANAGEMENT CARD
  // ============================================================

  Widget _buildHorizontalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 118,
      height: 130,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          splashColor: color.withValues(alpha: 0.10),
          highlightColor: color.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFD),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: color.withValues(alpha: 0.16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =================================================
                // ICON
                // =================================================

                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 23,
                  ),
                ),

                const Spacer(),

                // =================================================
                // TITLE
                // =================================================

                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                // =================================================
                // SUBTITLE
                // =================================================

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM INFO
  // ============================================================

  Widget _buildBottomInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.secondaryTeal.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.security_rounded,
              color: AppTheme.secondaryTeal,
              size: 20,
            ),
          ),
          const SizedBox(
            width: 11,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Department Admin Panel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                SizedBox(
                  height: 3,
                ),
                Text(
                  'All BCA department management tools are available above.',
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
