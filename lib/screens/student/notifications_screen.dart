import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final List<Map<String, String>> _notifications = const [
    {
      'title': 'BCA Mid-Sem Examination Schedule Released',
      'body': 'Check notice board for semester 3 timetable.',
      'time': '2 hours ago',
    },
    {
      'title': 'New Study Notes Uploaded by Dr. Smruti Rekha Das',
      'body': 'DBMS Unit 1 & 2 PDF notes are now available in Download Notes section.',
      'time': '1 day ago',
    },
    {
      'title': 'FCM Push Broadcast from HOD',
      'body': 'All students assemble in Seminar Hall at 11:00 AM tomorrow for Tech Fest briefing.',
      'time': '2 days ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Push Notifications')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final item = _notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: Colors.redAccent,
                child: Icon(Icons.notifications, color: Colors.white),
              ),
              title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(item['body']!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(item['time']!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
