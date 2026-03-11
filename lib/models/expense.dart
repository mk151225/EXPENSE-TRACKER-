import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 1)
class Expense extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String description;

  @HiveField(4)
  String paymentMode; // 'Cash' or 'GPay'

  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.description,
    this.paymentMode = 'GPay',
  });
}
