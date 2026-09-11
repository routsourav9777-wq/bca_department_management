import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class FacultyUploadNotesScreen extends StatefulWidget {
  const FacultyUploadNotesScreen({super.key});

  @override
  State<FacultyUploadNotesScreen> createState() =>
      _FacultyUploadNotesScreenState();
}

class _FacultyUploadNotesScreenState extends State<FacultyUploadNotesScreen> {
  final _titleController = TextEditingController();
  String _selectedSem = AppConstants.semesters[2];
  String? _selectedPdf;
  bool _isUploading = false;

  void _upload() {
    if (_titleController.text.isEmpty || _selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter note title and select PDF document')),
      );
      return;
    }

    setState(() => _isUploading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Notes uploaded to Firebase Storage and shared with students!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Faculty Notes Upload')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedSem,
                  decoration:
                      const InputDecoration(labelText: 'Target Semester'),
                  items: AppConstants.semesters
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSem = val);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration:
                      const InputDecoration(labelText: 'Notes Chapter Title'),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() =>
                        _selectedPdf = 'Java_Object_Oriented_Concepts.pdf');
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  label: Text(_selectedPdf ?? 'Select PDF Note from Device'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isUploading ? null : _upload,
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Upload Notes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
