import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class UploadInternalMarksScreen extends StatefulWidget {
  const UploadInternalMarksScreen({super.key});

  @override
  State<UploadInternalMarksScreen> createState() =>
      _UploadInternalMarksScreenState();
}

class _UploadInternalMarksScreenState extends State<UploadInternalMarksScreen> {
  String _selectedSem = AppConstants.semesters[2];
  String _examType = 'Mid-Sem Test 1';

  final List<Map<String, dynamic>> _studentsMarks = [
    {'rollNo': 'BC23-001', 'name': 'Aakash Mohanty', 'marks': '18.5'},
    {'rollNo': 'BC23-002', 'name': 'Aditya Prasad Das', 'marks': '16.0'},
    {'rollNo': 'BC23-003', 'name': 'Ankit Nayak', 'marks': '14.5'},
    {'rollNo': 'BC23-004', 'name': 'Bishnupriya Sahoo', 'marks': '19.5'},
    {'rollNo': 'BC23-005', 'name': 'Debasis Rout', 'marks': '15.0'},
  ];

  bool _isSaving = false;

  void _saveMarks() {
    setState(() => _isSaving = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Internal Marks uploaded to Firestore!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Internal Marks')),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveMarks,
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Publish Internal Marks'),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSem,
                    decoration: const InputDecoration(labelText: 'Semester'),
                    items: AppConstants.semesters
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSem = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _examType,
                    decoration: const InputDecoration(labelText: 'Test / Exam'),
                    items: const [
                      DropdownMenuItem(
                          value: 'Mid-Sem Test 1', child: Text('Mid-Sem 1')),
                      DropdownMenuItem(
                          value: 'Mid-Sem Test 2', child: Text('Mid-Sem 2')),
                      DropdownMenuItem(
                          value: 'Internal Viva', child: Text('Internal Viva')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _examType = val);
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
              itemCount: _studentsMarks.length,
              itemBuilder: (context, index) {
                final st = _studentsMarks[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${st['rollNo']} - ${st['name']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const Text('Max Marks: 20.0',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: st['marks'],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Marks',
                              contentPadding: EdgeInsets.all(8),
                            ),
                          ),
                        ),
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
