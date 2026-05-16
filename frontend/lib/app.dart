import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'features/auth/login_page.dart';

class BlindAssistApp extends StatelessWidget {
  const BlindAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blind Assist AI',
      theme: AppTheme.darkAccessibleTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}
