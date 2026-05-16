import 'package:dio/dio.dart';

class ApiService {
  ApiService(String baseUrl)
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  final Dio _dio;
  String? _accessToken;

  void setAccessToken(String token) {
    _accessToken = token;
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/auth/token/',
      data: {'email': email, 'password': password},
    );
    _accessToken = response.data['access'] as String?;
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
    String phoneNumber = '',
    String preferredLanguage = 'en',
    String voiceGender = 'neutral',
  }) async {
    await _dio.post(
      '/api/accounts/register/',
      data: {
        'email': email,
        'username': username,
        'password': password,
        'phone_number': phoneNumber,
        'preferred_language': preferredLanguage,
        'voice_gender': voiceGender,
      },
    );
  }

  Future<Map<String, dynamic>> requestRealtimeGuidance(
    List<Map<String, dynamic>> detectedObjects,
  ) async {
    final response = await _dio.post(
      '/api/ai/inference/mock/',
      data: {'detected_objects': detectedObjects},
      options: Options(headers: _authorizedHeaders()),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<bool> checkBackendConnectivity() async {
    try {
      await _dio.get('/api/accounts/health/');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendSos({
    required double latitude,
    required double longitude,
    required String message,
  }) async {
    await _dio.post(
      '/api/emergency/sos/',
      data: {
        'trigger_type': 'manual',
        'latitude': latitude,
        'longitude': longitude,
        'message': message,
      },
      options: Options(headers: _authorizedHeaders()),
    );
  }

  /// Fetch walking route using OSRM (free, no API key).
  Future<Map<String, dynamic>?> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      // OSRM — free, no API key needed
      final directDio = Dio();
      final response = await directDio.get(
        'https://router.project-osrm.org/route/v1/foot/'
        '$originLng,$originLat;$destLng,$destLat',
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
          'steps': 'true',
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (_) {
      return null;
    }
  }

  /// Geocode a place name using Nominatim (free, no API key needed).
  /// If [currentLat] and [currentLng] are provided, and the query contains
  /// 'nearest', 'nearby', or 'closest', the search is heavily biased to a local radius.
  Future<Map<String, double>?> geocodePlace(
    String placeName, {
    double? currentLat,
    double? currentLng,
  }) async {
    try {
      final directDio = Dio();
      
      String query = placeName;
      final queryLower = placeName.toLowerCase();
      bool isLocalSearch = false;
      
      // Clean up the query for better results
      if (queryLower.contains('nearest') || 
          queryLower.contains('nearby') || 
          queryLower.contains('closest')) {
        isLocalSearch = true;
        query = queryLower
            .replaceAll('nearest', '')
            .replaceAll('nearby', '')
            .replaceAll('closest', '')
            .replaceAll('take me to', '')
            .replaceAll('find', '')
            .replaceAll('the', '')
            .trim();
      }

      final queryParams = <String, dynamic>{
        'q': query.isEmpty ? placeName : query, // Fallback if query becomes empty
        'format': 'json',
        'limit': '1',
      };

      // If it's a local search and we have coordinates, draw a bounding box (~10km)
      if (isLocalSearch && currentLat != null && currentLng != null) {
        final latSpan = 0.1; // ~11km
        final lngSpan = 0.1;
        final minLon = currentLng - lngSpan;
        final maxLon = currentLng + lngSpan;
        final minLat = currentLat - latSpan;
        final maxLat = currentLat + latSpan;
        
        queryParams['viewbox'] = '$minLon,$minLat,$maxLon,$maxLat';
        queryParams['bounded'] = '1'; // Strictly limit to this box
      }

      final response = await directDio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: queryParams,
        options: Options(
          headers: {'User-Agent': 'BlindAssistAI/1.0'},
        ),
      );
      
      final results = response.data as List;
      if (results.isEmpty) return null;
      
      return {
        'lat': double.parse(results[0]['lat'] as String),
        'lng': double.parse(results[0]['lon'] as String),
      };
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _authorizedHeaders() {
    if (_accessToken == null) return {};
    return {'Authorization': 'Bearer $_accessToken'};
  }
}
