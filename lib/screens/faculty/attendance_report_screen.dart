// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// import '../../services/attendance_excel_service.dart';

// class AttendanceReportScreen
//     extends StatefulWidget {
//   const AttendanceReportScreen({
//     super.key,
//   });

//   @override
//   State<AttendanceReportScreen>
//       createState() =>
//           _AttendanceReportScreenState();
// }

// class _AttendanceReportScreenState
//     extends State<AttendanceReportScreen> {
//   final FirebaseFirestore _firestore =
//       FirebaseFirestore.instance;

//   final AttendanceExcelService
//       _excelService =
//       AttendanceExcelService.instance;

//   final List<String> _semesters = const [
//     'Semester 1',
//     'Semester 2',
//     'Semester 3',
//     'Semester 4',
//     'Semester 5',
//     'Semester 6',
//   ];

//   String _selectedSemester =
//       'Semester 1';

//   String? _selectedSubjectId;

//   String? _selectedSubjectName;

//   int _selectedYear =
//       DateTime.now().year;

//   int _selectedMonth =
//       DateTime.now().month;

//   bool _generating = false;

//   // ============================================================
//   // SUBJECT STREAM
//   // ============================================================

//   Stream<QuerySnapshot<
//           Map<String, dynamic>>>
//       _subjectStream() {
//     return _firestore
//         .collection(
//           'subjects',
//         )
//         .where(
//           'department',
//           isEqualTo: 'BCA',
//         )
//         .where(
//           'semester',
//           isEqualTo: _selectedSemester,
//         )
//         .snapshots();
//   }

//   // ============================================================
//   // GENERATE EXCEL
//   // ============================================================

//   Future<void> _generateExcel() async {
//     if (_selectedSubjectId ==
//             null ||
//         _selectedSubjectName ==
//             null) {
//       _showMessage(
//         'Please select a subject.',
//         isError: true,
//       );

//       return;
//     }

//     setState(() {
//       _generating = true;
//     });

//     try {
//       final FileResult result =
//           await _createExcel();

//       if (!mounted) return;

//       _showSuccessDialog(
//         result.fileName,
//         result.path,
//       );
//     } catch (e) {
//       if (!mounted) return;

//       _showMessage(
//         'Excel generation failed:\n$e',
//         isError: true,
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _generating = false;
//         });
//       }
//     }
//   }

//   // ============================================================
//   // CREATE EXCEL
//   // ============================================================

//   Future<FileResult> _createExcel() async {
//     final file =
//         await _excelService
//             .generateAttendanceExcel(
//       semester:
//           _selectedSemester,

//       subjectId:
//           _selectedSubjectId!,

//       subjectName:
//           _selectedSubjectName!,

//       year:
//           _selectedYear,

//       month:
//           _selectedMonth,

//       academicYear:
//           _academicYear,
//     );

//     return FileResult(
//       fileName:
//           file.path
//               .split(
//                 RegExp(
//                   r'[/\\]',
//                 ),
//               )
//               .last,

//       path:
//           file.path,
//     );
//   }

//   // ============================================================
//   // SHARE EXCEL
//   // ============================================================

//   Future<void> _shareExcel() async {
//     if (_selectedSubjectId ==
//             null ||
//         _selectedSubjectName ==
//             null) {
//       _showMessage(
//         'Please select a subject.',
//         isError: true,
//       );

//       return;
//     }

//     setState(() {
//       _generating = true;
//     });

//     try {
//       final file =
//           await _excelService
//               .generateAndShare(
//         semester:
//             _selectedSemester,

//         subjectId:
//             _selectedSubjectId!,

//         subjectName:
//             _selectedSubjectName!,

//         year:
//             _selectedYear,

//         month:
//             _selectedMonth,

//         academicYear:
//             _academicYear,
//       );

//       if (!mounted) return;

//       _showMessage(
//         'Excel generated successfully:\n'
//         '${file.path}',
//       );
//     } catch (e) {
//       if (!mounted) return;

//       _showMessage(
//         'Unable to share Excel:\n$e',
//         isError: true,
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _generating = false;
//         });
//       }
//     }
//   }

//   // ============================================================
//   // ACADEMIC YEAR
//   // ============================================================

//   String get _academicYear {
//     final int startYear =
//         _selectedMonth >= 6
//             ? _selectedYear
//             : _selectedYear - 1;

