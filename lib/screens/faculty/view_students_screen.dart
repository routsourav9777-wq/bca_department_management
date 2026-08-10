import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ViewStudentsScreen extends StatefulWidget {
  const ViewStudentsScreen({super.key});

  @override
  State<ViewStudentsScreen> createState() => _ViewStudentsScreenState();
}

class _ViewStudentsScreenState extends State<ViewStudentsScreen> {
  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // SELECTED SEMESTER
  // ============================================================

  String _selectedSem = 'Semester 1';

  bool _isPromoting = false;

  // ============================================================
  // SEMESTERS
  // ============================================================

  final List<String> _semesters = [
    'Semester 1',
    'Semester 2',
    'Semester 3',
    'Semester 4',
    'Semester 5',
    'Semester 6',
  ];

  // ============================================================
  // GET NEXT SEMESTER
  // ============================================================

  String? _getNextSemester(
    String semester,
  ) {
    final int index = _semesters.indexOf(semester);

    if (index == -1 || index >= _semesters.length - 1) {
      return null;
    }

    return _semesters[index + 1];
  }

  // ============================================================
  // SHIFT STUDENTS TO NEXT SEMESTER
  // ============================================================

  Future<void> _shiftStudentsToNextSemester() async {
    final String? nextSemester = _getNextSemester(_selectedSem);

    // Semester 6 has no next semester
    if (nextSemester == null) {
      _showMessage(
        'Semester 6 students cannot be shifted to another semester.',
        Colors.orange,
      );
      return;
    }

    // ==========================================================
    // GET STUDENTS
    // ==========================================================

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('students')
          .where(
            'semester',
            isEqualTo: _selectedSem,
          )
          .get();

      if (snapshot.docs.isEmpty) {
        _showMessage(
          'No students found in $_selectedSem.',
          Colors.orange,
        );
        return;
      }

      // ==========================================================
      // CONFIRMATION
      // ==========================================================

      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Shift Students?',
            ),
            content: Text(
              'Are you sure you want to shift '
              '${snapshot.docs.length} student(s) '
              'from $_selectedSem to $nextSemester?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Shift'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      // ==========================================================
      // START LOADING
      // ==========================================================

      setState(() {
        _isPromoting = true;
      });

      // ==========================================================
      // FIRESTORE BATCH
      // ==========================================================

      WriteBatch batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(
          doc.reference,
          {
            'semester': nextSemester,
            'previousSemester': _selectedSem,
            'semesterUpdatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      if (!mounted) return;

      setState(() {
        _isPromoting = false;
      });

      // ==========================================================
      // SUCCESS
      // ==========================================================

      _showMessage(
        '${snapshot.docs.length} student(s) shifted '
        'from $_selectedSem to $nextSemester successfully.',
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isPromoting = false;
      });

      _showMessage(
        'Failed to shift students:\n$e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // SHIFT SPECIFIC STUDENT
  // ============================================================

  Future<void> _shiftSingleStudent(
    DocumentSnapshot<Map<String, dynamic>> student,
  ) async {
    final String? nextSemester = _getNextSemester(_selectedSem);

    if (nextSemester == null) {
      _showMessage(
        'Semester 6 has no next semester.',
        Colors.orange,
      );
      return;
    }

    final Map<String, dynamic> data = student.data() ?? <String, dynamic>{};

    final String name = data['name']?.toString() ?? 'Student';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Shift Student?'),
          content: Text(
            'Shift $name from '
            '$_selectedSem to '
            '$nextSemester?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Shift'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await student.reference.update({
        'semester': nextSemester,
        'previousSemester': _selectedSem,
        'semesterUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage(
        '$name shifted to $nextSemester.',
        Colors.green,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to shift student:\n$e',
        Colors.red,
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String? nextSemester = _getNextSemester(_selectedSem);

    return Scaffold(
      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        title: const Text(
          'BCA Student Directory',
        ),
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: Column(
        children: [
          // ========================================================
          // FILTER + PROMOTION SECTION
          // ========================================================

          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // ==================================================
                // SEMESTER DROPDOWN
                // ==================================================

                DropdownButtonFormField<String>(
                  value: _selectedSem,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Semester',
                    prefixIcon: Icon(
                      Icons.school_outlined,
                    ),
                  ),
                  items: _semesters
                      .map(
                        (semester) => DropdownMenuItem<String>(
                          value: semester,
                          child: Text(
                            semester,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _isPromoting
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSem = value;
                            });
                          }
                        },
                ),

                const SizedBox(
                  height: 12,
                ),

                // ==================================================
                // SHIFT BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (_isPromoting || nextSemester == null)
                        ? null
                        : _shiftStudentsToNextSemester,
                    icon: _isPromoting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_forward,
                          ),
                    label: Text(
                      nextSemester == null
                          ? 'Semester 6 Completed'
                          : 'Shift $_selectedSem → $nextSemester',
                    ),
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  nextSemester == null
                      ? 'Semester 6 is the final semester.'
                      : 'Use this button after the semester is completed.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
          ),

          // ========================================================
          // FIREBASE STUDENT LIST
          // ========================================================

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('students')
                  .where(
                    'semester',
                    isEqualTo: _selectedSem,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                // ================================================
                // LOADING
                // ================================================

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // ================================================
                // ERROR
                // ================================================

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 50,
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          const Text(
                            'Unable to load students',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // ================================================
                // NO STUDENTS
                // ================================================

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.school_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          'No students in $_selectedSem',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        const Text(
                          'Students will appear here after registration approval.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final students = snapshot.data!.docs;

                // ================================================
                // STUDENT LIST
                // ================================================

                return ListView.builder(
                  padding: const EdgeInsets.all(
                    16,
                  ),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];

                    final Map<String, dynamic> data = student.data();

                    final String rollNo = data['rollNo']?.toString() ??
                        data['id']?.toString() ??
                        'N/A';

                    final String name = data['name']?.toString() ?? 'Student';

                    final String email = data['email']?.toString() ?? '';

                    final String phone = data['phone']?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(
                          14,
                        ),
                        child: Column(
                          children: [
                            // ==================================
                            // STUDENT INFORMATION
                            // ==================================

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      AppTheme.primaryBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Text(
                                    _getRollShort(
                                      rollNo,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$rollNo • $name',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      if (email.isNotEmpty)
                                        Text(
                                          '📧 $email',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (phone.isNotEmpty)
                                        Text(
                                          '📞 $phone',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(
                                        height: 3,
                                      ),
                                      Text(
                                        'Current: $_selectedSem',
                                        style: const TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            // ==================================
                            // INDIVIDUAL SHIFT BUTTON
                            // ==================================

                            if (nextSemester != null)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isPromoting
                                      ? null
                                      : () => _shiftSingleStudent(
                                            student,
                                          ),
                                  icon: const Icon(
                                    Icons.arrow_forward,
                                  ),
                                  label: Text(
                                    'Shift to $nextSemester',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green.shade700,
                                  ),
                                ),
                              ),
                          ],
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

  // ============================================================
  // SHORT ROLL NUMBER
  // ============================================================

  String _getRollShort(
    String rollNo,
  ) {
    if (rollNo.length <= 4) {
      return rollNo;
    }

    final parts = rollNo.split('-');

    if (parts.length > 1) {
      return parts.last;
    }

    return rollNo.substring(
      rollNo.length - 3,
    );
  }
}
