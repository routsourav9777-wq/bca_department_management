import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewStudentsScreen extends StatefulWidget {
  const ViewStudentsScreen({super.key});

  @override
  State<ViewStudentsScreen> createState() => _ViewStudentsScreenState();
}

class _ViewStudentsScreenState extends State<ViewStudentsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedSemester;
  bool _isShifting = false;

  // App primary color
  static const Color primaryColor = Color(0xFF1565C0);

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

  String? _getNextSemester(String semester) {
    final int index = _semesters.indexOf(semester);

    if (index == -1 || index == _semesters.length - 1) {
      return null;
    }

    return _semesters[index + 1];
  }

  // ============================================================
  // CALL STUDENT
  // ============================================================

  Future<void> _callStudent(String phone) async {
    String cleanPhone = phone.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    if (cleanPhone.isEmpty) {
      _showMessage(
        'Phone number is not available.',
        error: true,
      );
      return;
    }

    // Indian 10 digit number
    if (cleanPhone.length == 10 && !cleanPhone.startsWith('+')) {
      cleanPhone = '+91$cleanPhone';
    }

    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: cleanPhone,
    );

    try {
      final bool launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showMessage(
          'Unable to open phone dialer.',
          error: true,
        );
      }
    } catch (e) {
      _showMessage(
        'Unable to make call.',
        error: true,
      );
    }
  }

  // ============================================================
  // DELETE STUDENT
  // ============================================================

  Future<void> _deleteStudent(
    QueryDocumentSnapshot studentDoc,
  ) async {
    final Map<String, dynamic> data = studentDoc.data() as Map<String, dynamic>;

    final String name = (data['name'] ?? 'Unknown Student').toString();

    final String rollNo = (data['rollNo'] ?? '').toString();

    // ==========================================================
    // CONFIRMATION DIALOG
    // ==========================================================

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Text(
                'Delete Student',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this student?\n\n'
            'Name: $name'
            '${rollNo.isNotEmpty ? '\nRoll No: $rollNo' : ''}'
            '\n\nThis action cannot be undone.',
            style: const TextStyle(
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'DELETE',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // ==========================================================
    // DELETE FROM FIRESTORE
    // ==========================================================

    try {
      await studentDoc.reference.delete();

      if (!mounted) return;

      _showMessage(
        '$name deleted successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to delete student.',
        error: true,
      );
    }
  }

  // ============================================================
  // SHIFT ENTIRE SEMESTER
  // ============================================================

  Future<void> _shiftEntireSemester() async {
    if (_selectedSemester == null) {
      _showMessage(
        'Please select a semester first.',
        error: true,
      );
      return;
    }

    final String? nextSemester = _getNextSemester(_selectedSemester!);

    if (nextSemester == null) {
      _showMessage(
        'Semester 6 cannot be shifted further.',
        error: true,
      );
      return;
    }

    try {
      // Get all students from selected semester
      final QuerySnapshot snapshot = await _firestore
          .collection('students')
          .where(
            'semester',
            isEqualTo: _selectedSemester,
          )
          .get();

      if (snapshot.docs.isEmpty) {
        _showMessage(
          'No students found in $_selectedSemester.',
          error: true,
        );
        return;
      }

      // ========================================================
      // CONFIRMATION
      // ========================================================

      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Shift Entire Semester',
            ),
            content: Text(
              'Are you sure you want to shift all '
              '${snapshot.docs.length} students from '
              '$_selectedSemester to $nextSemester?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('SHIFT ALL'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      setState(() {
        _isShifting = true;
      });

      // Firestore batch maximum is 500 writes.
      // Using 450 to stay safely below the limit.
      const int batchLimit = 450;

      for (int start = 0; start < snapshot.docs.length; start += batchLimit) {
        final WriteBatch batch = _firestore.batch();

        final int end = (start + batchLimit < snapshot.docs.length)
            ? start + batchLimit
            : snapshot.docs.length;

        for (int i = start; i < end; i++) {
          final DocumentSnapshot student = snapshot.docs[i];

          batch.update(
            student.reference,
            {
              'semester': nextSemester,
              'previousSemester': _selectedSemester,
              'semesterUpdatedAt': FieldValue.serverTimestamp(),
            },
          );
        }

        await batch.commit();
      }

      if (!mounted) return;

      _showMessage(
        'All students shifted to $nextSemester successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to shift students.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isShifting = false;
        });
      }
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // SHORT ROLL NUMBER
  // ============================================================

  String _getRollShort(String rollNo) {
    if (rollNo.length <= 4) {
      return rollNo;
    }

    if (rollNo.contains('-')) {
      final List<String> parts = rollNo.split('-');

      if (parts.isNotEmpty) {
        return parts.last;
      }
    }

    return rollNo.substring(
      rollNo.length - 3,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String? nextSemester =
        _selectedSemester == null ? null : _getNextSemester(_selectedSemester!);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'View Students',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ==================================================
              // SEMESTER DROPDOWN
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSemester,
                    isExpanded: true,
                    hint: const Text(
                      'Select Semester',
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                    ),
                    items: _semesters.map(
                      (String semester) {
                        return DropdownMenuItem<String>(
                          value: semester,
                          child: Text(
                            semester,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedSemester = value;
                      });
                    },
                  ),
                ),
              ),

              // ==================================================
              // SHIFT BUTTON
              // ==================================================

              if (_selectedSemester != null && nextSemester != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isShifting ? null : _shiftEntireSemester,
                    icon: _isShifting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.arrow_forward_rounded,
                          ),
                    label: Text(
                      _isShifting
                          ? 'Shifting Students...'
                          : 'Shift $_selectedSemester → $nextSemester',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ==================================================
              // STUDENT AREA
              // ==================================================

              Expanded(
                child: _selectedSemester == null
                    ? _buildSelectSemesterMessage()
                    : _buildStudentList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECT SEMESTER MESSAGE
  // ============================================================

  Widget _buildSelectSemesterMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a semester',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Students will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDENT LIST
  // ============================================================

  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('students')
          .where(
            'semester',
            isEqualTo: _selectedSemester,
          )
          .snapshots(),
      builder: (
        BuildContext context,
        AsyncSnapshot<QuerySnapshot> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Something went wrong.',
              style: TextStyle(
                color: Colors.red.shade700,
              ),
            ),
          );
        }

        final List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyStudents();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${docs.length} Students',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (BuildContext context, int index) {
                  return const SizedBox(height: 10);
                },
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, dynamic> data =
                      docs[index].data() as Map<String, dynamic>;

                  return _buildStudentCard(
                    docs[index],
                    data,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // STUDENT CARD
  // ============================================================

  Widget _buildStudentCard(
    QueryDocumentSnapshot studentDoc,
    Map<String, dynamic> data,
  ) {
    final String name = (data['name'] ?? 'Unknown Student').toString();

    final String rollNo = (data['rollNo'] ?? '').toString();

    final String email = (data['email'] ?? '').toString();

    final String phone = (data['phone'] ?? '').toString();

    final String semester = (data['semester'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // STUDENT ICON
          // ======================================================

          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: primaryColor,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          // ======================================================
          // STUDENT DETAILS
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    // DELETE BUTTON
                    const SizedBox(width: 8),

                    InkWell(
                      onTap: () {
                        _deleteStudent(studentDoc);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),

                if (rollNo.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Roll No: ${_getRollShort(rollNo)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],

                const SizedBox(height: 6),

                // =================================================
                // PHONE + CALL ICON
                // =================================================

                if (phone.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          phone,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // CALL BUTTON
                      InkWell(
                        onTap: () {
                          _callStudent(phone);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.call_rounded,
                            size: 19,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                if (phone.isEmpty)
                  Text(
                    'Phone number not available',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),

                // =================================================
                // EMAIL
                // =================================================

                if (email.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 15,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),

                // =================================================
                // SEMESTER CHIP
                // =================================================

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    semester,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STUDENT MESSAGE
  // ============================================================

  Widget _buildEmptyStudents() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          Text(
            'No students found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No students are available in $_selectedSemester.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
