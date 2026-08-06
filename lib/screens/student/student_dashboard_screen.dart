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

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student Portal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Salipur Autonomous College', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
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
            // Student Banner
            Card(
              color: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.school, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Priyanka Mohapatra',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Roll No: BC23-045 • Semester 3',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          Text(
                            'BCA Honors • Salipur Autonomous College',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Attendance & Performance Quick Bar
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: const [
                          Icon(Icons.pie_chart, color: Colors.green, size: 28),
                          SizedBox(height: 6),
                          Text('88.5%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                          Text('Overall Attendance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: const [
                          Icon(Icons.star_rounded, color: AppTheme.primaryBlue, size: 28),
                          SizedBox(height: 6),
                          Text('18.5 / 20', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryBlue)),
                          Text('Mid-Sem Average', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Student Services & Modules',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _buildActionCard(
                  title: 'Download Notes',
                  subtitle: 'PDF Study Materials',
                  icon: Icons.file_download,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DownloadNotesScreen()),
                  ),
                ),
                _buildActionCard(
                  title: 'View Notices',
                  subtitle: 'Dept Announcements',
                  icon: Icons.campaign,
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentViewNoticesScreen()),
                  ),
                ),
                _buildActionCard(
                  title: 'Submit Assignments',
                  subtitle: 'Upload Homework & PDF',
                  icon: Icons.upload_file,
                  color: Colors.orange.shade800,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubmitAssignmentsScreen()),
                  ),
                ),
                _buildActionCard(
                  title: 'View Attendance %',
                  subtitle: 'Subject-wise Percentage',
                  icon: Icons.fact_check_outlined,
                  color: Colors.green.shade700,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ViewAttendanceScreen()),
                  ),
                ),
                _buildActionCard(
                  title: 'View Internal Marks',
                  subtitle: 'Mid-Sem Results',
                  icon: Icons.analytics_outlined,
                  color: AppTheme.secondaryTeal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentViewInternalMarksScreen()),
                  ),
                ),
                _buildActionCard(
                  title: 'Push Notifications',
                  subtitle: 'Lock-screen Alerts',
                  icon: Icons.circle_notifications,
                  color: Colors.redAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
