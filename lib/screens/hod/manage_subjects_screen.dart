import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  String _selectedSemester = AppConstants.semesters[0];

  final Map<String, List<Map<String, String>>> _semesterSubjects = {
    'Semester 1': [
      {
        'code': 'BCA-101',
        'name': 'Programming in C',
        'credits': '4',
        'faculty': 'Prof. Santosh Kumar Sahoo'
      },
      {
        'code': 'BCA-102',
        'name': 'Digital Electronics',
        'credits': '4',
        'faculty': 'Dr. Smruti Rekha Das'
      },
      {
        'code': 'BCA-103',
        'name': 'Discrete Mathematics',
        'credits': '3',
        'faculty': 'Er. Manoranjan Swain'
      },
    ],
    'Semester 2': [
      {
        'code': 'BCA-201',
        'name': 'Data Structures using C++',
        'credits': '4',
        'faculty': 'Prof. Santosh Kumar Sahoo'
      },
      {
        'code': 'BCA-202',
        'name': 'Computer Architecture',
        'credits': '4',
        'faculty': 'Dr. Smruti Rekha Das'
      },
    ],
    'Semester 3': [
      {
        'code': 'BCA-301',
        'name': 'Database Management System (DBMS)',
        'credits': '4',
        'faculty': 'Dr. Smruti Rekha Das'
      },
      {
        'code': 'BCA-302',
        'name': 'Java Programming',
        'credits': '4',
        'faculty': 'Prof. Santosh Kumar Sahoo'
      },
      {
        'code': 'BCA-303',
        'name': 'Operating Systems',
        'credits': '4',
        'faculty': 'Er. Manoranjan Swain'
      },
    ],
    'Semester 4': [
      {
        'code': 'BCA-401',
        'name': 'Computer Networks',
        'credits': '4',
        'faculty': 'Er. Manoranjan Swain'
      },
      {
        'code': 'BCA-402',
        'name': 'Software Engineering',
        'credits': '4',
        'faculty': 'Dr. Smruti Rekha Das'
      },
    ],
    'Semester 5': [
      {
        'code': 'BCA-501',
        'name': 'Web Technology & PHP',
        'credits': '4',
        'faculty': 'Er. Manoranjan Swain'
      },
      {
        'code': 'BCA-502',
        'name': 'Python & Data Science',
        'credits': '4',
        'faculty': 'Prof. Santosh Kumar Sahoo'
      },
    ],
    'Semester 6': [
      {
        'code': 'BCA-601',
        'name': 'Cloud Computing & Cyber Security',
        'credits': '4',
        'faculty': 'Dr. Smruti Rekha Das'
      },
      {
        'code': 'BCA-602',
        'name': 'Major Project & Viva',
        'credits': '6',
        'faculty': 'Prof. Santosh Kumar Sahoo'
      },
    ],
  };

  void _addSubjectDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final creditCtrl = TextEditingController(text: '4');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Subject to $_selectedSemester'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Subject Code (e.g. BCA-304)')),
            const SizedBox(height: 12),
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Subject Title')),
            const SizedBox(height: 12),
            TextField(
                controller: creditCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Credits')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _semesterSubjects[_selectedSemester]?.add({
                  'code': codeCtrl.text,
                  'name': nameCtrl.text,
                  'credits': creditCtrl.text,
                  'faculty': 'Assigned Faculty',
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Subject Added')));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _semesterSubjects[_selectedSemester] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects (Sem 1-6)'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSubjectDialog,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.library_books, color: Colors.white),
        label: const Text('Add Subject', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Semester Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppConstants.semesters.map((sem) {
                  final isSelected = sem == _selectedSemester;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(sem),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryBlue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedSemester = sem);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: subjects.isEmpty
                ? const Center(
                    child: Text('No subjects added for this semester.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final sub = subjects[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryTeal
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.class_outlined,
                                color: AppTheme.secondaryTeal),
                          ),
                          title: Text(
                            '${sub['code']}: ${sub['name']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                  'Credits: ${sub['credits']} • Semester: $_selectedSemester'),
                              Text('Assigned Faculty: ${sub['faculty']}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () {
                              setState(() => subjects.removeAt(index));
                            },
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
