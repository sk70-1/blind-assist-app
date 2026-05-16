import 'dart:async';
import 'package:battery_plus/battery_plus.dart';

class BatteryService {
  final Battery _battery = Battery();
  Timer? _monitorTimer;
  int _lastLevel = 100;
  bool _warned30 = false;
  bool _warned15 = false;

  int get lastLevel => _lastLevel;

  void startMonitoring(void Function(String warning) onWarning) {
    _checkBattery(onWarning);
    _monitorTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _checkBattery(onWarning);
    });
  }

  Future<void> _checkBattery(void Function(String) onWarning) async {
    try {
      _lastLevel = await _battery.batteryLevel;

      if (_lastLevel <= 15 && !_warned15) {
        _warned15 = true;
        onWarning(
          'Battery critically low at $_lastLevel percent. '
          'Please find a safe location to stop and charge your device.',
        );
      } else if (_lastLevel <= 30 && !_warned30) {
        _warned30 = true;
        final estimatedMinutes = (_lastLevel * 2).clamp(0, 120);
        onWarning(
          'Battery at $_lastLevel percent. '
          'Estimated $estimatedMinutes minutes of camera functionality remaining.',
        );
      }

      if (_lastLevel > 35) _warned30 = false;
      if (_lastLevel > 20) _warned15 = false;
    } catch (_) {
      // Battery info unavailable on this device
    }
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
  }
}
