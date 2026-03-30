import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/session_manager.dart';
import 'dashboard.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String _errorText = '';
  bool _isSettingPin = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    bool hasPin = await db.hasPin();
    setState(() {
      _isSettingPin = !hasPin;
    });
  }

  void _onKeyPress(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _errorText = '';
      });
      if (_pin.length == 4) {
        _verifyOrSetPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorText = '';
      });
    }
  }

  Future<void> _verifyOrSetPin() async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    if (_isSettingPin) {
      await db.savePin(_pin);
      if (mounted) {
        SessionManager.instance.startSession();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const Dashboard(isSecretMode: false),
          ),
        );
      }
    } else {
      if (await db.verifySecretPin(_pin)) {
        if (mounted) {
          SessionManager.instance.startSession();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const Dashboard(isSecretMode: true),
            ),
          );
        }
        return;
      }

      bool isCorrect = await db.verifyPin(_pin);
      if (isCorrect) {
        if (mounted) {
          SessionManager.instance.startSession();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const Dashboard(isSecretMode: false),
            ),
          );
        }
      } else {
        setState(() {
          _errorText = 'Incorrect PIN';
          _pin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            Text(
              _isSettingPin ? 'Set Your PIN' : 'Enter PIN',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length
                        ? Colors.blueAccent
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _errorText,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 40),
            _buildNumpad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        for (int i = 0; i < 3; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (j) => _buildNumpadButton((i * 3 + j + 1).toString()),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 80, height: 80),
            _buildNumpadButton('0'),
            _buildNumpadIconButton(Icons.backspace_outlined, _onBackspace),
          ],
        ),
      ],
    );
  }

  Widget _buildNumpadButton(String digit) {
    return Container(
      margin: const EdgeInsets.all(10),
      width: 80,
      height: 80,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () => _onKeyPress(digit),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadIconButton(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.all(10),
      width: 80,
      height: 80,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: Center(child: Icon(icon, size: 28)),
        ),
      ),
    );
  }
}
