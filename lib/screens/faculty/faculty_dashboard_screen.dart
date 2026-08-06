import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'mark_attendance_screen.dart';
import 'upload_notes_screen.dart';
import 'upload_assignments_screen.dart';
import 'upload_internal_marks_screen.dart';
import 'view_students_screen.dart';
import 'view_notices_screen.dart';

class FacultyDashboardScreen extends StatelessWidget {
  const FacultyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Faculty Portal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Salipur Autonomous College - BCA',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
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
            // Profile Card
            Card(
              color: AppTheme.secondaryTeal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 36, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Prof. Santosh Kumar Sahoo',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Senior Lecturer • EMP-FAC-01',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          Text(
                            'Assigned: BCA-101, BCA-302, BCA-502',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Faculty Tasks & Management',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
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
                  title: 'Mark Attendance',
                  subtitle: 'Daily Student Attendance',
                  icon: Icons.checklist,
                  color: AppTheme.primaryBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MarkAttendanceScreen()),
                  ),
                ),
                _buildActionCard(
                  title: 'Upload PDF Notes',
                  subtitle: 'Study Material for Students',
                  icon: Icons.picture_as_pdf,
                  color: Colors.redAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FacultyUploadNotesScreen()),
                  ),
                ),
                _buildActionCard(
                  title: 'Upload Assignments',
                  subtitle: 'Tasks with Deadlines',
                  icon: Icons.assignment_turned_in,
                  color: Colors.orange.shade800,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UploadAssignmentsScreen()),
                  ),
                ),
                _buildActionCard(
                  title: 'Upload Internal Marks',
                  subtitle: 'Mid-Sem 1 & 2 Results',
                  icon: Icons.grade,
                  color: AppTheme.secondaryTeal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UploadInternalMarksScreen()),
                  ),
                ),
                _buildActionCard(
                  title: 'View Student List',
                  subtitle: 'Semester-wise Roster',
                  icon: Icons.groups,
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ViewStudentsScreen()),
                  ),
                ),
                _buildActionCard(
                  title: 'View Dept Notices',
                  subtitle: 'HOD Announcements',
                  icon: Icons.campaign,
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FacultyViewNoticesScreen()),
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
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
