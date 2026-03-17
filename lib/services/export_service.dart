import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';

class ExportService {
  static Future<String?> exportCategoryToCSV({
    required Category category,
    required List<Expense> expenses,
    required List<Income> incomes,
    required bool exportExpenses,
    required bool exportIncomes,
  }) async {
    try {
      // 1. Save file to temporary/documents directory
      final directory = await getTemporaryDirectory();
      
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final safeCategoryName = category.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${directory.path}/${safeCategoryName}_$timestamp.csv');

      // 2. Prepare CSV data
      List<List<dynamic>> rows = [];
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

      // headers
      rows.add([
        'Date',
        'Type',
        'Title',
        'Amount',
        'Payment Mode',
        'Description',
      ]);

      if (exportIncomes) {
        for (var income in incomes) {
          rows.add([
            dateFormat.format(income.date),
            'Income',
            income.title,
            income.amount,
            income.paymentMode,
            income.description,
          ]);
        }
      }

      if (exportExpenses) {
        for (var expense in expenses) {
          rows.add([
            dateFormat.format(expense.date),
            'Expense',
            expense.title,
            expense.amount,
            expense.paymentMode,
            expense.description,
          ]);
        }
      }

      // 3. Convert to CSV
      String csvData = const CsvEncoder().convert(rows);

      await file.writeAsString(csvData);

      return file.path;
    } catch (e) {
      return 'Error exporting CSV: $e';
    }
  }
}
