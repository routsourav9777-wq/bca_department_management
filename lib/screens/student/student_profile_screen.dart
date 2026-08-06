import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryBlue,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Priyanka Mohapatra',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Roll No: BC23-045 • Semester 3',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    ListTile(
                      leading: Icon(Icons.school, color: AppTheme.primaryBlue),
                      title: Text('College Name'),
                      subtitle: Text(AppConstants.collegeName),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.business, color: AppTheme.primaryBlue),
                      title: Text('Department'),
                      subtitle: Text(AppConstants.departmentName),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.email, color: AppTheme.primaryBlue),
                      title: Text('Email Address'),
                      subtitle: Text('priyanka.m@salipurcollege.ac.in'),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.phone, color: AppTheme.primaryBlue),
                      title: Text('Phone Number'),
                      subtitle: Text('+91 9876543210'),
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text('HOD Approval Status'),
                      subtitle: Text('APPROVED (Active Batch 2023-2026)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
