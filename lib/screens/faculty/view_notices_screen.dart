import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FacultyViewNoticesScreen extends StatelessWidget {
  const FacultyViewNoticesScreen({super.key});

  final List<Map<String, String>> _notices = const [
    {
      'title': 'Mid-Sem Examination 2026 Schedule Released',
      'date': '04 Aug 2026',
      'author': 'HOD (BCA)',
      'content': 'All faculty members are requested to submit the Mid-Sem question papers for Semesters 1, 3, and 5 by August 10th.',
    },
    {
      'title': 'Internal Academic Audit & Attendance Verification',
      'date': '01 Aug 2026',
      'author': 'Principal Office',
      'content': 'Please verify and upload the month-end attendance percentage of all BCA students in the app.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Department Notices')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notices.length,
        itemBuilder: (context, index) {
          final n = _notices[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(6)),
                        child: Text(n['author']!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      Text(n['date']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(n['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(n['content']!, style: const TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
