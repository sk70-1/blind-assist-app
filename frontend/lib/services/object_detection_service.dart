import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import 'api_service.dart';

enum DetectionUrgency { critical, caution, info }

class DetectedObject {
  final String label;
  final double distanceM;
  final String direction;
  final DetectionUrgency urgency;

  DetectedObject({
    required this.label,
    required this.distanceM,
    required this.direction,
    required this.urgency,
  });

  String toWarning() {
    final dist = distanceM.toStringAsFixed(1);
    switch (urgency) {
      case DetectionUrgency.critical:
        return 'STOP! ${_cap(label)} directly $direction at $dist meters!';
      case DetectionUrgency.caution:
        return '${_cap(label)} $direction at $dist meters.';
      case DetectionUrgency.info:
        return '${_cap(label)} detected ${distanceM.toStringAsFixed(0)} meters $direction.';
    }
  }

  String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class ObjectDetectionService {
  ObjectDetectionService(this._apiService) {
    _objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
  }

  final ApiService _apiService;
  late final ObjectDetector _objectDetector;
  
  CameraImage? latestImage;
  int sensorOrientation = 0;
  bool _isProcessing = false;

  /// Run detection using Google ML Kit on the latest camera frame.
  Future<List<DetectedObject>> runDetection({bool isOutdoor = false}) async {
    if (latestImage == null || _isProcessing) return [];
    
    _isProcessing = true;
    try {
      final inputImage = _inputImageFromCameraImage(latestImage!, sensorOrientation);
      if (inputImage == null) return [];

      final objects = await _objectDetector.processImage(inputImage);
      
      final detectedObjects = <DetectedObject>[];
      final imageWidth = latestImage!.width.toDouble();
      final imageHeight = latestImage!.height.toDouble();

      for (final obj in objects) {
        if (obj.labels.isEmpty) continue;
        
        final label = obj.labels.first.text.toLowerCase();
        // Ignore generic labels if we want to be more specific, 
        // but default ML Kit gives: 'Food', 'Vehicle', 'Fashion good', 'Home good', 'Place'
        // If it's a vehicle or person, it's very important.
        
        final rect = obj.boundingBox;
        
        // Calculate direction based on X center
        final centerX = rect.center.dx;
        String direction = 'ahead';
        if (centerX < imageWidth * 0.33) {
          direction = 'on your left';
        } else if (centerX > imageWidth * 0.66) {
          direction = 'on your right';
        }

        // Estimate distance (pseudo-distance based on bounding box size)
        // A larger bounding box means it's closer to the camera
        final areaPercentage = (rect.width * rect.height) / (imageWidth * imageHeight);
        
        double estimatedDistanceM;
        DetectionUrgency urgency;
        
        if (areaPercentage > 0.4) {
          estimatedDistanceM = 0.5; // Very close
          urgency = DetectionUrgency.critical;
        } else if (areaPercentage > 0.15) {
          estimatedDistanceM = 1.5;
          urgency = DetectionUrgency.caution;
        } else {
          estimatedDistanceM = 4.0;
          urgency = DetectionUrgency.info;
        }

        detectedObjects.add(
          DetectedObject(
            label: label,
            distanceM: estimatedDistanceM,
            direction: direction,
            urgency: urgency,
          ),
        );
      }
      
      // Also send to backend for processing (if needed)
      try {
        await _apiService.requestRealtimeGuidance(
          detectedObjects
              .map((d) => {
                    'label': d.label,
                    'distance_m': d.distanceM,
                    'direction': d.direction,
                  })
              .toList(),
        );
      } catch (_) {}

      return detectedObjects;
    } catch (e) {
      debugPrint('ML Kit Detection Error: $e');
      return [];
    } finally {
      _isProcessing = false;
    }
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _inputImageFromCameraImage(CameraImage image, int sensorOrientation) {
    // Determine the format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    debugPrint('ML Kit Debug: Image Format Raw = ${image.format.raw}, Parsed = $format');
    
    if (format == null ||
        (defaultTargetPlatform == TargetPlatform.android &&
            format != InputImageFormat.nv21 &&
            format != InputImageFormat.yuv_420_888)) {
      debugPrint('ML Kit Debug: Unsupported format!');
      return null;
    }

    if (image.planes.isEmpty) return null;

    final bytes = image.planes.fold(
        <int>[],
        (List<int> previousValue, plane) =>
            previousValue..addAll(plane.bytes));

    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    return InputImage.fromBytes(
      bytes: Uint8List.fromList(bytes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  /// Get the most urgent warning from detections.
  String getMostUrgentWarning(List<DetectedObject> detections) {
    if (detections.isEmpty) return 'Path appears clear ahead.';

    final sorted = List<DetectedObject>.from(detections)
      ..sort((a, b) {
        final cmp = a.urgency.index.compareTo(b.urgency.index);
        if (cmp != 0) return cmp;
        return a.distanceM.compareTo(b.distanceM);
      });

    return sorted.first.toWarning();
  }

  /// Describe all detected objects.
  String describeAll(List<DetectedObject> detections) {
    if (detections.isEmpty) {
      return 'I don\'t detect any objects nearby. The path seems clear.';
    }
    final descs = detections
        .map((d) =>
            '${d.label} ${d.direction} at ${d.distanceM.toStringAsFixed(1)} meters')
        .toList();
    return 'I detect ${detections.length} objects: ${descs.join(", ")}.';
  }

  /// Trigger haptic feedback based on urgency level.
  Future<void> triggerHaptic(DetectionUrgency urgency) async {
    switch (urgency) {
      case DetectionUrgency.critical:
        for (int i = 0; i < 3; i++) {
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 120));
        }
      case DetectionUrgency.caution:
        for (int i = 0; i < 2; i++) {
          HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 150));
        }
      case DetectionUrgency.info:
        HapticFeedback.lightImpact();
    }
  }

  /// Get the highest urgency from a list of detections.
  DetectionUrgency? getHighestUrgency(List<DetectedObject> detections) {
    if (detections.isEmpty) return null;
    if (detections.any((d) => d.urgency == DetectionUrgency.critical)) {
      return DetectionUrgency.critical;
    }
    if (detections.any((d) => d.urgency == DetectionUrgency.caution)) {
      return DetectionUrgency.caution;
    }
    return DetectionUrgency.info;
  }
}
