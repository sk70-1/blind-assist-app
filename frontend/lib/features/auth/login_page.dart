import 'package:flutter/material.dart';

import '../navigation/navigation_assistant_page.dart';
import 'register_page.dart';
import '../../services/api_service.dart';
import '../../services/voice_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _voiceService = VoiceService();
  final _apiService = ApiService('http://10.150.65.129:8000');
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    await _voiceService.init();
    await _voiceService.speak('Welcome. Please login with your email and password.');
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await _apiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NavigationAssistantPage(
            apiService: _apiService,
            voiceService: _voiceService,
          ),
        ),
      );
    } catch (_) {
      await _voiceService.speak('Login failed. Please check your credentials.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Blind Assist AI', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: Text(_loading ? 'Logging in...' : 'Login'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterPage(
                        apiService: _apiService,
                        voiceService: _voiceService,
                      ),
                    ),
                  );
                },
                child: const Text('Create a new account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
