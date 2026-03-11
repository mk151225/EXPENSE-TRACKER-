import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';

class DatabaseService {
  static const String _categoriesBoxName = 'categoriesBox';
  static const String _secretCategoriesBoxName = 'secretCategoriesBox';
  static const String _pinKey = 'user_pin';

  Box<Category>? _categoriesBox;
  Box<Category>? _secretCategoriesBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(IncomeAdapter());
    _categoriesBox = await Hive.openBox<Category>(_categoriesBoxName);
    _secretCategoriesBox = await Hive.openBox<Category>(
      _secretCategoriesBoxName,
    );

    // Ensure main 'MK' category exists in Normal Wallet
    if (!hasMKCategory(isSecret: false)) {
      await _categoriesBox!.add(
        Category(name: 'MK', incomes: [], expenses: [], isLocked: false),
      );
    }

    // Ensure main 'MK' category exists in Secret Wallet
    if (!hasMKCategory(isSecret: true)) {
      await _secretCategoriesBox!.add(
        Category(name: 'MK', incomes: [], expenses: [], isLocked: false),
      );
    }
  }

  bool hasMKCategory({required bool isSecret}) {
    final box = isSecret ? _secretCategoriesBox : _categoriesBox;
    return box?.values.any((c) => c.name == 'MK') ?? false;
  }

  Category? getMKCategory({required bool isSecret}) {
    final box = isSecret ? _secretCategoriesBox : _categoriesBox;
    if (box == null) return null;
    try {
      return box.values.firstWhere((c) => c.name == 'MK');
    } catch (e) {
      return null;
    }
  }

  // --- PIN Methods ---

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) != null;
  }

  Future<bool> verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_pinKey);
    return storedPin == enteredPin;
  }

  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  // --- Category Methods ---

  List<Category> getCategories({required bool isSecret}) {
    final box = isSecret ? _secretCategoriesBox : _categoriesBox;
    if (box == null) return [];
    return box.values.toList();
  }

  Future<void> addCategory(Category category, {required bool isSecret}) async {
    final box = isSecret ? _secretCategoriesBox : _categoriesBox;
    await box?.add(category);
  }

  Future<void> updateCategory(Category category) async {
    await category.save();
  }

  Future<void> deleteCategory(Category category) async {
    await category.delete();
  }

  double getTotalIncome({required bool isSecret}) {
    double total = 0;
    for (var cat in getCategories(isSecret: isSecret)) {
      total += cat.totalIncome;
    }
    return total;
  }

  double getTotalExpense({required bool isSecret}) {
    double total = 0;
    for (var cat in getCategories(isSecret: isSecret)) {
      total += cat.totalExpenses;
    }
    return total;
  }

  double getBalance({required bool isSecret}) {
    return getTotalIncome(isSecret: isSecret) -
        getTotalExpense(isSecret: isSecret);
  }
}
