import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class UploadNoticeScreen extends StatefulWidget {
  const UploadNoticeScreen({super.key});

  @override
  State<UploadNoticeScreen> createState() => _UploadNoticeScreenState();
}

class _UploadNoticeScreenState extends State<UploadNoticeScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _targetAudience = 'All Students & Faculty';
  String? _selectedPdfName;
  bool _isUploading = false;

  void _pickPdf() {
    setState(() {
      _selectedPdfName = 'BCA_Notice_Ref_2026_08.pdf';
    });
  }

  void _publishNotice() {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter notice title and content')),
      );
      return;
    }

    setState(() => _isUploading = true);

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Department Notice Published Successfully! Notification sent to all users.'),
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
        title: const Text('Upload Department Notice'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Official BCA Department Notice',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This notice will be visible on student & faculty portals.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Notice Title',
                        hintText: 'e.g. Mid-Sem Examination Schedule 2026',
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _targetAudience,
                      decoration: const InputDecoration(labelText: 'Audience / Target'),
                      items: const [
                        DropdownMenuItem(value: 'All Students & Faculty', child: Text('All Students & Faculty')),
                        DropdownMenuItem(value: 'Faculty Members Only', child: Text('Faculty Members Only')),
                        DropdownMenuItem(value: 'Semester 1 Students', child: Text('Semester 1 Students')),
                        DropdownMenuItem(value: 'Semester 3 Students', child: Text('Semester 3 Students')),
                        DropdownMenuItem(value: 'Semester 5 Students', child: Text('Semester 5 Students')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _targetAudience = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _contentController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Notice Content / Instructions',
                        hintText: 'Enter detailed notification text here...',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PDF Attachment picker
                    OutlinedButton.icon(
                      onPressed: _pickPdf,
                      icon: const Icon(Icons.attach_file),
                      label: Text(_selectedPdfName ?? 'Attach Official PDF Document (Optional)'),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _publishNotice,
                      icon: const Icon(Icons.send),
                      label: _isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Publish & Broadcast Notice'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
