import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class ViewStudentsScreen extends StatefulWidget {
  const ViewStudentsScreen({super.key});

  @override
  State<ViewStudentsScreen> createState() => _ViewStudentsScreenState();
}

class _ViewStudentsScreenState extends State<ViewStudentsScreen> {
  String _selectedSem = AppConstants.semesters[2];

  final List<Map<String, String>> _studentsList = [
    {'rollNo': 'BC23-001', 'name': 'Aakash Mohanty', 'email': 'aakash.m@salipurcollege.ac.in', 'phone': '+91 9876500001'},
    {'rollNo': 'BC23-002', 'name': 'Aditya Prasad Das', 'email': 'aditya.d@salipurcollege.ac.in', 'phone': '+91 9876500002'},
    {'rollNo': 'BC23-003', 'name': 'Ankit Nayak', 'email': 'ankit.n@salipurcollege.ac.in', 'phone': '+91 9876500003'},
    {'rollNo': 'BC23-004', 'name': 'Bishnupriya Sahoo', 'email': 'bishnupriya.s@salipurcollege.ac.in', 'phone': '+91 9876500004'},
    {'rollNo': 'BC23-005', 'name': 'Debasis Rout', 'email': 'debasis.r@salipurcollege.ac.in', 'phone': '+91 9876500005'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BCA Student Directory')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: DropdownButtonFormField<String>(
              value: _selectedSem,
              decoration: const InputDecoration(labelText: 'Filter by Semester'),
              items: AppConstants.semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) { if (val != null) setState(() => _selectedSem = val); },
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _studentsList.length,
              itemBuilder: (context, index) {
                final st = _studentsList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                      child: Text(st['rollNo']!.replaceAll('BC23-', ''), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                    ),
                    title: Text('${st['rollNo']} • ${st['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('📧 ${st['email']}'),
                        Text('📞 ${st['phone']}'),
                      ],
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
