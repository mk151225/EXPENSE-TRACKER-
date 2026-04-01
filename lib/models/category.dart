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

  @HiveField(5)
  bool enablePaymentModes;

  @HiveField(6)
  bool isCore;

  @HiveField(7)
  int orderIndex;

  Category({
    required this.name,
    required this.incomes,
    required this.expenses,
    this.isLocked = false,
    this.password,
    this.enablePaymentModes = true,
    this.isCore = false,
    this.orderIndex = 0,
  });

  double get totalIncome {
    return incomes.fold(0, (sum, item) => sum + item.amount);
  }

  double get totalExpenses {
    return expenses.fold(0, (sum, item) => sum + item.amount);
  }

  double get totalWithoutExpense => totalIncome;

  double get remainingBalance => totalIncome - totalExpenses;

  double get cashIncome {
    return incomes
        .where((i) => i.paymentMode == 'Cash')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get gpayIncome {
    return incomes
        .where((i) => i.paymentMode == 'GPay')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get cashExpense {
    return expenses
        .where((e) => e.paymentMode == 'Cash')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get gpayExpense {
    return expenses
        .where((e) => e.paymentMode == 'GPay')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get cashBalance => cashIncome - cashExpense;

  double get gpayBalance => gpayIncome - gpayExpense;
}
