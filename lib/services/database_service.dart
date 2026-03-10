import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/expense.dart';

class DatabaseService {
  static const String _categoriesBoxName = 'categoriesBox';
  static const String _pinKey = 'user_pin';

  Box<Category>? _categoriesBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    _categoriesBox = await Hive.openBox<Category>(_categoriesBoxName);
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

  List<Category> getCategories() {
    if (_categoriesBox == null) return [];
    return _categoriesBox!.values.toList();
  }

  Future<void> addCategory(Category category) async {
    await _categoriesBox?.add(category);
  }

  Future<void> updateCategory(Category category) async {
    await category.save();
  }

  Future<void> deleteCategory(Category category) async {
    await category.delete();
  }

  double getTotalIncome() {
    double total = 0;
    for (var cat in getCategories()) {
      total += cat.income;
    }
    return total;
  }

  double getTotalExpense() {
    double total = 0;
    for (var cat in getCategories()) {
      total += cat.totalExpenses;
    }
    return total;
  }

  double getBalance() {
    return getTotalIncome() - getTotalExpense();
  }
}
