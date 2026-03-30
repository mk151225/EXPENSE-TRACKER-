import 'package:flutter/material.dart';

class PasswordDialog extends StatefulWidget {
  final bool isSettingPassword;
  final String? title;
  final String? hintText;
  final void Function(String)? onPasswordSet;

  const PasswordDialog({
    super.key,
    required this.isSettingPassword,
    this.title,
    this.hintText,
    this.onPasswordSet,
  });

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
        widget.title ??
            (widget.isSettingPassword
                ? 'Set Category Password'
                : 'Enter Password to Unlock Category'),
      ),
      content: TextField(
        controller: _passwordController,
        obscureText: _obscureText,
        decoration: InputDecoration(
          labelText: widget.hintText ?? 'Password',
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
            final pass = _passwordController.text;
            if (pass.isNotEmpty) {
              if (widget.onPasswordSet != null) {
                widget.onPasswordSet!(pass);
              }
              Navigator.pop(context, pass);
            }
          },
          child: Text(widget.isSettingPassword ? 'Set' : 'Unlock'),
        ),
      ],
    );
  }
}

