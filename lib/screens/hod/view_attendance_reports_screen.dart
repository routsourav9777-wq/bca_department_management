import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';


class ViewAttendanceReportsScreen extends StatefulWidget {
  const ViewAttendanceReportsScreen({super.key});

  @override
  State<ViewAttendanceReportsScreen> createState() => _ViewAttendanceReportsScreenState();
}

class _ViewAttendanceReportsScreenState extends State<ViewAttendanceReportsScreen> {
  String _selectedSem = AppConstants.semesters[2]; // Sem 3

  final List<Map<String, dynamic>> _attendanceData = [
    {'rollNo': 'BC23-001', 'name': 'Aakash Mohanty', 'totalClasses': 45, 'attended': 41, 'percentage': 91.1},
    {'rollNo': 'BC23-002', 'name': 'Aditya Prasad Das', 'totalClasses': 45, 'attended': 38, 'percentage': 84.4},
    {'rollNo': 'BC23-003', 'name': 'Ankit Nayak', 'totalClasses': 45, 'attended': 31, 'percentage': 68.8}, // < 75%
    {'rollNo': 'BC23-004', 'name': 'Bishnupriya Sahoo', 'totalClasses': 45, 'attended': 44, 'percentage': 97.7},
    {'rollNo': 'BC23-005', 'name': 'Debasis Rout', 'totalClasses': 45, 'attended': 32, 'percentage': 71.1}, // < 75%
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Attendance Summary'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Select Semester: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSem,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                    items: AppConstants.semesters
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSem = val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _attendanceData.length,
              itemBuilder: (context, index) {
                final st = _attendanceData[index];
                final double pct = st['percentage'];
                final bool isLow = pct < 75.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: isLow ? Colors.red.shade100 : Colors.green.shade100,
                      child: Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: isLow ? Colors.red : Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text('${st['rollNo']} - ${st['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Classes: ${st['attended']} / ${st['totalClasses']} attended'),
                    trailing: isLow
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                            child: const Text('Shortage', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                          )
                        : const Icon(Icons.check_circle, color: Colors.green),
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
