import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/voice_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    required this.apiService,
    required this.voiceService,
    super.key,
  });

  final ApiService apiService;
  final VoiceService voiceService;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      await widget.apiService.register(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      await widget.voiceService.speak('Account created successfully. Please login.');
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      await widget.voiceService.speak('Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(labelText: 'Phone Number (optional)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: Text(_loading ? 'Creating account...' : 'Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
