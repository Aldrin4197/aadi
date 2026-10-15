import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

import '../../core/error/result.dart';
import '../../domain/models/geo_point.dart';
import '../../domain/repositories/location_repository.dart';

/// Live location services with no API key:
///  * GPS fixes via `geolocator` (web + mobile),
///  * forward and reverse geocoding via OpenStreetMap Nominatim.
///
/// Nominatim is free and key-free; its usage policy asks for a descriptive
/// identifier and a light request rate. Searches are debounced at the provider
/// level, and we send an identifying `User-Agent` on native platforms (browsers
/// set the `Referer` automatically, which Nominatim also accepts).
class NominatimLocationRepository implements LocationRepository {
  NominatimLocationRepository({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://nominatim.openstreetmap.org',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {
                if (!kIsWeb)
                  'User-Agent':
                      'Aadi/1.0 (rental marketplace; contact: support@aadi.app)',
              },
              queryParameters: {
                'format': 'jsonv2',
                'addressdetails': 1,
                'accept-language': 'en',
              },
            ),
          );

  final Dio _dio;

  /// Bias results to the Philippines while the marketplace is PH-only.
  static const _countryCodes = 'ph';

  @override
  Future<List<GeoPoint>> searchPlaces(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    try {
      final res = await _dio.get<List<dynamic>>(
        '/search',
        queryParameters: {'q': q, 'countrycodes': _countryCodes, 'limit': 8},
      );
      final data = res.data ?? const [];
      final points = <GeoPoint>[];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final point = _pointFromJson(item);
          if (point != null) points.add(point);
        }
      }
      return points;
    } on DioException catch (e) {
      throw AppException('Location search is unavailable right now.', cause: e);
    }
  }

  @override
  Future<GeoPoint> currentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const AppException(
        'Location services are turned off. Enable them and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const AppException(
        'Location permission denied. You can search for a place instead.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AppException(
        'Location permission is permanently denied. Enable it in Settings to '
        'use your current location.',
      );
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      throw AppException(
        'We couldn\'t get your current location. Try again or search for a '
        'place.',
        cause: e,
      );
    }

    return _reverse(position.latitude, position.longitude);
  }

  /// Reverse-geocodes a GPS fix into a readable label, falling back to the raw
  /// coordinates if Nominatim is unreachable — the fix itself is still usable.
  Future<GeoPoint> _reverse(double lat, double lng) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/reverse',
        queryParameters: {'lat': lat, 'lon': lng, 'zoom': 12},
      );
      final data = res.data;
      final point = data == null
          ? null
          : _pointFromJson(data, fallbackLat: lat, fallbackLng: lng);
      if (point != null) return point;
    } on DioException {
      // Ignore and return the raw fix below.
    }
    return GeoPoint(lat: lat, lng: lng);
  }

  GeoPoint? _pointFromJson(
    Map<String, dynamic> json, {
    double? fallbackLat,
    double? fallbackLng,
  }) {
    final lat = _toDouble(json['lat']) ?? fallbackLat;
    final lng = _toDouble(json['lon']) ?? fallbackLng;
    if (lat == null || lng == null) return null;

    final address = json['address'];
    final addr = address is Map<String, dynamic>
        ? address
        : const <String, dynamic>{};
    final city =
        _firstString(addr, const [
          'city',
          'town',
          'municipality',
          'village',
          'hamlet',
          'suburb',
          'county',
        ]) ??
        _firstSegment(json['display_name']);
    final region = _firstString(addr, const ['state', 'region', 'province']);

    return GeoPoint(lat: lat, lng: lng, city: city, address: region);
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String? _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  static String? _firstSegment(Object? displayName) {
    if (displayName is String && displayName.isNotEmpty) {
      return displayName.split(',').first.trim();
    }
    return null;
  }
}
