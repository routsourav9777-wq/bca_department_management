import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StudentViewNoticesScreen extends StatelessWidget {
  const StudentViewNoticesScreen({super.key});

  final List<Map<String, String>> _notices = const [
    {
      'title': 'BCA Semester 3 Mid-Sem Examination Time Table 2026',
      'date': '04 Aug 2026',
      'author': 'HOD BCA',
      'content': 'The Mid-Sem examination for BCA Semester 3 will commence on August 16th. Attendance above 75% is strictly mandatory.',
    },
    {
      'title': 'Submission of Choice Based Credit System (CBCS) Forms',
      'date': '02 Aug 2026',
      'author': 'Dept Office',
      'content': 'All Semester 3 students must fill out the CBCS elective subject preference form at the BCA Lab by August 10th.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Department Notice Board')),
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
