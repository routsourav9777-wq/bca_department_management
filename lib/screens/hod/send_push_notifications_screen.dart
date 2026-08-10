import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SendPushNotificationsScreen extends StatefulWidget {
  const SendPushNotificationsScreen({super.key});

  @override
  State<SendPushNotificationsScreen> createState() =>
      _SendPushNotificationsScreenState();
}

class _SendPushNotificationsScreenState
    extends State<SendPushNotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _bodyController = TextEditingController();

  String _target = 'all';

  String _targetLabel = 'All Students & Faculty';

  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND NOTIFICATION
  // ============================================================

  Future<void> _sendNotification() async {
    final String title = _titleController.text.trim();

    final String body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter notification title and message',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final User? user = _auth.currentUser;

      // ========================================================
      // SAVE TO FIRESTORE
      // ========================================================

      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'target': _target,
        'targetLabel': _targetLabel,
        'department': 'BCA',
        'createdBy': user?.uid ?? '',
        'createdByEmail': user?.email ?? '',
        'createdByRole': 'hod',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'push',
      });

      if (!mounted) return;

      _titleController.clear();
      _bodyController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notification saved successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Firebase Error: ${e.message ?? e.code}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // ============================================================
  // TARGET DROPDOWN
  // ============================================================

  Widget _buildTargetDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _target,

      // IMPORTANT:
      // This prevents the selected text from overflowing.
      isExpanded: true,

      isDense: true,

      decoration: InputDecoration(
        labelText: 'Target Audience',
        prefixIcon: const Icon(
          Icons.groups_outlined,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 2,
          ),
        ),
      ),

      // ==========================================================
      // FULL OPTIONS
      // ==========================================================

      items: const [
        DropdownMenuItem(
          value: 'all',
          child: Text(
            'All BCA Students & Faculty',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: 'faculty',
          child: Text(
            'Faculty Members Only',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: 'semester_1',
          child: Text(
            'Semester 1 Students',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: 'semester_2',
          child: Text(
            'Semester 2 Students',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: 'semester_3',
          child: Text(
            'Semester 3 Students',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: 'semester_4',
          child: Text(
            'Semester 4 Students',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: 'semester_5',
          child: Text(
            'Semester 5 Students',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DropdownMenuItem(
          value: 'semester_6',
          child: Text(
            'Semester 6 Students',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],

      // ==========================================================
      // SELECTED VALUE UI
      // ==========================================================

      selectedItemBuilder: (BuildContext context) {
        return const [
          Text(
            'All BCA Students & Faculty',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Faculty Only',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Semester 1',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Semester 2',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Semester 3',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Semester 4',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Semester 5',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Semester 6',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ];
      },

      // ==========================================================
      // CHANGE TARGET
      // ==========================================================

      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _target = value;

          switch (value) {
            case 'all':
              _targetLabel = 'All Students & Faculty';
              break;

            case 'faculty':
              _targetLabel = 'Faculty Only';
              break;

            case 'semester_1':
              _targetLabel = 'Semester 1 Students';
              break;

            case 'semester_2':
              _targetLabel = 'Semester 2 Students';
              break;

            case 'semester_3':
              _targetLabel = 'Semester 3 Students';
              break;

            case 'semester_4':
              _targetLabel = 'Semester 4 Students';
              break;

            case 'semester_5':
              _targetLabel = 'Semester 5 Students';
              break;

            case 'semester_6':
              _targetLabel = 'Semester 6 Students';
              break;
          }
        });
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Push Notifications',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // =================================================
                  // HEADER
                  // =================================================

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(
                          10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(
                            0.10,
                          ),
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: const Icon(
                          Icons.cell_tower,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Send Push Notification',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Send an alert to selected BCA students or faculty.',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  // =================================================
                  // TARGET
                  // =================================================

                  _buildTargetDropdown(),

                  const SizedBox(
                    height: 18,
                  ),

                  // =================================================
                  // TITLE
                  // =================================================

                  TextField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: 'Notification Title',
                      hintText: 'e.g. Exam Alert',
                      prefixIcon: const Icon(
                        Icons.title,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                      ),
                      counterText: '',
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // =================================================
                  // MESSAGE
                  // =================================================

                  TextField(
                    controller: _bodyController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: 'Message Body',
                      hintText: 'Type your notification message...',
                      prefixIcon: const Icon(
                        Icons.message_outlined,
                      ),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                      ),
                      counterText: '',
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // =================================================
                  // SEND BUTTON
                  // =================================================

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendNotification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                            ),
                      label: Text(
                        _isSending ? 'Saving...' : 'Send Notification',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // =================================================
                  // INFO BOX
                  // =================================================

                  Container(
                    padding: const EdgeInsets.all(
                      14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Text(
                            'The notification is first saved in Firebase. '
                            'The secure backend will then deliver the '
                            'actual FCM push notification.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
