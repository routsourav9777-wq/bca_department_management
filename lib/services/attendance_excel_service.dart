import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AttendanceSheetStudent {
  final String rollNo;
  final String name;
  final Map<int, String> attendance;

  AttendanceSheetStudent({
    required this.rollNo,
    this.name = '',
    required this.attendance,
  });

  int get totalPresent {
    int count = 0;

    for (final value in attendance.values) {
      if (value.toUpperCase() == 'P') {
        count++;
      }
    }

    return count;
  }
}

class AttendanceExcelService {
  AttendanceExcelService._();

  // ============================================================
  // MONTH NAME
  // ============================================================

  static String monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month];
  }

  // ============================================================
  // TITLE
  // ============================================================

  static String createTitle({
    required String semester,
    required int year,
    String batch = '2026 AB',
    String? academicYear,
  }) {
    final academic = academicYear ?? '$year-${year + 1}';

    return "STUDENTS' ATTENDANCE SHEET FOR BCA-$batch-$semester "
        'FOR THE ACADEMIC YEAR $academic';
  }

  // ============================================================
  // DOWNLOAD EXCEL
  // ============================================================

  static Future<void> downloadExcel({
    required String subjectName,
    required String semester,
    required int month,
    required int year,
    required List<AttendanceSheetStudent> students,
    String batch = '2026 AB',
    String? academicYear,
    String facultyName = '',
  }) async {
    final excel = xl.Excel.createExcel();

    const String sheetName = 'Attendance';

    final sheet = excel[sheetName];

    // ==========================================================
    // BORDER
    // ==========================================================

    final border = xl.Border(
      borderStyle: xl.BorderStyle.Thin,
      borderColorHex: xl.ExcelColor.black,
    );

    // ==========================================================
    // STYLES
    // ==========================================================

    final titleStyle = xl.CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
      textWrapping: xl.TextWrapping.WrapText,
      leftBorder: border,
      rightBorder: border,
      topBorder: border,
      bottomBorder: border,
    );

    final headerStyle = xl.CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
      textWrapping: xl.TextWrapping.WrapText,
      leftBorder: border,
      rightBorder: border,
      topBorder: border,
      bottomBorder: border,
    );

    final cellStyle = xl.CellStyle(
      fontSize: 10,
      horizontalAlign: xl.HorizontalAlign.Center,
      verticalAlign: xl.VerticalAlign.Center,
      leftBorder: border,
      rightBorder: border,
      topBorder: border,
      bottomBorder: border,
    );

    final rollNoStyle = xl.CellStyle(
      fontSize: 10,
      horizontalAlign: xl.HorizontalAlign.Left,
      verticalAlign: xl.VerticalAlign.Center,
      leftBorder: border,
      rightBorder: border,
      topBorder: border,
      bottomBorder: border,
    );

    // ==========================================================
    // TOTAL COLUMNS
    // ==========================================================

    // 0  = Roll No
    // 1  = Day 1
    // ...
    // 31 = Day 31
    // 32 = TOTAL
    // 33 = REMARKS

    const int totalColumns = 34;

    // ==========================================================
    // ROW 1 - TITLE
    // ==========================================================

    sheet.merge(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 0,
      ),
      xl.CellIndex.indexByColumnRow(
        columnIndex: totalColumns - 1,
        rowIndex: 0,
      ),
    );

    sheet.updateCell(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 0,
      ),
      xl.TextCellValue(
        createTitle(
          semester: semester,
          year: year,
          batch: batch,
          academicYear: academicYear,
        ),
      ),
      cellStyle: titleStyle,
    );

    sheet.setRowHeight(0, 35);

    // ==========================================================
    // ROW 2 - SUBJECT
    // ==========================================================

    sheet.merge(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 1,
      ),
      xl.CellIndex.indexByColumnRow(
        columnIndex: 1,
        rowIndex: 1,
      ),
    );

    sheet.updateCell(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 1,
      ),
      xl.TextCellValue('SUBJECT'),
      cellStyle: headerStyle,
    );

    // Subject name

    sheet.merge(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 2,
        rowIndex: 1,
      ),
      xl.CellIndex.indexByColumnRow(
        columnIndex: 15,
        rowIndex: 1,
      ),
    );

    sheet.updateCell(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 2,
        rowIndex: 1,
      ),
      xl.TextCellValue(subjectName),
      cellStyle: headerStyle,
    );

    // ==========================================================
    // MONTH
    // ==========================================================

    sheet.merge(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 16,
        rowIndex: 1,
      ),
      xl.CellIndex.indexByColumnRow(
        columnIndex: 17,
        rowIndex: 1,
      ),
    );

    sheet.updateCell(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 16,
        rowIndex: 1,
      ),
      xl.TextCellValue('MONTH'),
      cellStyle: headerStyle,
    );

    sheet.merge(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 18,
        rowIndex: 1,
      ),
      xl.CellIndex.indexByColumnRow(
        columnIndex: totalColumns - 1,
        rowIndex: 1,
      ),
    );

    sheet.updateCell(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 18,
        rowIndex: 1,
      ),
      xl.TextCellValue(monthName(month)),
      cellStyle: headerStyle,
    );

    sheet.setRowHeight(1, 25);

    // ==========================================================
    // ROW 3 - HEADER
    // ==========================================================

    sheet.updateCell(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: 2,
      ),
      xl.TextCellValue(r'Roll No\Date'),
      cellStyle: headerStyle,
    );

    // Days 1 to 31

    for (int day = 1; day <= 31; day++) {
      sheet.updateCell(
        xl.CellIndex.indexByColumnRow(
          columnIndex: day,
          rowIndex: 2,
        ),
        xl.IntCellValue(day),
        cellStyle: headerStyle,
      );
    }

    // TOTAL

    sheet.updateCell(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 32,
        rowIndex: 2,
      ),
      xl.TextCellValue('TOTAL'),
      cellStyle: headerStyle,
    );

    // REMARKS

    sheet.updateCell(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 33,
        rowIndex: 2,
      ),
      xl.TextCellValue('REMARKS'),
      cellStyle: headerStyle,
    );

    sheet.setRowHeight(2, 30);

    // ==========================================================
    // STUDENTS
    // ==========================================================

    int currentRow = 3;

    for (final student in students) {
      // --------------------------------------------------------
      // ROLL NUMBER
      // --------------------------------------------------------

      sheet.updateCell(
        xl.CellIndex.indexByColumnRow(
          columnIndex: 0,
          rowIndex: currentRow,
        ),
        xl.TextCellValue(student.rollNo),
        cellStyle: rollNoStyle,
      );

      // --------------------------------------------------------
      // DAYS
      // --------------------------------------------------------

      for (int day = 1; day <= 31; day++) {
        String value = '';

        if (student.attendance.containsKey(day)) {
          value = student.attendance[day]!.toUpperCase();
        }

        sheet.updateCell(
          xl.CellIndex.indexByColumnRow(
            columnIndex: day,
            rowIndex: currentRow,
          ),
          xl.TextCellValue(value),
          cellStyle: cellStyle,
        );
      }

      // --------------------------------------------------------
      // TOTAL PRESENT
      // --------------------------------------------------------

      sheet.updateCell(
        xl.CellIndex.indexByColumnRow(
          columnIndex: 32,
          rowIndex: currentRow,
        ),
        xl.IntCellValue(student.totalPresent),
        cellStyle: cellStyle,
      );

      // --------------------------------------------------------
      // REMARKS
      // --------------------------------------------------------

      sheet.updateCell(
        xl.CellIndex.indexByColumnRow(
          columnIndex: 33,
          rowIndex: currentRow,
        ),
        xl.TextCellValue(''),
        cellStyle: cellStyle,
      );

      sheet.setRowHeight(currentRow, 22);

      currentRow++;
    }

    // ==========================================================
    // FACULTY SIGNATURE
    // ==========================================================

    final signatureRow = currentRow;

    sheet.merge(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: signatureRow,
      ),
      xl.CellIndex.indexByColumnRow(
        columnIndex: 5,
        rowIndex: signatureRow,
      ),
    );

    final signatureStyle = xl.CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: xl.HorizontalAlign.Left,
      verticalAlign: xl.VerticalAlign.Center,
      textWrapping: xl.TextWrapping.WrapText,
      leftBorder: border,
      rightBorder: border,
      topBorder: border,
      bottomBorder: border,
    );

    sheet.updateCell(
      xl.CellIndex.indexByColumnRow(
        columnIndex: 0,
        rowIndex: signatureRow,
      ),
      xl.TextCellValue(
        facultyName.isEmpty
            ? 'Faculty\nSignature'
            : 'Faculty\nSignature: $facultyName',
      ),
      cellStyle: signatureStyle,
    );

    // Remaining cells of signature row

    for (int column = 6; column < totalColumns; column++) {
      sheet.updateCell(
        xl.CellIndex.indexByColumnRow(
          columnIndex: column,
          rowIndex: signatureRow,
        ),
        xl.TextCellValue(''),
        cellStyle: cellStyle,
      );
    }

    sheet.setRowHeight(signatureRow, 40);

    // ==========================================================
    // COLUMN WIDTHS
    // ==========================================================

    // Roll No

    sheet.setColumnWidth(0, 15);

    // Day 1 - 31

    for (int column = 1; column <= 31; column++) {
      sheet.setColumnWidth(column, 5);
    }

    // Total

    sheet.setColumnWidth(32, 9);

    // Remarks

    sheet.setColumnWidth(33, 15);

    // ==========================================================
    // SAVE EXCEL
    // ==========================================================

    final bytes = excel.save();

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Unable to create Excel file.');
    }

    final safeSubject = subjectName
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    final fileName =
        'Attendance_${safeSubject}_${monthName(month)}_$year';

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'xlsx',
      includeExtension: true,
      mimeType: MimeType.microsoftExcel,
    );
  }

  // ============================================================
  // DOWNLOAD PDF
  // ============================================================

  static Future<void> downloadPdf({
    required String subjectName,
    required String semester,
    required int month,
    required int year,
    required List<AttendanceSheetStudent> students,
    String batch = '2026 AB',
    String? academicYear,
    String facultyName = '',
  }) async {
    final pdf = pw.Document();

    final title = createTitle(
      semester: semester,
      year: year,
      batch: batch,
      academicYear: academicYear,
    );

    // ==========================================================
    // HEADER
    // ==========================================================

    final headers = <String>[
      r'Roll No\Date',
      ...List.generate(
        31,
        (index) => '${index + 1}',
      ),
      'TOTAL',
      'REMARKS',
    ];

    // ==========================================================
    // STUDENT DATA
    // ==========================================================

    final data = <List<String>>[];

    for (final student in students) {
      final row = <String>[];

      row.add(student.rollNo);

      for (int day = 1; day <= 31; day++) {
        final value = student.attendance[day] ?? '';

        row.add(value.toUpperCase());
      }

      row.add(student.totalPresent.toString());

      row.add('');

      data.add(row);
    }

    // ==========================================================
    // PDF
    // ==========================================================

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(15),
        build: (context) {
          return [
            // --------------------------------------------------
            // TITLE
            // --------------------------------------------------

            pw.Center(
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),

            pw.SizedBox(height: 8),

            // --------------------------------------------------
            // SUBJECT + MONTH
            // --------------------------------------------------

            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.black,
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(55),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FixedColumnWidth(45),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  children: [
                    _pdfCell(
                      'SUBJECT',
                      bold: true,
                    ),
                    _pdfCell(
                      subjectName,
                      bold: true,
                    ),
                    _pdfCell(
                      'MONTH',
                      bold: true,
                    ),
                    _pdfCell(
                      monthName(month),
                      bold: true,
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 5),

            // --------------------------------------------------
            // ATTENDANCE TABLE
            // --------------------------------------------------

            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,

              border: pw.TableBorder.all(
                color: PdfColors.black,
                width: 0.5,
              ),

              headerStyle: pw.TextStyle(
                fontSize: 5,
                fontWeight: pw.FontWeight.bold,
              ),

              cellStyle: const pw.TextStyle(
                fontSize: 5,
              ),

              headerAlignment: pw.Alignment.center,

              cellAlignment: pw.Alignment.center,

              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 3,
              ),

              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.white,
              ),

              columnWidths: {
                0: const pw.FixedColumnWidth(48),

                for (int i = 1; i <= 31; i++)
                  i: const pw.FixedColumnWidth(14),

                32: const pw.FixedColumnWidth(32),

                33: const pw.FixedColumnWidth(50),
              },
            ),

            pw.SizedBox(height: 15),

            // --------------------------------------------------
            // FACULTY SIGNATURE
            // --------------------------------------------------

            pw.Container(
              height: 45,
              width: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.black,
                  width: 0.5,
                ),
              ),
              alignment: pw.Alignment.centerLeft,
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                facultyName.isEmpty
                    ? 'Faculty Signature'
                    : 'Faculty Signature: $facultyName',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // ==========================================================
    // SAVE PDF
    // ==========================================================

    final bytes = await pdf.save();

    final safeSubject = subjectName
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');

    final fileName =
        'Attendance_${safeSubject}_${monthName(month)}_$year';

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      fileExtension: 'pdf',
      includeExtension: true,
      mimeType: MimeType.pdf,
    );
  }

  // ============================================================
  // PDF CELL
  // ============================================================

  static pw.Widget _pdfCell(
    String text, {
    bool bold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: bold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}