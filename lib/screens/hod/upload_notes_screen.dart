import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class UploadNotesScreen extends StatefulWidget {
  const UploadNotesScreen({super.key});

  @override
  State<UploadNotesScreen> createState() => _UploadNotesScreenState();
}

class _UploadNotesScreenState extends State<UploadNotesScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedSemester = AppConstants.semesters[2]; // Sem 3
  String _subjectCode = 'BCA-301 (DBMS)';
  String? _selectedFileName;
  bool _isUploading = false;

  void _selectFile() {
    setState(() {
      _selectedFileName = 'DBMS_Unit_1_2_Notes_Salipur.pdf';
    });
  }

  void _uploadNote() {
    if (_titleController.text.isEmpty || _selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter note title and select PDF file')),
      );
      return;
    }

    setState(() => _isUploading = true);

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF Study Material uploaded successfully to Firebase Storage!'),
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
        title: const Text('Upload PDF Study Notes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Upload Department Notes / E-Books',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedSemester,
                  decoration: const InputDecoration(labelText: 'Target Semester'),
                  items: AppConstants.semesters
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSemester = val);
                  },
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Notes Title',
                    hintText: 'e.g. Unit-1 Relational Algebra & SQL',
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Subject / Topic Details',
                    hintText: 'e.g. DBMS BCA-301 Full Handwritten Lecture Notes',
                  ),
                ),
                const SizedBox(height: 20),

                InkWell(
                  onTap: _selectFile,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3), style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFileName ?? 'Tap to Select PDF File from Device Storage',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: _selectedFileName != null ? FontWeight.bold : FontWeight.normal,
                            color: _selectedFileName != null ? AppTheme.primaryBlue : AppTheme.textSecondary,
                          ),
                        ),
                        if (_selectedFileName != null)
                          const Text('Size: 2.4 MB • PDF Document', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadNote,
                  icon: const Icon(Icons.cloud_upload),
                  label: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Upload to Firebase Storage'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
