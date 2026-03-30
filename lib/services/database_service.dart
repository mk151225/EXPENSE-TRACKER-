import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';

class DatabaseService {
  static const String _categoriesBoxName = 'categoriesBox';
  static const String _secretCategoriesBoxName = 'secretCategoriesBox';
  static const String _pinKey = 'user_pin';
  static const String _masterPinKey = 'master_pin';
  static const String _secretPinKey = 'secret_pin';

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

    // Ensure main 'MK' category exists and is marked as core
    if (!hasCoreCategory(isSecret: false)) {
      await _categoriesBox!.add(
        Category(
          name: 'MK',
          incomes: [],
          expenses: [],
          isLocked: true,
          password: '1416',
          isCore: true,
        ),
      );
    } else {
      // Repair logic: if person has MK but it is not marked core, mark it.
      final mkCat = getCoreCategory(isSecret: false);
      if (mkCat != null && !mkCat.isCore) {
        mkCat.isCore = true;
        if (mkCat.password == null || mkCat.password!.isEmpty) {
          mkCat.password = '1416';
          mkCat.isLocked = true;
        }
        await mkCat.save();
      }
    }

    // Secret Wallet CORE marking
    if (!hasCoreCategory(isSecret: true)) {
      await _secretCategoriesBox!.add(
        Category(
          name: 'MK',
          incomes: [],
          expenses: [],
          isLocked: false,
          isCore: true,
        ),
      );
    } else {
      final secretCat = getCoreCategory(isSecret: true);
      if (secretCat != null && !secretCat.isCore) {
        secretCat.isCore = true;
        await secretCat.save();
      }
    }
  }

  bool hasCoreCategory({required bool isSecret}) {
    final box = isSecret ? _secretCategoriesBox : _categoriesBox;
    return box?.values.any((c) => c.isCore) ?? false;
  }

  @Deprecated('Use hasCoreCategory instead')
  bool hasMKCategory({required bool isSecret}) {
    final box = isSecret ? _secretCategoriesBox : _categoriesBox;
    return box?.values.any((c) => c.name == 'MK' || c.isCore) ?? false;
  }

  Category? getCoreCategory({required bool isSecret}) {
    final box = isSecret ? _secretCategoriesBox : _categoriesBox;
    if (box == null) return null;
    try {
      return box.values.firstWhere((c) => c.isCore);
    } catch (e) {
      try {
        return box.values.firstWhere((c) => c.name == 'MK');
      } catch (e2) {
        return null;
      }
    }
  }

  @Deprecated('Use getCoreCategory instead')
  Category? getMKCategory({required bool isSecret}) =>
      getCoreCategory(isSecret: isSecret);

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

  Future<bool> verifyMasterPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_masterPinKey) ?? '1518';
    return storedPin == enteredPin;
  }

  Future<void> saveMasterPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_masterPinKey, pin);
  }

  Future<bool> verifySecretPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_secretPinKey) ?? '9786';
    return storedPin == enteredPin;
  }

  Future<void> saveSecretPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_secretPinKey, pin);
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
