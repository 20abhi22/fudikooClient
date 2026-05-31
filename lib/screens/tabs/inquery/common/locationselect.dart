import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/model/auth/mapplace-model.dart';
import 'package:fudikoclient/service/auth/map-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;

class LocationSelect extends StatefulWidget {
  final Function(String, String, String) returndata;

  const LocationSelect({super.key, required this.returndata});

  @override
  State<LocationSelect> createState() => _LocationSelectState();
}

class _LocationSelectState extends State<LocationSelect> {
  static const double _orangeHue = BitmapDescriptor.hueOrange;

  double _distance = 10;
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(12.9716, 77.5946);
  late String lat = '12.9716';
  late String lng = '77.5946';
  LatLng _selectedLocation = const LatLng(12.9716, 77.5946);

  final loc.Location location = loc.Location();
  final MapService mapService = MapService();
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<MapPlacesResponse> _placeSuggestions = [];
  bool _isSearching = false;

  Set<Circle> get _circles => {
    Circle(
      circleId: const CircleId('selected_radius'),
      center: _selectedLocation,
      radius: _distance * 1000,
      strokeColor: const Color(0xFFf87b0d),
      strokeWidth: 1,
      fillColor: const Color(0xFFf87b0d).withValues(alpha: 0.08),
    ),
  };

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _setSelectedLocation(_center, markerId: 'initial_location');
  }

  void _setSelectedLocation(
    LatLng position, {
    required String markerId,
    String? title,
  }) {
    setState(() {
      lat = position.latitude.toString();
      lng = position.longitude.toString();
      _selectedLocation = position;
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: MarkerId(markerId),
            position: position,
            infoWindow: title == null || title.isEmpty
                ? InfoWindow.noText
                : InfoWindow(title: title),
            icon: BitmapDescriptor.defaultMarkerWithHue(_orangeHue),
          ),
        );
    });
  }

  Future<void> _goToCurrentLocation() async {
    final userLocation = await location.getLocation();
    final currentLatLng = LatLng(
      userLocation.latitude!,
      userLocation.longitude!,
    );

    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: currentLatLng, zoom: 15),
      ),
    );
    _setSelectedLocation(currentLatLng, markerId: 'current_location');
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadPlaceSuggestions(value.trim());
    });
  }

  Future<void> _loadPlaceSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placeSuggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final suggestions = await mapService.listPlaces(
      query,
      lat: double.tryParse(lat),
      lng: double.tryParse(lng),
    );
    if (!mounted) return;
    setState(() {
      _placeSuggestions = suggestions;
      _isSearching = false;
    });
  }

  Future<void> _selectPlaceSuggestion(MapPlacesResponse place) async {
    final placeId = place.placeId;
    if (placeId == null || placeId.isEmpty) return;

    final coordinates = await mapService.getPlace(placeId);
    final target = LatLng(coordinates.lat ?? 0, coordinates.lng ?? 0);
    if (target.latitude == 0 && target.longitude == 0) return;
    if (!mounted) return;

    _searchController.text = place.mainText ?? '';
    FocusScope.of(context).unfocus();
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 14)),
    );
    _setSelectedLocation(
      target,
      markerId: 'searched_location',
      title: place.mainText,
    );
    setState(() => _placeSuggestions = []);
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (_placeSuggestions.isNotEmpty) {
      await _selectPlaceSuggestion(_placeSuggestions.first);
      return;
    }

    try {
      final locations = await geo.locationFromAddress(query);
      if (locations.isEmpty) return;
      final target = LatLng(
        locations.first.latitude,
        locations.first.longitude,
      );

      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 14),
        ),
      );
      _setSelectedLocation(target, markerId: 'searched_location', title: query);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location not found: $query')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: SizedBox.expand(
          child: Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 11,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                markers: _markers,
                circles: _circles,
                onTap: (tappedLocation) {
                  FocusScope.of(context).unfocus();
                  setState(() => _placeSuggestions = []);
                  _setSelectedLocation(
                    tappedLocation,
                    markerId: 'selected_location',
                  );
                },
              ),
              Positioned(
                left: 20,
                right: 20,
                top: 24,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _searchBar(),
                    if (_placeSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _suggestionsBox(),
                    ],
                  ],
                ),
              ),
              Positioned(
                bottom: 250,
                right: 20,
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: _goToCurrentLocation,
                  child: const Icon(Icons.my_location, color: Colors.black),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _bottomControls(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_searchController.text.isNotEmpty ||
                  _placeSuggestions.isNotEmpty) {
                _searchController.clear();
                setState(() => _placeSuggestions = []);
              } else {
                Navigator.pop(context);
              }
            },
            child: const SizedBox(
              width: 44,
              child: Icon(Icons.close, size: 18, color: Color(0xFFf87b0d)),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFFf87b0d)),
              decoration: const InputDecoration(
                hintText: 'Search Location',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFf87b0d),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _searchLocation(),
            ),
          ),
          SizedBox(
            width: 44,
            child: _isSearching
                ? const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFf87b0d),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFFf87b0d),
                    ),
                    onPressed: _searchLocation,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionsBox() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 210),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _placeSuggestions.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final place = _placeSuggestions[index];
          return ListTile(
            dense: true,
            leading: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFFf87b0d),
              size: 18,
            ),
            title: Text(
              place.mainText ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              place.secondaryText ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            onTap: () => _selectPlaceSuggestion(place),
          );
        },
      ),
    );
  }

  Widget _bottomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFf87b0d),
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: const Color(0xFFf87b0d),
                      overlayColor: const Color(
                        0xFFf87b0d,
                      ).withValues(alpha: 0.2),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      min: 0,
                      max: 100,
                      value: _distance,
                      onChanged: (value) => setState(() => _distance = value),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_distance.toInt()} km',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 150,
              height: 40,
              child: AppButton(
                text: 'Apply',
                onPressed: () {
                  Navigator.pop(context);
                  widget.returndata(lat, lng, _distance.toInt().toString());
                },
                size: 15,
                borderRadius: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