//     return '$startYear-${(startYear + 1).toString().substring(2)}';
//   }

//   // ============================================================
//   // SUCCESS DIALOG
//   // ============================================================

//   void _showSuccessDialog(
//     String fileName,
//     String filePath,
//   ) {
//     showDialog<void>(
//       context: context,
//       builder:
//           (dialogContext) {
//         return AlertDialog(
//           shape:
//               RoundedRectangleBorder(
//             borderRadius:
//                 BorderRadius.circular(
//               18,
//             ),
//           ),

//           icon:
//               const Icon(
//             Icons
//                 .check_circle,
//             color:
//                 Colors.green,
//             size: 60,
//           ),

//           title:
//               const Text(
//             'Excel Ready',
//             textAlign:
//                 TextAlign.center,
//           ),

//           content:
//               Column(
//             mainAxisSize:
//                 MainAxisSize.min,

//             children: [
//               const Text(
//                 'Attendance Excel generated successfully.',

//                 textAlign:
//                     TextAlign.center,
//               ),

//               const SizedBox(
//                 height: 12,
//               ),

//               Text(
//                 fileName,

//                 textAlign:
//                     TextAlign.center,

//                 style:
//                     const TextStyle(
//                   fontWeight:
//                       FontWeight.bold,
//                   fontSize:
//                       12,
//                 ),
//               ),

//               const SizedBox(
//                 height: 8,
//               ),

//               Text(
//                 filePath,

//                 textAlign:
//                     TextAlign.center,

//                 style:
//                     const TextStyle(
//                   color:
//                       Colors.grey,
//                   fontSize:
//                       10,
//                 ),
//               ),
//             ],
//           ),

//           actions: [
//             SizedBox(
//               width:
//                   double.infinity,

//               child:
//                   ElevatedButton.icon(
//                 onPressed:
//                     () {
//                   Navigator.pop(
//                     dialogContext,
//                   );

//                   _shareExcel();
//                 },

//                 icon:
//                     const Icon(
//                   Icons
//                       .share,
//                 ),

//                 label:
//                     const Text(
//                   'Share / Send Excel',
//                 ),
//               ),
//             ),

//             SizedBox(
//               width:
//                   double.infinity,

//               child:
//                   TextButton(
//                 onPressed:
//                     () {
//                   Navigator.pop(
//                     dialogContext,
//                   );
//                 },

//                 child:
//                     const Text(
//                   'Done',
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // ============================================================
//   // MESSAGE
//   // ============================================================

//   void _showMessage(
//     String message, {
//     bool isError = false,
//   }) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(
//       SnackBar(
//         content:
//             Text(message),

//         backgroundColor:
//             isError
//                 ? Colors.red
//                 : Colors.green,

//         duration:
//             const Duration(
//           seconds: 4,
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // BUILD
//   // ============================================================

//   @override
//   Widget build(
//     BuildContext context,
//   ) {
//     return Scaffold(
//       appBar:
//           AppBar(
//         title:
//             const Text(
//           'Attendance Report',
//         ),
//       ),

//       body:
//           SafeArea(
//         child:
//             SingleChildScrollView(
//           padding:
//               const EdgeInsets.all(
//             16,
//           ),

//           child:
//               Column(
//             crossAxisAlignment:
//                 CrossAxisAlignment
//                     .stretch,

//             children: [
//               // ==================================================
//               // INFO CARD
//               // ==================================================

//               Card(
//                 color:
//                     Colors.blue.shade50,

//                 child:
//                     Padding(
//                   padding:
//                       const EdgeInsets.all(
//                     16,
//                   ),

//                   child:
//                       Row(
//                     children: [
//                       Icon(
//                         Icons
//                             .table_chart,
//                         color:
//                             Colors.blue
//                                 .shade700,
//                         size:
//                             34,
//                       ),

//                       const SizedBox(
//                         width:
//                             12,
//                       ),

//                       const Expanded(
//                         child:
//                             Column(
//                           crossAxisAlignment:
//                               CrossAxisAlignment
//                                   .start,

//                           children: [
//                             Text(
//                               'College Attendance Excel',

//                               style:
//                                   TextStyle(
//                                 fontSize:
//                                     17,
//                                 fontWeight:
//                                     FontWeight
//                                         .bold,
//                               ),
//                             ),

//                             SizedBox(
//                               height:
//                                   5,
//                             ),

