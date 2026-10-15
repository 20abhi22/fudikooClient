import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/auth/mapplace-model.dart';

// ---------------------------------------------------------------------------
// Exception
// ---------------------------------------------------------------------------

class MapPlaceSearchException implements Exception {
  final String status;
  final String message;

  const MapPlaceSearchException(this.status, this.message);

  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Callback typedef (kept for callers that use the progressive variant)
// ---------------------------------------------------------------------------

typedef PlaceSearchProgressCallback =
    void Function(List<MapPlacesResponse> results, bool isLoadingMore);

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class MapService {
  // ── Search ──────────────────────────────────────────────────────────────

  /// Returns autocomplete predictions for [query], routed through the backend.
  /// [lat]/[lng] optionally bias results toward a location.
  Future<List<MapPlacesResponse>> fetchAutocompletePredictions(
    String query, {
    double? lat,
    double? lng,
    String? tokenOverride,
  }) async {
    try {
      final response = await DioClient.dio.get(
        '/places/search',
        queryParameters: {
          'input': query,
          if (lat != null && lng != null) 'location': '$lat,$lng',
          if (lat != null && lng != null) 'radius': 50000,
        },
        options: tokenOverride == null || tokenOverride.isEmpty
            ? null
            : Options(headers: {'Authorization': 'Bearer $tokenOverride'}),
      );

      _ensureOkStatus(response.data);

      final rawPredictions = response.data['predictions'];
      final predictions = rawPredictions is List ? rawPredictions : <dynamic>[];

      return predictions.map<MapPlacesResponse>((place) {
        final json = _asMap(place);
        final structured = json['structured_formatting'] is Map
            ? _asMap(json['structured_formatting'])
            : <String, dynamic>{};

        return MapPlacesResponse.fromJson({
          'place_id': json['place_id'],
          'main_text':
              structured['main_text'] ?? json['description'] ?? json['name'],
          'secondary_text': structured['secondary_text'] ?? '',
          'types': json['types'],
          'is_seed': false,
        });
      }).toList();
    } on MapPlaceSearchException {
      rethrow;
    } catch (e) {
      debugPrint('MapService.fetchAutocompletePredictions error: $e');
      throw const MapPlaceSearchException(
        'NETWORK_ERROR',
        'Could not load search suggestions. Please try again.',
      );
    }
  }

  /// Convenience alias kept for backward compatibility.
  Future<List<MapPlacesResponse>> fetchAutocompleteSuggestions(String query) =>
      fetchAutocompletePredictions(query);

  /// Legacy alias for [fetchAutocompletePredictions] kept for existing
  /// call sites across the app.
  Future<List<MapPlacesResponse>> listPlaces(
    String place, {
    double? lat,
    double? lng,
    String? tokenOverride,
  }) => fetchAutocompletePredictions(
    place,
    lat: lat,
    lng: lng,
    tokenOverride: tokenOverride,
  );

  // ── Place details ────────────────────────────────────────────────────────

  /// Fetches full place details (name, address, lat/lng) for [placeId].
  Future<MapPlacesResponse> fetchPlaceDetails(
    String placeId, {
    String? tokenOverride,
  }) async {
    try {
      final response = await DioClient.dio.get(
        '/places/details',
        queryParameters: {'place_id': placeId},
        options: tokenOverride == null || tokenOverride.isEmpty
            ? null
            : Options(headers: {'Authorization': 'Bearer $tokenOverride'}),
      );

      _ensureOkStatus(response.data);

      final rawResult = response.data['result'];
      if (rawResult is! Map) {
        throw const MapPlaceSearchException(
          'INVALID_REQUEST',
          'Place details were not available.',
        );
      }

      final result = _asMap(rawResult);
      return _placeFromResultJson(result, placeId: placeId);
    } on MapPlaceSearchException {
      rethrow;
    } catch (e) {
      debugPrint('MapService.fetchPlaceDetails error: $e');
      throw const MapPlaceSearchException(
        'NETWORK_ERROR',
        'Could not load place details. Please try again.',
      );
    }
  }

  /// Returns only coordinates for [placeId].
  /// Kept for callers that previously used `getPlace`.
  Future<MapCoordinatesResponse> getPlace(
    String placeId, {
    String? tokenOverride,
  }) async {
    try {
      final response = await DioClient.dio.get(
        '/places/details',
        queryParameters: {'place_id': placeId},
        options: tokenOverride == null || tokenOverride.isEmpty
            ? null
            : Options(headers: {'Authorization': 'Bearer $tokenOverride'}),
      );

      _ensureOkStatus(response.data);

      final location = response.data['result']?['geometry']?['location'];
      if (location == null) {
        return MapCoordinatesResponse(lat: 0.0, lng: 0.0);
      }
      return MapCoordinatesResponse.fromJson(_asMap(location));
    } catch (e) {
      debugPrint('MapService.getPlace error: $e');
      return MapCoordinatesResponse(lat: 0.0, lng: 0.0);
    }
  }

  /// Reverse-geocodes coordinates into a formatted address.
  /// Kept for callers that previously used `getPlaceName`.
  Future<String?> getPlaceName(String lat, String lng) async {
    const apiKey = 'AIzaSyAHuxPvcWL8s0Ye2fGbiDNJ9cTdcSoxvEw';
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';

    try {
      final response = await Dio().get(url);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('MapService.getPlaceName error: $e');
      return null;
    }
  }

  // ── Higher-level helpers (kept for call-site compatibility) ──────────────

  /// Searches for places matching [query] and returns a flat list.
  Future<List<MapPlacesResponse>> smartPlaceSearch(String query) =>
      fetchAutocompletePredictions(query);

  /// Progressive variant — emits results immediately then resolves details.
  Future<List<MapPlacesResponse>> smartPlaceSearchProgressive(
    String query, {
    required PlaceSearchProgressCallback onResults,
    String? tokenOverride,
  }) async {
    // Emit initial empty loading state.
    onResults([], true);

    final predictions =
        await fetchAutocompletePredictions(
          query,
          tokenOverride: tokenOverride,
        ).catchError((e) {
          debugPrint('Skipping autocomplete branch: $e');
          return <MapPlacesResponse>[];
        });

    // Emit predictions immediately so the UI shows names without coords.
    onResults(predictions, true);

    // Resolve details (lat/lng) for each prediction progressively.
    final resolved = <MapPlacesResponse>[];
    for (final prediction in predictions) {
      final placeId = prediction.placeId;
      if (placeId == null || placeId.isEmpty) {
        resolved.add(prediction);
        onResults(List.unmodifiable(resolved), true);
        continue;
      }
      try {
        final detail = await fetchPlaceDetails(
          placeId,
          tokenOverride: tokenOverride,
        );
        resolved.add(detail);
      } catch (_) {
        resolved.add(prediction);
      }
      onResults(List.unmodifiable(resolved), true);
    }

    onResults(List.unmodifiable(resolved), false);
    return resolved;
  }

  // ── Deduplication & sorting ────────────────────────────────────────────

  List<MapPlacesResponse> mergeAndRemoveDuplicates(
    List<MapPlacesResponse> results,
  ) {
    final seenKeys = <String>{};
    final unique = <MapPlacesResponse>[];
    for (final place in results) {
      if (seenKeys.add(_duplicateKey(place))) {
        unique.add(place);
      }
    }
    return unique;
  }

  List<MapPlacesResponse> sortResultsByRelevance(
    List<MapPlacesResponse> results,
    String query,
  ) {
    final normalizedQuery = _normalize(query);
    final sorted = [...results];

    sorted.sort((a, b) {
      final aName = _normalize(a.mainText ?? '');
      final bName = _normalize(b.mainText ?? '');

      final aExact = aName == normalizedQuery;
      final bExact = bName == normalizedQuery;
      if (aExact != bExact) return aExact ? -1 : 1;

      if (a.isSeed != b.isSeed) return a.isSeed ? -1 : 1;

      final aContains = aName.contains(normalizedQuery);
      final bContains = bName.contains(normalizedQuery);
      if (aContains != bContains) return aContains ? -1 : 1;

      final distCompare = (a.distanceMeters ?? double.infinity).compareTo(
        b.distanceMeters ?? double.infinity,
      );
      if (distCompare != 0) return distCompare;

      final ratingCompare = (b.rating ?? 0).compareTo(a.rating ?? 0);
      if (ratingCompare != 0) return ratingCompare;

      return (b.userRatingsTotal ?? 0).compareTo(a.userRatingsTotal ?? 0);
    });

    return sorted;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  MapPlacesResponse _placeFromResultJson(
    Map<String, dynamic> result, {
    required String placeId,
  }) {
    final geometry = result['geometry'] is Map
        ? _asMap(result['geometry'])
        : <String, dynamic>{};
    final location = geometry['location'] is Map
        ? _asMap(geometry['location'])
        : <String, dynamic>{};

    return MapPlacesResponse.fromJson({
      'place_id': placeId,
      'main_text': result['name'],
      'secondary_text': result['formatted_address'] ?? '',
      'lat': location['lat'],
      'lng': location['lng'],
      'types': result['types'],
      'rating': result['rating'],
      'user_ratings_total': result['user_ratings_total'],
      'is_seed': true,
    });
  }

  void _ensureOkStatus(dynamic data) {
    if (data is! Map) {
      throw const MapPlaceSearchException(
        'INVALID_RESPONSE',
        'Places search returned an invalid response.',
      );
    }
    final body = _asMap(data);
    final status = body['status']?.toString() ?? 'OK';
    if (status == 'OK') return;

    final message = switch (status) {
      'ZERO_RESULTS' => 'No places found.',
      'OVER_QUERY_LIMIT' => 'Search limit reached. Please try again later.',
      'REQUEST_DENIED' => 'Places request was denied.',
      'INVALID_REQUEST' => 'Invalid search request. Please try again.',
      _ => body['error_message']?.toString() ?? 'Places search failed.',
    };
    throw MapPlaceSearchException(status, message);
  }

  String _duplicateKey(MapPlacesResponse place) {
    final placeId = place.placeId;
    if (placeId != null && placeId.isNotEmpty) return 'id:$placeId';
    final name = _normalize(place.mainText ?? '');
    final lat = place.lat?.toStringAsFixed(5) ?? '';
    final lng = place.lng?.toStringAsFixed(5) ?? '';
    return 'fallback:$name:$lat:$lng';
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(value as Map);
  }
}
