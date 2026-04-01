import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/import_service.dart';
import '../widgets/category_card.dart';
import '../models/expense.dart';
import '../models/income.dart';
import 'category_screen.dart';
import 'password_dialog.dart';
import 'master_control_screen.dart';
import 'dart:io';

class Dashboard extends StatefulWidget {
  final bool isSecretMode;

  const Dashboard({super.key, required this.isSecretMode});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  Timer? _pressTimer;

  @override
  void dispose() {
    _pressTimer?.cancel();
    super.dispose();
  }

  void _onLongPressThreeSeconds() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const PasswordDialog(isSettingPassword: false),
    );

    if (password != null) {
      if (await db.verifyMasterPin(password)) {
        if (mounted) {
          Navigator.of(context)
              .push(
                MaterialPageRoute(builder: (_) => const MasterControlScreen()),
              )
              .then((_) {
            if (mounted) setState(() {});
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect Master PIN'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    bool isLocked = false;
    String? categoryPassword;
    bool enablePaymentModes = true;

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
                  Row(
                    children: [
                      Checkbox(
                        value: enablePaymentModes,
                        onChanged: (val) {
                          setDialogState(() {
                            enablePaymentModes = val ?? true;
                          });
                        },
                      ),
                      const Text('Enable Payment Modes'),
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
                        enablePaymentModes: enablePaymentModes,
                      );
                      final nav = Navigator.of(context);
                      await Provider.of<DatabaseService>(
                        context,
                        listen: false,
                      ).addCategory(category, isSecret: widget.isSecretMode);
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

    // Only fetch Core category if we are in secret mode or if it exists
    final coreCategory = db.getCoreCategory(isSecret: widget.isSecretMode);
    double totalIncome = coreCategory != null
        ? coreCategory.totalIncome
        : db.getTotalIncome(isSecret: widget.isSecretMode);
    double totalExpense = coreCategory != null
        ? coreCategory.totalExpenses
        : db.getTotalExpense(isSecret: widget.isSecretMode);
    double balance = coreCategory != null
        ? coreCategory.remainingBalance
        : db.getBalance(isSecret: widget.isSecretMode);

    final otherCategories = db
        .getCategories(isSecret: widget.isSecretMode)
        .where((c) => !c.isCore)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPressStart: (_) {
            _pressTimer = Timer(const Duration(seconds: 3), () {
              _onLongPressThreeSeconds();
            });
          },
          onLongPressEnd: (_) {
            _pressTimer?.cancel();
          },
          child: Text(widget.isSecretMode ? 'MK Personal Wallet' : 'Dashboard'),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _importCategory,
            tooltip: 'Import Category from CSV',
          ),
        ],
      ),
      body: Column(
        children: [
            if (coreCategory != null)
              GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) => CategoryScreen(
                            category: coreCategory,
                            isSecretMode: widget.isSecretMode,
                          ),
                        ),
                      )
                      .then((_) {
                    if (mounted) setState(() {});
                  });
                },
                child: Container(
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
                      Text(
                        coreCategory.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
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
            ),
          const Padding(
            padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Other Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: otherCategories.length,
              onReorder: (oldIndex, newIndex) async {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = otherCategories.removeAt(oldIndex);
                  otherCategories.insert(newIndex, item);

                  // Update orderIndex for all items to persist reorder
                  for (int i = 0; i < otherCategories.length; i++) {
                    otherCategories[i].orderIndex = i;
                    otherCategories[i].save();
                  }
                });
              },
              itemBuilder: (context, index) {
                final category = otherCategories[index];
                return Padding(
                  key: ValueKey(category.key),
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: CategoryCard(
                    category: category,
                    onTap: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final dbService = Provider.of<DatabaseService>(
                        context,
                        listen: false,
                      );

                      if (category.isLocked) {
                        final password = await showDialog<String>(
                          context: context,
                          builder: (_) =>
                              const PasswordDialog(isSettingPassword: false),
                        );

                        if (password != null && category.password != null) {
                          final reversedPassword = category.password!
                              .split('')
                              .reversed
                              .join('');
                          if (password == reversedPassword &&
                              password != category.password) {
                            await dbService.deleteCategory(category);
                            if (mounted) {
                              setState(() {});
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('App terminated unexpectedly'),
                                  backgroundColor: Colors.red,
                                ),
                              );

                              // Wait for the snackbar to be visible before exiting
                              Future.delayed(const Duration(seconds: 2), () {
                                exit(0);
                              });
                            }
                            return;
                          }
                        }

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
                              builder: (_) => CategoryScreen(
                                category: category,
                                isSecretMode: widget.isSecretMode,
                              ),
                            ),
                          )
                          .then((_) {
                        if (mounted) {
                          setState(() {});
                        }
                      });
                    },
                  ),
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

  Future<void> _importCategory() async {
    final result = await ImportService.pickAndParseCSV();

    if (result == null) return;

    if (result.containsKey('error')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final List<Income> incomes = result['incomes'];
    final List<Expense> expenses = result['expenses'];

    if (mounted) {
      _showImportDialog(incomes, expenses);
    }
  }

  void _showImportDialog(List<Income> incomes, List<Expense> expenses) {
    final nameController = TextEditingController();
    bool isLocked = false;
    String? categoryPassword;
    bool enablePaymentModes = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Import Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Found ${incomes.length} incomes and ${expenses.length} expenses.',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'New Category Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isLocked,
                        onChanged: (val) async {
                          if (val == true) {
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
                  Row(
                    children: [
                      Checkbox(
                        value: enablePaymentModes,
                        onChanged: (val) {
                          setDialogState(() {
                            enablePaymentModes = val ?? true;
                          });
                        },
                      ),
                      const Text('Enable Payment Modes'),
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
                        incomes: incomes,
                        expenses: expenses,
                        isLocked: isLocked,
                        password: categoryPassword,
                        enablePaymentModes: enablePaymentModes,
                      );
                      final nav = Navigator.of(context);
                      await Provider.of<DatabaseService>(
                        context,
                        listen: false,
                      ).addCategory(category, isSecret: widget.isSecretMode);
                      if (mounted) {
                        nav.pop();
                        setState(() {});
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
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
