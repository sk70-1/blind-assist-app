import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  VoiceService()
      : _tts = FlutterTts(),
        _speech = SpeechToText();

  final FlutterTts _tts;
  final SpeechToText _speech;
  bool _isListening = false;

  bool get isListening => _isListening;

  Future<void> init() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _speech.initialize();
  }

  Future<void> speak(String message) async {
    await _tts.stop();
    await _tts.speak(message);
  }

  Future<void> listen(
    void Function(String words) onResult, {
    bool onlyFinal = false,
    Duration listenFor = const Duration(seconds: 8),
  }) async {
    _isListening = true;
    await _speech.listen(
      onResult: (result) {
        if (onlyFinal && !result.finalResult) return;
        if (result.finalResult) _isListening = false;
        onResult(result.recognizedWords);
      },
      listenFor: listenFor,
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}
