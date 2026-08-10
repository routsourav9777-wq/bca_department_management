import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

class DownloadNotesScreen extends StatelessWidget {
  const DownloadNotesScreen({super.key});

  final String _collection = 'study_notes';

  // ============================================================
  // OPEN FILE
  // ============================================================

  Future<void> _openFile(
    BuildContext context,
    String url,
  ) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File is not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final Uri uri = Uri.parse(url);

      final bool success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is Timestamp) {
      final DateTime date = value.toDate();

      final String day =
          date.day.toString().padLeft(2, '0');

      final String month =
          date.month.toString().padLeft(2, '0');

      return '$day/$month/${date.year}';
    }

    return value.toString();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Download Notes',
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(_collection)
            .where(
              'department',
              isEqualTo: 'BCA',
            )
            .where(
              'status',
              isEqualTo: 'published',
            )
            .snapshots(),

        builder: (context, snapshot) {
          // ======================================================
          // LOADING
          // ======================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ======================================================
          // ERROR
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
                      color: Colors.red,
                      size: 55,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Unable to load notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ======================================================
          // NO NOTES
          // ======================================================

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 65,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 12),

                  Text(
                    'No Notes Available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    'Uploaded study materials will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final List<
                  QueryDocumentSnapshot<
                      Map<String, dynamic>>>
              notes = List.from(
            snapshot.data!.docs,
          );

          // ======================================================
          // SORT NEWEST FIRST
          // ======================================================

          notes.sort((a, b) {
            final dynamic aCreated =
                a.data()['createdAt'];

            final dynamic bCreated =
                b.data()['createdAt'];

            if (aCreated is Timestamp &&
                bCreated is Timestamp) {
              return bCreated.compareTo(
                aCreated,
              );
            }

            return 0;
          });

          // ======================================================
          // LIST
          // ======================================================

          return ListView.builder(
            padding: const EdgeInsets.all(16),

            itemCount: notes.length,

            itemBuilder: (context, index) {
              final Map<String, dynamic> data =
                  notes[index].data();

              final String title =
                  data['title']?.toString() ??
                      'Untitled Notes';

              final String description =
                  data['description']?.toString() ??
                      '';

              final String semester =
                  data['semester']?.toString() ??
                      '';

              final String department =
                  data['department']?.toString() ??
                      'BCA';

              final String pdfUrl =
                  data['pdfUrl']?.toString() ??
                      '';

              final String pdfName =
                  data['pdfName']?.toString() ??
                      'PDF Notes';

              final String imageUrl =
                  data['imageUrl']?.toString() ??
                      '';

              final String imageName =
                  data['imageName']?.toString() ??
                      'Camera Image';

              final String date =
                  _formatDate(
                data['createdAt'],
              );

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 14,
                ),

                elevation: 2,

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),

                child: Padding(
                  padding:
                      const EdgeInsets.all(16),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // ==========================================
                      // TITLE
                      // ==========================================

                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Container(
                            padding:
                                const EdgeInsets.all(
                              10,
                            ),

                            decoration:
                                BoxDecoration(
                              color: Colors.indigo
                                  .withOpacity(0.10),

                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                            ),

                            child: const Icon(
                              Icons.menu_book,
                              color: Colors.indigo,
                              size: 28,
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
                                  title,

                                  maxLines: 2,

                                  overflow:
                                      TextOverflow
                                          .ellipsis,

                                  style:
                                      const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Text(
                                  '$department • '
                                  '$semester',

                                  style:
                                      const TextStyle(
                                    color:
                                        AppTheme
                                            .primaryBlue,

                                    fontSize: 12,

                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (date.isNotEmpty)
                            Text(
                              date,

                              style:
                                  const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // ==========================================
                      // DESCRIPTION
                      // ==========================================

                      if (description.isNotEmpty)
                        Text(
                          description,

                          style:
                              const TextStyle(
                            fontSize: 13,
                            color:
                                AppTheme
                                    .textSecondary,

                            height: 1.4,
                          ),
                        ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ==========================================
                      // PDF
                      // ==========================================

                      if (pdfUrl.isNotEmpty)
                        Container(
                          padding:
                              const EdgeInsets.all(
                            10,
                          ),

                          decoration:
                              BoxDecoration(
                            border: Border.all(
                              color:
                                  Colors.grey.shade300,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                          ),

                          child: Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red,
                                size: 30,
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    const Text(
                                      'PDF Notes',

                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),

                                    Text(
                                      pdfName,

                                      maxLines: 1,

                                      overflow:
                                          TextOverflow
                                              .ellipsis,

                                      style:
                                          const TextStyle(
                                        fontSize: 11,
                                        color:
                                            Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              ElevatedButton.icon(
                                onPressed: () {
                                  _openFile(
                                    context,
                                    pdfUrl,
                                  );
                                },

                                icon: const Icon(
                                  Icons.download,
                                  size: 18,
                                ),

                                label:
                                    const Text(
                                  'PDF',
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ==========================================
                      // CAMERA IMAGE
                      // ==========================================

                      if (imageUrl.isNotEmpty) ...[
                        const SizedBox(
                          height: 10,
                        ),

                        Container(
                          padding:
                              const EdgeInsets.all(
                            10,
                          ),

                          decoration:
                              BoxDecoration(
                            border: Border.all(
                              color:
                                  Colors.grey.shade300,
                            ),

                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                          ),

                          child: Row(
                            children: [
                              const Icon(
                                Icons.image,
                                color:
                                    Colors.green,
                                size: 30,
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    const Text(
                                      'Photo Notes',

                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),

                                    Text(
                                      imageName,

                                      maxLines: 1,

                                      overflow:
                                          TextOverflow
                                              .ellipsis,

                                      style:
                                          const TextStyle(
                                        fontSize: 11,
                                        color:
                                            Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              IconButton(
                                onPressed: () {
                                  _openFile(
                                    context,
                                    imageUrl,
                                  );
                                },

                                icon: const Icon(
                                  Icons.open_in_new,
                                  color:
                                      AppTheme
                                          .primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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