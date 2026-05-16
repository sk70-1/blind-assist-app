import 'package:flutter/material.dart';

class EmergencyWidget extends StatelessWidget {
  const EmergencyWidget({
    required this.onSosPressed,
    super.key,
  });

  final VoidCallback onSosPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onSosPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
      ),
      icon: const Icon(Icons.sos),
      label: const Text('Emergency SOS'),
    );
  }
}
