import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import 'password_dialog.dart';

class MasterControlScreen extends StatefulWidget {
  const MasterControlScreen({super.key});

  @override
  State<MasterControlScreen> createState() => _MasterControlScreenState();
}

class _MasterControlScreenState extends State<MasterControlScreen> {
  late DatabaseService _db;

  @override
  void initState() {
    super.initState();
    _db = Provider.of<DatabaseService>(context, listen: false);
  }

  void _showChangeCategoryNameDialog(Category category) {
    final nameController = TextEditingController(text: category.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Category Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'New Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  category.name = nameController.text;
                });
                await _db.updateCategory(category);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangeCategoryPasswordDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => PasswordDialog(
        isSettingPassword: true,
        title: 'Set ${category.name} Password',
        hintText: 'Password',
        onPasswordSet: (newPassword) async {
          setState(() {
            category.password = newPassword;
            category.isLocked = newPassword.isNotEmpty;
          });
          await _db.updateCategory(category);
        },
      ),
    );
  }

  void _showChangeMasterPinDialog() {
    showDialog(
      context: context,
      builder: (context) => PasswordDialog(
        isSettingPassword: true,
        title: 'Change Master PIN',
        hintText: 'New 4-Digit PIN',
        onPasswordSet: (newPin) async {
          if (newPin.length == 4) {
            await _db.saveMasterPin(newPin);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Master PIN updated')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN must be 4 digits')),
              );
            }
          }
        },
      ),
    );
  }

  void _showChangeSecretPinDialog() {
    showDialog(
      context: context,
      builder: (context) => PasswordDialog(
        isSettingPassword: true,
        title: 'Change Secret Vault PIN',
        hintText: 'New 4-Digit PIN',
        onPasswordSet: (newPin) async {
          if (newPin.length == 4) {
            await _db.saveSecretPin(newPin);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Secret PIN updated')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN must be 4 digits')),
              );
            }
          }
        },
      ),
    );
  }

  void _toggleLock(Category category) async {
    if (category.password == null || category.password!.isEmpty) {
      // No password set, must set one to lock
      _showChangeCategoryPasswordDialog(category);
    } else {
      setState(() {
        category.isLocked = !category.isLocked;
      });
      await _db.updateCategory(category);
    }
  }

  void _showDeleteConfirmation(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}" and all its data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _db.deleteCategory(category);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalCategories = _db.getCategories(isSecret: false);
    final secretCategories = _db.getCategories(isSecret: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Master Control')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('Global Settings', theme),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings_suggest, color: Colors.orange),
                    title: const Text('Change Master PIN'),
                    subtitle: const Text('PIN to access this page'),
                    onTap: _showChangeMasterPinDialog,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security, color: Colors.red),
                    title: const Text('Change Secret Vault PIN'),
                    subtitle: const Text('PIN to access Secret Mode'),
                    onTap: _showChangeSecretPinDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Normal Wallet Categories', theme),
            ...normalCategories.map((c) => _buildCategoryTile(c, theme)),
            const SizedBox(height: 24),
            _buildSectionHeader('Secret Wallet Categories', theme),
            ...secretCategories.map((c) => _buildCategoryTile(c, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryTile(Category category, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          category.isLocked ? 'Locked with Password' : 'No Password',
          style: TextStyle(
            color: category.isLocked ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showChangeCategoryNameDialog(category),
              tooltip: 'Rename',
            ),
            IconButton(
              icon: Icon(
                category.isLocked ? Icons.lock : Icons.lock_open,
                size: 20,
                color: category.isLocked ? Colors.red : Colors.green,
              ),
              onPressed: () => _toggleLock(category),
              tooltip: category.isLocked ? 'Unlock' : 'Lock',
            ),
            IconButton(
              icon: const Icon(Icons.password, size: 20, color: Colors.blue),
              onPressed: () => _showChangeCategoryPasswordDialog(category),
              tooltip: 'Change Password',
            ),
            if (!category.isCore)
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.grey),
                onPressed: () => _showDeleteConfirmation(category),
                tooltip: 'Delete',
              ),
          ],
        ),
      ),
    );
  }
}
