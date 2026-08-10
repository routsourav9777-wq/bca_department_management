import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedSemester = AppConstants.semesters[0];

  bool _isAdding = false;

  // ============================================================
  // ADD SUBJECT DIALOG
  // ============================================================

  void _addSubjectDialog() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    String? selectedFacultyId;
    String? selectedFacultyName;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Add Subject to $_selectedSemester',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==================================================
                    // SUBJECT CODE
                    // ==================================================

                    TextField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Subject Code',
                        hintText: 'e.g. BCA-101',
                        prefixIcon: Icon(Icons.code),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // SUBJECT NAME
                    // ==================================================

                    TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Subject Name',
                        hintText: 'e.g. Programming in C',
                        prefixIcon: Icon(Icons.menu_book),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ==================================================
                    // FACULTY DROPDOWN FROM FIREBASE
                    // ==================================================

                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestore
                          .collection('faculty')
                          .where(
                            'department',
                            isEqualTo: 'BCA',
                          )
                          .where(
                            'status',
                            isEqualTo: 'active',
                          )
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Text(
                            'Unable to load faculty',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          );
                        }

                        final facultyDocs = snapshot.data?.docs ?? [];

                        if (facultyDocs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            child: Text(
                              'No active faculty found.',
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedFacultyId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Select Faculty',
                            prefixIcon: Icon(Icons.person),
                          ),
                          items: facultyDocs.map((doc) {
                            final data = doc.data();

                            final name =
                                data['name']?.toString() ?? 'Unknown Faculty';

                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;

                            final selectedDoc = facultyDocs.firstWhere(
                              (doc) => doc.id == value,
                            );

                            final data = selectedDoc.data();

                            setDialogState(() {
                              selectedFacultyId = value;

                              selectedFacultyName = data['name']?.toString();
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ========================================================
              // BUTTONS
              // ========================================================

              actions: [
                TextButton(
                  onPressed: _isAdding
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isAdding
                      ? null
                      : () async {
                          // ==========================
                          // VALIDATION
                          // ==========================

                          if (codeCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(
                              this.context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter subject code',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(
                              this.context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter subject name',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (selectedFacultyId == null) {
                            ScaffoldMessenger.of(
                              this.context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select faculty',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            _isAdding = true;
                          });

                          try {
                            // ==========================
                            // SAVE TO FIRESTORE
                            // ==========================

                            await _firestore.collection('subjects').add({
                              'code': codeCtrl.text.trim().toUpperCase(),
                              'name': nameCtrl.text.trim(),
                              'semester': _selectedSemester,
                              'facultyId': selectedFacultyId,
                              'facultyName': selectedFacultyName,
                              'department': 'BCA',
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (!mounted) return;

                            Navigator.pop(
                              dialogContext,
                            );

                            ScaffoldMessenger.of(
                              this.context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Subject added successfully',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() {
                              _isAdding = false;
                            });

                            if (!mounted) return;

                            ScaffoldMessenger.of(
                              this.context,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to add subject: $e',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: _isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Add Subject',
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DELETE SUBJECT
  // ============================================================

  Future<void> _deleteSubject(
    String documentId,
    String subjectName,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Subject?'),
          content: Text(
            'Are you sure you want to delete $subjectName?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                false,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(
                context,
                true,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await _firestore.collection('subjects').doc(documentId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Subject deleted successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete subject: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Subjects (Sem 1-6)',
        ),
      ),

      // ==========================================================
      // ADD SUBJECT BUTTON
      // ==========================================================

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSubjectDialog,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(
          Icons.library_books,
          color: Colors.white,
        ),
        label: const Text(
          'Add Subject',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: Column(
        children: [
          // ========================================================
          // SEMESTER CHIPS
          // ========================================================

          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 8,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppConstants.semesters.map((sem) {
                  final isSelected = sem == _selectedSemester;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    child: ChoiceChip(
                      label: Text(sem),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryBlue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (value) {
                        if (value) {
                          setState(() {
                            _selectedSemester = sem;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(
            height: 1,
          ),

          // ========================================================
          // FIRESTORE SUBJECT LIST
          // ========================================================

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('subjects')
                  .where(
                    'department',
                    isEqualTo: 'BCA',
                  )
                  .where(
                    'semester',
                    isEqualTo: _selectedSemester,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Error
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Error loading subjects:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                final subjects = snapshot.data?.docs ?? [];

                // Empty
                if (subjects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          size: 65,
                          color: Colors.grey,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          'No subjects added for $_selectedSemester.',
                        ),
                      ],
                    ),
                  );
                }

                // Subject List
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final doc = subjects[index];

                    final data = doc.data();

                    final code = data['code']?.toString() ?? '';

                    final name = data['name']?.toString() ?? '';

                    final facultyName =
                        data['facultyName']?.toString() ?? 'Not Assigned';

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(
                          16,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(
                            10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryTeal.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: const Icon(
                            Icons.class_outlined,
                            color: AppTheme.secondaryTeal,
                          ),
                        ),
                        title: Text(
                          '$code: $name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(
                            top: 5,
                          ),
                          child: Text(
                            'Faculty: $facultyName\nSemester: $_selectedSemester',
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            _deleteSubject(
                              doc.id,
                              name,
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
