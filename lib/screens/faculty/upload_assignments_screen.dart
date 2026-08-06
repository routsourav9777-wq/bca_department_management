import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class UploadAssignmentsScreen extends StatefulWidget {
  const UploadAssignmentsScreen({super.key});

  @override
  State<UploadAssignmentsScreen> createState() => _UploadAssignmentsScreenState();
}

class _UploadAssignmentsScreenState extends State<UploadAssignmentsScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedSem = AppConstants.semesters[2];
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;

  void _publishAssignment() {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter assignment title')),
      );
      return;
    }

    setState(() => _isSaving = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment published successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Assignment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedSem,
                  decoration: const InputDecoration(labelText: 'Target Semester'),
                  items: AppConstants.semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) { if (val != null) setState(() => _selectedSem = val); },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Assignment Title', hintText: 'e.g. DBMS Normalization Problems'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Instructions / Questions', hintText: 'Explain 1NF, 2NF, 3NF with examples...'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                  leading: const Icon(Icons.calendar_today, color: AppTheme.primaryBlue),
                  title: Text('Due Date: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _publishAssignment,
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Publish Assignment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
