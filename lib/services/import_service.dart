import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/income.dart';

class ImportService {
  static Future<Map<String, dynamic>?> pickAndParseCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (result == null || result.files.single.path == null) {
        return null;
      }

      final file = File(result.files.single.path!);
      final extension = result.files.single.extension?.toLowerCase();
      
      List<List<dynamic>> fields;
      if (extension == 'xlsx') {
        final bytes = file.readAsBytesSync();
        fields = _parseXLSX(bytes);
      } else {
        final csvData = await file.readAsString(encoding: utf8);
        fields = _parseCSV(csvData);
      }

      if (fields.isEmpty) {
        return {'error': 'The file is empty.'};
      }

      // Analyze Header to determine column mapping
      final header = fields[0].map((e) => e.toString().trim().toLowerCase()).toList();
      
      int dateIdx = -1;
      int typeIdx = -1;
      int titleIdx = -1;
      int amountIdx = -1;
      int modeIdx = -1;
      int descIdx = -1;

      for (int i = 0; i < header.length; i++) {
        final col = header[i];
        if (col.contains('date')) dateIdx = i;
        else if (col == 'type') typeIdx = i;
        else if (col == 'title') titleIdx = i;
        else if (col == 'amount') amountIdx = i;
        else if (col.contains('mode')) modeIdx = i;
        else if (col.contains('description') || col == 'desc') descIdx = i;
      }

      if (dateIdx == -1 || typeIdx == -1 || titleIdx == -1 || amountIdx == -1) {
        return {'error': 'Could not identify required columns (Date, Type, Title, Amount).'};
      }

      List<Income> incomes = [];
      List<Expense> expenses = [];

      for (int i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length <= dateIdx || row.length <= typeIdx || row.length <= titleIdx || row.length <= amountIdx) continue;

        try {
          final dateStr = row[dateIdx].toString().trim();
          final typeStr = row[typeIdx].toString().trim().toLowerCase();
          final titleStr = row[titleIdx].toString().trim();
          final amount = double.tryParse(row[amountIdx].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
          final modeStr = modeIdx != -1 && row.length > modeIdx ? row[modeIdx].toString().trim() : 'GPay';
          final descStr = descIdx != -1 && row.length > descIdx ? row[descIdx].toString().trim() : '';

          final date = _parseDate(dateStr);
          if (date == null) continue;

          if (typeStr.contains('income')) {
            incomes.add(Income(
              title: titleStr,
              amount: amount,
              date: date,
              paymentMode: modeStr,
              description: descStr,
            ));
          } else if (typeStr.contains('expense')) {
            expenses.add(Expense(
              title: titleStr,
              amount: amount,
              date: date,
              paymentMode: modeStr,
              description: descStr,
            ));
          }
        } catch (e) {
          continue;
        }
      }

      return {
        'incomes': incomes,
        'expenses': expenses,
      };
    } catch (e) {
      return {'error': 'Error picking or parsing file: $e'};
    }
  }

  static DateTime? _parseDate(String dateStr) {
    final formats = [
      DateFormat('yyyy-MM-dd HH:mm:ss'),
      DateFormat('yyyy-MM-dd'),
      DateFormat('dd-MM-yyyy'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('MM/dd/yyyy'),
    ];

    for (var format in formats) {
      try {
        return format.parse(dateStr);
      } catch (_) {}
    }
    return null;
  }

  static List<List<dynamic>> _parseXLSX(List<int> bytes) {
    var excel = Excel.decodeBytes(bytes);
    List<List<dynamic>> rows = [];
    for (var table in excel.tables.keys) {
      for (var row in excel.tables[table]!.rows) {
        rows.add(row.map((cell) => cell?.value).toList());
      }
      break; // Only parse the first sheet
    }
    return rows;
  }

  static List<List<dynamic>> _parseCSV(String data) {
    List<List<dynamic>> rows = [];
    final lines = data.split(RegExp(r'\r?\n'));
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      
      // Better CSV splitting that handles some quoting
      List<String> parts = [];
      bool inQuotes = false;
      StringBuffer currentPart = StringBuffer();
      
      for (int i = 0; i < line.length; i++) {
        String char = line[i];
        if (char == '"') {
          inQuotes = !inQuotes;
        } else if (char == ',' && !inQuotes) {
          parts.add(currentPart.toString().trim());
          currentPart.clear();
        } else {
          currentPart.write(char);
        }
      }
      parts.add(currentPart.toString().trim());
      
      // Clean quotes from parts
      rows.add(parts.map((p) {
        if (p.startsWith('"') && p.endsWith('"')) {
          return p.substring(1, p.length - 1);
        }
        return p;
      }).toList());
    }
    return rows;
  }
}
