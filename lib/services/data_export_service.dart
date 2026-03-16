import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/category.dart';

class DataExportService {
  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true; // For other platforms or handled differently
  }

  static Future<String?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
  }

  static Future<void> exportCategoryToCsv(Category category) async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) return;

    final dirPath = await _getDownloadDirectory();
    if (dirPath == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final fileName = '${category.name}_Transactions_$dateStr.csv';
    final filePath = '$dirPath/$fileName';

    final headers = ['Type', 'Title', 'Amount', 'Mode', 'Date', 'Description'];
    final List<List<dynamic>> rows = [headers];

    final dateFormat = DateFormat('dd-MM-yyyy');

    for (var income in category.incomes) {
      rows.add([
        'Income',
        income.title,
        income.amount,
        income.paymentMode,
        dateFormat.format(income.date),
        income.description,
      ]);
    }

    for (var expense in category.expenses) {
      rows.add([
        'Expense',
        expense.title,
        expense.amount,
        expense.paymentMode,
        dateFormat.format(expense.date),
        expense.description,
      ]);
    }

    String csv = const CsvEncoder().convert(rows);
    final file = File(filePath);
    await file.writeAsString(csv);
  }

  static Future<void> exportCategoryToExcel(Category category) async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) return;

    final dirPath = await _getDownloadDirectory();
    if (dirPath == null) return;

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final fileName = '${category.name}_Transactions_$dateStr.xlsx';
    final filePath = '$dirPath/$fileName';

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    final headers = ['Type', 'Title', 'Amount', 'Mode', 'Date', 'Description'];
    sheetObject.appendRow(headers.map((e) => TextCellValue(e)).toList());

    final dateFormat = DateFormat('dd-MM-yyyy');

    for (var income in category.incomes) {
      sheetObject.appendRow([
        TextCellValue('Income'),
        TextCellValue(income.title),
        DoubleCellValue(income.amount),
        TextCellValue(income.paymentMode),
        TextCellValue(dateFormat.format(income.date)),
        TextCellValue(income.description),
      ]);
    }

    for (var expense in category.expenses) {
      sheetObject.appendRow([
        TextCellValue('Expense'),
        TextCellValue(expense.title),
        DoubleCellValue(expense.amount),
        TextCellValue(expense.paymentMode),
        TextCellValue(dateFormat.format(expense.date)),
        TextCellValue(expense.description),
      ]);
    }

    final fileBytes = excel.encode();
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
    }
  }
}
