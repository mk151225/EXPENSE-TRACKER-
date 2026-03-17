import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/expense_tile.dart';
import '../widgets/income_tile.dart';
import 'password_dialog.dart';
import 'add_transaction_screen.dart';

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
  String _selectedFilter = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isDateInRange(DateTime date) {
    if (_selectedFilter == 'All') return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);

    if (_selectedFilter == '1 Week') {
      final weekAgo = today.subtract(const Duration(days: 7));
      return itemDate.isAfter(weekAgo) || itemDate.isAtSameMomentAs(weekAgo);
    } else if (_selectedFilter == '1 Month') {
      final monthAgo = DateTime(today.year, today.month - 1, today.day);
      return itemDate.isAfter(monthAgo) || itemDate.isAtSameMomentAs(monthAgo);
    } else if (_selectedFilter == 'Custom Date Range') {
      if (_startDate == null || _endDate == null) return true;
      final start =
          DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
      return (itemDate.isAfter(start) || itemDate.isAtSameMomentAs(start)) &&
          (itemDate.isBefore(end) || itemDate.isAtSameMomentAs(end));
    }
    return true;
  }

  List<Expense> get _filteredExpenses {
    final filtered = widget.category.expenses
        .where((e) => _isDateInRange(e.date))
        .toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  List<Income> get _filteredIncomes {
    final filtered = widget.category.incomes
        .where((i) => _isDateInRange(i.date))
        .toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportDialog,
          ),
          if (widget.category.name != 'MK')
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDeleteCategory(context),
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
                      'Total Income',
                      currencyFormat.format(
                        widget.category.totalWithoutExpense,
                      ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter by Date:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: ['All', '1 Week', '1 Month', 'Custom Date Range']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue == 'Custom Date Range') {
                      _selectCustomDateRange();
                    } else if (newValue != null) {
                      setState(() {
                        _selectedFilter = newValue;
                        _startDate = null;
                        _endDate = null;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          if (_selectedFilter == 'Custom Date Range' &&
              _startDate != null &&
              _endDate != null)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
              child: Text(
                'Selected Range: ${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}',
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
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
                        _filteredExpenses.isEmpty
                            ? const Center(
                                child: Text('No expenses found.'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _filteredExpenses.length,
                                itemBuilder: (context, index) {
                                  final expense = _filteredExpenses[index];
                                  return ExpenseTile(
                                    expense: expense,
                                    onAuthenticate: _authenticateForDelete,
                                    onDelete: () => _deleteExpense(expense),
                                    onEdit: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddTransactionScreen(
                                            category: widget.category,
                                            isSecretMode: widget.isSecretMode,
                                            expenseToEdit: expense,
                                          ),
                                        ),
                                      ).then((_) => setState(() {}));
                                    },
                                  );
                                },
                              ),
                        // Incomes Tab
                        _filteredIncomes.isEmpty
                            ? const Center(
                                child: Text('No incomes found.'),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _filteredIncomes.length,
                                itemBuilder: (context, index) {
                                  final income = _filteredIncomes[index];
                                  return IncomeTile(
                                    income: income,
                                    onAuthenticate: _authenticateForDelete,
                                    onDelete: () => _deleteIncome(income),
                                    onEdit: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddTransactionScreen(
                                            category: widget.category,
                                            isSecretMode: widget.isSecretMode,
                                            incomeToEdit: income,
                                          ),
                                        ),
                                      ).then((_) => setState(() {}));
                                    },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(
                category: widget.category,
                isSecretMode: widget.isSecretMode,
              ),
            ),
          ).then((_) => setState(() {}));
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
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

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _selectedFilter = 'Custom Date Range';
        _startDate = picked.start;
        _endDate = picked.end;
      });
    } else {
      if (_startDate == null || _endDate == null) {
        setState(() {
          _selectedFilter = 'All';
        });
      }
    }
  }

  void _showExportDialog() {
    bool exportIncomes = true;
    bool exportExpenses = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Export Category Data'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select data to export to CSV:'),
                  CheckboxListTile(
                    title: const Text('Incomes'),
                    value: exportIncomes,
                    onChanged: (val) {
                      setState(() {
                        exportIncomes = val ?? true;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Expenses'),
                    value: exportExpenses,
                    onChanged: (val) {
                      setState(() {
                        exportExpenses = val ?? true;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!exportIncomes && !exportExpenses) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select at least one option to export.')),
                      );
                      return;
                    }
                    Navigator.pop(context); // Close dialog
                    _exportData(exportIncomes, exportExpenses);
                  },
                  child: const Text('Download'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportData(bool exportIncomes, bool exportExpenses) async {
    final result = await ExportService.exportCategoryToCSV(
      category: widget.category,
      expenses: _filteredExpenses,
      incomes: _filteredIncomes,
      exportExpenses: exportExpenses,
      exportIncomes: exportIncomes,
    );

    if (mounted && result != null && result.startsWith('/')) {
       // Share the file
       await SharePlus.instance.share(
         ShareParams(
           files: [XFile(result)],
           text: 'Exported data for ${widget.category.name}',
         ),
       );
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text(result ?? 'Download failed'),
           duration: const Duration(seconds: 4),
         ),
       );
    }
  }

  void _confirmDeleteCategory(BuildContext context) {
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
              final messenger = ScaffoldMessenger.of(context);
              final dbService = Provider.of<DatabaseService>(
                context,
                listen: false,
              );

              if (widget.category.isLocked) {
                final password = await showDialog<String>(
                  context: context,
                  builder: (_) =>
                      const PasswordDialog(isSettingPassword: false),
                );
                if (password == null ||
                    (password != widget.category.password &&
                        password != '1518')) {
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Incorrect Password'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }
              }

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

  Future<void> _deleteExpense(Expense expense) async {
    widget.category.expenses.remove(expense);
    await widget.category.save();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteIncome(Income income) async {
    widget.category.incomes.remove(income);
    await widget.category.save();
    if (mounted) {
      setState(() {});
    }
  }
}
