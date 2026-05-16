import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/object_detection_service.dart';
import '../../services/voice_service.dart';

class OutdoorModePage extends StatefulWidget {
  const OutdoorModePage({
    required this.cameraController,
    required this.detectionService,
    required this.voiceService,
    required this.apiService,
    required this.locationService,
    required this.isCameraReady,
    super.key,
  });

  final CameraController? cameraController;
  final ObjectDetectionService detectionService;
  final VoiceService voiceService;
  final ApiService apiService;
  final LocationService locationService;
  final bool isCameraReady;

  @override
  State<OutdoorModePage> createState() => OutdoorModePageState();
}

class OutdoorModePageState extends State<OutdoorModePage> {
  Timer? _detectionTimer;
  Timer? _locationTimer;
  final MapController _mapController = MapController();
  Position? _currentPosition;
  String _lastWarning = 'Scanning surroundings...';
  String _destination = '';
  int _objectCount = 0;
  List<DetectedObject> _lastDetections = [];
  List<LatLng> _routePoints = [];
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
    _startDetection();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await widget.locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() => _currentPosition = pos);
      _mapController.move(
        LatLng(pos.latitude, pos.longitude),
        16,
      );
    } catch (_) {}

    // Update location every 10 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final pos = await widget.locationService.getCurrentPosition();
        if (!mounted) return;
        setState(() => _currentPosition = pos);
      } catch (_) {}
    });
  }

  void _startDetection() {
    _detectionTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      await _runDetectionCycle();
    });
    _runDetectionCycle();
  }

  Future<void> _runDetectionCycle() async {
    try {
      final detections =
          await widget.detectionService.runDetection(isOutdoor: true);
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

      if (urgency != null) {
        await widget.detectionService.triggerHaptic(urgency);
      }

      await widget.voiceService.speak(warning);
    } catch (_) {}
  }

  /// Navigate to a destination by name. Called by the parent hub.
  Future<void> navigateToDestination(String destination) async {
    setState(() => _destination = destination);
    final destLower = destination.toLowerCase();
    final isLocalSearch = destLower.contains('nearest') ||
        destLower.contains('nearby') ||
        destLower.contains('closest');

    if (isLocalSearch) {
      final query = destLower
          .replaceAll('nearest', '')
          .replaceAll('nearby', '')
          .replaceAll('closest', '')
          .replaceAll('take me to', '')
          .replaceAll('find', '')
          .replaceAll('the', '')
          .trim();
      await widget.voiceService.speak(
        'Searching for the nearest $query near your current location. Please wait.',
      );
    } else {
      await widget.voiceService.speak(
        'Searching for $destination. Please wait.',
      );
    }

    // Use free Nominatim geocoding (OpenStreetMap) with location bias
    final coords = await widget.apiService.geocodePlace(
      destination,
      currentLat: _currentPosition?.latitude,
      currentLng: _currentPosition?.longitude,
    );

    if (coords == null) {
      await widget.voiceService.speak(
        'Sorry, I could not find $destination. Please try again.',
      );
      return;
    }

    final destLatLng = LatLng(coords['lat']!, coords['lng']!);

    // Add destination marker
    setState(() {
      _markers = [
        Marker(
          point: destLatLng,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      ];
    });

    // Fetch route using free OSRM
    if (_currentPosition == null) {
      await widget.voiceService.speak(
        'Cannot determine your current location. Please try again.',
      );
      return;
    }

    final route = await widget.apiService.getDirections(
      originLat: _currentPosition!.latitude,
      originLng: _currentPosition!.longitude,
      destLat: coords['lat']!,
      destLng: coords['lng']!,
    );

    if (route == null) {
      await widget.voiceService.speak(
        'Could not find a walking route to $destination.',
      );
      return;
    }

    // Parse OSRM route geometry (GeoJSON coordinates)
    try {
      final routeData = route['routes'] as List;
      if (routeData.isEmpty) {
        await widget.voiceService.speak('No route found to $destination.');
        return;
      }

      final geometry = routeData[0]['geometry'];
      final coordinates = geometry['coordinates'] as List;
      final points = coordinates
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      setState(() {
        _routePoints = points;
      });

      // Fit map to show the route
      if (points.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints([
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          destLatLng,
        ]);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
        );
      }

      // Speak route info
      final durationSec = (routeData[0]['duration'] as num).toDouble();
      final distanceM = (routeData[0]['distance'] as num).toDouble();
      final durationMin = (durationSec / 60).round();
      final distanceDisplay = distanceM > 1000
          ? '${(distanceM / 1000).toStringAsFixed(1)} kilometers'
          : '${distanceM.round()} meters';

      await widget.voiceService.speak(
        'Route found. $distanceDisplay walk, about $durationMin minutes. Starting navigation.',
      );

      // Speak first step instruction
      final legs = routeData[0]['legs'] as List;
      if (legs.isNotEmpty) {
        final steps = legs[0]['steps'] as List;
        if (steps.isNotEmpty) {
          final maneuver = steps[0]['maneuver'];
          final instruction =
              '${maneuver['type']} ${maneuver['modifier'] ?? ''}'.trim();
          await widget.voiceService.speak(instruction);
        }
      }
    } catch (_) {
      await widget.voiceService.speak('Route to $destination is ready.');
    }
  }

  /// Called by parent hub for "describe" command
  void describeEnvironment() {
    final desc = widget.detectionService.describeAll(_lastDetections);
    widget.voiceService.speak(desc);
  }

  /// Called by parent hub for "where am I" command
  void speakLocation() {
    if (_currentPosition == null) {
      widget.voiceService.speak('Unable to determine your location.');
    } else {
      widget.voiceService.speak(
        'You are at latitude ${_currentPosition!.latitude.toStringAsFixed(4)}, '
        'longitude ${_currentPosition!.longitude.toStringAsFixed(4)}.',
      );
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(22.5726, 88.3639);

    return Column(
      children: [
        // Mode indicator
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          color: const Color(0xFF1A2A3A),
          child: Row(
            children: [
              const Icon(Icons.map, color: Color(0xFF60A5FA), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _destination.isEmpty
                      ? 'OUTDOOR MODE — Navigation + Detection'
                      : 'Navigating to: $_destination',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF60A5FA),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF60A5FA).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_objectCount detected',
                  style: const TextStyle(
                      color: Color(0xFF60A5FA), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        // Top half: Camera preview with detection overlay
        Expanded(
          flex: 4,
          child: widget.isCameraReady && widget.cameraController != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(widget.cameraController!),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Text(
                          _lastWarning,
                          style: const TextStyle(
                            fontSize: 18,
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
                  child: const Text(
                    'Camera initializing...',
                    style: TextStyle(fontSize: 18, color: Colors.white54),
                  ),
                ),
        ),

        // Divider
        Container(height: 2, color: const Color(0xFF00D1FF).withOpacity(0.4)),

        // Bottom half: OpenStreetMap (FREE!)
        Expanded(
          flex: 5,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: 16,
            ),
            children: [
              // OpenStreetMap tile layer (completely free)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.blind_assist_ai',
              ),

              // Route polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: const Color(0xFF00D1FF),
                      strokeWidth: 5,
                    ),
                  ],
                ),

              // Current location marker
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),

              // Destination markers
              if (_markers.isNotEmpty) MarkerLayer(markers: _markers),
            ],
          ),
        ),
      ],
    );
  }
}
