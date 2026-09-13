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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
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
          backgroundColor: error ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // SEND NOTIFICATION
  // ============================================================

  Future<void> _sendNotification() async {
    final String title = _titleController.text.trim();

    final String body = _bodyController.text.trim();

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (title.isEmpty) {
      _showMessage(
        'Please enter notification title.',
        error: true,
      );
      return;
    }

    if (body.isEmpty) {
      _showMessage(
        'Please enter notification message.',
        error: true,
      );
      return;
    }

    if (title.length > 80) {
      _showMessage(
        'Title cannot be more than 80 characters.',
        error: true,
      );
      return;
    }

    if (body.length > 500) {
      _showMessage(
        'Message cannot be more than 500 characters.',
        error: true,
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        throw Exception(
          'You are not logged in.',
        );
      }

      // --------------------------------------------------------
      // SAVE NOTIFICATION
      //
      // Cloud Function will detect this document and send
      // the real FCM notification.
      // --------------------------------------------------------

      await _firestore.collection('notifications').add({
        'title': title,
        'body': body,
        'target': _target,
        'targetLabel': _targetLabel,
        'department': 'BCA',
        'createdBy': user.uid,
        'createdByEmail': user.email ?? '',
        'createdByRole': 'hod',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': 'push',
      });

      if (!mounted) return;

      _titleController.clear();
      _bodyController.clear();

      _showMessage(
        'Notification sent successfully.',
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        'Firebase Error: ${e.message ?? e.code}',
        error: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Error: ${e.toString()}',
        error: true,
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
  // DELETE ONE NOTIFICATION
  // ============================================================

  Future<void> _deleteNotification(
    String documentId,
  ) async {
    try {
      await _firestore.collection('notifications').doc(documentId).delete();

      if (!mounted) return;

      _showMessage(
        'Notification deleted.',
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        'Delete failed: ${e.message ?? e.code}',
        error: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Delete failed: ${e.toString()}',
        error: true,
      );
    }
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  Future<void> _confirmDeleteNotification(
    String documentId,
    String title,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Notification?',
          ),
          content: Text(
            'Are you sure you want to delete "$title"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteNotification(
        documentId,
      );
    }
  }

  // ============================================================
  // DELETE ALL NOTIFICATIONS
  // ============================================================

  Future<void> _deleteAllNotifications(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) async {
    if (documents.isEmpty) {
      _showMessage(
        'There are no notifications to delete.',
        error: true,
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete All Notifications?',
          ),
          content: Text(
            'This will permanently delete '
            '${documents.length} notification records '
            'from the history.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Delete All',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      // --------------------------------------------------------
      // FIRESTORE BATCH
      // --------------------------------------------------------

      WriteBatch batch = _firestore.batch();

      int operationCount = 0;

      for (final document in documents) {
        batch.delete(document.reference);
        operationCount++;

        // Firestore batch limit is 500.
        if (operationCount == 450) {
          await batch.commit();

          batch = _firestore.batch();
          operationCount = 0;
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }

      if (!mounted) return;

      _showMessage(
        'All notification history deleted.',
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        'Delete failed: ${e.message ?? e.code}',
        error: true,
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Delete failed: ${e.toString()}',
        error: true,
      );
    }
  }

  // ============================================================
  // TARGET DROPDOWN
  // ============================================================

  Widget _buildTargetDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _target,

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

      // ========================================================
      // OPTIONS
      // ========================================================

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

      // ========================================================
      // SELECTED VALUE
      // ========================================================

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

      // ========================================================
      // CHANGE
      // ========================================================

      onChanged: (value) {
        if (value == null) return;

        String label;

        switch (value) {
          case 'all':
            label = 'All Students & Faculty';
            break;

          case 'faculty':
            label = 'Faculty Only';
            break;

          case 'semester_1':
            label = 'Semester 1 Students';
            break;

          case 'semester_2':
            label = 'Semester 2 Students';
            break;

          case 'semester_3':
            label = 'Semester 3 Students';
            break;

          case 'semester_4':
            label = 'Semester 4 Students';
            break;

          case 'semester_5':
            label = 'Semester 5 Students';
            break;

          case 'semester_6':
            label = 'Semester 6 Students';
            break;

          default:
            label = 'All Students & Faculty';
        }

        setState(() {
          _target = value;
          _targetLabel = label;
        });
      },
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(
    String status,
  ) {
    Color color;
    IconData icon;
    String text;

    switch (status.toLowerCase()) {
      case 'sent':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        text = 'Sent';
        break;

      case 'failed':
        color = Colors.red;
        icon = Icons.error_outline;
        text = 'Failed';
        break;

      default:
        color = Colors.orange;
        icon = Icons.hourglass_top;
        text = 'Sending...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(
    Timestamp? timestamp,
  ) {
    if (timestamp == null) {
      return 'Just now';
    }

    final DateTime date = timestamp.toDate();

    String twoDigits(
      int number,
    ) {
      return number.toString().padLeft(2, '0');
    }

    final String day = twoDigits(date.day);

    final String month = twoDigits(date.month);

    final String year = date.year.toString();

    final int hour12 = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final String hour = twoDigits(hour12);

    final String minute = twoDigits(date.minute);

    final String period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year • '
        '$hour:$minute $period';
  }

  // ============================================================
  // NOTIFICATION HISTORY
  // ============================================================

  Widget _buildNotificationHistory() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // --------------------------------------------------------
      // IMPORTANT:
      //
      // NO orderBy()
      //
      // Therefore composite index is NOT required.
      // We sort the notifications locally.
      // --------------------------------------------------------

      stream: _firestore
          .collection('notifications')
          .where(
            'type',
            isEqualTo: 'push',
          )
          .snapshots(),

      builder: (
        context,
        snapshot,
      ) {
        // ------------------------------------------------------
        // ERROR
        // ------------------------------------------------------

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    'Unable to load notification history.\n'
                    '${snapshot.error}',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // ------------------------------------------------------
        // LOADING
        // ------------------------------------------------------

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // ------------------------------------------------------
        // DOCUMENTS
        // ------------------------------------------------------

        final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
            List.from(
          snapshot.data?.docs ?? [],
        );

        // ------------------------------------------------------
        // SORT LOCALLY
        //
        // This removes the need for Firestore index.
        // ------------------------------------------------------

        documents.sort(
          (
            a,
            b,
          ) {
            final dynamic aTime = a.data()['createdAt'];

            final dynamic bTime = b.data()['createdAt'];

            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(
                aTime,
              );
            }

            if (aTime is Timestamp) {
              return -1;
            }

            if (bTime is Timestamp) {
              return 1;
            }

            return 0;
          },
        );

        // ------------------------------------------------------
        // EMPTY
        // ------------------------------------------------------

        if (documents.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(
                16,
              ),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 50,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  'Notifications you send will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        // ------------------------------------------------------
        // HISTORY
        // ------------------------------------------------------

        return Column(
          children: [
            // --------------------------------------------------
            // DELETE ALL
            // --------------------------------------------------

            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _deleteAllNotifications(
                  documents,
                ),
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  size: 18,
                ),
                label: const Text(
                  'Delete All',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
                    color: Colors.red,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // --------------------------------------------------
            // NOTIFICATION CARDS
            // --------------------------------------------------

            ...documents.map(
              (
                document,
              ) {
                final Map<String, dynamic> data = document.data();

                final String title =
                    data['title']?.toString() ?? 'Untitled Notification';

                final String body = data['body']?.toString() ?? '';

                final String targetLabel = data['targetLabel']?.toString() ??
                    data['target']?.toString() ??
                    'Unknown';

                final String status = data['status']?.toString() ?? 'pending';

                final Timestamp? createdAt = data['createdAt'] is Timestamp
                    ? data['createdAt'] as Timestamp
                    : null;

                final String error = data['error']?.toString() ?? '';

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                      16,
                    ),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(
                      15,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --------------------------------------
                        // TOP ROW
                        // --------------------------------------

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(
                                9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(
                                  10,
                                ),
                              ),
                              child: const Icon(
                                Icons.notifications_active,
                                color: Colors.redAccent,
                                size: 21,
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            // TITLE
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    _formatDate(
                                      createdAt,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              width: 5,
                            ),

                            // STATUS
                            _buildStatusChip(
                              status,
                            ),

                            const SizedBox(
                              width: 5,
                            ),

                            // DELETE BUTTON
                            IconButton(
                              onPressed: () => _confirmDeleteNotification(
                                document.id,
                                title,
                              ),
                              tooltip: 'Delete',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 21,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        // --------------------------------------
                        // BODY
                        // --------------------------------------

                        Text(
                          body,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        // --------------------------------------
                        // TARGET
                        // --------------------------------------

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(
                              8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.groups_outlined,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(
                                width: 6,
                              ),
                              Flexible(
                                child: Text(
                                  targetLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --------------------------------------
                        // FAILED ERROR
                        // --------------------------------------

                        if (status == 'failed' && error.isNotEmpty) ...[
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(
                              10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(
                                8,
                              ),
                            ),
                            child: Text(
                              'Error: $error',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Push Notifications',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =================================================
              // SEND CARD
              // =================================================

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // -----------------------------------------
                      // HEADER
                      // -----------------------------------------

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(
                              10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(
                                alpha: 0.10,
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
                                  'Send a real-time alert to selected BCA students or faculty.',
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

                      // -----------------------------------------
                      // TARGET
                      // -----------------------------------------

                      _buildTargetDropdown(),

                      const SizedBox(
                        height: 18,
                      ),

                      // -----------------------------------------
                      // TITLE
                      // -----------------------------------------

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

                      // -----------------------------------------
                      // BODY
                      // -----------------------------------------

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

                      // -----------------------------------------
                      // SEND BUTTON
                      // -----------------------------------------

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
                            _isSending ? 'Sending...' : 'Send Notification',
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

                      // -----------------------------------------
                      // INFO
                      // -----------------------------------------

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
                                'The notification is saved in Firebase and then delivered through Firebase Cloud Messaging.',
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

              const SizedBox(
                height: 28,
              ),

              // =================================================
              // HISTORY HEADER
              // =================================================

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notification History',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestore
                        .collection(
                          'notifications',
                        )
                        .where(
                          'type',
                          isEqualTo: 'push',
                        )
                        .snapshots(),
                    builder: (
                      context,
                      snapshot,
                    ) {
                      final int count = snapshot.data?.docs.length ?? 0;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                'Notifications sent from the HOD panel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              // =================================================
              // HISTORY
              // =================================================

              _buildNotificationHistory(),
            ],
          ),
        ),
      ),
    );
  }
}
