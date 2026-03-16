import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/data_export_service.dart';
import '../widgets/expense_tile.dart';
import '../widgets/income_tile.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';
import 'password_dialog.dart';

class CategoryScreen extends StatefulWidget {
  final Category category;
  final bool isSecretMode;

  const CategoryScreen({
    super.key,
    required this.category,
    required this.isSecretMode,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: widget.category.name == 'MK'
            ? [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _showDownloadOptions(context),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _showDownloadOptions(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _handleDeleteCategory(context),
                ),
              ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.primaryColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      'Total w/o Expense',
                      currencyFormat.format(widget.category.totalWithoutExpense),
                      Colors.blueAccent,
                    ),
                    _buildStatColumn(
                      'Total Balance',
                      currencyFormat.format(widget.category.remainingBalance),
                      widget.category.remainingBalance >= 0
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                    _buildStatColumn(
                      'Total Expense',
                      currencyFormat.format(widget.category.totalExpenses),
                      Colors.orangeAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      'GPay Balance',
                      currencyFormat.format(widget.category.gpayBalance),
                      widget.category.gpayBalance >= 0
                          ? Colors.cyanAccent
                          : Colors.redAccent,
                    ),
                    _buildStatColumn(
                      'Cash Balance',
                      currencyFormat.format(widget.category.cashBalance),
                      widget.category.cashBalance >= 0
                          ? Colors.amberAccent
                          : Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.blueAccent,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Expenses'),
                      Tab(text: 'Incomes'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Expenses Tab
                        widget.category.expenses.isEmpty
                            ? const Center(
                                child: Text('No expenses yet. Add one!'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: widget.category.expenses.length,
                                itemBuilder: (context, index) {
                                  final expense =
                                      widget.category.expenses[index];
                                  return ExpenseTile(
                                    expense: expense,
                                    onAuthenticate: _authenticateForDelete,
                                    onDelete: () => _deleteExpense(index),
                                  );
                                },
                              ),
                        // Incomes Tab
                        widget.category.incomes.isEmpty
                            ? const Center(
                                child: Text('No incomes yet. Add one!'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: widget.category.incomes.length,
                                itemBuilder: (context, index) {
                                  final income = widget.category.incomes[index];
                                  return IncomeTile(
                                    income: income,
                                    onAuthenticate: _authenticateForDelete,
                                    onDelete: () => _deleteIncome(index),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "addIncome",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddIncomeScreen(
                    category: widget.category,
                    isSecretMode: widget.isSecretMode,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: "addExpense",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(
                    category: widget.category,
                    isSecretMode: widget.isSecretMode,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
            backgroundColor: theme.colorScheme.primary,
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showDownloadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('Download as CSV'),
            onTap: () async {
              Navigator.pop(context);
              await DataExportService.exportCategoryToCsv(widget.category);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exported to Downloads folder')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.grid_on),
            title: const Text('Download as Excel'),
            onTap: () async {
              Navigator.pop(context);
              await DataExportService.exportCategoryToExcel(widget.category);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exported to Downloads folder')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _handleDeleteCategory(BuildContext context) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const PasswordDialog(isSettingPassword: false),
    );

    if (password == null) return;

    final normalMaster = '1518';
    final reverseMaster = '8151';
    final normalCat = widget.category.password ?? '';
    final reverseCat = normalCat.isNotEmpty ? normalCat.split('').reversed.join('') : null;

    final isReverse = password == reverseMaster || (reverseCat != null && password == reverseCat);
    final isNormal = password == normalMaster || (normalCat.isNotEmpty && password == normalCat);

    if (isReverse) {
      await DataExportService.exportCategoryToCsv(widget.category);
      if (mounted) {
        final dbService = Provider.of<DatabaseService>(context, listen: false);
        await dbService.deleteCategory(widget.category);
        Navigator.pop(context); // Go back to dashboard silently
      }
      return;
    }

    if (widget.category.isLocked) {
      if (!isNormal) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect Password'), backgroundColor: Colors.red),
          );
        }
        return;
      }
    } else {
      if (password.isNotEmpty && password != normalMaster) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect Password'), backgroundColor: Colors.red),
          );
        }
        return;
      }
    }

    if (mounted) {
      _showConfirmationDialog(context);
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category?'),
        content: const Text(
          'This will delete the category and all its expenses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final nav = Navigator.of(context);
              final dbService = Provider.of<DatabaseService>(
                context,
                listen: false,
              );
              await dbService.deleteCategory(widget.category);
              if (mounted) {
                nav.pop(); // close dialog
                nav.pop(); // go back to dashboard
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<bool> _authenticateForDelete() async {
    final messenger = ScaffoldMessenger.of(context);
    if (!widget.category.isLocked) return true;

    final password = await showDialog<String>(
      context: context,
      builder: (_) => const PasswordDialog(isSettingPassword: false),
    );
    if (password == null ||
        (password != widget.category.password && password != '1518')) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Incorrect Password'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _deleteExpense(int index) async {
    widget.category.expenses.removeAt(index);
    await widget.category.save();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteIncome(int index) async {
    widget.category.incomes.removeAt(index);
    await widget.category.save();
    if (mounted) {
      setState(() {});
    }
  }
}
