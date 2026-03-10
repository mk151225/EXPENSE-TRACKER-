import 'package:hive/hive.dart';
import 'expense.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double income;

  @HiveField(2)
  List<Expense> expenses;

  Category({required this.name, required this.income, required this.expenses});

  double get totalExpenses {
    double total = 0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  double get remainingBalance {
    return income - totalExpenses;
  }
}