//                             Text(
//                               'Firebase attendance will be converted to the college A4 attendance format.',

//                               style:
//                                   TextStyle(
//                                 fontSize:
//                                     12,
//                                 color:
//                                     Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(
//                 height:
//                     20,
//               ),

//               // ==================================================
//               // SEMESTER
//               // ==================================================

//               DropdownButtonFormField<
//                   String>(
//                 initialValue:
//                     _selectedSemester,

//                 isExpanded:
//                     true,

//                 decoration:
//                     InputDecoration(
//                   labelText:
//                       'Semester',

//                   prefixIcon:
//                       const Icon(
//                     Icons
//                         .school_outlined,
//                   ),

//                   border:
//                       OutlineInputBorder(
//                     borderRadius:
//                         BorderRadius.circular(
//                       12,
//                     ),
//                   ),
//                 ),

//                 items:
//                     _semesters
//                         .map(
//                   (
//                     semester,
//                   ) {
//                     return DropdownMenuItem<
//                         String>(
//                       value:
//                           semester,

//                       child:
//                           Text(
//                         semester,
//                       ),
//                     );
//                   },
//                 ).toList(),

//                 onChanged:
//                     (value) {
//                   if (value ==
//                       null) {
//                     return;
//                   }

//                   setState(() {
//                     _selectedSemester =
//                         value;

//                     _selectedSubjectId =
//                         null;

//                     _selectedSubjectName =
//                         null;
//                   });
//                 },
//               ),

//               const SizedBox(
//                 height:
//                     16,
//               ),

//               // ==================================================
//               // SUBJECT
//               // ==================================================

//               StreamBuilder<
//                   QuerySnapshot<
//                       Map<String,
//                           dynamic>>>(
//                 stream:
//                     _subjectStream(),

//                 builder:
//                     (
//                   context,
//                   snapshot,
//                 ) {
//                   if (snapshot
//                       .connectionState ==
//                       ConnectionState
//                           .waiting) {
//                     return const Center(
//                       child:
//                           CircularProgressIndicator(),
//                     );
//                   }

//                   if (snapshot
//                       .hasError) {
//                     return Text(
//                       'Subject error:\n${snapshot.error}',
//                       style:
//                           const TextStyle(
//                         color:
//                             Colors.red,
//                       ),
//                     );
//                   }

//                   final docs =
//                       snapshot.data
//                               ?.docs ??
//                           [];

//                   if (docs.isEmpty) {
//                     return Container(
//                       padding:
//                           const EdgeInsets
//                               .all(
//                         16,
//                       ),

//                       decoration:
//                           BoxDecoration(
//                         color:
//                             Colors.orange
//                                 .shade50,

//                         borderRadius:
//                             BorderRadius
//                                 .circular(
//                           12,
//                         ),
//                       ),

//                       child:
//                           const Text(
//                         'No subjects found for this semester.',
//                         style:
//                             TextStyle(
//                           color:
//                               Colors.orange,
//                         ),
//                       ),
//                     );
//                   }

//                   return DropdownButtonFormField<
//                       String>(
//                     initialValue:
//                         docs.any(
//                       (doc) =>
//                           doc.id ==
//                           _selectedSubjectId,
//                     )
//                             ? _selectedSubjectId
//                             : null,

//                     isExpanded:
//                         true,

//                     decoration:
//                         InputDecoration(
//                       labelText:
//                           'Subject',

//                       prefixIcon:
//                           const Icon(
//                         Icons
//                             .menu_book_outlined,
//                       ),

//                       border:
//                           OutlineInputBorder(
//                         borderRadius:
//                             BorderRadius
//                                 .circular(
//                           12,
//                         ),
//                       ),
//                     ),

//                     items:
//                         docs
//                             .map(
//                       (doc) {
//                         final data =
//                             doc.data();

//                         final String
//                             name =
//                             data['name']
//                                     ?.toString() ??
//                                 'Unnamed Subject';

//                         final String
//                             code =
//                             data['code']
//                                     ?.toString() ??
//                                 '';

//                         final String
//                             title =
//                             code.isEmpty
//                                 ? name
//                                 : '$code - $name';

//                         return DropdownMenuItem<
//                             String>(
//                           value:
//                               doc.id,

//                           child:
//                               Text(
//                             title,

//                             overflow:
//                                 TextOverflow
//                                     .ellipsis,
//                           ),
//                         );
//                       },
//                     ).toList(),

