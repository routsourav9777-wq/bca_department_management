import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ViewAttendanceScreen extends StatelessWidget {
  const ViewAttendanceScreen({super.key});

  final List<Map<String, dynamic>> _subjectAttendance = const [
    {'code': 'BCA-301', 'name': 'Database Management System', 'total': 24, 'attended': 22, 'pct': 91.6},
    {'code': 'BCA-302', 'name': 'Java Programming', 'total': 20, 'attended': 17, 'pct': 85.0},
    {'code': 'BCA-303', 'name': 'Operating Systems', 'total': 18, 'attended': 16, 'pct': 88.8},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: AppTheme.primaryBlue,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Text('Semester 3 Overall Attendance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    SizedBox(height: 8),
                    Text('88.5%', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Status: Good Standing (Above 75% Requirement)', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            ..._subjectAttendance.map((sub) {
              final double pct = sub['pct'];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${sub['code']}: ${sub['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: pct >= 75 ? Colors.green : Colors.red,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text('Attended: ${sub['attended']} / ${sub['total']} classes', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
