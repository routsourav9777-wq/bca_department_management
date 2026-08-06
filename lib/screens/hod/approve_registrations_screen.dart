import 'package:flutter/material.dart';
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

  final List<Map<String, String>> _pendingStudents = [
    {
      'id': '1',
      'name': 'Priyanka Mohapatra',
      'email': 'priyanka.m@salipurcollege.ac.in',
      'rollNo': 'BC23-045',
      'semester': 'Semester 3',
      'phone': '+91 9876543210'
    },
    {
      'id': '2',
      'name': 'Rakesh Kumar Jena',
      'email': 'rakesh.j@salipurcollege.ac.in',
      'rollNo': 'BC23-048',
      'semester': 'Semester 3',
      'phone': '+91 9876543211'
    },
    {
      'id': '3',
      'name': 'Subhashree Dash',
      'email': 'subhashree.d@salipurcollege.ac.in',
      'rollNo': 'BC24-002',
      'semester': 'Semester 1',
      'phone': '+91 9876543212'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  void _approve(String name, int index) {
    setState(() {
      _pendingStudents.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Approved registration for $name'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _reject(String name, int index) {
    setState(() {
      _pendingStudents.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rejected registration for $name'),
        backgroundColor: Colors.red,
      ),
    );
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
          tabs: [
            Tab(text: 'Students (${_pendingStudents.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Student Approvals List
          _pendingStudents.isEmpty
              ? const Center(child: Text('No pending student registrations.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingStudents.length,
                  itemBuilder: (context, index) {
                    final item = _pendingStudents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      AppTheme.primaryBlue.withOpacity(0.1),
                                  child: const Icon(Icons.school,
                                      color: AppTheme.primaryBlue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name']!,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      Text(
                                        '${item['rollNo']} • ${item['semester']}',
                                        style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Text('Email: ${item['email']}'),
                            Text('Phone: ${item['phone']}'),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _reject(item['name']!, index),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    child: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _approve(item['name']!, index),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green),
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
                ),

          // Faculty Approvals List
        ],
      ),
    );
  }
}
