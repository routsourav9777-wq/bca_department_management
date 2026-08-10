import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class FacultyViewNoticesScreen extends StatelessWidget {
  const FacultyViewNoticesScreen({super.key});

  // ============================================================
  // FIRESTORE
  // ============================================================

  final String _collectionName = 'notices';

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) {
      return '';
    }

    // Firebase Timestamp
    if (value is Timestamp) {
      final DateTime date = value.toDate();

      final String day = date.day.toString().padLeft(2, '0');

      final String month = date.month.toString().padLeft(2, '0');

      final String year = date.year.toString();

      return '$day/$month/$year';
    }

    // DateTime
    if (value is DateTime) {
      final String day = value.day.toString().padLeft(2, '0');

      final String month = value.month.toString().padLeft(2, '0');

      return '$day/$month/${value.year}';
    }

    // String date
    return value.toString();
  }

  // ============================================================
  // GET AUTHOR
  // ============================================================

  String _getAuthor(
    Map<String, dynamic> data,
  ) {
    return data['author']?.toString() ??
        data['uploadedBy']?.toString() ??
        data['createdBy']?.toString() ??
        'Department';
  }

  // ============================================================
  // GET DATE
  // ============================================================

  String _getDate(
    Map<String, dynamic> data,
  ) {
    final dynamic date = data['date'] ?? data['createdAt'];

    return _formatDate(date);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        title: const Text(
          'Department Notices',
        ),
      ),

      // ==========================================================
      // FIREBASE STREAM
      // ==========================================================

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance.collection(_collectionName).snapshots(),
        builder: (context, snapshot) {
          // ======================================================
          // LOADING
          // ======================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ======================================================
          // FIREBASE ERROR
          // ======================================================

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    const Text(
                      'Unable to load notices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // StreamBuilder automatically
                        // retries when widget rebuilds.
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FacultyViewNoticesScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // ======================================================
          // NO DATA
          // ======================================================

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 70,
                    color: Colors.grey,
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Text(
                    'No department notices',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 6,
                  ),
                  Text(
                    'New notices will appear here.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // ======================================================
          // FIRESTORE DOCUMENTS
          // ======================================================

          final List<QueryDocumentSnapshot<Map<String, dynamic>>> notices =
              snapshot.data!.docs;

          // ======================================================
          // SORT NEWEST FIRST
          // ======================================================

          notices.sort((a, b) {
            final dynamic aDate = a.data()['createdAt'];

            final dynamic bDate = b.data()['createdAt'];

            if (aDate is Timestamp && bDate is Timestamp) {
              return bDate.compareTo(aDate);
            }

            return 0;
          });

          // ======================================================
          // NOTICE LIST
          // ======================================================

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final Map<String, dynamic> data = notices[index].data();

              final String title =
                  data['title']?.toString() ?? 'Untitled Notice';

              final String content = data['content']?.toString() ??
                  data['description']?.toString() ??
                  '';

              final String author = _getAuthor(data);

              final String date = _getDate(data);

              final String department = data['department']?.toString() ?? 'BCA';

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 12,
                ),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==========================================
                      // AUTHOR + DATE
                      // ==========================================

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(
                                6,
                              ),
                            ),
                            child: Text(
                              author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (date.isNotEmpty)
                            Text(
                              date,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // ==========================================
                      // DEPARTMENT
                      // ==========================================

                      Row(
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 15,
                            color: Colors.grey,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            department,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // ==========================================
                      // TITLE
                      // ==========================================

                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ==========================================
                      // CONTENT
                      // ==========================================

                      Text(
                        content,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.4,
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
    );
  }
}
