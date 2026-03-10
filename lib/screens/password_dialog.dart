import 'package:flutter/material.dart';

class PasswordDialog extends StatefulWidget {
  final bool isSettingPassword;

  const PasswordDialog({super.key, required this.isSettingPassword});

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isSettingPassword
            ? 'Set Category Password'
            : 'Enter Password to Unlock Category',
      ),
      content: TextField(
        controller: _passwordController,
        obscureText: _obscureText,
        decoration: InputDecoration(
          labelText: 'Password',
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_passwordController.text.isNotEmpty) {
              Navigator.pop(context, _passwordController.text);
            }
          },
          child: Text(widget.isSettingPassword ? 'Set Password' : 'Unlock'),
        ),
      ],
    );
  }
}
