import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../widgets/expense_tile.dart';
import 'add_expense_screen.dart';

class CategoryScreen extends StatefulWidget {
  final Category category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDeleteCategory(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: theme.primaryColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Income',
                  currencyFormat.format(widget.category.income),
                  Colors.blueAccent,
                ),
                _buildStatColumn(
                  'Expenses',
                  currencyFormat.format(widget.category.totalExpenses),
                  Colors.orangeAccent,
                ),
                _buildStatColumn(
                  'Remaining',
                  currencyFormat.format(widget.category.remainingBalance),
                  widget.category.remainingBalance >= 0
                      ? Colors.greenAccent
                      : Colors.redAccent,
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.category.expenses.isEmpty
                ? const Center(child: Text('No expenses yet. Add one!'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.category.expenses.length,
                    itemBuilder: (context, index) {
                      final expense = widget.category.expenses[index];
                      return ExpenseTile(
                        expense: expense,
                        onDelete: () async {
                          widget.category.expenses.removeAt(index);
                          await widget.category.save();
                          setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(category: widget.category),
            ),
          ).then((_) => setState(() {}));
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
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
              await Provider.of<DatabaseService>(
                context,
                listen: false,
              ).deleteCategory(widget.category);
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
}
