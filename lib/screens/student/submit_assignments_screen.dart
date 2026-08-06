import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SubmitAssignmentsScreen extends StatefulWidget {
  const SubmitAssignmentsScreen({super.key});

  @override
  State<SubmitAssignmentsScreen> createState() => _SubmitAssignmentsScreenState();
}

class _SubmitAssignmentsScreenState extends State<SubmitAssignmentsScreen> {
  final List<Map<String, dynamic>> _assignments = [
    {
      'title': 'DBMS Normalization & BCNF Problems',
      'subject': 'BCA-301 DBMS',
      'dueDate': '12 Aug 2026',
      'submitted': false,
    },
    {
      'title': 'Java Multithreading & GUI Swing App',
      'subject': 'BCA-302 Java',
      'dueDate': '15 Aug 2026',
      'submitted': true,
      'submittedDate': '03 Aug 2026',
    },
  ];

  void _submitFile(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Submit Solution: ${_assignments[index]['title']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              label: const Text('Select Solution PDF File'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _assignments[index]['submitted'] = true;
                  _assignments[index]['submittedDate'] = 'Today';
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Assignment solution submitted successfully!'), backgroundColor: Colors.green),
                );
              },
              child: const Text('Confirm Upload to Firebase'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Assignments')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _assignments.length,
        itemBuilder: (context, index) {
          final asg = _assignments[index];
          final isSubmitted = asg['submitted'] as bool;

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
                        decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(asg['subject']!, style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSubmitted ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isSubmitted ? 'Submitted' : 'Pending',
                          style: TextStyle(color: isSubmitted ? Colors.green : Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(asg['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Due Date: ${asg['dueDate']}', style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),

                  if (isSubmitted)
                    Text('✔ Submitted on ${asg['submittedDate']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                  else
                    ElevatedButton.icon(
                      onPressed: () => _submitFile(index),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Solution PDF'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
