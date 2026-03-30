import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  final Future<bool> Function() onAuthenticate;
  final VoidCallback? onEdit;
  final bool showPaymentMode;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.onDelete,
    required this.onAuthenticate,
    this.onEdit,
    this.showPaymentMode = true,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Dismissible(
      key: Key(expense.key.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await onAuthenticate();
      },
      onDismissed: (direction) {
        onDelete();
      },
      child: ListTile(
        onLongPress: onEdit,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.receipt_long,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(expense.date)),
            if (showPaymentMode)
              Text(
                'Mode: ${expense.paymentMode}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            if (expense.description.isNotEmpty)
              Text(
                expense.description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Text(
          currencyFormat.format(expense.amount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.redAccent,
          ),
        ),
      ),
    );
  }
}
