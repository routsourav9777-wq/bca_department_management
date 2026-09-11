import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class LocalAttendanceExcelService {
  LocalAttendanceExcelService._();

  static final LocalAttendanceExcelService instance =
      LocalAttendanceExcelService._();

  // ============================================================
  // YOUR EXCEL TEMPLATE
  // ============================================================

  static const String templatePath = 'assets/excel/attendance_template.xlsx';

  static const String localFileName = 'BCA_ATTENDANCE.xlsx';

  // ============================================================
  // GET LOCAL EXCEL
  // ============================================================

  Future<File> getAttendanceFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();

    final File file = File(
      '${directory.path}${Platform.pathSeparator}$localFileName',
    );

    // First time only:
    // Copy college Excel from assets to writable storage.
    if (!await file.exists()) {
      final ByteData data = await rootBundle.load(templatePath);

      final Uint8List bytes = data.buffer.asUint8List();

      await file.writeAsBytes(
        bytes,
        flush: true,
      );
    }

    return file;
  }

  // ============================================================
  // RESET EXCEL
  // ============================================================
  //
  // TESTING ke liye.
  // Isse local Excel delete ho jayegi.
  // Next time template se new Excel banegi.
  //

  Future<void> resetAttendanceFile() async {
    final Directory directory = await getApplicationDocumentsDirectory();

    final File file = File(
      '${directory.path}${Platform.pathSeparator}$localFileName',
    );

    if (await file.exists()) {
      await file.delete();
    }
  }

  // ============================================================
  // MARK PRESENT
  // ============================================================

  Future<File> markPresent({
    required String rollNo,
    required String studentName,
    required DateTime date,
  }) async {
    final File file = await getAttendanceFile();

    final List<int> bytes = await file.readAsBytes();

    final Excel excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      throw Exception(
        'Excel sheet nahi mili.',
      );
    }

    final String sheetName = excel.tables.keys.first;

    final Sheet sheet = excel[sheetName];

    // ----------------------------------------------------------
    // FIND STUDENT ROW
    // ----------------------------------------------------------

    int? studentRow = _findStudentRow(
      sheet: sheet,
      rollNo: rollNo,
    );

    // ----------------------------------------------------------
    // IF STUDENT NOT FOUND
    // ----------------------------------------------------------

    if (studentRow == null) {
      studentRow = _findEmptyStudentRow(
        sheet,
      );

      // Roll No
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: studentRow,
            ),
          )
          .value = TextCellValue(
        rollNo,
      );

      // Student Name
      sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: studentRow,
            ),
          )
          .value = TextCellValue(
        studentName,
      );
    }

    // ----------------------------------------------------------
    // FIND TODAY'S DATE COLUMN
    // ----------------------------------------------------------

    final int dateColumn = _getOrCreateDateColumn(
      sheet: sheet,
      date: date,
    );

    // ----------------------------------------------------------
    // WRITE P
    // ----------------------------------------------------------

    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: dateColumn,
            rowIndex: studentRow,
          ),
        )
        .value = TextCellValue(
      'P',
    );

    // ----------------------------------------------------------
    // SAVE
    // ----------------------------------------------------------

    await _saveExcel(
      excel: excel,
      file: file,
    );

    return file;
  }

  // ============================================================
  // MARK ABSENT
  // ============================================================

  Future<File> markAbsent({
    required String rollNo,
    required DateTime date,
  }) async {
    final File file = await getAttendanceFile();

    final List<int> bytes = await file.readAsBytes();

    final Excel excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) {
      throw Exception(
        'Excel sheet nahi mili.',
      );
    }

    final String sheetName = excel.tables.keys.first;

    final Sheet sheet = excel[sheetName];

    final int? studentRow = _findStudentRow(
      sheet: sheet,
      rollNo: rollNo,
    );

    if (studentRow == null) {
      throw Exception(
        'Student $rollNo Excel me nahi mila.',
      );
    }

    final int dateColumn = _getOrCreateDateColumn(
      sheet: sheet,
      date: date,
    );

    sheet
        .cell(
          CellIndex.indexByColumnRow(
            columnIndex: dateColumn,
            rowIndex: studentRow,
          ),
        )
        .value = TextCellValue(
      'A',
    );

    await _saveExcel(
      excel: excel,
      file: file,
    );

    return file;
  }

  // ============================================================
  // FIND STUDENT ROW
  // ============================================================

  int? _findStudentRow({
    required Sheet sheet,
    required String rollNo,
  }) {
    final String wanted = rollNo.trim().toLowerCase();

    // Student rows start after heading.
    // We check first 1000 rows.
    for (int row = 4; row < 1000; row++) {
      final CellValue? cell = sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: row,
            ),
          )
          .value;

      final String value = _cellText(cell).trim().toLowerCase();

      if (value.isEmpty) {
        continue;
      }

      if (value == wanted) {
        return row;
      }

      // In case cell contains:
      // BCA001 - Sourav
      if (value.startsWith('$wanted ')) {
        return row;
      }

      if (value.startsWith('$wanted-')) {
        return row;
      }

      if (value.startsWith('$wanted -')) {
        return row;
      }
    }

    return null;
  }

  // ============================================================
  // FIND EMPTY STUDENT ROW
  // ============================================================

  int _findEmptyStudentRow(
    Sheet sheet,
  ) {
    for (int row = 4; row < 1000; row++) {
      final CellValue? cell = sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: row,
            ),
          )
          .value;

      final String value = _cellText(cell).trim();

      if (value.isEmpty) {
        return row;
      }
    }

    return 4;
  }

  // ============================================================
  // GET / CREATE DATE COLUMN
  // ============================================================

  int _getOrCreateDateColumn({
    required Sheet sheet,
    required DateTime date,
  }) {
    // ----------------------------------------------------------
    // First check existing date columns.
    // ----------------------------------------------------------

    for (int column = 1; column < 40; column++) {
      final CellValue? cell = sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: column,
              rowIndex: 3,
            ),
          )
          .value;

      final String value = _cellText(cell).trim();

      if (value.isEmpty) {
        continue;
      }

      final int? day = _extractDay(value);

      if (day == date.day) {
        return column;
      }
    }

    // ----------------------------------------------------------
    // Date not found.
    // Create next date column.
    // ----------------------------------------------------------

    for (int column = 1; column < 40; column++) {
      final CellValue? cell = sheet
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: column,
              rowIndex: 3,
            ),
          )
          .value;

      final String value = _cellText(cell).trim();

      if (value.isEmpty) {
        sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: column,
                rowIndex: 3,
              ),
            )
            .value = IntCellValue(
          date.day,
        );

        return column;
      }
    }

    throw Exception(
      'Excel me date ke liye space nahi hai.',
    );
  }

  // ============================================================
  // EXTRACT DAY
  // ============================================================

  int? _extractDay(
    String value,
  ) {
    final String clean = value
        .replaceAll(
          RegExp(r'[^0-9]'),
          '',
        )
        .trim();

    if (clean.isEmpty) {
      return null;
    }

    final int? number = int.tryParse(clean);

    if (number == null) {
      return null;
    }

    if (number < 1 || number > 31) {
      return null;
    }

    return number;
  }

  // ============================================================
  // SAVE EXCEL
  // ============================================================

  Future<void> _saveExcel({
    required Excel excel,
    required File file,
  }) async {
    final List<int>? output = excel.save();

    if (output == null) {
      throw Exception(
        'Excel save failed.',
      );
    }

    await file.writeAsBytes(
      output,
      flush: true,
    );

    // Verify that file actually exists.
    if (!await file.exists()) {
      throw Exception(
        'Excel file save nahi hui.',
      );
    }

    final int size = await file.length();

    if (size <= 0) {
      throw Exception(
        'Excel file empty hai.',
      );
    }
  }

  // ============================================================
  // GET FILE PATH
  // ============================================================

  Future<String> getFilePath() async {
    final File file = await getAttendanceFile();

    return file.path;
  }

  // ============================================================
  // SHARE EXCEL
  // ============================================================

  Future<void> shareExcel() async {
    final File file = await getAttendanceFile();

    await SharePlus.instance.share(
      ShareParams(
        title: 'BCA Attendance Register',
        text: 'BCA Attendance Excel',
        files: [
          XFile(
            file.path,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CELL TO STRING
  // ============================================================

  String _cellText(CellValue? value) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }
}
