import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StudentViewInternalMarksScreen extends StatelessWidget {
  const StudentViewInternalMarksScreen({super.key});

  final List<Map<String, dynamic>> _marks = const [
    {'subject': 'BCA-301 DBMS', 'exam': 'Mid-Sem Test 1', 'obtained': 18.5, 'max': 20.0},
    {'subject': 'BCA-302 Java', 'exam': 'Mid-Sem Test 1', 'obtained': 17.0, 'max': 20.0},
    {'subject': 'BCA-303 OS', 'exam': 'Mid-Sem Test 1', 'obtained': 19.0, 'max': 20.0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Internal Marks')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _marks.length,
        itemBuilder: (context, index) {
          final m = _marks[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                child: Text('${m['obtained']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              ),
              title: Text(m['subject']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Exam: ${m['exam']}'),
              trailing: Text('Max: ${m['max']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          );
        },
      ),
    );
  }
}
