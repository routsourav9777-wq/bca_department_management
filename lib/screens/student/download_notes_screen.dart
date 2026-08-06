import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class DownloadNotesScreen extends StatefulWidget {
  const DownloadNotesScreen({super.key});

  @override
  State<DownloadNotesScreen> createState() => _DownloadNotesScreenState();
}

class _DownloadNotesScreenState extends State<DownloadNotesScreen> {
  String _selectedSem = AppConstants.semesters[2]; // Semester 3

  final List<Map<String, String>> _notesList = [
    {
      'title': 'DBMS Unit 1 & 2 Relational Model & SQL',
      'subject': 'BCA-301 DBMS',
      'uploadedBy': 'Dr. Smruti Rekha Das',
      'size': '2.8 MB',
      'date': '02 Aug 2026',
    },
    {
      'title': 'Java OOP Concepts & Exception Handling',
      'subject': 'BCA-302 Java',
      'uploadedBy': 'Prof. Santosh Kumar Sahoo',
      'size': '3.4 MB',
      'date': '30 Jul 2026',
    },
    {
      'title': 'Operating System Process Synchronization',
      'subject': 'BCA-303 OS',
      'uploadedBy': 'Er. Manoranjan Swain',
      'size': '1.9 MB',
      'date': '28 Jul 2026',
    },
  ];

  void _downloadPdf(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading PDF: "$title" to device storage...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download Study Notes')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: DropdownButtonFormField<String>(
              value: _selectedSem,
              decoration: const InputDecoration(labelText: 'Select Semester Notes'),
              items: AppConstants.semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) { if (val != null) setState(() => _selectedSem = val); },
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notesList.length,
              itemBuilder: (context, index) {
                final note = _notesList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(note['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text('${note['subject']} • ${note['size']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Uploaded by ${note['uploadedBy']} on ${note['date']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ElevatedButton.icon(
                              onPressed: () => _downloadPdf(note['title']!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('PDF Download', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
