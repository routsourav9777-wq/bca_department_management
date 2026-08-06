import 'package:flutter/material.dart';

class SendPushNotificationsScreen extends StatefulWidget {
  const SendPushNotificationsScreen({super.key});

  @override
  State<SendPushNotificationsScreen> createState() =>
      _SendPushNotificationsScreenState();
}

class _SendPushNotificationsScreenState
    extends State<SendPushNotificationsScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _topic = 'All Students & Faculty';
  bool _isSending = false;

  void _sendBroadcast() {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter notification title and message body')),
      );
      return;
    }

    setState(() => _isSending = true);

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isSending = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('FCM Push Notification sent to $_topic successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _titleController.clear();
      _bodyController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Push Notifications'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: const [
                    Icon(Icons.cell_tower, color: Colors.redAccent, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Instant Broadcast FCM Push Alert',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _topic,
                  decoration: const InputDecoration(
                      labelText: 'Target Topic / Audience'),
                  items: const [
                    DropdownMenuItem(
                        value: 'All Students & Faculty',
                        child: Text('All BCA Students & Faculty')),
                    DropdownMenuItem(
                        value: 'Faculty Only',
                        child: Text('Faculty Members Only')),
                    DropdownMenuItem(
                        value: 'Semester 1 Students',
                        child: Text('Semester 1 Students')),
                    DropdownMenuItem(
                        value: 'Semester 3 Students',
                        child: Text('Semester 3 Students')),
                    DropdownMenuItem(
                        value: 'Semester 5 Students',
                        child: Text('Semester 5 Students')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _topic = val);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Alert Heading / Title',
                    hintText: 'e.g. Urgent Class Cancelled / Exam Alert',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bodyController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message Body',
                    hintText:
                        'Type your message to pop up on mobile lock screens...',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendBroadcast,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent),
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  label: _isSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Send Instant Push Notification',
                          style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
