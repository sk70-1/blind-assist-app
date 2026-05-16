import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../emergency/emergency_widget.dart';
import '../../services/api_service.dart';
import '../../services/battery_service.dart';
import '../../services/location_service.dart';
import '../../services/object_detection_service.dart';
import '../../services/voice_command_service.dart';
import '../../services/voice_service.dart';
import 'indoor_mode_page.dart';
import 'outdoor_mode_page.dart';

enum AssistantMode { none, indoor, outdoor }

class NavigationAssistantPage extends StatefulWidget {
  const NavigationAssistantPage({
    required this.apiService,
    required this.voiceService,
    super.key,
  });

  final ApiService apiService;
  final VoiceService voiceService;

  @override
  State<NavigationAssistantPage> createState() =>
      _NavigationAssistantPageState();
}

class _NavigationAssistantPageState extends State<NavigationAssistantPage> {
  // Services
  late final ObjectDetectionService _detectionService;
  late final VoiceCommandService _commandService;
  final _locationService = LocationService();
  final _batteryService = BatteryService();

  // State
  AssistantMode _currentMode = AssistantMode.none;
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _voiceListening = false;
  String _statusMessage = 'Welcome';
  String _lastCommand = '';

  // Keys for accessing child state
  final GlobalKey<OutdoorModePageState> _outdoorKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    _detectionService = ObjectDetectionService(widget.apiService);
    _commandService = VoiceCommandService(widget.voiceService);
    _initialize();
  }

  Future<void> _initialize() async {
    await _requestPermissions();
    await _initCamera();

    // Start battery monitoring
    _batteryService.startMonitoring((warning) {
      widget.voiceService.speak(warning);
    });

    // Greet user and start listening
    await widget.voiceService.speak(
      'Welcome to Blind Assist AI. '
      'Say "indoor mode" for object detection, '
      'or "outdoor mode" for map navigation. '
      'You can also say "go to" followed by a destination.',
    );

    // Start continuous voice command listening after greeting
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) _startVoiceListening();
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.locationWhenInUse.request();
    await Permission.microphone.request();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) return;
      
      _detectionService.sensorOrientation = cameras.first.sensorOrientation;
      
      // Stream live frames to the AI detection service
      controller.startImageStream((CameraImage image) {
        _detectionService.latestImage = image;
      });

      setState(() {
        _cameraController = controller;
        _cameraReady = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cameraReady = false);
    }
  }

  void _startVoiceListening() {
    setState(() => _voiceListening = true);
    _commandService.startContinuousListening(_handleVoiceCommand);
  }

  void _handleVoiceCommand(VoiceCommand command) {
    if (!mounted) return;

    setState(() => _lastCommand = command.rawText);

    switch (command.type) {
      case VoiceCommandType.switchIndoor:
        _switchMode(AssistantMode.indoor);

      case VoiceCommandType.switchOutdoor:
        _switchMode(AssistantMode.outdoor);

      case VoiceCommandType.navigateTo:
        _handleNavigateTo(command.destination ?? '');

      case VoiceCommandType.emergency:
        _triggerEmergency();

      case VoiceCommandType.describe:
        _handleDescribe();

      case VoiceCommandType.whereAmI:
        _handleWhereAmI();

      case VoiceCommandType.stop:
        _handleStop();

      case VoiceCommandType.unknown:
        widget.voiceService.speak(
          'I didn\'t understand that. '
          'Say "indoor mode", "outdoor mode", or "go to" a destination.',
        );
    }
  }

  void _switchMode(AssistantMode mode) {
    // Pause voice listening while speaking
    _commandService.pauseListening();

    setState(() {
      _currentMode = mode;
      _statusMessage = mode == AssistantMode.indoor
          ? 'Indoor Mode Active'
          : 'Outdoor Mode Active';
    });

    final modeName =
        mode == AssistantMode.indoor ? 'indoor' : 'outdoor';
    widget.voiceService.speak(
      'Switching to $modeName mode. Detection is active.',
    );

    // Resume listening after speaking
    Future.delayed(const Duration(seconds: 3), () {
      _commandService.resumeListening(_handleVoiceCommand);
    });
  }

  void _handleNavigateTo(String destination) {
    if (destination.isEmpty) {
      widget.voiceService.speak('Where would you like to go?');
      return;
    }

    // Auto-switch to outdoor mode if not already there
    if (_currentMode != AssistantMode.outdoor) {
      setState(() {
        _currentMode = AssistantMode.outdoor;
        _statusMessage = 'Outdoor Mode — Navigating';
      });
    }

    // Pause voice listening during navigation setup
    _commandService.pauseListening();

    // Wait for outdoor page to build, then navigate
    Future.delayed(const Duration(milliseconds: 800), () {
      _outdoorKey.currentState?.navigateToDestination(destination);

      // Resume listening after navigation starts
      Future.delayed(const Duration(seconds: 8), () {
        _commandService.resumeListening(_handleVoiceCommand);
      });
    });
  }

  void _handleDescribe() {
    _commandService.pauseListening();

    if (_currentMode == AssistantMode.none) {
      widget.voiceService.speak(
        'Please select a mode first. Say "indoor mode" or "outdoor mode".',
      );
    } else {
      _outdoorKey.currentState?.describeEnvironment();
    }

    Future.delayed(const Duration(seconds: 4), () {
      _commandService.resumeListening(_handleVoiceCommand);
    });
  }

  void _handleWhereAmI() async {
    _commandService.pauseListening();

    try {
      final pos = await _locationService.getCurrentPosition();
      await widget.voiceService.speak(
        'You are at latitude ${pos.latitude.toStringAsFixed(4)}, '
        'longitude ${pos.longitude.toStringAsFixed(4)}.',
      );
    } catch (_) {
      await widget.voiceService.speak('Unable to determine your location.');
    }

    Future.delayed(const Duration(seconds: 3), () {
      _commandService.resumeListening(_handleVoiceCommand);
    });
  }

  void _handleStop() {
    _commandService.pauseListening();
    widget.voiceService.speak(
      'Paused. Say any command to resume.',
    );
    // Will resume when next voice input is detected
    Future.delayed(const Duration(seconds: 5), () {
      _commandService.resumeListening(_handleVoiceCommand);
    });
  }

  Future<void> _triggerEmergency() async {
    _commandService.pauseListening();
    await widget.voiceService.speak('Sending emergency alert!');

    try {
      final pos = await _locationService.getCurrentPosition();
      await widget.apiService.sendSos(
        latitude: pos.latitude,
        longitude: pos.longitude,
        message: 'User triggered emergency SOS',
      );
      await widget.voiceService.speak('Emergency alert sent to guardians.');
    } catch (_) {
      await widget.voiceService.speak('Unable to send emergency alert.');
    }

    Future.delayed(const Duration(seconds: 3), () {
      _commandService.resumeListening(_handleVoiceCommand);
    });
  }

  @override
  void dispose() {
    _commandService.stopContinuousListening();
    _batteryService.stopMonitoring();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF161B22),
              child: Row(
                children: [
                  // Voice listening indicator
                  Icon(
                    _voiceListening ? Icons.mic : Icons.mic_off,
                    color: _voiceListening
                        ? const Color(0xFF4ADE80)
                        : Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastCommand.isEmpty
                          ? _statusMessage
                          : 'Heard: "$_lastCommand"',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Battery indicator
                  Icon(
                    Icons.battery_std,
                    color: _batteryService.lastLevel > 30
                        ? Colors.green
                        : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_batteryService.lastLevel}%',
                    style: TextStyle(
                      fontSize: 13,
                      color: _batteryService.lastLevel > 30
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            // Main content area
            Expanded(
              child: _buildModeContent(),
            ),

            // Bottom SOS bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF161B22),
              child: EmergencyWidget(onSosPressed: _triggerEmergency),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeContent() {
    switch (_currentMode) {
      case AssistantMode.none:
        return _buildWelcomeScreen();
      case AssistantMode.indoor:
        return IndoorModePage(
          cameraController: _cameraController,
          detectionService: _detectionService,
          voiceService: widget.voiceService,
          isCameraReady: _cameraReady,
        );
      case AssistantMode.outdoor:
        return OutdoorModePage(
          key: _outdoorKey,
          cameraController: _cameraController,
          detectionService: _detectionService,
          voiceService: widget.voiceService,
          apiService: widget.apiService,
          locationService: _locationService,
          isCameraReady: _cameraReady,
        );
    }
  }

  Widget _buildWelcomeScreen() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.accessibility_new,
            size: 80,
            color: Color(0xFF00D1FF),
          ),
          const SizedBox(height: 24),
          const Text(
            'Blind Assist AI',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00D1FF),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your voice-controlled navigation assistant',
            style: TextStyle(fontSize: 18, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Quick action buttons (large, accessible)
          _ModeButton(
            icon: Icons.sensor_door,
            label: 'Indoor Mode',
            subtitle: 'Object detection',
            color: const Color(0xFF4ADE80),
            onTap: () => _switchMode(AssistantMode.indoor),
          ),
          const SizedBox(height: 16),
          _ModeButton(
            icon: Icons.map,
            label: 'Outdoor Mode',
            subtitle: 'Navigation + Detection',
            color: const Color(0xFF60A5FA),
            onTap: () => _switchMode(AssistantMode.outdoor),
          ),
          const SizedBox(height: 24),
          const Text(
            'Or say a command:\n'
            '"Indoor mode" • "Outdoor mode"\n'
            '"Go to [place]" • "Emergency"',
            style: TextStyle(fontSize: 16, color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
