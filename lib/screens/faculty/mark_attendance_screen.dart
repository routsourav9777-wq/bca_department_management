import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  String _selectedSem = AppConstants.semesters[2]; // Sem 3
  String _subject = 'BCA-301 (DBMS)';

  final List<Map<String, dynamic>> _students = [
    {'rollNo': 'BC23-001', 'name': 'Aakash Mohanty', 'present': true},
    {'rollNo': 'BC23-002', 'name': 'Aditya Prasad Das', 'present': true},
    {'rollNo': 'BC23-003', 'name': 'Ankit Nayak', 'present': false},
    {'rollNo': 'BC23-004', 'name': 'Bishnupriya Sahoo', 'present': true},
    {'rollNo': 'BC23-005', 'name': 'Debasis Rout', 'present': true},
    {'rollNo': 'BC23-006', 'name': 'Divya Ranjan Swain', 'present': true},
  ];

  bool _isSaving = false;

  void _submitAttendance() {
    setState(() => _isSaving = true);

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isSaving = false);

      final presentCount = _students.where((s) => s['present'] == true).length;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Attendance recorded for $_subject! Present: $presentCount / ${_students.length}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Student Attendance'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _submitAttendance,
          icon: const Icon(Icons.check_circle_outline),
          label: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Save & Submit Attendance'),
        ),
      ),
      body: Column(
        children: [
          // Header options
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSem,
                        decoration: const InputDecoration(
                            labelText: 'Semester',
                            contentPadding: EdgeInsets.all(12)),
                        items: AppConstants.semesters
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSem = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _subject,
                        decoration: const InputDecoration(
                            labelText: 'Subject',
                            contentPadding: EdgeInsets.all(12)),
                        items: const [
                          DropdownMenuItem(
                              value: 'BCA-301 (DBMS)',
                              child: Text('BCA-301 DBMS')),
                          DropdownMenuItem(
                              value: 'BCA-302 (Java)',
                              child: Text('BCA-302 Java')),
                          DropdownMenuItem(
                              value: 'BCA-303 (OS)', child: Text('BCA-303 OS')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _subject = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              for (var s in _students) s['present'] = true;
                            });
                          },
                          child: const Text('Mark All Present'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              for (var s in _students) s['present'] = false;
                            });
                          },
                          child: const Text('Mark All Absent',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final st = _students[index];
                final isPresent = st['present'] as bool;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: SwitchListTile(
                    activeColor: Colors.green,
                    value: isPresent,
                    onChanged: (val) {
                      setState(() => st['present'] = val);
                    },
                    title: Text('${st['rollNo']} - ${st['name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      isPresent ? 'Status: Present' : 'Status: Absent',
                      style: TextStyle(
                        color: isPresent ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
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
