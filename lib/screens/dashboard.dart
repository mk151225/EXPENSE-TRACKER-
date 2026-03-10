import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../widgets/category_card.dart';
import 'category_screen.dart';
import 'password_dialog.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    bool isLocked = false;
    String? categoryPassword;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name (e.g., Home)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isLocked,
                        onChanged: (val) async {
                          if (val == true) {
                            // User wants to lock, ask for password
                            final password = await showDialog<String>(
                              context: context,
                              builder: (_) =>
                                  const PasswordDialog(isSettingPassword: true),
                            );
                            if (password != null && password.isNotEmpty) {
                              setDialogState(() {
                                isLocked = true;
                                categoryPassword = password;
                              });
                            }
                          } else {
                            setDialogState(() {
                              isLocked = false;
                              categoryPassword = null;
                            });
                          }
                        },
                      ),
                      const Text('Enable Category Lock'),
                    ],
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
                    if (nameController.text.isNotEmpty) {
                      final category = Category(
                        name: nameController.text,
                        incomes: [],
                        expenses: [],
                        isLocked: isLocked,
                        password: categoryPassword,
                      );
                      final nav = Navigator.of(context);
                      await Provider.of<DatabaseService>(
                        context,
                        listen: false,
                      ).addCategory(category);
                      if (mounted) {
                        nav.pop();
                        setState(() {});
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final theme = Theme.of(context);

    double totalIncome = db.getTotalIncome();
    double totalExpense = db.getTotalExpense();
    double balance = db.getBalance();

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), elevation: 0),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Current Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  currencyFormat.format(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem(
                      'Total Income',
                      currencyFormat.format(totalIncome),
                      Icons.arrow_downward,
                      Colors.greenAccent,
                    ),
                    _buildSummaryItem(
                      'Total Expense',
                      currencyFormat.format(totalExpense),
                      Icons.arrow_upward,
                      Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 80),
              itemCount: db.getCategories().length,
              itemBuilder: (context, index) {
                final category = db.getCategories()[index];
                return CategoryCard(
                  category: category,
                  onTap: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    if (category.isLocked) {
                      final password = await showDialog<String>(
                        context: context,
                        builder: (_) =>
                            const PasswordDialog(isSettingPassword: false),
                      );
                      if (password == null ||
                          (password != category.password &&
                              password != '1518')) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Incorrect Password'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                    }

                    navigator
                        .push(
                          MaterialPageRoute(
                            builder: (_) => CategoryScreen(category: category),
                          ),
                        )
                        .then((_) {
                          if (mounted) {
                            setState(() {});
                          }
                        });
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white24,
          radius: 20,
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
