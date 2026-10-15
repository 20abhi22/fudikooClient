import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/auth/mapplace-model.dart';
import 'package:fudikoclient/service/auth/map-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fudikoclient/utils/snackbar.dart';

/// Full-screen place picker shared by every screen that asks the customer to
/// choose a location. Mirrors the partner app's picker so both products behave
/// the same way: debounced progressive search, saved/recent shortcuts, a
/// draggable orange pin, and a bottom panel that shows the resolved address.
///
/// Pops a `{'lat': double, 'lng': double, 'place': String}` map on Confirm and
/// `null` when the user backs out.
class MapPickerPage extends StatefulWidget {
  /// Where the map opens. When null the picker falls back to the device
  /// location, then to the Kerala centroid.
  final LatLng? initialLocation;

  /// Address already stored for the caller, offered as a "Saved address"
  /// shortcut in the dropdown.
  final String initialPlaceName;

  /// Bearer token used before the user is fully signed in (registration flow).
  final String? authToken;

  /// App bar title — screens differ ("Select Location" vs "Select Place").
  final String title;

  const MapPickerPage({
    super.key,
    this.initialLocation,
    this.initialPlaceName = '',
    this.authToken,
    this.title = 'Select Location',
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? _mapController;
  final TextEditingController _placeSearchController = TextEditingController();
  final MapService _mapService = MapService();
  Timer? _placeSearchDebounce;
  static final BitmapDescriptor _orangeMarker =
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);

  /// Kerala centroid — only used until a better location is known.
  static const LatLng _fallbackLocation = LatLng(10.8505, 76.2711);

  late LatLng _pickedLocation;
  String _placeName = 'Fetching location...';
  bool _isGeocoding = false;
  bool _isSearchingPlaces = false;
  bool _isFetchingNextPage = false;
  bool _isFetchingCurrentLocation = false;
  bool _hasSubmittedSearch = false;
  String? _placeSearchError;
  List<MapPlacesResponse> _textSearchResults = [];
  List<MapPlacesResponse> _savedAddresses = [];
  List<MapPlacesResponse> _recentSearches = [];
  Set<Marker> _markers = {};
  int _placeSearchRequestId = 0;
  bool _isSearchDropdownOpen = false;
  bool _showPickedMarker = false;
  static const String _recentSearchPrefsKey = 'recent_map_place_searches';

  /// Secondary copy — subtitles, section headers, empty/error states.
  /// [AppText] defaults its color to the brand orange, so body text has to
  /// pass a color explicitly.
  Color get _mutedTextColor => appTextColor5.withValues(alpha: 0.6);

  @override
  void initState() {
    super.initState();
    // A caller-supplied location is already a real choice, so show its pin
    // straight away instead of waiting for the user to tap the map.
    _showPickedMarker = widget.initialLocation != null;
    _pickedLocation = widget.initialLocation ?? _fallbackLocation;
    _updateMarker(_pickedLocation);
    _loadSavedAndRecent();

    if (widget.initialLocation == null) {
      _getCurrentLocation();
    } else {
      _reverseGeocode(_pickedLocation);
    }
  }

  @override
  void dispose() {
    _placeSearchDebounce?.cancel();
    _placeSearchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation({bool selectLocation = false}) async {
    if (_isFetchingCurrentLocation) return;

    setState(() => _isFetchingCurrentLocation = true);
    try {
      final isLocationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        _showLocationSnackBar(
          'Turn on location services to use your current location',
          actionLabel: 'Settings',
          onAction: Geolocator.openLocationSettings,
        );
        await _reverseGeocode(_pickedLocation);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _showLocationSnackBar('Location permission was denied');
        await _reverseGeocode(_pickedLocation);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _showLocationSnackBar(
          'Location permission is permanently denied',
          actionLabel: 'Settings',
          onAction: Geolocator.openAppSettings,
        );
        await _reverseGeocode(_pickedLocation);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _pickedLocation = latLng;
        if (selectLocation) {
          _showPickedMarker = true;
          _textSearchResults = [];
          _isSearchDropdownOpen = false;
          _hasSubmittedSearch = false;
          _placeSearchError = null;
        }
      });
      await _animateTo(latLng, 15);
      _updateMarker(latLng);
      await _reverseGeocode(latLng);
    } catch (e) {
      debugPrint('Location error: $e');
      if (!mounted) return;
      await _reverseGeocode(_pickedLocation);
    } finally {
      if (mounted) setState(() => _isFetchingCurrentLocation = false);
    }
  }

