import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ManageFacultyScreen extends StatefulWidget {
  const ManageFacultyScreen({super.key});

  @override
  State<ManageFacultyScreen> createState() => _ManageFacultyScreenState();
}

class _ManageFacultyScreenState extends State<ManageFacultyScreen> {
  final List<Map<String, String>> _faculties = [
    {
      'id': '101',
      'name': 'Prof. Santosh Kumar Sahoo',
      'designation': 'Senior Lecturer (Computer Applications)',
      'email': 'santosh.sahoo@salipurcollege.ac.in',
      'phone': '+91 9437112233',
      'empId': 'BCA-FAC-01',
    },
    {
      'id': '102',
      'name': 'Dr. Smruti Rekha Das',
      'designation': 'Assistant Professor (DBMS & C++)',
      'email': 'smruti.das@salipurcollege.ac.in',
      'phone': '+91 9861098765',
      'empId': 'BCA-FAC-02',
    },
    {
      'id': '103',
      'name': 'Er. Manoranjan Swain',
      'designation': 'Guest Faculty (Web Development)',
      'email': 'manoranjan.swain@salipurcollege.ac.in',
      'phone': '+91 8249054321',
      'empId': 'BCA-FAC-03',
    },
  ];

  void _showAddEditDialog({Map<String, String>? faculty, int? index}) {
    final nameCtrl = TextEditingController(text: faculty?['name'] ?? '');
    final desigCtrl =
        TextEditingController(text: faculty?['designation'] ?? '');
    final emailCtrl = TextEditingController(text: faculty?['email'] ?? '');
    final passwordCtrl =
        TextEditingController(text: faculty?['password'] ?? '');

    final confirmPasswordCtrl =
        TextEditingController(text: faculty?['password'] ?? '');

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(
                  faculty == null ? 'Add New Faculty' : 'Edit Faculty Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        controller: nameCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Full Name')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: desigCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Designation')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: emailCtrl,
                        decoration:
                            const InputDecoration(labelText: 'College Email')),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Create Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        errorText: confirmPasswordCtrl.text.isEmpty
                            ? null
                            : (passwordCtrl.text == confirmPasswordCtrl.text)
                                ? null
                                : 'Passwords do not match',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    // ===== Validation =====

                    if (nameCtrl.text.trim().isEmpty ||
                        desigCtrl.text.trim().isEmpty ||
                        emailCtrl.text.trim().isEmpty ||
                        passwordCtrl.text.isEmpty ||
                        confirmPasswordCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (passwordCtrl.text != confirmPasswordCtrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Passwords do not match'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // ===== Save Faculty =====

                    setState(() {
                      final newObj = {
                        'id': faculty?['id'] ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': nameCtrl.text.trim(),
                        'designation': desigCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'password': passwordCtrl.text,
                      };

                      if (index != null) {
                        _faculties[index] = newObj;
                      } else {
                        _faculties.add(newObj);
                      }
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          faculty == null
                              ? 'Faculty added successfully'
                              : 'Faculty updated successfully',
                        ),
                      ),
                    );
                  },
                  child: const Text("Save"),
                ),
              ],
            ));
  }

  void _deleteFaculty(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to remove ${_faculties[index]['name']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _faculties.removeAt(index));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Faculty removed successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Faculty Members'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Faculty', style: TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faculties.length,
        itemBuilder: (context, index) {
          final f = _faculties[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                child: Text(
                  f['name']!.split(' ').map((e) => e[0]).take(2).join(''),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
              ),
              title: Text(f['name']!,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    f['designation']!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('📧 ${f['email']}'),
                ],
              ),
              trailing: PopupMenuButton(
                onSelected: (val) {
                  if (val == 'edit')
                    _showAddEditDialog(faculty: f, index: index);
                  if (val == 'delete') _deleteFaculty(index);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit')
                      ])),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red))
                      ])),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
