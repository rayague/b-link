import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _isLogin = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _pwCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: () async {
                final email = _emailCtrl.text.trim();
                final pw = _pwCtrl.text;
                if (email.isEmpty || pw.isEmpty) {
                  setState(() => _error = 'Please fill fields');
                  return;
                }
                if (_isLogin) {
                  final ok = await auth.login(email, pw);
                    if (!mounted) return;
                  if (ok) {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                  else setState(() => _error = 'Invalid credentials');
                } else {
                  await auth.register(email, pw);
                  // after local register, navigate to profile registration to collect birth info
                    if (!mounted) return;
                  Navigator.of(context).pushReplacementNamed('/profile-register');
                }
              },
              child: Text(_isLogin ? 'Login' : 'Create account'),
            ),
            TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? 'Create account' : 'Have an account? Login'))
          ],
        ),
      ),
    );
  }
}