  void _showLocationSnackBar(
    String message, {
    String? actionLabel,
    Future<bool> Function()? onAction,
  }) {
    if (!mounted) return;
    showInfoSnack(
      context,
      message,
      action: actionLabel == null || onAction == null
          ? null
          : SnackBarAction(
              label: actionLabel,
              textColor: snackTextColor,
              onPressed: () {
                onAction();
              },
            ),
    );
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final Placemark p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((value) => value != null && value.isNotEmpty).toList();
        setState(() {
          _placeName = parts.isEmpty
              ? '${latLng.latitude}, ${latLng.longitude}'
              : parts.join(', ');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _placeName = '${latLng.latitude}, ${latLng.longitude}');
    }
    if (!mounted) return;
    setState(() => _isGeocoding = false);
  }

  void _onPlaceSearchChanged(String value) {
    _placeSearchDebounce?.cancel();
    final trimmed = value.trim();
    final requestId = ++_placeSearchRequestId;

    if (trimmed.length < 3) {
      setState(() {
        _textSearchResults = [];
        _isSearchDropdownOpen = true;
        _isSearchingPlaces = false;
        _isFetchingNextPage = false;
        _placeSearchError = null;
        _hasSubmittedSearch = false;
      });
      return;
    }

    setState(() {
      _isSearchDropdownOpen = true;
      _isSearchingPlaces = true;
      _placeSearchError = null;
      _hasSubmittedSearch = true;
    });

    _placeSearchDebounce = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || requestId != _placeSearchRequestId) return;
      smartPlaceSearch();
    });
  }

  Future<void> smartPlaceSearch() async {
    final query = _placeSearchController.text.trim();
    if (query.isEmpty) return;

    _placeSearchDebounce?.cancel();
    final requestId = ++_placeSearchRequestId;

    setState(() {
      _hasSubmittedSearch = true;
      _isSearchDropdownOpen = true;
      _isSearchingPlaces = true;
      _isFetchingNextPage = false;
      _placeSearchError = null;
      _textSearchResults = [];
    });

    try {
      final results = await _mapService.smartPlaceSearchProgressive(
        query,
        tokenOverride: widget.authToken,
        onResults: (results, isLoadingMore) {
          if (!mounted || requestId != _placeSearchRequestId) return;

          setState(() {
            _textSearchResults = results;
            _isFetchingNextPage = isLoadingMore;
            _placeSearchError = null;
          });
        },
      );

      if (!mounted || requestId != _placeSearchRequestId) return;
      setState(() {
        _textSearchResults = results;
        _isSearchingPlaces = false;
        _isFetchingNextPage = false;
        _placeSearchError = results.isEmpty ? 'No places found' : null;
      });
    } catch (e) {
      if (!mounted || requestId != _placeSearchRequestId) return;
      setState(() {
        _isSearchingPlaces = false;
        _isFetchingNextPage = false;
        _placeSearchError = e is MapPlaceSearchException
            ? e.message
            : 'Could not search places. Please try again.';
      });
    }
  }

  Future<void> _selectSearchResult(MapPlacesResponse place) async {
    // Progressive results carry coordinates; a bare prediction still needs a
    // details lookup before the map can move.
    var lat = place.lat;
    var lng = place.lng;
    final placeId = place.placeId;

    if ((lat == null || lng == null) && placeId != null && placeId.isNotEmpty) {
      setState(() => _isSearchingPlaces = true);
      final coordinates = await _mapService.getPlace(
        placeId,
        tokenOverride: widget.authToken,
      );
      if (!mounted) return;
      setState(() => _isSearchingPlaces = false);
      lat = coordinates.lat;
      lng = coordinates.lng;
    }

    if (lat == null || lng == null) return;

    final latLng = LatLng(lat, lng);
    final label = [
      place.mainText,
      place.secondaryText,
    ].where((value) => value != null && value.isNotEmpty).join(', ');

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _pickedLocation = latLng;
      _placeName = label;
      _placeSearchController.text = place.mainText ?? label;
      _textSearchResults = [];
      _isSearchDropdownOpen = false;
      _hasSubmittedSearch = false;
      _isFetchingNextPage = false;
      _placeSearchError = null;
      _showPickedMarker = true;
    });
    _updateMarker(latLng);
    await _animateTo(latLng, 16);
    await _saveRecentSearch(
      MapPlacesResponse(
        placeId: placeId,
        mainText: place.mainText,
        secondaryText: place.secondaryText,
        lat: latLng.latitude,
        lng: latLng.longitude,
      ),
    );
  }

  Future<void> _animateTo(LatLng latLng, double zoom) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, zoom));
  }

  void _updateMarker(LatLng latLng) {
    setState(() {
      _markers = _showPickedMarker
          ? {
              Marker(
                markerId: const MarkerId('picked'),
                position: latLng,
                icon: _orangeMarker,
                draggable: true,
                onDragEnd: (newPos) async {
                  setState(() {
                    _pickedLocation = newPos;
                    _showPickedMarker = true;
                  });
                  await _reverseGeocode(newPos);
                  _updateMarker(newPos);
                },
              ),
            }
          : {};
    });
  }

  Future<void> _loadSavedAndRecent() async {
    final initialLocation = widget.initialLocation;
    final saved =
        widget.initialPlaceName.trim().isEmpty || initialLocation == null
        ? <MapPlacesResponse>[]
        : [
            MapPlacesResponse(
              placeId: 'saved_initial',
              mainText: widget.initialPlaceName,
              secondaryText: 'Saved address',
              lat: initialLocation.latitude,
              lng: initialLocation.longitude,
            ),
          ];

    final prefs = await SharedPreferences.getInstance();
    final rawRecent = prefs.getStringList(_recentSearchPrefsKey) ?? [];
    final recent = rawRecent
        .map((value) {
          try {
            return MapPlacesResponse.fromJson(
              Map<String, dynamic>.from(jsonDecode(value) as Map),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<MapPlacesResponse>()
        .toList();

    if (!mounted) return;
    setState(() {
      _savedAddresses = saved;
      _recentSearches = _mapService.mergeAndRemoveDuplicates(recent);
    });
  }

  Future<void> _saveRecentSearch(MapPlacesResponse place) async {
    if ((place.mainText ?? '').isEmpty) return;

    final merged = _mapService
        .mergeAndRemoveDuplicates([place, ..._recentSearches])
        .take(6)
        .toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recentSearchPrefsKey,
      merged.map((place) => jsonEncode(place.toJson())).toList(),
    );

    if (!mounted) return;
    setState(() => _recentSearches = merged);
  }

  bool _canShowQuickSuggestions() {
    return _isSearchDropdownOpen &&
        !_hasSubmittedSearch &&
        !_isSearchingPlaces &&
        (_savedAddresses.isNotEmpty || _recentSearches.isNotEmpty);
  }

  Widget _buildPlaceSearchField({
    required bool isMobile,
    required double fieldRadius,
  }) {
    final hasText = _placeSearchController.text.trim().isNotEmpty;
    final iconSize = isMobile ? 22.0 : 20.0;

    return TranslatedBuilder(
      text: 'Search place',
      builder: (context, hintText) => TextField(
        controller: _placeSearchController,
        textInputAction: TextInputAction.search,
        onTap: () => setState(() => _isSearchDropdownOpen = true),
        onChanged: _onPlaceSearchChanged,
        style: TextStyle(fontSize: 14, color: appTextColor5),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 14, color: _mutedTextColor),
          prefixIcon: Icon(Icons.search, color: appTextColor, size: iconSize),
          suffixIcon: hasText
              ? IconButton(
                  icon: Icon(Icons.close, color: appTextColor, size: iconSize),
                  onPressed: () {
                    _placeSearchDebounce?.cancel();
                    _placeSearchRequestId++;
                    setState(() {
                      _placeSearchController.clear();
                      _textSearchResults = [];
                      _isSearchingPlaces = false;
                      _isFetchingNextPage = false;
                      _hasSubmittedSearch = false;
                      _placeSearchError = null;
                      _isSearchDropdownOpen = true;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: appSecondaryBackgroundColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildListShell({
    required double maxHeight,
    required double panelRadius,
    required Widget child,
  }) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(panelRadius),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: child,
    );
  }

  Widget _buildQuickSuggestions({
    required bool isMobile,
    required double maxHeight,
    required double panelRadius,
  }) {
    if (!_canShowQuickSuggestions()) return const SizedBox.shrink();

    return _buildListShell(
      maxHeight: maxHeight,
      panelRadius: panelRadius,
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: [
          if (_savedAddresses.isNotEmpty)
            _buildPlaceSection(
              title: 'Saved addresses',
              places: _savedAddresses,
              icon: Icons.bookmark_border,
              isMobile: isMobile,
              onTap: _selectSearchResult,
            ),
          if (_recentSearches.isNotEmpty)
            _buildPlaceSection(
              title: 'Recent searches',
              places: _recentSearches,
              icon: Icons.history,
              isMobile: isMobile,
              onTap: _selectSearchResult,
            ),
        ],
      ),
    );
  }

  Widget _buildTextSearchResults({
    required bool isMobile,
    required double maxHeight,
    required double panelRadius,
  }) {
    if (!_isSearchDropdownOpen || !_hasSubmittedSearch) {
      return const SizedBox.shrink();
    }

    if (_placeSearchError != null) {
      return _buildListShell(
        maxHeight: maxHeight,
        panelRadius: panelRadius,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: AppText(
            text: _placeSearchError!,
            size: 13,
            fontWeight: FontWeight.w400,
            color: _mutedTextColor,
            isCentered: true,
          ),
        ),
      );
    }

    if (_textSearchResults.isEmpty && _isSearchingPlaces) {
      return _buildListShell(
        maxHeight: maxHeight,
        panelRadius: panelRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: appTextColor,
              ),
            ),
          ),
        ),
      );
    }

    if (_textSearchResults.isEmpty) {
      return _buildListShell(
        maxHeight: maxHeight,
        panelRadius: panelRadius,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: AppText(
            text: 'No places found',
            size: 13,
            fontWeight: FontWeight.w400,
            color: _mutedTextColor,
            isCentered: true,
          ),
        ),
      );
    }

    return _buildListShell(
      maxHeight: maxHeight,
      panelRadius: panelRadius,
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _textSearchResults.length + (_isFetchingNextPage ? 1 : 0),
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: appTextColor5.withValues(alpha: 0.12)),
        itemBuilder: (context, index) {
          if (index >= _textSearchResults.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: appTextColor,
                  ),
                ),
              ),
            );
          }

          final place = _textSearchResults[index];
          return _buildPlaceTile(
            place: place,
            icon: Icons.place_outlined,
            isMobile: isMobile,
            onTap: () => _selectSearchResult(place),
          );
        },
      ),
    );
  }

  Widget _buildPlaceSection({
    required String title,
    required List<MapPlacesResponse> places,
    required IconData icon,
    required bool isMobile,
    required ValueChanged<MapPlacesResponse> onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: AppText(
            text: title,
            size: 12,
            fontWeight: FontWeight.w600,
            color: _mutedTextColor,
          ),
        ),
        ...places.map(
          (place) => _buildPlaceTile(
            place: place,
            icon: icon,
            isMobile: isMobile,
            onTap: () => onTap(place),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceTile({
    required MapPlacesResponse place,
    required IconData icon,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: appTextColor, size: isMobile ? 24.0 : 22.0),
      // AppText already clamps its size responsively, so pass the base value.
      title: AppText(
        text: place.mainText ?? '',
        size: 14,
        fontWeight: FontWeight.w500,
        color: appTextColor5,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: (place.secondaryText ?? '').isEmpty
          ? null
          : AppText(
              text: place.secondaryText!,
              size: 12,
              fontWeight: FontWeight.w400,
              color: _mutedTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      onTap: onTap,
    );
  }

  /// White circular control that floats over the map — back arrow,
  /// my-location. [size] is both the width and the height so it stays round.
  Widget _floatingCircle({
    required double size,
    required Widget child,
    required VoidCallback? onTap,
    String? tooltip,
  }) {
    final button = Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  /// White pill that floats over the map — the title, Confirm, and the
  /// resolved-address panel.
  Widget _floatingCapsule({
    required double radius,
    required Widget child,
    EdgeInsets? padding,
    double? height,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          padding: padding,
          // widthFactor shrink-wraps the pill around its label, while the
          // alignment still centres that label inside the pill's fixed height.
          // Setting Container.alignment instead would stretch the pill to fill
          // whatever width it is offered.
          child: Align(
            alignment: Alignment.center,
            widthFactor: 1.0,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(MapPickerMetrics metrics) {
    final capsulePadding = EdgeInsets.symmetric(
      horizontal: metrics.capsulePadding,
    );

    return Row(
      children: [
        _floatingCircle(
          size: metrics.controlHeight,
          onTap: () => Navigator.pop(context),
          child: Image.asset(
            backOrange,
            width: metrics.backIconSize,
            height: metrics.backIconSize,
          ),
        ),
        SizedBox(width: metrics.controlGap),
        _floatingCapsule(
          radius: metrics.controlRadius,
          height: metrics.controlHeight,
          padding: capsulePadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: metrics.titleMaxWidth),
            child: AppText(
              text: widget.title,
              size: metrics.titleTextSize,
              fontWeight: FontWeight.w600,
              color: appTextColor5,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        SizedBox(width: metrics.controlGap),
        _confirmCapsule(
          radius: metrics.controlRadius,
          height: metrics.controlHeight,
          padding: capsulePadding,
          onTap: () {
            Navigator.pop(context, {
              'lat': _pickedLocation.latitude,
              'lng': _pickedLocation.longitude,
              'place': _placeName,
            });
          },
          child: AppText(
            text: 'Confirm',
            size: metrics.titleTextSize,
            fontWeight: FontWeight.w600,
            color: appTextColor,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  /// Wraps the Confirm pill so it takes the row's leftover width and stays
  /// pinned to the right edge while the title pill hugs its label.
  Widget _confirmCapsule({
    required double radius,
    required double height,
    required EdgeInsets padding,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: _floatingCapsule(
          radius: radius,
          height: height,
          padding: padding,
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }

  Widget _buildBottomBar(MapPickerMetrics metrics) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _floatingCapsule(
            radius: metrics.bottomCapsuleRadius,
            padding: metrics.bottomPanelPadding,
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: appTextColor,
                  size: metrics.bottomIconSize,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _isGeocoding
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: appTextColor,
                          ),
                        )
                      : AppText(
                          text: _placeName,
                          size: 14,
                          fontWeight: FontWeight.w500,
                          color: appTextColor5,
                          maxLines: metrics.isMobile ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: metrics.controlGap),
        TranslatedBuilder(
          text: 'Use current location',
          builder: (context, tooltip) => _floatingCircle(
            size: metrics.locationButtonSize,
            tooltip: tooltip,
            onTap: _isFetchingCurrentLocation
                ? null
                : () => _getCurrentLocation(selectLocation: true),
            child: _isFetchingCurrentLocation
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: appTextColor,
                    ),
                  )
                : Icon(
                    Icons.my_location,
                    color: appTextColor,
                    size: metrics.bottomIconSize,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = MapPickerMetrics(size: MediaQuery.sizeOf(context));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: appSecondaryBackgroundColor,
      // No AppBar — the controls float over the map instead, so the map fills
      // the screen and every control reads as a card above it.
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _animateTo(_pickedLocation, 15);
            },
            markers: _markers,
            myLocationEnabled: true,
            // Native grey controls are off; the floating orange my-location
            // button drives recentering instead.
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: (latLng) async {
              setState(() {
                _pickedLocation = latLng;
                _showPickedMarker = true;
              });
              _updateMarker(latLng);
              await _reverseGeocode(latLng);
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.overlayPadding,
                  metrics.overlayTop,
                  metrics.overlayPadding,
                  0,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: metrics.searchPanelMaxWidth,
                    ),
                    child: Column(
                      children: [
                        _buildTopBar(metrics),
                        SizedBox(height: metrics.topBarGap),
                        Material(
                          color: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.black26,
                          borderRadius: BorderRadius.circular(
                            metrics.controlRadius,
                          ),
                          child: _buildPlaceSearchField(
                            isMobile: metrics.isMobile,
                            fieldRadius: metrics.controlRadius,
                          ),
                        ),
                        if (_canShowQuickSuggestions()) ...[
                          SizedBox(height: metrics.suggestionGap),
                          _buildQuickSuggestions(
                            isMobile: metrics.isMobile,
                            maxHeight: metrics.suggestionMaxHeight,
                            panelRadius: metrics.panelRadius,
                          ),
                        ],
                        if (_hasSubmittedSearch) ...[
                          SizedBox(height: metrics.suggestionGap),
                          _buildTextSearchResults(
                            isMobile: metrics.isMobile,
                            maxHeight: metrics.suggestionMaxHeight,
                            panelRadius: metrics.panelRadius,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  metrics.overlayPadding,
                  0,
                  metrics.overlayPadding,
                  metrics.bottomInset,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: metrics.bottomPanelMaxWidth,
                    ),
                    child: _buildBottomBar(metrics),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Layout numbers for [MapPickerPage], kept in one place so phone, wide-short
/// phone, tablet and desktop all stay legible.
class MapPickerMetrics {
  const MapPickerMetrics({required this.size});

  final Size size;

  double get width => size.width;
  double get height => size.height;
  bool get isMobile => Breakpoints.isMobile(width);
  bool get isTabletDevice => Breakpoints.isTabletDevice(size);

  /// The user app's [Breakpoints] has no wide-short-phone helper, so the
  /// same rule the rest of the app uses is applied inline here.
  bool get isWideShortPhone =>
      Breakpoints.isMobileDevice(size) && width >= 500 && height <= 760;
  bool get isLandscape => width > height;
  bool get isCompactLandscape =>
      isWideShortPhone || (isLandscape && height < 520);

  double get overlayPadding => isMobile || isCompactLandscape ? 16.0 : 24.0;

  double get overlayTop => isCompactLandscape ? 10.0 : 16.0;

  // ── Floating controls ───────────────────────────────────────────────────
  // Circles and pills share one height so the top row lines up. The values
  // stay plain doubles: a circle needs the same number on both axes.

  double get controlHeight {
    if (isCompactLandscape) return 40.0;
    if (isTabletDevice) return 52.0;
    return 46.0;
  }

  double get controlRadius => controlHeight / 2;
  double get controlGap => isCompactLandscape ? 8.0 : 10.0;
  double get capsulePadding => isCompactLandscape ? 14.0 : 18.0;
  double get backIconSize => isCompactLandscape ? 18.0 : 20.0;

  double get titleTextSize {
    if (isCompactLandscape) return 13.0;
    if (isTabletDevice) return 16.0;
    return 15.0;
  }

  double get topBarGap => isCompactLandscape ? 8.0 : 12.0;

  /// Ceiling for the title pill so an unusually long label ellipsizes instead
  /// of squeezing the Confirm pill off the row.
  double get titleMaxWidth {
    if (isCompactLandscape) return 150.0;
    if (isTabletDevice) return 260.0;
    return math.min(200.0, width * 0.42);
  }

  double get locationButtonSize {
    if (isCompactLandscape) return 44.0;
    if (isTabletDevice) return 56.0;
    return 50.0;
  }

  double get bottomIconSize => isCompactLandscape ? 20.0 : 22.0;
  double get bottomCapsuleRadius => isCompactLandscape ? 20.0 : 26.0;
  double get bottomInset => isCompactLandscape ? 10.0 : 16.0;

  EdgeInsets get bottomPanelPadding => EdgeInsets.symmetric(
    horizontal: 18,
    vertical: isCompactLandscape ? 10.0 : 14.0,
  );

  // ── Search dropdown ─────────────────────────────────────────────────────

  double get panelRadius => 14.0;
  double get suggestionGap => isCompactLandscape ? 6.0 : 8.0;
  double get suggestionMaxHeight {
    final rawHeight = isMobile
        ? 220.0
        : isTabletDevice
        ? 280.0
        : 300.0;
    final usableHeight = height - 156.0;
    final capFraction = isLandscape ? 0.36 : 0.44;
    return math.max(
      96.0,
      math.min(rawHeight, math.min(usableHeight, height * capFraction)),
    );
  }

  double get searchPanelMaxWidth => isMobile ? double.infinity : 560.0;
  double get bottomPanelMaxWidth => isMobile ? double.infinity : 680.0;
}
