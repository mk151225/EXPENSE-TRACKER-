// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../models/income.dart';

class AddTransactionScreen extends StatefulWidget {
  final Category category;
  final bool isSecretMode;
  final Expense? expenseToEdit;
  final Income? incomeToEdit;

  const AddTransactionScreen({
    super.key,
    required this.category,
    required this.isSecretMode,
    this.expenseToEdit,
    this.incomeToEdit,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedPaymentMode = 'GPay';

  bool get _isEditing =>
      widget.expenseToEdit != null || widget.incomeToEdit != null;

  @override
  void initState() {
    super.initState();
    // 0 for Expense, 1 for Income
    int initialIndex = widget.incomeToEdit != null ? 1 : 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      setState(() {});
    });

    if (_isEditing) {
      if (widget.expenseToEdit != null) {
        final e = widget.expenseToEdit!;
        _titleController.text = e.title;
        _amountController.text = e.amount.toString();
        _descriptionController.text = e.description;
        _selectedDate = e.date;
        _selectedPaymentMode = e.paymentMode;
      } else if (widget.incomeToEdit != null) {
        final i = widget.incomeToEdit!;
        _titleController.text = i.title;
        _amountController.text = i.amount.toString();
        _descriptionController.text = i.description;
        _selectedDate = i.date;
        _selectedPaymentMode = i.paymentMode;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _saveTransaction() async {
    final title = _titleController.text;
    final amountText = _amountController.text;
    final description = _descriptionController.text;

    if (title.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and amount')),
      );
      return;
    }

    double? amount;
    try {
      // Evaluate math expressions like 100+200
      Parser p = Parser();
      Expression exp = p.parse(
        amountText.replaceAll('x', '*'),
      ); // replace x with * for user convenience
      ContextModel cm = ContextModel();
      amount = exp.evaluate(EvaluationType.REAL, cm);
    } catch (e) {
      amount = double.tryParse(amountText);
    }

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final isExpense = _tabController.index == 0;

    if (_isEditing) {
      final wasExpense = widget.expenseToEdit != null;

      if (isExpense == wasExpense) {
        if (wasExpense) {
          widget.expenseToEdit!.title = title;
          widget.expenseToEdit!.amount = amount;
          widget.expenseToEdit!.date = _selectedDate;
          widget.expenseToEdit!.description = description;
          widget.expenseToEdit!.paymentMode = _selectedPaymentMode;
        } else {
          widget.incomeToEdit!.title = title;
          widget.incomeToEdit!.amount = amount;
          widget.incomeToEdit!.date = _selectedDate;
          widget.incomeToEdit!.description = description;
          widget.incomeToEdit!.paymentMode = _selectedPaymentMode;
        }
      } else {
        if (wasExpense) {
          widget.category.expenses.remove(widget.expenseToEdit);
          final newIncome = Income(
            title: title,
            amount: amount,
            date: _selectedDate,
            description: description,
            paymentMode: _selectedPaymentMode,
          );
          widget.category.incomes.add(newIncome);
        } else {
          widget.category.incomes.remove(widget.incomeToEdit);
          final newExpense = Expense(
            title: title,
            amount: amount,
            date: _selectedDate,
            description: description,
            paymentMode: _selectedPaymentMode,
          );
          widget.category.expenses.add(newExpense);
        }
      }
      await widget.category.save();
    } else {
      if (isExpense) {
        final expense = Expense(
          title: title,
          amount: amount,
          date: _selectedDate,
          description: description,
          paymentMode: _selectedPaymentMode,
        );
        widget.category.expenses.add(expense);
      } else {
        final income = Income(
          title: title,
          amount: amount,
          date: _selectedDate,
          description: description,
          paymentMode: _selectedPaymentMode,
        );
        widget.category.incomes.add(income);
      }
      await widget.category.save(); // Save to Hive
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                ),
              ),
              if (widget.category.enablePaymentModes) ...[
                const SizedBox(height: 16),
                const Text(
                  'Payment Mode',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('GPay'),
                        value: 'GPay',
                        groupValue: _selectedPaymentMode,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMode = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Cash'),
                        value: 'Cash',
                        groupValue: _selectedPaymentMode,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMode = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                    ),
                  ),
                  TextButton(
                    onPressed: _presentDatePicker,
                    child: const Text('Choose Date'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _tabController.index == 0
                      ? Colors.red
                      : Colors.green,
                ),
                child: Text(
                  _isEditing ? 'Save Changes' : 'Save Transaction',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