//                     onChanged:
//                         (value) {
//                       if (value ==
//                           null) {
//                         return;
//                       }

//                       final doc =
//                           docs.firstWhere(
//                         (item) =>
//                             item.id ==
//                             value,
//                       );

//                       final data =
//                           doc.data();

//                       setState(() {
//                         _selectedSubjectId =
//                             doc.id;

//                         _selectedSubjectName =
//                             data['name']
//                                     ?.toString() ??
//                                 'Subject';
//                       });
//                     },
//                   );
//                 },
//               ),

//               const SizedBox(
//                 height:
//                     16,
//               ),

//               // ==================================================
//               // MONTH
//               // ==================================================

//               Row(
//                 children: [
//                   Expanded(
//                     child:
//                         DropdownButtonFormField<
//                             int>(
//                       initialValue:
//                           _selectedMonth,

//                       isExpanded:
//                           true,

//                       decoration:
//                           InputDecoration(
//                         labelText:
//                             'Month',

//                         prefixIcon:
//                             const Icon(
//                           Icons
//                               .calendar_month,
//                         ),

//                         border:
//                             OutlineInputBorder(
//                           borderRadius:
//                               BorderRadius
//                                   .circular(
//                             12,
//                           ),
//                         ),
//                       ),

//                       items:
//                           List.generate(
//                         12,
//                         (
//                           index,
//                         ) {
//                           final int
//                               month =
//                               index +
//                                   1;

//                           return DropdownMenuItem<
//                               int>(
//                             value:
//                                 month,

//                             child:
//                                 Text(
//                               _monthName(
//                                 month,
//                               ),
//                             ),
//                           );
//                         },
//                       ),

//                       onChanged:
//                           (value) {
//                         if (value ==
//                             null) {
//                           return;
//                         }

//                         setState(() {
//                           _selectedMonth =
//                               value;
//                         });
//                       },
//                     ),
//                   ),

//                   const SizedBox(
//                     width:
//                         12,
//                   ),

//                   Expanded(
//                     child:
//                         DropdownButtonFormField<
//                             int>(
//                       initialValue:
//                           _selectedYear,

//                       isExpanded:
//                           true,

//                       decoration:
//                           InputDecoration(
//                         labelText:
//                             'Year',

//                         prefixIcon:
//                             const Icon(
//                           Icons
//                               .calendar_today,
//                         ),

//                         border:
//                             OutlineInputBorder(
//                           borderRadius:
//                               BorderRadius
//                                   .circular(
//                             12,
//                           ),
//                         ),
//                       ),

//                       items:
//                           List.generate(
//                         5,
//                         (
//                           index,
//                         ) {
//                           final int
//                               year =
//                               DateTime.now()
//                                       .year -
//                                   2 +
//                                   index;

//                           return DropdownMenuItem<
//                               int>(
//                             value:
//                                 year,

//                             child:
//                                 Text(
//                               '$year',
//                             ),
//                           );
//                         },
//                       ),

//                       onChanged:
//                           (value) {
//                         if (value ==
//                             null) {
//                           return;
//                         }

