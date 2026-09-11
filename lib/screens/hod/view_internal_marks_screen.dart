import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class ViewInternalMarksScreen extends StatefulWidget {
  const ViewInternalMarksScreen({super.key});

  @override
  State<ViewInternalMarksScreen> createState() => _ViewInternalMarksScreenState();
}

class _ViewInternalMarksScreenState extends State<ViewInternalMarksScreen> {
  String _selectedSem = AppConstants.semesters[2]; // Sem 3

  final List<Map<String, dynamic>> _marksList = [
    {'rollNo': 'BC23-001', 'name': 'Aakash Mohanty', 'subject': 'BCA-301 (DBMS)', 'exam': 'Mid-Sem 1', 'marks': 18.5, 'max': 20},
    {'rollNo': 'BC23-002', 'name': 'Aditya Prasad Das', 'subject': 'BCA-301 (DBMS)', 'exam': 'Mid-Sem 1', 'marks': 16.0, 'max': 20},
    {'rollNo': 'BC23-003', 'name': 'Ankit Nayak', 'subject': 'BCA-301 (DBMS)', 'exam': 'Mid-Sem 1', 'marks': 14.5, 'max': 20},
    {'rollNo': 'BC23-004', 'name': 'Bishnupriya Sahoo', 'subject': 'BCA-301 (DBMS)', 'exam': 'Mid-Sem 1', 'marks': 19.5, 'max': 20},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internal Marks Register'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Semester: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSem,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: AppConstants.semesters
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSem = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _marksList.length,
              itemBuilder: (context, index) {
                final m = _marksList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${m['marks']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue),
                      ),
                    ),
                    title: Text('${m['rollNo']} • ${m['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${m['subject']} | Exam: ${m['exam']}'),
                    trailing: Text(
                      'Max: ${m['max']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
