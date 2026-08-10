import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';

class ApproveRegistrationsScreen extends StatefulWidget {
  const ApproveRegistrationsScreen({super.key});

  @override
  State<ApproveRegistrationsScreen> createState() =>
      _ApproveRegistrationsScreenState();
}

class _ApproveRegistrationsScreenState extends State<ApproveRegistrationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ================= APPROVE STUDENT =================

  Future<void> _approveStudent(
    String documentId,
    String name,
  ) async {
    try {
      await _firestore.collection('students').doc(documentId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approval failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= REJECT STUDENT =================

  Future<void> _rejectStudent(
    String documentId,
    String name,
  ) async {
    try {
      await _firestore.collection('students').doc(documentId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name rejected'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rejection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Approvals'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              text: 'Student Registrations',
            ),
          ],
        ),
      ),

      // ================= FIREBASE STREAM =================

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('students')
            .where('status', isEqualTo: 'pending')
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
                  'Error loading registrations:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            );
          }

          final students = snapshot.data?.docs ?? [];

          // No pending students
          if (students.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 70,
                    color: Colors.green,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'No pending student registrations.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          // Student list
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final doc = students[index];

              final data = doc.data();

              final name = data['name']?.toString() ?? 'Unknown Student';
              final email = data['email']?.toString() ?? 'No email';
              final phone = data['phone']?.toString() ?? 'No phone';
              final rollNo = data['rollNo']?.toString() ?? 'No Roll Number';
              final semester = data['semester']?.toString() ?? 'No Semester';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= STUDENT HEADER =================

                      Row(
                        children: [
                          CircleAvatar(
                            radius: 27,
                            backgroundColor:
                                AppTheme.primaryBlue.withOpacity(0.1),
                            child: const Icon(
                              Icons.school,
                              color: AppTheme.primaryBlue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$rollNo • $semester',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      // ================= DETAILS =================

                      Text(
                        'Email: $email',
                        style: const TextStyle(fontSize: 14),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Phone: $phone',
                        style: const TextStyle(fontSize: 14),
                      ),

                      const SizedBox(height: 16),

                      // ================= BUTTONS =================

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _showRejectDialog(
                                  doc.id,
                                  name,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _showApproveDialog(
                                  doc.id,
                                  name,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ================= APPROVE CONFIRMATION =================

  void _showApproveDialog(
    String documentId,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Approve Student?'),
          content: Text(
            'Are you sure you want to approve $name?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);

                await _approveStudent(
                  documentId,
                  name,
                );
              },
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  // ================= REJECT CONFIRMATION =================

  void _showRejectDialog(
    String documentId,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Student?'),
          content: Text(
            'Are you sure you want to reject $name?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(context);

                await _rejectStudent(
                  documentId,
                  name,
                );
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }
}
