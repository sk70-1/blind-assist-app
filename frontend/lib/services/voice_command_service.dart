import 'dart:async';
import 'voice_service.dart';

enum VoiceCommandType {
  switchIndoor,
  switchOutdoor,
  navigateTo,
  emergency,
  stop,
  describe,
  whereAmI,
  unknown,
}

class VoiceCommand {
  final VoiceCommandType type;
  final String? destination;
  final String rawText;

  VoiceCommand({required this.type, this.destination, required this.rawText});
}

class VoiceCommandService {
  VoiceCommandService(this._voiceService);

  final VoiceService _voiceService;
  bool _isActive = false;
  Timer? _restartTimer;

  bool get isActive => _isActive;

  /// Start continuous listening loop. Calls [onCommand] for each recognized command.
  void startContinuousListening(void Function(VoiceCommand) onCommand) {
    _isActive = true;
    _beginListening(onCommand);
  }

  void stopContinuousListening() {
    _isActive = false;
    _restartTimer?.cancel();
    _voiceService.stopListening();
  }

  /// Pause listening temporarily (e.g. while TTS is speaking).
  void pauseListening() {
    _restartTimer?.cancel();
    _voiceService.stopListening();
  }

  /// Resume listening after a pause.
  void resumeListening(void Function(VoiceCommand) onCommand) {
    if (_isActive) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_isActive) _beginListening(onCommand);
      });
    }
  }

  void _beginListening(void Function(VoiceCommand) onCommand) {
    if (!_isActive) return;

    _voiceService.listen(
      (String words) {
        if (words.isEmpty) return;
        final command = parseCommand(words);
        onCommand(command);
      },
      onlyFinal: true,
      listenFor: const Duration(seconds: 8),
    );

    // Auto-restart after listen duration expires
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(seconds: 10), () {
      if (_isActive) _beginListening(onCommand);
    });
  }

  VoiceCommand parseCommand(String text) {
    final lower = text.toLowerCase().trim();

    // Emergency (highest priority)
    if (_matchesAny(lower, ['emergency', 'help me', 'sos', 'danger'])) {
      return VoiceCommand(type: VoiceCommandType.emergency, rawText: text);
    }

    // Navigation with destination
    final destMatch = RegExp(
      r'(?:go to|navigate to|take me to|directions to|find)\s+(.+)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (destMatch != null) {
      return VoiceCommand(
        type: VoiceCommandType.navigateTo,
        destination: destMatch.group(1)?.trim(),
        rawText: text,
      );
    }

    // Mode switching
    if (_matchesAny(lower, ['indoor', 'inside', 'detect object', 'detection mode', 'camera mode'])) {
      return VoiceCommand(type: VoiceCommandType.switchIndoor, rawText: text);
    }
    if (_matchesAny(lower, ['outdoor', 'outside', 'map', 'walking mode'])) {
      return VoiceCommand(type: VoiceCommandType.switchOutdoor, rawText: text);
    }

    // Describe surroundings
    if (_matchesAny(lower, ['what do you see', 'describe', 'what is around', 'surroundings'])) {
      return VoiceCommand(type: VoiceCommandType.describe, rawText: text);
    }

    // Location
    if (_matchesAny(lower, ['where am i', 'my location', 'current location'])) {
      return VoiceCommand(type: VoiceCommandType.whereAmI, rawText: text);
    }

    // Stop
    if (_matchesAny(lower, ['stop', 'pause', 'quiet', 'silence'])) {
      return VoiceCommand(type: VoiceCommandType.stop, rawText: text);
    }

    return VoiceCommand(type: VoiceCommandType.unknown, rawText: text);
  }

  bool _matchesAny(String input, List<String> keywords) {
    return keywords.any((kw) => input.contains(kw));
  }
}