//                         setState(() {
//                           _selectedYear =
//                               value;
//                         });
//                       },
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(
//                 height:
//                     16,
//               ),

//               // ==================================================
//               // ACADEMIC YEAR
//               // ==================================================

//               Container(
//                 padding:
//                     const EdgeInsets
//                         .all(
//                   14,
//                 ),

//                 decoration:
//                     BoxDecoration(
//                   color:
//                       Colors.grey
//                           .shade100,

//                   borderRadius:
//                       BorderRadius.circular(
//                     12,
//                   ),
//                 ),

//                 child:
//                     Row(
//                   children: [
//                     const Icon(
//                       Icons
//                           .school,
//                     ),

//                     const SizedBox(
//                       width:
//                           10,
//                     ),

//                     const Text(
//                       'Academic Year:',
//                     ),

//                     const SizedBox(
//                       width:
//                           8,
//                     ),

//                     Text(
//                       _academicYear,

//                       style:
//                           const TextStyle(
//                         fontWeight:
//                             FontWeight
//                                 .bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(
//                 height:
//                     20,
//               ),

//               // ==================================================
//               // FORMAT PREVIEW
//               // ==================================================

//               Card(
//                 child:
//                     Padding(
//                   padding:
//                       const EdgeInsets
//                           .all(
//                     16,
//                   ),

//                   child:
//                       Column(
//                     crossAxisAlignment:
//                         CrossAxisAlignment
//                             .start,

//                     children: [
//                       const Text(
//                         'Excel will contain:',

//                         style:
//                             TextStyle(
//                           fontWeight:
//                               FontWeight
//                                   .bold,
//                           fontSize:
//                               15,
//                         ),
//                       ),

//                       const SizedBox(
//                         height:
//                             10,
//                       ),

//                       _previewItem(
//                         Icons
//                             .business,
//                         'Salipur Autonomous College heading',
//                       ),

//                       _previewItem(
//                         Icons
//                             .people,
//                         'Firebase student Roll No + Name',
//                       ),

//                       _previewItem(
//                         Icons
//                             .calendar_today,
//                         'Month/date-wise attendance',
//                       ),

//                       _previewItem(
//                         Icons
//                             .check_circle,
//                         'P = Present',
//                       ),

//                       _previewItem(
//                         Icons
//                             .cancel,
//                         'A = Absent',
//                       ),

//                       _previewItem(
//                         Icons
//                             .calculate,
//                         'TOTAL Present',
//                       ),

//                       _previewItem(
//                         Icons
//                             .notes,
//                         'REMARKS',
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(
//                 height:
//                     20,
//               ),

//               // ==================================================
//               // GENERATE BUTTON
//               // ==================================================

//               SizedBox(
//                 height:
//                     54,

//                 child:
//                     ElevatedButton.icon(
//                   onPressed:
//                       _generating
//                           ? null
//                           : _generateExcel,

//                   icon:
//                       _generating
//                           ? const SizedBox(
//                               width:
//                                   20,
//                               height:
//                                   20,
//                               child:
//                                   CircularProgressIndicator(
//                                 color:
//                                     Colors.white,
//                                 strokeWidth:
//                                     2,
//                               ),
//                             )
//                           : const Icon(
//                               Icons
//                                   .file_download,
//                             ),

//                   label:
//                       Text(
//                     _generating
//                         ? 'Generating Excel...'
//                         : 'Generate & Download Excel',

//                     style:
//                         const TextStyle(
//                       fontWeight:
//                           FontWeight
//                               .bold,
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(
//                 height:
//                     12,
//               ),

//               // ==================================================
//               // SHARE BUTTON
//               // ==================================================

//               SizedBox(
//                 height:
//                     50,

//                 child:
//                     OutlinedButton.icon(
//                   onPressed:
//                       _generating
//                           ? null
//                           : _shareExcel,

//                   icon:
//                       const Icon(
//                     Icons.share,
//                   ),

//                   label:
//                       const Text(
//                     'Generate & Share Excel',
//                   ),
//                 ),
//               ),

//               const SizedBox(
//                 height:
//                     20,
//               ),

//               const Text(
//                 'Note: Attendance dates are taken from the actual Firebase attendance sessions. A student gets P if they have a present record for that class date; otherwise A.',
//                 textAlign:
//                     TextAlign.center,

//                 style:
//                     TextStyle(
//                   color:
//                       Colors.grey,
//                   fontSize:
//                       11,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // PREVIEW ITEM
//   // ============================================================

//   Widget _previewItem(
//     IconData icon,
//     String text,
//   ) {
//     return Padding(
//       padding:
//           const EdgeInsets.only(
//         bottom: 8,
//       ),

//       child:
//           Row(
//         children: [
//           Icon(
//             icon,
//             size:
//                 18,
//             color:
//                 Colors.blue,
//           ),

//           const SizedBox(
//             width:
//                 8,
//           ),

//           Expanded(
//             child:
//                 Text(
//               text,
//               style:
//                   const TextStyle(
//                 fontSize:
//                     12,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ============================================================
//   // MONTH NAME
//   // ============================================================

//   String _monthName(
//     int month,
//   ) {
//     const months = [
//       'January',
//       'February',
//       'March',
//       'April',
//       'May',
//       'June',
//       'July',
//       'August',
//       'September',
//       'October',
//       'November',
//       'December',
//     ];

//     return months[month - 1];
//   }
// }

// // ================================================================
// // FILE RESULT
// // ================================================================

// class FileResult {
//   final String fileName;
//   final String path;

//   FileResult({
//     required this.fileName,
//     required this.path,
//   });
// }