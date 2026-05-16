import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../services/object_detection_service.dart';
import '../../services/voice_service.dart';

class IndoorModePage extends StatefulWidget {
  const IndoorModePage({
    required this.cameraController,
    required this.detectionService,
    required this.voiceService,
    required this.isCameraReady,
    super.key,
  });

  final CameraController? cameraController;
  final ObjectDetectionService detectionService;
  final VoiceService voiceService;
  final bool isCameraReady;

  @override
  State<IndoorModePage> createState() => _IndoorModePageState();
}

class _IndoorModePageState extends State<IndoorModePage> {
  Timer? _detectionTimer;
  String _lastWarning = 'Scanning environment...';
  int _objectCount = 0;
  List<DetectedObject> _lastDetections = [];
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startDetection();
  }

  void _startDetection() {
    _detectionTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_isPaused) return;
      await _runDetectionCycle();
    });
    // Run once immediately
    _runDetectionCycle();
  }

  Future<void> _runDetectionCycle() async {
    try {
      final detections =
          await widget.detectionService.runDetection(isOutdoor: false);
      if (!mounted) return;

      final warning =
          widget.detectionService.getMostUrgentWarning(detections);
      final urgency =
          widget.detectionService.getHighestUrgency(detections);

      setState(() {
        _lastWarning = warning;
        _objectCount = detections.length;
        _lastDetections = detections;
      });

      // Haptic feedback
      if (urgency != null) {
        await widget.detectionService.triggerHaptic(urgency);
      }

      // Speak the warning
      await widget.voiceService.speak(warning);
    } catch (_) {
      // Detection cycle failed; will retry on next tick
    }
  }

  /// Called by parent hub when user says "describe"
  void describeEnvironment() {
    final desc = widget.detectionService.describeAll(_lastDetections);
    widget.voiceService.speak(desc);
  }

  void togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      widget.voiceService.speak('Detection paused.');
    } else {
      widget.voiceService.speak('Detection resumed.');
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mode indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          color: const Color(0xFF1A3A2A),
          child: Row(
            children: [
              const Icon(Icons.sensor_door, color: Color(0xFF4ADE80), size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'INDOOR MODE — Object Detection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4ADE80),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_objectCount detected',
                  style: const TextStyle(
                      color: Color(0xFF4ADE80), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        // Full-screen camera preview
        Expanded(
          child: widget.isCameraReady && widget.cameraController != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(widget.cameraController!),

                    // Warning overlay at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.85),
                            ],
                          ),
                        ),
                        child: Text(
                          _lastWarning,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                )
              : Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.white54),
                      SizedBox(height: 12),
                      Text(
                        'Camera initializing...',
                        style: TextStyle(fontSize: 20, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
