import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';

class IncomeTile extends StatelessWidget {
  final Income income;
  final VoidCallback onDelete;
  final Future<bool> Function() onAuthenticate;
  final VoidCallback? onEdit;

  const IncomeTile({
    super.key,
    required this.income,
    required this.onDelete,
    required this.onAuthenticate,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Dismissible(
      key: Key(income.key.toString()),
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
          backgroundColor: Colors.green.withValues(alpha: 0.2),
          child: const Icon(Icons.account_balance_wallet, color: Colors.green),
        ),
        title: Text(
          income.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(income.date)),
            Text(
              'Mode: ${income.paymentMode}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (income.description.isNotEmpty)
              Text(
                income.description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: Text(
          '+ ${currencyFormat.format(income.amount)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}
