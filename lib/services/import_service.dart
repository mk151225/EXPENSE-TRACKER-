import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/income.dart';

class ImportService {
  static Future<Map<String, dynamic>?> pickAndParseCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        return null;
      }

      final file = File(result.files.single.path!);
      final input = file.openRead();
      final csvData = await input.transform(utf8.decoder).join();
      final fields = _parseCSV(csvData);

      if (fields.isEmpty) {
        return {'error': 'The CSV file is empty.'};
      }

      // Validate header
      final header = fields[0];
      if (header.length < 6 ||
          header[0] != 'Date' ||
          header[1] != 'Type' ||
          header[2] != 'Title' ||
          header[3] != 'Amount' ||
          header[4] != 'Payment Mode' ||
          header[5] != 'Description') {
        return {'error': 'Invalid CSV format. Please use a file exported from this app.'};
      }

      List<Income> incomes = [];
      List<Expense> expenses = [];
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

      for (int i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length < 6) continue;

        try {
          final date = dateFormat.parse(row[0].toString());
          final type = row[1].toString();
          final title = row[2].toString();
          final amount = double.tryParse(row[3].toString()) ?? 0.0;
          final paymentMode = row[4].toString();
          final description = row[5].toString();

          if (type == 'Income') {
            incomes.add(Income(
              title: title,
              amount: amount,
              date: date,
              paymentMode: paymentMode,
              description: description,
            ));
          } else if (type == 'Expense') {
            expenses.add(Expense(
              title: title,
              amount: amount,
              date: date,
              paymentMode: paymentMode,
              description: description,
            ));
          }
        } catch (e) {
          // Skip invalid rows
          continue;
        }
      }

      return {
        'incomes': incomes,
        'expenses': expenses,
      };
    } catch (e) {
      return {'error': 'Error picking or parsing CSV: $e'};
    }
  }

  static List<List<dynamic>> _parseCSV(String data) {
    List<List<dynamic>> rows = [];
    final lines = data.split('\n');
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      
      // Basic CSV splitting (doesn't handle commas inside quotes, 
      // but the app's export doesn't seem to produce them for this data)
      final parts = line.split(',').map((part) {
        String p = part.trim();
        if (p.startsWith('"') && p.endsWith('"')) {
          p = p.substring(1, p.length - 1);
        }
        return p;
      }).toList();
      
      rows.add(parts);
    }
    return rows;
  }
}
