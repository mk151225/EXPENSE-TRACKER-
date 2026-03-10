import 'package:hive/hive.dart';
import 'expense.dart';
import 'income.dart';

part 'category.g.dart';

@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<Income> incomes;

  @HiveField(2)
  List<Expense> expenses;

  @HiveField(3)
  bool isLocked;

  @HiveField(4)
  String? password;

  Category({
    required this.name,
    required this.incomes,
    required this.expenses,
    this.isLocked = false,
    this.password,
  });

  double get totalIncome {
    double total = 0;
    for (var income in incomes) {
      total += income.amount;
    }
    return total;
  }

  double get totalExpenses {
    double total = 0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  double get remainingBalance {
    return totalIncome - totalExpenses;
  }
}
