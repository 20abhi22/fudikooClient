import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/screens/tabs/components/restaurantMapCard.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fudikoclient/components/appsearchbar.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/features/map/providers/map_providers.dart';
import 'package:fudikoclient/features/map/services/map_controller_service.dart';
import 'package:fudikoclient/features/map/services/marker_bitmap_service.dart';
import 'package:fudikoclient/features/map/widgets/persistent_google_map.dart';
import 'package:fudikoclient/model/auth/mapplace-model.dart';
import 'package:fudikoclient/model/restaurant/restaurant_filter_model.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/screens/tabs/components/restaurantCard.dart';
import 'package:fudikoclient/screens/tabs/home/addnumberofpeople.dart';
import 'package:fudikoclient/screens/tabs/home/filterbottommodal.dart';
import 'package:fudikoclient/screens/tabs/home/rating.dart';
import 'package:fudikoclient/screens/tabs/home/timebottommodal.dart';
import 'package:fudikoclient/screens/tabs/profile/restaurantProfile.dart';
import 'package:fudikoclient/service/auth/map-service.dart';
import 'package:fudikoclient/service/restaurant/restaurant-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:ui' show lerpDouble;
import 'dart:ui' as ui;

class Home extends ConsumerStatefulWidget {
  final String currentCity;
  final double? currentLat;
  final double? currentLng;

  const Home({
    super.key,
    this.currentCity = "Locating...",
    this.currentLat,
    this.currentLng,
  });

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  late String _currentCity;
  double? _currentLat;
  double? _currentLng;
  bool _hasMapPermission = false;
  bool _isLocationLoading = false;

  Timer? _zoomDebounce;

  bool isClicked = false;
  bool isOpen = false;
  bool isBookingModalOpen = false;
  bool isLoading = false;
  String errorMessage = '';
  RestaurantService restaurantService = RestaurantService();
  List<RestaurantModel> restaurantsList = [];
  List<RestaurantModel> filteredList = [];
  List<RestaurantModel> _restaurantSearchResults = [];
  List<RestaurantModel> _lastNonSearchFilteredList = [];
  final TextEditingController _restaurantSearchController =
      TextEditingController();
  bool _isRestaurantSearchLoading = false;
  bool _showRestaurantSearchDropdown = false;
  bool _ignoreRestaurantSearchChange = false;
  String _restaurantSearchQuery = '';
  int _restaurantSearchRequestId = 0;
  int? selectedDiscountIndex;
  int? selectedTypeIndex;
  double selectedDistance = 10;
  DateTime selectedDateTime = DateTime.now();
  late final MapControllerService _mapControllerService;
  final MarkerBitmapService _markerBitmapService = const MarkerBitmapService();
  String _lastMarkerSignature = '';
  bool _isFilterLoading = false;

  static const String _cacheKeyDiscountIndex = 'cached_filter_discount_index';
  static const String _cacheKeyTypeIndex = 'cached_filter_type_index';
  static const String _cacheKeyDistance = 'cached_filter_distance_km';

  double _mapExpandProgress = 0.0; // 0 = collapsed, 1 = fully expanded
  final GlobalKey _mapPreviewKey = GlobalKey(); // ← add here

  // Separate controller for the collapsed preview so it doesn't
  // conflict with the expanded map controller.
  late final MapControllerService _collapsedMapControllerService;
  late final ProviderSubscription<SelectedLocation?> _locationSubscription;

  @override
  void initState() {
    super.initState();
    _mapControllerService = MapControllerService();
    _collapsedMapControllerService = MapControllerService();
    final sharedLocation = ref.read(selectedLocationProvider);
    _currentCity = sharedLocation?.city ?? widget.currentCity;
    _currentLat = sharedLocation?.latitude ?? widget.currentLat;
    _currentLng = sharedLocation?.longitude ?? widget.currentLng;
    _locationSubscription = ref.listenManual<SelectedLocation?>(
      selectedLocationProvider,
      (previous, next) {
        if (next != null) _applySelectedLocation(next);
      },
    );
    if (_currentLat != null && _currentLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _currentLat == null || _currentLng == null) return;
        ref.read(userLocationProvider.notifier).state = LatLng(
          _currentLat!,
          _currentLng!,
        );
      });
    }
    // _checkLocationPermission();
    _checkLocationPermission().then(
      (_) => _buildUserLocationIcon(),
    ); // ← add this
    selectedDateTime = DateTime.now();
    getAllRestaurtantList();

    // _fetchLocation();
  }

  @override
  void dispose() {
    _locationSubscription.close();
    _restaurantSearchController.dispose();
    _mapControllerService.dispose();
    _collapsedMapControllerService.dispose();
    _zoomDebounce?.cancel();
    super.dispose();
  }

  void _setLocation(String city, double? latitude, double? longitude) {
    final location = SelectedLocation(
      city: city,
      latitude: latitude,
      longitude: longitude,
    );
    _applySelectedLocation(location);
    ref.read(selectedLocationProvider.notifier).state = location;
  }

  void _applySelectedLocation(SelectedLocation location) {
    final hasChanged =
        _currentCity != location.city ||
        _currentLat != location.latitude ||
        _currentLng != location.longitude;
    if (!hasChanged || !mounted) return;

    setState(() {
      _currentCity = location.city;
      _currentLat = location.latitude;
      _currentLng = location.longitude;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final latitude = location.latitude;
      final longitude = location.longitude;
      if (latitude == null || longitude == null) {
        ref.read(userLocationProvider.notifier).state = null;
        return;
      }

      final target = LatLng(latitude, longitude);
      ref.read(userLocationProvider.notifier).state = target;
      if (_mapControllerService.isReady) {
        unawaited(_mapControllerService.animateTo(target, zoom: 15.5));
      }
      if (_collapsedMapControllerService.isReady) {
        unawaited(_collapsedMapControllerService.animateTo(target, zoom: 12.5));
      }
      getAllRestaurtantList();
    });
  }

  Future<void> _buildUserLocationIcon() async {
    const double size = 120; // large canvas to fit the accuracy ring
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Accuracy ring (large semi-transparent circle)
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = const Color(0x22B97A3E), // very transparent orange
    );

    // Thin border ring
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 1,
      Paint()
        ..color = const Color(0x44B97A3E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // White ring around dot
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      10,
      Paint()..color = Colors.white,
    );

    // Orange dot center
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      7,
      Paint()..color = const Color(0xFFB97A3E),
    );

    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final icon = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      width: 120,
      height: 120,
    );

    ref.read(userLocationIconProvider.notifier).state = icon;
  }

  Future<void> _cacheFilterSelection(
    int? discountIndex,
    int? typeIndex,
    double distance,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (discountIndex == null) {
      await prefs.remove(_cacheKeyDiscountIndex);
    } else {
      await prefs.setInt(_cacheKeyDiscountIndex, discountIndex);
    }

    if (typeIndex == null) {
      await prefs.remove(_cacheKeyTypeIndex);
    } else {
      await prefs.setInt(_cacheKeyTypeIndex, typeIndex);
    }

    await prefs.setDouble(_cacheKeyDistance, distance);
  }

  bool get _hasActiveRestaurantSearch =>
      _restaurantSearchQuery.trim().isNotEmpty;

  bool get _shouldShowRestaurantSearchDropdown =>
      _hasActiveRestaurantSearch &&
      (_showRestaurantSearchDropdown || _isRestaurantSearchLoading);

  Future<void> _handleRestaurantSearchChanged(String value) async {
    if (_ignoreRestaurantSearchChange) return;

    final query = value.trim();
    _restaurantSearchQuery = query;

    if (query.isEmpty) {
      _restaurantSearchRequestId++;
      if (!mounted) return;
      setState(() {
        _isRestaurantSearchLoading = false;
        _showRestaurantSearchDropdown = false;
        _restaurantSearchResults = [];
        filteredList = List.of(_lastNonSearchFilteredList);
        errorMessage = '';
      });
      _buildCollapsedMarkers();
      await _refreshMapMarkers();
      return;
    }

    if (_lastNonSearchFilteredList.isEmpty && filteredList.isNotEmpty) {
      _lastNonSearchFilteredList = List.of(filteredList);
    }

    final requestId = ++_restaurantSearchRequestId;
    setState(() {
      _isRestaurantSearchLoading = true;
      _showRestaurantSearchDropdown = true;
      errorMessage = '';
    });

    final response = await restaurantService.searchRestaurants(
      name: query,
      lat: _currentLat,
      lng: _currentLng,
    );

    if (!mounted || requestId != _restaurantSearchRequestId) return;

    final results = response.restaurant;
    setState(() {
      _restaurantSearchResults = results;
      filteredList = results;
      _isRestaurantSearchLoading = false;
      _showRestaurantSearchDropdown = true;
      errorMessage = response.status ? '' : 'Unable to search restaurants';
    });
    _buildCollapsedMarkers();
    await _refreshMapMarkers();
  }

  Future<void> _handleRestaurantSearchSubmitted(String value) async {
    if (_restaurantSearchResults.length == 1) {
      await _selectMainSearchRestaurant(_restaurantSearchResults.first);
      return;
    }

    if (value.trim().isNotEmpty) {
      setState(() => _showRestaurantSearchDropdown = true);
    }
  }

  Future<void> _selectMainSearchRestaurant(RestaurantModel restaurant) async {
    _setRestaurantSearchText(restaurant.name);

    setState(() {
      filteredList = [restaurant];
      _restaurantSearchResults = [restaurant];
      _showRestaurantSearchDropdown = false;
      errorMessage = '';
    });

    _buildCollapsedMarkers();
    await _refreshMapMarkers();

    final position = _restaurantPosition(restaurant);
    if (position != null && _collapsedMapControllerService.isReady) {
      await _collapsedMapControllerService.animateTo(position, zoom: 14.5);
    }
  }

  Future<void> _handleExpandedMapSearchResults(
    List<RestaurantModel> results,
  ) async {
    if (!mounted) return;
    setState(() {
      filteredList = results;
      errorMessage = '';
    });
    _lastMarkerSignature = '';
    _buildCollapsedMarkers();
    await _refreshMapMarkers();
  }

  Future<void> _handleExpandedMapSearchCleared() async {
    if (!mounted) return;
    final restoredList = _lastNonSearchFilteredList.isNotEmpty
        ? _lastNonSearchFilteredList
        : _applyDistanceFilter(restaurantsList, selectedDistance);

    setState(() {
      filteredList = List.of(restoredList);
      errorMessage = '';
    });
    await _clearMapRestaurantSelection();
    _lastMarkerSignature = '';
    _buildCollapsedMarkers();
    await _refreshMapMarkers();
  }

  Future<void> _handleExpandedMapRestaurantSelected(
    RestaurantModel restaurant,
  ) async {
    if (!filteredList.any((item) => item.uuid == restaurant.uuid)) {
      setState(() => filteredList = [restaurant, ...filteredList]);
    }

    _lastMarkerSignature = '';
    await _refreshMapMarkers();
    await _selectMapRestaurant(restaurant);
  }

  LatLng? _restaurantPosition(RestaurantModel restaurant) {
    final lat = double.tryParse(restaurant.lat);
    final lng = double.tryParse(restaurant.lng);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  void _setRestaurantSearchText(String text) {
    _ignoreRestaurantSearchChange = true;
    _restaurantSearchController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _ignoreRestaurantSearchChange = false;
  }

  int? _selectedOfferPercentage() {
    if (selectedDiscountIndex == null) return null;
    if (selectedDiscountIndex! < 0 || selectedDiscountIndex! > 7) {
      return null;
    }
    return (selectedDiscountIndex! + 1) * 10;
  }

  Future<void> getAllRestaurtantList() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final RestaurantListResponse response = await restaurantService
          .getRestaurantList(
            lat: _currentLat,
            lng: _currentLng,
            searchRadiusKm: selectedDistance,
            dateTime: selectedDateTime,
          );
      if (!mounted) return;
      setState(() {
        restaurantsList = response.restaurant;
        filteredList = _applyDistanceFilter(
          response.restaurant,
          selectedDistance,
        );
        if (!_hasActiveRestaurantSearch) {
          _lastNonSearchFilteredList = List.of(filteredList);
        }
        isLoading = false;
        errorMessage = '';
      });
      _buildCollapsedMarkers();
      await _refreshMapMarkers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!mounted) return;

    setState(() {
      _hasMapPermission =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });
  }

  /// Builds simple default Google Maps pins for the collapsed preview.
  /// These are cheap: no async bitmap rendering needed.
  Future<void> _buildCollapsedMarkers() async {
    if (!mounted) return;

    final markers = <Marker>{};
    for (final restaurant in filteredList) {
      if (restaurant.lat.isEmpty || restaurant.lng.isEmpty) continue;
      if (restaurant.offers.isEmpty) continue;

      final bestOffer = restaurant.offers.reduce(
        (a, b) => a.discountPercentage >= b.discountPercentage ? a : b,
      );
      final position = LatLng(
        double.tryParse(restaurant.lat) ?? 0,
        double.tryParse(restaurant.lng) ?? 0,
      );

      final icon = await _markerBitmapService.buildOfferMarker(
        context,
        label: '-${bestOffer.discountPercentage.toStringAsFixed(0)}%',
        isSelected: false,
        isDimmed: false,
        scale: 0.41,
      );

      markers.add(
        Marker(
          markerId: MarkerId(restaurant.uuid),
          position: position,
          icon: icon,
          anchor: const Offset(.5, .94),
          onTap: _expandMap,
        ),
      );
    }

    if (!mounted) return;
    ref.read(collapsedMarkersProvider.notifier).state = markers;
  }

  Future<void> applyFilters(
    int? discountIndex,
    int? typeIndex,
    double distance,
  ) async {
    setState(() {
      selectedDiscountIndex = discountIndex;
      selectedTypeIndex = typeIndex;
      selectedDistance = distance;
      _isFilterLoading = true;
      errorMessage = '';
    });

    await _cacheFilterSelection(discountIndex, typeIndex, distance);

    final types = ["Restaurant", "Cafe", "Cool Bar", "Bar", "Buffet"];
    final bool hasValidTypeIndex =
        typeIndex != null && typeIndex >= 0 && typeIndex < types.length;
    final String? selectedType = hasValidTypeIndex ? types[typeIndex] : null;

    final bool hasLocation = await _ensureFilterLocation();
    if (!hasLocation || _currentLat == null || _currentLng == null) {
      if (!mounted) return;
      setState(() {
        _isFilterLoading = false;
        errorMessage = 'Location is required to apply backend filters';
        filteredList = [];
      });
      return;
    }

    final request = RestaurantFilterRequest(
      lat: _currentLat!,
      lng: _currentLng!,
      searchRadiusKm: distance,
      type: selectedType,
      offerPercentage: _selectedOfferPercentage(),
      dateTime: selectedDateTime,
    );

    try {
      final response = await restaurantService.filterRestaurants(request);
      if (!mounted) return;
      setState(() {
        filteredList = _applyDistanceFilter(response.restaurant, distance);
        if (!_hasActiveRestaurantSearch) {
          _lastNonSearchFilteredList = List.of(filteredList);
        }
        _isFilterLoading = false;
        errorMessage = '';
      });
      _buildCollapsedMarkers();
      await _refreshMapMarkers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFilterLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _applyDateTimeFilter(DateTime dateTime) async {
    setState(() => selectedDateTime = dateTime);
    await applyFilters(
      selectedDiscountIndex,
      selectedTypeIndex,
      selectedDistance,
    );
  }

  void _showFiltersClearedSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: appButtonColor,
        content: const AppText(
          text: 'Filters cleared',
          size: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    final hasActiveFilters =
        selectedDiscountIndex != null ||
        selectedTypeIndex != null ||
        selectedDistance != 10;

    if (hasActiveFilters) {
      await applyFilters(
        selectedDiscountIndex,
        selectedTypeIndex,
        selectedDistance,
      );
    } else {
      await getAllRestaurtantList();
    }
  }

  List<RestaurantModel> _applyDistanceFilter(
    List<RestaurantModel> restaurants,
    double distanceKm,
  ) {
    final List<RestaurantModel> result = distanceKm <= 0
        ? List.of(restaurants)
        : restaurants.where((r) {
            final double? d = r.distance;
            return d != null && d <= distanceKm;
          }).toList();

    result.sort((a, b) {
      final double aD = a.distance ?? double.infinity;
      final double bD = b.distance ?? double.infinity;
      return aD.compareTo(bD);
    });
    return result;
  }

  Future<bool> _ensureFilterLocation() async {
    if (_currentLat != null && _currentLng != null) return true;
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return false;
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });
      ref.read(userLocationProvider.notifier).state = LatLng(
        position.latitude,
        position.longitude,
      ); // ← here
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchLocation() async {
    if (mounted) setState(() => _isLocationLoading = true);
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _currentCity = "Location denied");
        return;
      }
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });
      ref.read(userLocationProvider.notifier).state = LatLng(
        position.latitude,
        position.longitude,
      ); // ← here
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        _setLocation(
          p.locality ?? p.subLocality ?? p.name ?? "Unknown",
          position.latitude,
          position.longitude,
        );
      }
    } catch (e) {
      setState(() => _currentCity = "Unknown");
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  //   Future<void> _expandMap() async {
  //   if (ref.read(mapExpandedProvider)) return;

  //   _mapControllerService.reset();

  //   ref.read(mapExpandedProvider.notifier).state = true;

  //   await _refreshMapMarkers();

  //   // Small delay so map first opens at user location
  //   await Future.delayed(const Duration(milliseconds: 800));

  //   final restaurants = _mapRestaurants;

  //   if (restaurants.isNotEmpty) {
  //     await _mapControllerService.fitRestaurants(
  //       restaurants.map((r) => r.position),
  //     );
  //   }
  // }
  Future<void> _expandMap() async {
    if (ref.read(mapExpandedProvider)) return;
    ref.read(mapExpandedProvider.notifier).state = true;
    try {
      await _refreshMapMarkers();
      if (!mounted) return;

      await Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => _ExpandedMapPage(
            initialCameraPosition: _initialCameraPosition,
            controllerService: _mapControllerService,
            hasMapPermission: _hasMapPermission,
            onClose: () => Navigator.pop(context),
            currentCity: _currentCity,
            currentLat: _currentLat,
            currentLng: _currentLng,
            selectedDateTime: selectedDateTime,
            selectedDiscountIndex: selectedDiscountIndex,
            selectedTypeIndex: selectedTypeIndex,
            selectedDistance: selectedDistance,
            onApplyFilters: applyFilters,
            onApplyDateTime: _applyDateTimeFilter,
            onClearSelectedRestaurant: _clearMapRestaurantSelection,
            onSearchResultsChanged: _handleExpandedMapSearchResults,
            onSearchCleared: _handleExpandedMapSearchCleared,
            onRestaurantSelected: _handleExpandedMapRestaurantSelected,
            onLocationChanged: (city, lat, lng) {
              _setLocation(city, lat, lng);
            },
          ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0.5, 1.0),
              ),
              child: child,
            );
          },
        ),
      );
    } finally {
      if (mounted) _collapseMap();
    }
  }

  Future<void> _refreshMapMarkersWithZoom(double zoom) async {
    if (!ref.read(mapExpandedProvider) || !mounted) return;

    final selectedRestaurant = ref.read(selectedRestaurantProvider);
    final double scale = ((zoom - 10) / 8).clamp(0.3, 1.4);
    final markers = <Marker>{};

    for (final restaurant in filteredList) {
      if (restaurant.lat.isEmpty || restaurant.lng.isEmpty) continue;
      if (restaurant.offers.isEmpty) continue;

      final bestOffer = restaurant.offers.reduce(
        (a, b) => a.discountPercentage >= b.discountPercentage ? a : b,
      );
      final position = LatLng(
        double.tryParse(restaurant.lat) ?? 0,
        double.tryParse(restaurant.lng) ?? 0,
      );
      final isSelected = selectedRestaurant?.uuid == restaurant.uuid;
      final isDimmed = selectedRestaurant != null && !isSelected;

      final icon = await _markerBitmapService.buildOfferMarker(
        context,
        label: '-${bestOffer.discountPercentage.toStringAsFixed(0)}%',
        isSelected: isSelected,
        isDimmed: isDimmed,
        scale: scale,
      );

      markers.add(
        Marker(
          markerId: MarkerId(restaurant.uuid),
          position: position,
          icon: icon,
          anchor: const Offset(.5, .94),
          zIndexInt: isSelected ? 2 : 1,
          onTap: () => _selectMapRestaurant(restaurant),
        ),
      );
    }

    if (!mounted) return;
    ref.read(mapMarkersProvider.notifier).state = markers;
  }

  void _collapseMap() {
    ref.read(selectedRestaurantProvider.notifier).state = null;
    ref.read(mapExpandedProvider.notifier).state = false;
    ref.read(mapMarkersProvider.notifier).state = const <Marker>{};
    _lastMarkerSignature = '';
  }

  // List<map_feature.Restaurant> get _mapRestaurants {
  //   return filteredList
  //       .where((r) => r.lat.isNotEmpty && r.lng.isNotEmpty)
  //       .map(map_feature.Restaurant.fromLegacy)
  //       .toList(growable: false);
  // }

  Future<void> _refreshMapMarkers() async {
    if (!ref.read(mapExpandedProvider) || !mounted) return;

    final zoom = ref.read(mapZoomProvider);
    final double scale = ((zoom - 10) / 8).clamp(0.3, 1.4);
    final selectedRestaurant = ref.read(selectedRestaurantProvider);

    final signature = filteredList
        .where((r) => r.offers.isNotEmpty)
        .map((r) {
          final best = r.offers.reduce(
            (a, b) => a.discountPercentage >= b.discountPercentage ? a : b,
          );
          return '${r.uuid}:${best.discountPercentage}:${selectedRestaurant?.uuid}';
        })
        .join('|');

    if (signature == _lastMarkerSignature) return;
    _lastMarkerSignature = signature;

    final markers = <Marker>{};
    for (final restaurant in filteredList) {
      if (restaurant.lat.isEmpty || restaurant.lng.isEmpty) continue;
      if (restaurant.offers.isEmpty) continue;

      final bestOffer = restaurant.offers.reduce(
        (a, b) => a.discountPercentage >= b.discountPercentage ? a : b,
      );
      final position = LatLng(
        double.tryParse(restaurant.lat) ?? 0,
        double.tryParse(restaurant.lng) ?? 0,
      );
      final isSelected = selectedRestaurant?.uuid == restaurant.uuid;
      final isDimmed = selectedRestaurant != null && !isSelected;

      final icon = await _markerBitmapService.buildOfferMarker(
        context,
        label: '-${bestOffer.discountPercentage.toStringAsFixed(0)}%',
        isSelected: isSelected,
        isDimmed: isDimmed,
        scale: scale,
      );

      markers.add(
        Marker(
          markerId: MarkerId(restaurant.uuid),
          position: position,
          icon: icon,
          anchor: const Offset(.5, .94),
          zIndexInt: isSelected ? 2 : 1,
          onTap: () => _selectMapRestaurant(restaurant),
        ),
      );
    }

    if (!mounted) return;
    ref.read(mapMarkersProvider.notifier).state = markers;
  }

  Future<void> _selectMapRestaurant(RestaurantModel restaurant) async {
    ref.read(selectedRestaurantProvider.notifier).state = restaurant;
    _lastMarkerSignature = '';
    await _refreshMapMarkers();
    await _mapControllerService.focusRestaurant(
      LatLng(
        double.tryParse(restaurant.lat) ?? 0,
        double.tryParse(restaurant.lng) ?? 0,
      ),
    );
  }

  Future<void> _clearMapRestaurantSelection() async {
    if (ref.read(selectedRestaurantProvider) == null) return;

    ref.read(selectedRestaurantProvider.notifier).state = null;
    _lastMarkerSignature = '';
    await _refreshMapMarkers();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(mapZoomProvider, (previous, next) {
      if (previous == next) return;
      _zoomDebounce?.cancel();
      _zoomDebounce = Timer(const Duration(milliseconds: 300), () {
        _lastMarkerSignature = '';
        _refreshMapMarkersWithZoom(next);
      });
    });
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final isCompactLandscape = isLandscape && size.height < 500;
    final double filterHeaderHeight = isLandscape
        ? (isCompactLandscape ? 56.h : 62.h)
        : 72.h;
    final bool isMapExpanded = ref.watch(mapExpandedProvider);
    final RestaurantModel? selectedMapRestaurant = ref.watch(
      selectedRestaurantProvider,
    );
    final collapsedMarkers = ref.watch(collapsedMarkersProvider);

    if (isLandscape) {
      return Scaffold(
        backgroundColor: const Color(0xfffdf8f5),
        body: SafeArea(
          child: RefreshIndicator(
            color: appButtonColor,
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: isCompactLandscape ? 10.h : 14.h,
                    ),
                    child: AppSearchBar(
                      city: _currentCity,
                      isLocationLoading: _isLocationLoading,
                      searchController: _restaurantSearchController,
                      searchHintText: 'Search restaurants...',
                      onSearchChanged: _handleRestaurantSearchChanged,
                      onSearchSubmitted: _handleRestaurantSearchSubmitted,
                      onLocationTap: _showLocationPicker,
                    ),
                  ),
                ),
                if (_shouldShowRestaurantSearchDropdown)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18.w),
                      child: _RestaurantSearchDropdown(
                        query: _restaurantSearchQuery,
                        restaurants: _restaurantSearchResults,
                        isLoading: _isRestaurantSearchLoading,
                        onSelected: (restaurant) {
                          FocusScope.of(context).unfocus();
                          unawaited(_selectMainSearchRestaurant(restaurant));
                        },
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: _discountBuilder()),
                SliverToBoxAdapter(
                  child: _collapsedMapPreview(collapsedMarkers),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Center(child: _dropDownBuilder()),
                  ),
                ),
                if (isLoading || _isFilterLoading)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220.h,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (errorMessage.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 220.h,
                      child: Center(
                        child: AppText(
                          text: 'Error: $errorMessage',
                          size: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  )
                else if (filteredList.isEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 260.h,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off,
                              size: 60,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10.h),
                            AppText(
                              text: "No restaurants found",
                              size: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10.h),
                            GestureDetector(
                              onTap: () {
                                _setRestaurantSearchText('');
                                setState(() {
                                  filteredList = restaurantsList;
                                  _lastNonSearchFilteredList = List.of(
                                    filteredList,
                                  );
                                  _restaurantSearchResults = [];
                                  _restaurantSearchQuery = '';
                                  _showRestaurantSearchDropdown = false;
                                  selectedDiscountIndex = null;
                                  selectedTypeIndex = null;
                                  selectedDistance = 10;
                                });
                                _showFiltersClearedSnackBar();
                                _buildCollapsedMarkers();
                              },
                              child: AppText(
                                text: "Clear filters",
                                size: 14,
                                fontWeight: FontWeight.w500,
                                color: appTextColor3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((
                      context,
                      index,
                    ) {
                      final restaurant = filteredList[index];
                      return InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestaurantProfile(
                                uuid: restaurant.uuid,
                                deliveryServiceArea:
                                    restaurant.deliveryServiceArea,
                                averageReview: restaurant.averageReview,
                                distance: restaurant.distance,
                                isFavourite: restaurant.isFavorite,
                              ),
                            ),
                          );
                          if (result is bool) {
                            if (!mounted) return;
                            setState(() {
                              restaurantsList = restaurantsList
                                  .map(
                                    (r) => r.uuid == restaurant.uuid
                                        ? r.copyWith(isFavorite: result)
                                        : r,
                                  )
                                  .toList();
                              filteredList = filteredList
                                  .map(
                                    (r) => r.uuid == restaurant.uuid
                                        ? r.copyWith(isFavorite: result)
                                        : r,
                                  )
                                  .toList();
                            });
                          }
                        },
                        child: RestaurantCard(
                          uuid: restaurant.uuid,
                          name: restaurant.name,
                          type: restaurant.type,
                          address: restaurant.address,
                          phone: restaurant.phone,
                          lat: restaurant.lat,
                          lng: restaurant.lng,
                          description: restaurant.description,
                          availableDishes: restaurant.availableDishes,
                          takeAwayService: restaurant.takeAwayService,
                          deliveryService: restaurant.deliveryService,
                          deliveryServiceArea: restaurant.deliveryServiceArea,
                          averageReview: restaurant.averageReview,
                          distance: restaurant.distance,
                          restaurantType: restaurant.restaurantType,
                          status: restaurant.status,
                          isFavourite: restaurant.isFavorite,
                          image: restaurant.image,
                          offers: restaurant.offers,
                          onRatingOnClick: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RatingPage(
                                restaurantId: restaurant.uuid,
                                restaurantName: restaurant.name,
                                restaurantAddress: restaurant.address,
                              ),
                            ),
                          ),
                          onBoxClicked: (String? offerId, OfferModel? offer) {
                            final selectedOffers = restaurant.offers
                                .where((offer) => offer.uuid == offerId)
                                .toList();
                            setState(
                              () => isBookingModalOpen = !isBookingModalOpen,
                            );
                            if (isBookingModalOpen) {
                              showModalBottomSheet(
                                backgroundColor: Colors.white,
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(25),
                                  ),
                                ),
                                builder: (_) => NumberOfPeopleModal(
                                  uuid: restaurant.uuid,
                                  reservationDate: selectedDateTime,
                                  offerId: offerId,
                                  offer:
                                      offer ??
                                      (selectedOffers.isEmpty
                                          ? null
                                          : selectedOffers.first),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    }, childCount: filteredList.length),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfffdf8f5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Search bar stays fixed at top.
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 18.w : 30.w,
                    vertical: isLandscape
                        ? (isCompactLandscape ? 10.h : 14.h)
                        : 25.h,
                  ),
                  child: AppSearchBar(
                    city: _currentCity,
                    isLocationLoading: _isLocationLoading,
                    searchController: _restaurantSearchController,
                    searchHintText: 'Search restaurants...',
                    onSearchChanged: _handleRestaurantSearchChanged,
                    onSearchSubmitted: _handleRestaurantSearchSubmitted,
                    onLocationTap: _showLocationPicker,
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    color: appButtonColor,
                    onRefresh: _handleRefresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        // Discount cards
                        SliverToBoxAdapter(child: _discountBuilder()),

                        SliverToBoxAdapter(
                          child: _collapsedMapPreview(collapsedMarkers),
                        ),

                        // Filter row: sticky
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _FilterHeaderDelegate(
                            child: Container(
                              color: const Color(0xfffdf8f5),
                              child: SizedBox(
                                height: filterHeaderHeight,
                                child: _dropDownBuilder(),
                              ),
                            ),
                            height: filterHeaderHeight,
                          ),
                        ),

                        // Restaurant list
                        if (isLoading || _isFilterLoading)
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 220.h,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          )
                        else if (errorMessage.isNotEmpty)
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 220.h,
                              child: Center(
                                child: AppText(
                                  text: 'Error: $errorMessage',
                                  size: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          )
                        else if (filteredList.isEmpty)
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 260.h,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.search_off,
                                      size: 60,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 10.h),
                                    AppText(
                                      text: "No restaurants found",
                                      size: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 10.h),
                                    GestureDetector(
                                      onTap: () {
                                        _setRestaurantSearchText('');
                                        setState(() {
                                          filteredList = restaurantsList;
                                          _lastNonSearchFilteredList = List.of(
                                            filteredList,
                                          );
                                          _restaurantSearchResults = [];
                                          _restaurantSearchQuery = '';
                                          _showRestaurantSearchDropdown = false;
                                          selectedDiscountIndex = null;
                                          selectedTypeIndex = null;
                                          selectedDistance = 10;
                                        });
                                        _showFiltersClearedSnackBar();
                                        _buildCollapsedMarkers();
                                      },
                                      child: AppText(
                                        text: "Clear filters",
                                        size: 14,
                                        fontWeight: FontWeight.w500,
                                        color: appTextColor3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final restaurant = filteredList[index];
                              return InkWell(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RestaurantProfile(
                                        uuid: restaurant.uuid,
                                        deliveryServiceArea:
                                            restaurant.deliveryServiceArea,
                                        averageReview: restaurant.averageReview,
                                        distance: restaurant.distance,
                                        isFavourite: restaurant.isFavorite,
                                      ),
                                    ),
                                  );
                                  if (result is bool) {
                                    if (!mounted) return;
                                    setState(() {
                                      restaurantsList = restaurantsList
                                          .map(
                                            (r) => r.uuid == restaurant.uuid
                                                ? r.copyWith(isFavorite: result)
                                                : r,
                                          )
                                          .toList();
                                      filteredList = filteredList
                                          .map(
                                            (r) => r.uuid == restaurant.uuid
                                                ? r.copyWith(isFavorite: result)
                                                : r,
                                          )
                                          .toList();
                                    });
                                  }
                                },
                                child: RestaurantCard(
                                  uuid: restaurant.uuid,
                                  name: restaurant.name,
                                  type: restaurant.type,
                                  address: restaurant.address,
                                  phone: restaurant.phone,
                                  lat: restaurant.lat,
                                  lng: restaurant.lng,
                                  description: restaurant.description,
                                  availableDishes: restaurant.availableDishes,
                                  takeAwayService: restaurant.takeAwayService,
                                  deliveryService: restaurant.deliveryService,
                                  deliveryServiceArea:
                                      restaurant.deliveryServiceArea,
                                  averageReview: restaurant.averageReview,
                                  distance: restaurant.distance,
                                  restaurantType: restaurant.restaurantType,
                                  status: restaurant.status,
                                  isFavourite: restaurant.isFavorite,
                                  image: restaurant.image,
                                  offers: restaurant.offers,
                                  onRatingOnClick: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RatingPage(
                                        restaurantId: restaurant.uuid,
                                        restaurantName: restaurant.name,
                                        restaurantAddress: restaurant.address,
                                      ),
                                    ),
                                  ),
                                  onBoxClicked:
                                      (String? offerId, OfferModel? offer) {
                                        final selectedOffers = restaurant.offers
                                            .where(
                                              (offer) => offer.uuid == offerId,
                                            )
                                            .toList();
                                        setState(
                                          () => isBookingModalOpen =
                                              !isBookingModalOpen,
                                        );
                                        if (isBookingModalOpen) {
                                          showModalBottomSheet(
                                            backgroundColor: Colors.white,
                                            context: context,
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(25),
                                                  ),
                                            ),
                                            builder: (_) => NumberOfPeopleModal(
                                              uuid: restaurant.uuid,
                                              reservationDate: selectedDateTime,
                                              offerId: offerId,
                                              offer:
                                                  offer ??
                                                  (selectedOffers.isEmpty
                                                      ? null
                                                      : selectedOffers.first),
                                            ),
                                          );
                                        }
                                      },
                                ),
                              );
                            }, childCount: filteredList.length),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (_shouldShowRestaurantSearchDropdown)
              Positioned(
                top: 25.h + 68.h,
                left: 30.w,
                right: 30.w,
                child: _RestaurantSearchDropdown(
                  query: _restaurantSearchQuery,
                  restaurants: _restaurantSearchResults,
                  isLoading: _isRestaurantSearchLoading,
                  onSelected: (restaurant) {
                    FocusScope.of(context).unfocus();
                    unawaited(_selectMainSearchRestaurant(restaurant));
                  },
                ),
              ),

            // if (isMapExpanded) _expandedMapOverlay(),

            // if (isMapExpanded)
            //   Positioned(
            //     left: 16.w,
            //     top: MediaQuery.paddingOf(context).top + 16.h,
            //     child: Material(
            //       color: Colors.white,
            //       shape: const CircleBorder(),
            //       elevation: 8,
            //       shadowColor: const Color(0x26000000),
            //       child: IconButton(
            //         onPressed: _collapseMap,
            //         icon: const Icon(Icons.close_rounded),
            //       ),
            //     ),
            //   ),

            // if (isMapExpanded && selectedMapRestaurant != null)
            //   RestaurantBottomSheet(restaurant: selectedMapRestaurant),
          ],
        ),
      ),
    );
  }

  CameraPosition get _initialCameraPosition {
    return CameraPosition(
      target: LatLng(_currentLat ?? 10.8505, _currentLng ?? 76.2711),
      zoom: _currentLat == null ? 7.4 : 15.5,
    );
  }

  CameraPosition get _collapsedMapCameraPosition {
    return CameraPosition(
      target: LatLng(_currentLat ?? 10.8505, _currentLng ?? 76.2711),
      zoom: _currentLat == null ? 10 : 12.5,
    );
  }

  // Replace _collapsedMapPreview with this:
  Widget _collapsedMapPreview(Set<Marker> collapsedMarkers) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    final isCompactLandscape = isLandscape && size.height < 500;
    final isWideShortPhone =
        !Breakpoints.isTabletDevice(size) &&
        size.width >= 500 &&
        size.height <= 760;
    final previewHeight = isCompactLandscape
      ? 72.0
      : isWideShortPhone
      ? 82.0
      : 100.h;

    return Padding(
      key: _mapPreviewKey,
      padding: EdgeInsets.symmetric(
        horizontal: isCompactLandscape
            ? 16.0
            : isWideShortPhone
            ? 28.0
            : 20.w,
        vertical: isCompactLandscape
            ? 10.0
            : isWideShortPhone
            ? 14.0
            : 20.h,
      ),
      child: Hero(
        tag: 'map-expand',
        flightShuttleBuilder: (_, animation, __, fromContext, ___) {
          // During flight: animate the border radius from rounded → 0
          return AnimatedBuilder(
            animation: animation,
            builder: (_, __) {
              final radius = Tween<double>(begin: 20, end: 0).evaluate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                ),
              );
              return Material(
                color: Colors.black,
                borderRadius: BorderRadius.circular(radius),
                clipBehavior: Clip.antiAlias,
                child: Container(color: Colors.black87),
              );
            },
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.25),
                  offset: const Offset(0, 0), // X = 0, Y = 0
                  blurRadius: 15, // Blur = 15
                  spreadRadius: 0, // Spread = 0
                ),
              ],
              borderRadius: BorderRadius.circular(18.r),
            ),
            height: previewHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (kIsWeb)
                  _staticCollapsedMapPreview()
                else
                  PersistentGoogleMap(
                    key: const ValueKey('home-collapsed-google-map'),
                    initialCameraPosition: _collapsedMapCameraPosition,
                    controllerService: _collapsedMapControllerService,
                    onMapTap: _expandMap,
                    gesturesEnabled: false,
                    overrideMarkers: collapsedMarkers,
                    showMyLocation: _hasMapPermission,
                  ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(onTap: _expandMap),
                  ),
                ),
                if (!kIsWeb)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _expandMap,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _staticCollapsedMapPreview() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFE7DE), Color(0xFFDDEAD6)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 22,
            top: 16,
            child: _mapPreviewPin(const Color(0xFFF87B0D), 16),
          ),
          Positioned(
            right: 34,
            top: 24,
            child: _mapPreviewPin(const Color(0xFF417629), 12),
          ),
          Positioned(
            left: 110,
            bottom: 16,
            child: _mapPreviewPin(const Color(0xFFF87B0D), 10),
          ),
          Center(
            child: Icon(
              Icons.map_outlined,
              color: appButtonColor.withValues(alpha: 0.7),
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapPreviewPin(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
      ),
    );
  }

  Widget _expandedMapOverlay() {
    // Grab the card's position on screen
    Rect cardRect = Rect.fromLTWH(
      20.w,
      0,
      MediaQuery.sizeOf(context).width - 40.w,
      90.h,
    );
    final RenderObject? ro = _mapPreviewKey.currentContext?.findRenderObject();
    if (ro is RenderBox && ro.hasSize) {
      final Offset topLeft = ro.localToGlobal(Offset.zero);
      cardRect = topLeft & ro.size;
    }

    final Size screen = MediaQuery.sizeOf(context);
    final Rect fullRect = Rect.fromLTWH(0, 0, screen.width, screen.height);

    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
        onEnd: () {
          if (mounted) setState(() => _mapExpandProgress = 1.0);
        },
        builder: (context, value, child) {
          // Sync progress for fading the collapsed preview
          if ((_mapExpandProgress - value).abs() > 0.01) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _mapExpandProgress = value);
            });
          }

          // Interpolate from card rect → full screen
          final Rect animRect = Rect.lerp(cardRect, fullRect, value)!;
          // Border radius 20 → 0
          final double radius = lerpDouble(20.r, 0, value)!;

          return Stack(
            children: [
              Positioned(
                left: animRect.left,
                top: animRect.top,
                width: animRect.width,
                height: animRect.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: Opacity(
                    opacity: value.clamp(0.3, 1.0), // start slightly visible
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
        child: PersistentGoogleMap(
          key: const ValueKey('home-expanded-google-map'),
          initialCameraPosition: _initialCameraPosition,
          controllerService: _mapControllerService,
          onMapTap: _expandMap,
          showMyLocation: _hasMapPermission,
        ),
      ),
    );
  }

  Widget _dropDownBuilder() {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    // Device-class decision (chip padding/icon/text sizes, sheet width
    // cap) — use shortest side so a phone rotated to landscape keeps
    // phone-sized chips instead of jumping to tablet sizing.
    final isTablet = Breakpoints.isTabletDevice(size);
    final isCompactPhone = width < 390 || height < 700;
    final tabletSheetWidth = width * 0.88;
    final chipHorizontalPadding = isTablet ? 16.0 : 14.w;
    final chipVerticalPadding = isTablet ? 11.0 : 10.h;
    final chipIconSize = isTablet ? 18.0 : 15.w;
    final chipTextSize = isTablet
        ? 13.0
        : isCompactPhone
        ? 10.0
        : 10.sp;
    final dateTextSize = isTablet
        ? 14.0
        : isCompactPhone
        ? 12.0
        : 13.sp;
    final chipGap = isTablet ? 12.0 : 10.w;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                backgroundColor: Colors.white,
                context: context,
                isScrollControlled: true,
                constraints: isTablet
                    ? BoxConstraints(
                        minWidth: tabletSheetWidth,
                        maxWidth: tabletSheetWidth,
                      )
                    : null,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                builder: (context) => FilterBottomModal(
                  onApply: applyFilters,
                  initialDiscountIndex: selectedDiscountIndex,
                  initialTypeIndex: selectedTypeIndex,
                  initialDistance: selectedDistance,
                  onClear: _showFiltersClearedSnackBar,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: chipHorizontalPadding,
                vertical: chipVerticalPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.10),
                    offset: const Offset(0, 0),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    filterIcon,
                    width: chipIconSize,
                    height: chipIconSize,
                    color: Colors.black87,
                  ),
                  SizedBox(width: 6.w),
                  AppText(
                    text: "Filter",
                    size: chipTextSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87.withValues(alpha: 0.8),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: isTablet ? 18.0 : 16.w,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: chipGap),

          Flexible(
            fit: FlexFit.loose,
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  backgroundColor: Colors.white,
                  context: context,
                  isScrollControlled: true,
                  constraints: isTablet
                      ? BoxConstraints(
                          minWidth: tabletSheetWidth,
                          maxWidth: tabletSheetWidth,
                        )
                      : null,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  builder: (context) => TimeBottomModal(
                    initialDateTime: selectedDateTime,
                    onApply: _applyDateTimeFilter,
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: chipHorizontalPadding,
                  vertical: chipVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.10),
                      offset: const Offset(0, 0),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          filtercalenderIcon,
                          width: chipIconSize,
                          height: chipIconSize,
                          color: Colors.black87,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: AppText(
                            text:
                                "${DateFormat('d MMM').format(selectedDateTime)} at ${DateFormat('h:mma').format(selectedDateTime)}",
                            size: dateTextSize,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87.withValues(alpha: 0.8),

                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: isTablet ? 18.0 : 16.w,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _discountBuilder() {
    final colors = [
      {'color2': const Color(0xFF6CCB3F), 'color1': const Color(0XFF36651F)},
      {'color2': const Color(0xFF3FB2CB), 'color1': const Color(0xFF1F5965)},
      {'color2': const Color(0xFF9E3FCB), 'color1': const Color(0xFF4F1F65)},
      {'color2': const Color(0xFFCBAC3F), 'color1': const Color(0xFF65561F)},
    ];
    final discountDetails = [
      {
        'offer_range': "10%-20%",
        'discount_tag': "assets/images/discount_tag1.png",
      },
      {
        'offer_range': "20%-30%",
        'discount_tag': "assets/images/discount_tag2.png",
      },
      {
        'offer_range': "30%-40%",
        'discount_tag': "assets/images/discount_tag3.png",
      },
      {
        'offer_range': "40%-50%",
        'discount_tag': "assets/images/discount_tag4.png",
      },
    ];

    final size = MediaQuery.sizeOf(context);
    // Device-class decision (card size, strip height) — shortest side, not
    // raw width. This also un-blocks isWideShortPhone below: previously
    // isTablet was already (wrongly) true for landscape phones, so the
    // isWideShortPhone branch built for exactly that case could never run.
    final isLandscape = size.width > size.height;
    final isCompactLandscape = isLandscape && size.height < 500;
    final isTablet = Breakpoints.isTabletDevice(size);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;
    final stripHeight = isTablet
      ? (isLandscape ? 184.0 : 210.0)
      : isCompactLandscape
      ? 118.0
        : isWideShortPhone
      ? 150.0
        : isCompactPhone
      ? 138.0
        : 180.h;
    final cardWidth = isTablet
      ? (isLandscape ? 138.0 : 150.0)
      : isCompactLandscape
      ? 92.0
        : isWideShortPhone
      ? 150.0
        : isCompactPhone
      ? 96.0
        : 120.w;
    final cardHeight = isTablet
      ? (isLandscape ? 170.0 : 200.0)
      : isCompactLandscape
      ? 110.0
        : isWideShortPhone
      ? 136.0
        : isCompactPhone
      ? 130.0
        : 180.h;
    final cardGap = isTablet
      ? (isLandscape ? 5.0 : 8.0)
      : isCompactLandscape
      ? 3.0
        : isWideShortPhone
      ? 4.0
        : isCompactPhone
        ? 4.0
        : 5.w;
    final radius = isTablet
      ? (isLandscape ? 18.0 : 22.0)
      : isCompactLandscape
      ? 14.0
        : isWideShortPhone
      ? 16.0
        : isCompactPhone
        ? 16.0
        : 20.0;
    final borderWidth = isTablet
      ? (isLandscape ? 1.5 : 2.0)
      : isCompactLandscape
      ? 1.25
        : isWideShortPhone
        ? 1.5
        : isCompactPhone
        ? 1.5
        : 2.w;
    final offerTextSize = isTablet
      ? (isLandscape ? 20.0 : 22.0)
      : isCompactLandscape
      ? 15.0
        : isWideShortPhone
      ? 19.0
        : isCompactPhone
        ? 16.0
        : 20.sp;
    final discountTextSize = isTablet
      ? (isLandscape ? 17.0 : 19.0)
      : isCompactLandscape
      ? 12.5
        : isWideShortPhone
      ? 17.0
        : isCompactPhone
        ? 14.5
        : 18.sp;
    final tagSize = isTablet
      ? (isLandscape ? 64.0 : 82.0)
      : isCompactLandscape
      ? 42.0
        : isWideShortPhone
      ? 52.0
        : isCompactPhone
      ? 48.0
        : 70.w;

    Widget buildDiscountCard(int index) {
      final color1 = colors[index]['color1']!;
      final color2 = colors[index]['color2']!;
      final filterDiscountIndex = index;
      final isSelected = selectedDiscountIndex == filterDiscountIndex;

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: cardGap),
        child: GestureDetector(
          onTap: _isFilterLoading
              ? null
              : () => applyFilters(
                  isSelected ? null : filterDiscountIndex,
                  selectedTypeIndex,
                  selectedDistance,
                ),
          child: Container(
            height: cardHeight,
            width: cardWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: isSelected ? appButtonColor : Colors.transparent,
                width: borderWidth,
              ),
              gradient: LinearGradient(
                colors: [color1, color2],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/boxbg.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompactLandscape ? 6.0 : isCompactPhone ? 8.0 : 10.0,
                    vertical: isCompactLandscape
                        ? 6.0
                        : isWideShortPhone
                        ? 8.0
                        : isCompactPhone
                        ? 10.0
                        : 14.0,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: cardWidth - 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AppText(
                            text: discountDetails[index]['offer_range']!,
                            size: offerTextSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            maxLines: 1,
                            isboxShadow: const [
                              BoxShadow(
                                color: Color(0x4D000000),
                                offset: Offset(0, 3),
                                blurRadius: 5,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          SizedBox(height: isCompactLandscape ? 1.0 : isCompactPhone ? 2.0 : 4.0),
                          AppText(
                            text: "Discount",
                            size: discountTextSize,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            maxLines: 1,
                          ),
                          SizedBox(
                            height: isCompactLandscape
                                ? 2.0
                                : isWideShortPhone
                                ? 4.0
                                : isCompactPhone
                                ? 4.0
                                : 8.0,
                          ),
                          Image.asset(
                            discountDetails[index]['discount_tag']!,
                            height: tagSize,
                            width: tagSize,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: stripHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalCardWidth = colors.length * (cardWidth + cardGap * 2);

          if ((isTablet || isLandscape) && totalCardWidth <= constraints.maxWidth) {
            return Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(colors.length, buildDiscountCard),
              ),
            );
          }

          return ListView.builder(
            itemCount: colors.length,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) => buildDiscountCard(index),
          );
        },
      ),
    );
  }

  Future<void> _showLocationPicker() async {
    final MapService mapService = MapService();
    List<MapPlacesResponse> locations = [];
    bool isSearchLoading = false;
    final TextEditingController searchController = TextEditingController();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTabletSheet = Breakpoints.isTabletDevice(MediaQuery.sizeOf(context));
    final tabletSheetWidth = screenWidth * 0.88;

    // Debounce timer
    Timer? _debounce; // 👈 add: import 'dart:async';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: isTabletSheet
          ? BoxConstraints(
              minWidth: tabletSheetWidth,
              maxWidth: tabletSheetWidth,
            )
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final deviceSize = MediaQuery.sizeOf(context);
                final width = constraints.maxWidth;
                final height = deviceSize.height;
                // Device-class decision for padding/font/icon sizes inside
                // the sheet — shortest side of the actual device, not the
                // sheet's own (possibly capped) width.
                final isTablet = Breakpoints.isTabletDevice(deviceSize);
                final isCompactPhone = width < 390 || height < 700;
                final sheetHorizontalPadding = isTablet
                    ? width * 0.06
                    : isCompactPhone
                    ? 16.0
                    : 20.0;
                final titleSize = isTablet
                    ? AppDimensions.title(context)
                    : isCompactPhone
                    ? 16.0
                    : 18.0;
                final actionTextSize = isTablet
                    ? AppDimensions.body(context)
                    : isCompactPhone
                    ? 13.0
                    : 14.0;
                final subtitleSize = isTablet
                    ? AppDimensions.caption(context)
                    : isCompactPhone
                    ? 11.0
                    : 12.0;
                final iconSize = isTablet
                    ? 22.0
                    : isCompactPhone
                    ? 18.0
                    : 20.0;
                final topGap = isTablet ? 20.0 : 16.h;
                final innerGap = isTablet ? 18.0 : 16.h;
                // Cap the sheet's own content height to a fraction of the
                // real screen height instead of letting it grow unbounded —
                // short landscape viewports (~350-450px) can't fit an
                // unconstrained results list otherwise (checklist item #5).
                final maxSheetContentHeight = deviceSize.height * 0.85;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxSheetContentHeight),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                      left: sheetHorizontalPadding,
                      right: sheetHorizontalPadding,
                      top: topGap,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isTablet ? 48.0 : 40.w,
                          height: isTablet ? 5.0 : 4.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: innerGap),
                        AppText(
                          text: "Select Location",
                          size: titleSize,
                          fontWeight: FontWeight.w600,
                          color: appTextColor3,
                        ),
                        SizedBox(height: innerGap),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _fetchLocation();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 18.0 : 16.w,
                              vertical: isTablet ? 14.0 : 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: appButtonColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.my_location,
                                  color: appButtonColor,
                                  size: iconSize,
                                ),
                                SizedBox(width: isTablet ? 12.0 : 10.w),
                                AppText(
                                  text: "Use current location",
                                  size: actionTextSize,
                                  fontWeight: FontWeight.w500,
                                  color: appButtonColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: innerGap),
                        TextField(
                          controller: searchController,
                          style: TextStyle(fontSize: actionTextSize),
                          decoration: InputDecoration(
                            hintText: "Search location...",
                            hintStyle: TextStyle(fontSize: actionTextSize),
                            prefixIcon: Icon(
                              Icons.search,
                              color: appTextColor3,
                              size: iconSize,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          onChanged: (val) {
                            _debounce?.cancel();
                            if (val.length < 2) {
                              setModalState(() => locations = []);
                              return;
                            }
                            _debounce = Timer(
                              const Duration(milliseconds: 400),
                              () async {
                                setModalState(() => isSearchLoading = true);
                                final response = await mapService.listPlaces(
                                  val,
                                  lat: _currentLat,
                                  lng: _currentLng,
                                );
                                setModalState(() {
                                  locations = response;
                                  isSearchLoading = false;
                                });
                              },
                            );
                          },
                        ),
                        SizedBox(height: isTablet ? 12.0 : 10.h),
                        if (isSearchLoading)
                          Padding(
                            padding: EdgeInsets.all(isTablet ? 18.0 : 16.h),
                            child: const CircularProgressIndicator(),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: locations.length,
                            itemBuilder: (context, index) {
                              final place = locations[index];
                              return ListTile(
                                leading: Icon(
                                  Icons.location_on,
                                  color: appTextColor3,
                                  size: iconSize,
                                ),
                                title: Text(
                                  place.mainText ?? '',
                                  style: TextStyle(fontSize: actionTextSize),
                                ),
                                subtitle: Text(
                                  place.secondaryText ?? '',
                                  style: TextStyle(
                                    fontSize: subtitleSize,
                                    color: Colors.grey,
                                  ),
                                ),
                                onTap: () async {
                                  final placeId = place.placeId ?? '';
                                  try {
                                    final coords = await mapService.getPlace(
                                      placeId,
                                    );
                                    if (!mounted) return;
                                    _setLocation(
                                      place.mainText ?? '',
                                      coords.lat,
                                      coords.lng,
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    _setLocation(
                                      place.mainText ?? '',
                                      null,
                                      null,
                                    );
                                  }
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                        SizedBox(height: isTablet ? 24.0 : 20.h),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    _debounce?.cancel(); // clean up on sheet close
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _FilterHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_FilterHeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}

// ─── Replace _ExpandedMapPage class ──────────────────────────────────────────
class _ExpandedMapPage extends ConsumerStatefulWidget {
  final CameraPosition initialCameraPosition;
  final MapControllerService controllerService;
  final bool hasMapPermission;
  final VoidCallback onClose;
  final String currentCity;
  final double? currentLat;
  final double? currentLng;
  final DateTime? selectedDateTime;
  final int? selectedDiscountIndex;
  final int? selectedTypeIndex;
  final double selectedDistance;
  final Future<void> Function(int?, int?, double) onApplyFilters;
  final Future<void> Function(DateTime) onApplyDateTime;
  final Future<void> Function() onClearSelectedRestaurant;
  final Future<void> Function(List<RestaurantModel>) onSearchResultsChanged;
  final Future<void> Function() onSearchCleared;
  final Future<void> Function(RestaurantModel) onRestaurantSelected;
  // Callback so Home stays in sync when user picks a new location on the map
  final void Function(String city, double? lat, double? lng) onLocationChanged;

  const _ExpandedMapPage({
    required this.initialCameraPosition,
    required this.controllerService,
    required this.hasMapPermission,
    required this.onClose,
    required this.currentCity,
    required this.currentLat,
    required this.currentLng,
    required this.selectedDateTime,
    required this.selectedDiscountIndex,
    required this.selectedTypeIndex,
    required this.selectedDistance,
    required this.onApplyFilters,
    required this.onApplyDateTime,
    required this.onClearSelectedRestaurant,
    required this.onSearchResultsChanged,
    required this.onSearchCleared,
    required this.onRestaurantSelected,
    required this.onLocationChanged,
  });

  @override
  ConsumerState<_ExpandedMapPage> createState() => _ExpandedMapPageState();
}

class _ExpandedMapPageState extends ConsumerState<_ExpandedMapPage> {
  final RestaurantService _restaurantService = RestaurantService();
  final TextEditingController _restaurantSearchController =
      TextEditingController();
  late String _city;
  late double? _lat;
  late double? _lng;
  late DateTime _selectedDateTime;
  late int? _selectedDiscountIndex;
  late int? _selectedTypeIndex;
  late double _selectedDistance;
  bool _isLocationLoading = false;
  bool _isRestaurantSearchLoading = false;
  bool _showRestaurantSearchDropdown = false;
  bool _ignoreRestaurantSearchChange = false;
  String _restaurantSearchQuery = '';
  int _restaurantSearchRequestId = 0;
  List<RestaurantModel> _restaurantSearchResults = [];

  @override
  void initState() {
    super.initState();
    _city = widget.currentCity;
    _lat = widget.currentLat;
    _lng = widget.currentLng;
    _selectedDateTime = widget.selectedDateTime ?? DateTime.now();
    _selectedDiscountIndex = widget.selectedDiscountIndex;
    _selectedTypeIndex = widget.selectedTypeIndex;
    _selectedDistance = widget.selectedDistance;
  }

  @override
  void dispose() {
    _restaurantSearchController.dispose();
    super.dispose();
  }

  bool get _hasActiveRestaurantSearch =>
      _restaurantSearchQuery.trim().isNotEmpty;

  bool get _shouldShowRestaurantSearchDropdown =>
      _hasActiveRestaurantSearch &&
      (_showRestaurantSearchDropdown || _isRestaurantSearchLoading);

  Future<void> _handleRestaurantSearchChanged(String value) async {
    if (_ignoreRestaurantSearchChange) return;

    final query = value.trim();
    _restaurantSearchQuery = query;

    if (query.isEmpty) {
      _restaurantSearchRequestId++;
      if (!mounted) return;
      setState(() {
        _isRestaurantSearchLoading = false;
        _showRestaurantSearchDropdown = false;
        _restaurantSearchResults = [];
      });
      await widget.onSearchCleared();
      return;
    }

    final requestId = ++_restaurantSearchRequestId;
    setState(() {
      _isRestaurantSearchLoading = true;
      _showRestaurantSearchDropdown = true;
    });

    final response = await _restaurantService.searchRestaurants(
      name: query,
      lat: _lat,
      lng: _lng,
    );

    if (!mounted || requestId != _restaurantSearchRequestId) return;

    final results = response.restaurant;
    setState(() {
      _restaurantSearchResults = results;
      _isRestaurantSearchLoading = false;
      _showRestaurantSearchDropdown = true;
    });
    await widget.onSearchResultsChanged(results);
  }

  Future<void> _handleRestaurantSearchSubmitted(String value) async {
    if (_restaurantSearchResults.length == 1) {
      await _selectSearchRestaurant(_restaurantSearchResults.first);
      return;
    }

    if (value.trim().isNotEmpty) {
      setState(() => _showRestaurantSearchDropdown = true);
    }
  }

  Future<void> _selectSearchRestaurant(RestaurantModel restaurant) async {
    _setRestaurantSearchText(restaurant.name);
    setState(() {
      _restaurantSearchResults = [restaurant];
      _showRestaurantSearchDropdown = false;
    });

    await widget.onSearchResultsChanged(_restaurantSearchResults);
    await widget.onRestaurantSelected(restaurant);
  }

  Future<void> _applyDateTimeFilter(DateTime dateTime) async {
    setState(() => _selectedDateTime = dateTime);
    await widget.onApplyDateTime(dateTime);
  }

  Future<void> _applyFilters(
    int? discountIndex,
    int? typeIndex,
    double distance,
  ) async {
    setState(() {
      _selectedDiscountIndex = discountIndex;
      _selectedTypeIndex = typeIndex;
      _selectedDistance = distance;
    });
    await widget.onApplyFilters(discountIndex, typeIndex, distance);
  }

  void _showFiltersClearedSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: appButtonColor,
        content: const AppText(
          text: 'Filters cleared',
          size: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  void _setRestaurantSearchText(String text) {
    _ignoreRestaurantSearchChange = true;
    _restaurantSearchController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _ignoreRestaurantSearchChange = false;
  }

  // Same location-picker logic as Home, but runs inside the map page
  Future<void> _showLocationPicker() async {
    final MapService mapService = MapService();
    List<String> places = [];
    List<MapPlacesResponse> locations = [];
    bool isSearchLoading = false;
    final TextEditingController searchController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final deviceSize = MediaQuery.sizeOf(context);
            // Cap the sheet's content height to a fraction of real screen
            // height so a long search-results list can't overflow a short
            // landscape viewport (checklist item #4 / #5).
            final maxSheetContentHeight = deviceSize.height * 0.85;

            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetContentHeight),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20.w,
                  right: 20.w,
                  top: 20.h,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    AppText(
                      text: "Select Location",
                      size: 18,
                      fontWeight: FontWeight.w600,
                      color: appTextColor3,
                    ),
                    SizedBox(height: 16.h),
                    // Use current GPS location
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        await _fetchAndApplyCurrentLocation();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: appButtonColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              color: appButtonColor,
                              size: 20.w,
                            ),
                            SizedBox(width: 10.w),
                            AppText(
                              text: "Use current location",
                              size: 14,
                              fontWeight: FontWeight.w500,
                              color: appButtonColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search location...",
                        prefixIcon: Icon(Icons.search, color: appTextColor3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      onChanged: (val) async {
                        if (val.length >= 2) {
                          setModalState(() => isSearchLoading = true);
                          final response = await mapService.listPlaces(val);
                          setModalState(() {
                            places = response
                                .map((p) => p.mainText ?? '')
                                .toList();
                            locations = response;
                            isSearchLoading = false;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 10.h),
                    if (isSearchLoading)
                      Padding(
                        padding: EdgeInsets.all(16.h),
                        child: const CircularProgressIndicator(),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: places.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: appTextColor3,
                            ),
                            title: Text(places[index]),
                            onTap: () async {
                              final placeId = locations[index].placeId ?? '';
                              final selectedPlace = places[index];
                              try {
                                final coords = await mapService.getPlace(placeId);
                                final lat = double.tryParse(
                                  coords.lat.toString(),
                                );
                                final lng = double.tryParse(
                                  coords.lng.toString(),
                                );
                                if (!mounted) return;
                                // Update local state (search bar city label)
                                setState(() {
                                  _city = selectedPlace;
                                  _lat = lat;
                                  _lng = lng;
                                });
                                // Move the map camera to the new location
                                if (lat != null && lng != null) {
                                  widget.controllerService.animateTo(
                                    LatLng(lat, lng),
                                    zoom: 14,
                                  );
                                }
                                // Keep Home in sync
                                widget.onLocationChanged(selectedPlace, lat, lng);
                              } catch (_) {
                                if (!mounted) return;
                                setState(() => _city = selectedPlace);
                                widget.onLocationChanged(
                                  selectedPlace,
                                  null,
                                  null,
                                );
                              }
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _fetchAndApplyCurrentLocation() async {
    if (mounted) setState(() => _isLocationLoading = true);
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final city = placemarks.isNotEmpty
          ? (placemarks.first.locality ??
                placemarks.first.subLocality ??
                placemarks.first.name ??
                "Unknown")
          : "Unknown";

      if (!mounted) return;
      setState(() {
        _city = city;
        _lat = position.latitude;
        _lng = position.longitude;
      });
      ref.read(userLocationProvider.notifier).state = LatLng(
        position.latitude,
        position.longitude,
      ); // ← here
      widget.controllerService.animateTo(
        LatLng(position.latitude, position.longitude),
        zoom: 15.5,
      );
      widget.onLocationChanged(city, position.latitude, position.longitude);
    } catch (_) {
      if (!mounted) return;
      setState(() => _city = "Unknown");
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _handleBack() async {
    if (ref.read(selectedRestaurantProvider) != null) {
      await widget.onClearSelectedRestaurant();
      return;
    }

    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    // ← WidgetRef via ConsumerState
    final selectedMapRestaurant = ref.watch(selectedRestaurantProvider);
    final topPad = MediaQuery.paddingOf(context).top;
    final mapSize = MediaQuery.sizeOf(context);
    // Device-class decision — shortest side.
    final isLandscape = mapSize.width > mapSize.height;
    final isCompactLandscape = isLandscape && mapSize.height < 500;
    final isTablet = Breakpoints.isTabletDevice(mapSize);
    final isCompactPhone = mapSize.width < 390 || mapSize.height < 700;
    final cardHorizontalInset = isTablet
      ? (isLandscape ? 18.0 : 24.0)
      : isCompactLandscape
      ? 8.0
      : isCompactPhone
      ? 8.0
      : 12.0;
    final cardBottomInset = isTablet
      ? (isLandscape ? mapSize.height * 0.06 : mapSize.height * 0.10)
      : isCompactLandscape
      ? mapSize.height * 0.05
      : isCompactPhone
      ? mapSize.height * 0.12
      : mapSize.height * 0.15;
    final searchTop = topPad + (isLandscape ? (isCompactLandscape ? 4.h : 6.h) : 10.h);
    final filterTop = searchTop + (isLandscape ? (isCompactLandscape ? 46.h : 54.h) : 70.h);
    final dropdownTop = searchTop + (isLandscape ? (isCompactLandscape ? 44.h : 52.h) : 68.h);
    final double cardMaxWidth = isTablet
      ? (isLandscape ? 620.0 : 720.0)
      : isCompactLandscape
      ? mapSize.width - (cardHorizontalInset * 2)
        : (mapSize.width - (cardHorizontalInset * 2))
              .clamp(0.0, 560.0)
              .toDouble();
    final cardMaxHeight = mapSize.height * (isLandscape ? 0.42 : isTablet ? 0.58 : 0.55);
    final landscapeCardLeft = 12.w;
    final landscapeCardTop = filterTop + (isCompactLandscape ? 8.h : 12.h);
    final landscapeCardWidth = (mapSize.width * 0.44).clamp(320.0, 560.0).toDouble();
    final landscapeCardHeight = (mapSize.height - landscapeCardTop - 12.h)
        .clamp(260.0, mapSize.height - 16.h)
        .toDouble();

    return WillPopScope(
      onWillPop: () async {
        await _handleBack();
        return false;
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'map-expand',
              child: PersistentGoogleMap(
                key: const ValueKey('home-expanded-google-map'),
                initialCameraPosition: widget.initialCameraPosition,
                controllerService: widget.controllerService,
                onMapTap: () {
                  unawaited(widget.onClearSelectedRestaurant());
                },
                gesturesEnabled: true,
                showMyLocation: widget.hasMapPermission,
              ),
            ),

            // Search bar — uses local _city so it updates instantly
            Positioned(
              top: searchTop,
              left: 16.w,
              right: 16.w,
              child: AppSearchBar(
                city: _city,
                isLocationLoading: _isLocationLoading,
                searchController: _restaurantSearchController,
                searchHintText: 'Search restaurants...',
                onSearchChanged: _handleRestaurantSearchChanged,
                onSearchSubmitted: _handleRestaurantSearchSubmitted,
                onBackTap: () => unawaited(_handleBack()),
                onLocationTap: _showLocationPicker, // ← opens picker in-map
              ),
            ),

            // Filter row
            Positioned(
              top: filterTop,
              left: 0,
              right: 0,
              child: Center(
                child: _MapFilterRow(
                  selectedDateTime: _selectedDateTime,
                  selectedDiscountIndex: _selectedDiscountIndex,
                  selectedTypeIndex: _selectedTypeIndex,
                  selectedDistance: _selectedDistance,
                  onApplyFilters: _applyFilters,
                  onApplyDateTime: _applyDateTimeFilter,
                  onClearFilters: _showFiltersClearedSnackBar,
                ),
              ),
            ),

            if (_shouldShowRestaurantSearchDropdown)
              Positioned(
                top: dropdownTop,
                left: 16.w,
                right: 16.w,
                child: _RestaurantSearchDropdown(
                  query: _restaurantSearchQuery,
                  restaurants: _restaurantSearchResults,
                  isLoading: _isRestaurantSearchLoading,
                  onSelected: (restaurant) {
                    FocusScope.of(context).unfocus();
                    unawaited(_selectSearchRestaurant(restaurant));
                  },
                ),
              ),

            if (selectedMapRestaurant != null)
              Positioned(
                left: isLandscape ? landscapeCardLeft : cardHorizontalInset,
                right: isLandscape ? null : cardHorizontalInset,
                bottom: isLandscape ? null : cardBottomInset,
                top: isLandscape ? landscapeCardTop : null,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) {
                    final slide =
                        Tween<Offset>(
                          begin: isLandscape ? const Offset(-0.08, 0) : const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        );
                    return SlideTransition(
                      position: slide,
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isLandscape ? landscapeCardWidth : cardMaxWidth,
                        maxHeight: isLandscape ? landscapeCardHeight : cardMaxHeight,
                      ),
                      child: SingleChildScrollView(
                        child: InkWell(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RestaurantProfile(
                                  uuid: selectedMapRestaurant.uuid,
                                  deliveryServiceArea: selectedMapRestaurant
                                      .deliveryServiceArea,
                                  averageReview:
                                      selectedMapRestaurant.averageReview,
                                  distance: selectedMapRestaurant.distance,
                                  isFavourite:
                                      selectedMapRestaurant.isFavorite,
                                ),
                              ),
                            );
                          },
                          child: RestaurantMapCard(
                            uuid: selectedMapRestaurant.uuid,
                            name: selectedMapRestaurant.name,
                            type: selectedMapRestaurant.type,
                            address: selectedMapRestaurant.address,
                            phone: selectedMapRestaurant.phone,
                            lat: selectedMapRestaurant.lat,
                            lng: selectedMapRestaurant.lng,
                            description: selectedMapRestaurant.description,
                            availableDishes:
                                selectedMapRestaurant.availableDishes,
                            takeAwayService:
                                selectedMapRestaurant.takeAwayService,
                            deliveryService:
                                selectedMapRestaurant.deliveryService,
                            deliveryServiceArea:
                                selectedMapRestaurant.deliveryServiceArea,
                            averageReview:
                                selectedMapRestaurant.averageReview,
                            distance: selectedMapRestaurant.distance,
                            restaurantType:
                                selectedMapRestaurant.restaurantType,
                            status: selectedMapRestaurant.status,
                            isFavourite: selectedMapRestaurant.isFavorite,
                            image: selectedMapRestaurant.image,
                            offers: selectedMapRestaurant.offers,
                            isFavoriteBox: false,
                            onRatingOnClick: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RatingPage(
                                  restaurantId: selectedMapRestaurant.uuid,
                                  restaurantName: selectedMapRestaurant.name,
                                  restaurantAddress:
                                      selectedMapRestaurant.address,
                                ),
                              ),
                            ),
                            onBoxClicked: (String? offerId, OfferModel? offer) {
                              final selectedOffers = selectedMapRestaurant
                                  .offers
                                  .where((offer) => offer.uuid == offerId)
                                  .toList();
                              showModalBottomSheet(
                                backgroundColor: Colors.white,
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(25),
                                  ),
                                ),
                                builder: (_) => NumberOfPeopleModal(
                                  uuid: selectedMapRestaurant.uuid,
                                  reservationDate: _selectedDateTime,
                                  offerId: offerId,
                                  offer:
                                      offer ??
                                      (selectedOffers.isEmpty
                                          ? null
                                          : selectedOffers.first),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter row widget ────────────────────────────────────────────────────────
class _RestaurantSearchDropdown extends StatelessWidget {
  const _RestaurantSearchDropdown({
    required this.query,
    required this.restaurants,
    required this.isLoading,
    required this.onSelected,
  });

  final String query;
  final List<RestaurantModel> restaurants;
  final bool isLoading;
  final ValueChanged<RestaurantModel> onSelected;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Device-class decision — shortest side.
    final isTablet = Breakpoints.isTabletDevice(size);
    final isCompactPhone = size.width < 390 || size.height < 700;
    final maxHeight = isTablet
        ? 360.0
        : isCompactPhone
        ? 260.0
        : 310.0;
    final itemImageSize = isTablet
        ? 52.0
        : isCompactPhone
        ? 42.0
        : 46.0;
    final titleSize = isTablet
        ? 14.0
        : isCompactPhone
        ? 12.0
        : 13.sp;
    final metaSize = isTablet
        ? 12.0
        : isCompactPhone
        ? 10.5
        : 11.sp;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFF0E1D6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildContent(
          context,
          imageSize: itemImageSize,
          titleSize: titleSize,
          metaSize: metaSize,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required double imageSize,
    required double titleSize,
    required double metaSize,
  }) {
    if (isLoading && restaurants.isEmpty) {
      return SizedBox(
        height: 86.h,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: appButtonColor,
            ),
          ),
        ),
      );
    }

    if (restaurants.isEmpty) {
      return SizedBox(
        height: 92.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: appButtonColor.withValues(alpha: 0.78),
              size: 21,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                'No restaurants found for "$query"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: locationTextColor.withValues(alpha: 0.72),
                  fontSize: metaSize + 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      shrinkWrap: true,
      itemCount: restaurants.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: imageSize + 26.w,
        endIndent: 14.w,
        color: const Color(0xFFF2E8DF),
      ),
      itemBuilder: (context, index) {
        final restaurant = restaurants[index];
        final distanceLabel = restaurant.distance == null
            ? null
            : '${restaurant.distance!.toStringAsFixed(restaurant.distance! % 1 == 0 ? 0 : 1)} km';

        return InkWell(
          onTap: () => onSelected(restaurant),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
            child: Row(
              children: [
                _SearchRestaurantImage(
                  imageUrl: restaurant.image,
                  size: imageSize,
                ),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: appTextColor3,
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (distanceLabel != null) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: appButtonColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                distanceLabel,
                                style: TextStyle(
                                  color: appButtonColor,
                                  fontSize: metaSize,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        restaurant.type.isNotEmpty
                            ? restaurant.type
                            : restaurant.restaurantType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: locationTextColor.withValues(alpha: 0.7),
                          fontSize: metaSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        restaurant.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: locationTextColor.withValues(alpha: 0.52),
                          fontSize: metaSize,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.near_me_rounded,
                  color: appButtonColor,
                  size: titleSize + 7,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchRestaurantImage extends StatelessWidget {
  const _SearchRestaurantImage({required this.imageUrl, required this.size});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: appButtonColor.withValues(alpha: 0.1),
      child: Icon(
        Icons.restaurant_rounded,
        color: appButtonColor,
        size: size * 0.48,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: imageUrl == null || imageUrl!.isEmpty
          ? fallback
          : Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

class _MapFilterRow extends StatelessWidget {
  final DateTime? selectedDateTime;
  final int? selectedDiscountIndex;
  final int? selectedTypeIndex;
  final double selectedDistance;
  final Future<void> Function(int?, int?, double) onApplyFilters;
  final Future<void> Function(DateTime) onApplyDateTime;
  final VoidCallback onClearFilters;

  const _MapFilterRow({
    required this.selectedDateTime,
    required this.selectedDiscountIndex,
    required this.selectedTypeIndex,
    required this.selectedDistance,
    required this.onApplyFilters,
    required this.onApplyDateTime,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    // Device-class decision — shortest side.
    final isTablet = Breakpoints.isTabletDevice(size);
    final isCompactPhone = size.width < 390 || size.height < 700;
    final tabletSheetWidth = width * 0.88;
    final iconSize = isTablet ? 18.0 : 14.w;
    final gap = isTablet ? 12.0 : 8.w;

    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        // Filter button
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              backgroundColor: Colors.white,
              context: context,
              isScrollControlled: true,
              constraints: isTablet
                  ? BoxConstraints(
                      minWidth: tabletSheetWidth,
                      maxWidth: tabletSheetWidth,
                    )
                  : null,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              builder: (_) => FilterBottomModal(
                onApply: onApplyFilters,
                initialDiscountIndex: selectedDiscountIndex,
                initialTypeIndex: selectedTypeIndex,
                initialDistance: selectedDistance,
                onClear: onClearFilters,
              ),
            );
          },
          child: _filterChip(
            context,
            icon: Image.asset(
              filterIcon,
              width: iconSize,
              height: iconSize,
              color: Colors.black87,
            ),
            label: 'Filter',
            isTablet: isTablet,
            isCompactPhone: isCompactPhone,
          ),
        ),

        SizedBox(width: gap),

        // Date / time button
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              backgroundColor: Colors.white,
              context: context,
              isScrollControlled: true,
              constraints: isTablet
                  ? BoxConstraints(
                      minWidth: tabletSheetWidth,
                      maxWidth: tabletSheetWidth,
                    )
                  : null,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              builder: (_) => TimeBottomModal(
                initialDateTime: selectedDateTime ?? DateTime.now(),
                onApply: onApplyDateTime,
              ),
            );
          },
          child: _filterChip(
            context,
            icon: Image.asset(
              filtercalenderIcon,
              width: iconSize,
              height: iconSize,
              color: Colors.black87,
            ),
            label: selectedDateTime != null
                ? "${DateFormat('d MMM').format(selectedDateTime!)} at ${DateFormat('h:mma').format(selectedDateTime!)}"
                : "${DateFormat('d MMM').format(DateTime.now())} at ${DateFormat('h:mma').format(DateTime.now())}",
            isTablet: isTablet,
            isCompactPhone: isCompactPhone,
          ),
        ),
      ],
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required Widget icon,
    required String label,
    required bool isTablet,
    required bool isCompactPhone,
  }) {
    final horizontalPadding = isTablet ? 14.0 : 12.w;
    final verticalPadding = isTablet ? 10.0 : 9.h;
    final textSize = isTablet
        ? 13.0
        : isCompactPhone
        ? 11.0
        : 12.sp;
    final arrowSize = isTablet ? 17.0 : 15.w;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.10),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
          SizedBox(width: 4.w),
          Icon(
            Icons.keyboard_arrow_down,
            size: arrowSize,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }
}


// import 'dart:async';

// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';
// import 'package:fudikoclient/components/apptextfeild.dart';
// import 'package:fudikoclient/screens/tabs/components/restaurantMapCard.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:fudikoclient/components/appsearchbar.dart';
// import 'package:fudikoclient/components/apptext.dart';
// import 'package:fudikoclient/core/responsive/app_dimensions.dart';
// import 'package:fudikoclient/core/responsive/breakpoints.dart';
// import 'package:fudikoclient/features/map/providers/map_providers.dart';
// import 'package:fudikoclient/features/map/services/map_controller_service.dart';
// import 'package:fudikoclient/features/map/services/marker_bitmap_service.dart';
// import 'package:fudikoclient/features/map/widgets/persistent_google_map.dart';
// import 'package:fudikoclient/model/auth/mapplace-model.dart';
// import 'package:fudikoclient/model/restaurant/restaurant_filter_model.dart';
// import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
// import 'package:fudikoclient/screens/tabs/components/restaurantCard.dart';
// import 'package:fudikoclient/screens/tabs/home/addnumberofpeople.dart';
// import 'package:fudikoclient/screens/tabs/home/filterbottommodal.dart';
// import 'package:fudikoclient/screens/tabs/home/rating.dart';
// import 'package:fudikoclient/screens/tabs/home/timebottommodal.dart';
// import 'package:fudikoclient/screens/tabs/profile/restaurantProfile.dart';
// import 'package:fudikoclient/service/auth/map-service.dart';
// import 'package:fudikoclient/service/restaurant/restaurant-service.dart';
// import 'package:fudikoclient/utils/constants.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'dart:ui' show lerpDouble;
// import 'dart:ui' as ui;

// class Home extends ConsumerStatefulWidget {
//   final String currentCity;
//   final double? currentLat;
//   final double? currentLng;

//   const Home({
//     super.key,
//     this.currentCity = "Locating...",
//     this.currentLat,
//     this.currentLng,
//   });

//   @override
//   ConsumerState<Home> createState() => _HomeState();
// }

// class _HomeState extends ConsumerState<Home> {
//   late String _currentCity;
//   double? _currentLat;
//   double? _currentLng;
//   bool _hasMapPermission = false;
//   bool _isLocationLoading = false;

//   Timer? _zoomDebounce;

//   bool isClicked = false;
//   bool isOpen = false;
//   bool isBookingModalOpen = false;
//   bool isLoading = false;
//   String errorMessage = '';
//   RestaurantService restaurantService = RestaurantService();
//   List<RestaurantModel> restaurantsList = [];
//   List<RestaurantModel> filteredList = [];
//   List<RestaurantModel> _restaurantSearchResults = [];
//   List<RestaurantModel> _lastNonSearchFilteredList = [];
//   final TextEditingController _restaurantSearchController =
//       TextEditingController();
//   bool _isRestaurantSearchLoading = false;
//   bool _showRestaurantSearchDropdown = false;
//   bool _ignoreRestaurantSearchChange = false;
//   String _restaurantSearchQuery = '';
//   int _restaurantSearchRequestId = 0;
//   int? selectedDiscountIndex;
//   int? selectedTypeIndex;
//   double selectedDistance = 10;
//   DateTime selectedDateTime = DateTime.now();
//   late final MapControllerService _mapControllerService;
//   final MarkerBitmapService _markerBitmapService = const MarkerBitmapService();
//   String _lastMarkerSignature = '';
//   bool _isFilterLoading = false;

//   static const String _cacheKeyDiscountIndex = 'cached_filter_discount_index';
//   static const String _cacheKeyTypeIndex = 'cached_filter_type_index';
//   static const String _cacheKeyDistance = 'cached_filter_distance_km';

//   double _mapExpandProgress = 0.0; // 0 = collapsed, 1 = fully expanded
//   final GlobalKey _mapPreviewKey = GlobalKey(); // ← add here

//   // Separate controller for the collapsed preview so it doesn't
//   // conflict with the expanded map controller.
//   late final MapControllerService _collapsedMapControllerService;
//   late final ProviderSubscription<SelectedLocation?> _locationSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _mapControllerService = MapControllerService();
//     _collapsedMapControllerService = MapControllerService();
//     final sharedLocation = ref.read(selectedLocationProvider);
//     _currentCity = sharedLocation?.city ?? widget.currentCity;
//     _currentLat = sharedLocation?.latitude ?? widget.currentLat;
//     _currentLng = sharedLocation?.longitude ?? widget.currentLng;
//     _locationSubscription = ref.listenManual<SelectedLocation?>(
//       selectedLocationProvider,
//       (previous, next) {
//         if (next != null) _applySelectedLocation(next);
//       },
//     );
//     if (_currentLat != null && _currentLng != null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (!mounted || _currentLat == null || _currentLng == null) return;
//         ref.read(userLocationProvider.notifier).state = LatLng(
//           _currentLat!,
//           _currentLng!,
//         );
//       });
//     }
//     // _checkLocationPermission();
//     _checkLocationPermission().then(
//       (_) => _buildUserLocationIcon(),
//     ); // ← add this
//     selectedDateTime = DateTime.now();
//     getAllRestaurtantList();

//     // _fetchLocation();
//   }

//   @override
//   void dispose() {
//     _locationSubscription.close();
//     _restaurantSearchController.dispose();
//     _mapControllerService.dispose();
//     _collapsedMapControllerService.dispose();
//     _zoomDebounce?.cancel();
//     super.dispose();
//   }

//   void _setLocation(String city, double? latitude, double? longitude) {
//     final location = SelectedLocation(
//       city: city,
//       latitude: latitude,
//       longitude: longitude,
//     );
//     _applySelectedLocation(location);
//     ref.read(selectedLocationProvider.notifier).state = location;
//   }

//   void _applySelectedLocation(SelectedLocation location) {
//     final hasChanged =
//         _currentCity != location.city ||
//         _currentLat != location.latitude ||
//         _currentLng != location.longitude;
//     if (!hasChanged || !mounted) return;

//     setState(() {
//       _currentCity = location.city;
//       _currentLat = location.latitude;
//       _currentLng = location.longitude;
//     });

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted) return;

//       final latitude = location.latitude;
//       final longitude = location.longitude;
//       if (latitude == null || longitude == null) {
//         ref.read(userLocationProvider.notifier).state = null;
//         return;
//       }

//       final target = LatLng(latitude, longitude);
//       ref.read(userLocationProvider.notifier).state = target;
//       if (_mapControllerService.isReady) {
//         unawaited(_mapControllerService.animateTo(target, zoom: 15.5));
//       }
//       if (_collapsedMapControllerService.isReady) {
//         unawaited(_collapsedMapControllerService.animateTo(target, zoom: 12.5));
//       }
//       getAllRestaurtantList();
//     });
//   }

//   Future<void> _buildUserLocationIcon() async {
//     const double size = 120; // large canvas to fit the accuracy ring
//     final recorder = ui.PictureRecorder();
//     final canvas = Canvas(recorder);

//     // Accuracy ring (large semi-transparent circle)
//     canvas.drawCircle(
//       const Offset(size / 2, size / 2),
//       size / 2,
//       Paint()..color = const Color(0x22B97A3E), // very transparent orange
//     );

//     // Thin border ring
//     canvas.drawCircle(
//       const Offset(size / 2, size / 2),
//       size / 2 - 1,
//       Paint()
//         ..color = const Color(0x44B97A3E)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 1.5,
//     );

//     // White ring around dot
//     canvas.drawCircle(
//       const Offset(size / 2, size / 2),
//       10,
//       Paint()..color = Colors.white,
//     );

//     // Orange dot center
//     canvas.drawCircle(
//       const Offset(size / 2, size / 2),
//       7,
//       Paint()..color = const Color(0xFFB97A3E),
//     );

//     final image = await recorder.endRecording().toImage(
//       size.toInt(),
//       size.toInt(),
//     );
//     final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
//     final icon = BitmapDescriptor.bytes(
//       bytes!.buffer.asUint8List(),
//       width: 120,
//       height: 120,
//     );

//     ref.read(userLocationIconProvider.notifier).state = icon;
//   }

//   Future<void> _cacheFilterSelection(
//     int? discountIndex,
//     int? typeIndex,
//     double distance,
//   ) async {
//     final prefs = await SharedPreferences.getInstance();
//     if (discountIndex == null) {
//       await prefs.remove(_cacheKeyDiscountIndex);
//     } else {
//       await prefs.setInt(_cacheKeyDiscountIndex, discountIndex);
//     }

//     if (typeIndex == null) {
//       await prefs.remove(_cacheKeyTypeIndex);
//     } else {
//       await prefs.setInt(_cacheKeyTypeIndex, typeIndex);
//     }

//     await prefs.setDouble(_cacheKeyDistance, distance);
//   }

//   bool get _hasActiveRestaurantSearch =>
//       _restaurantSearchQuery.trim().isNotEmpty;

//   bool get _shouldShowRestaurantSearchDropdown =>
//       _hasActiveRestaurantSearch &&
//       (_showRestaurantSearchDropdown || _isRestaurantSearchLoading);

//   Future<void> _handleRestaurantSearchChanged(String value) async {
//     if (_ignoreRestaurantSearchChange) return;

//     final query = value.trim();
//     _restaurantSearchQuery = query;

//     if (query.isEmpty) {
//       _restaurantSearchRequestId++;
//       if (!mounted) return;
//       setState(() {
//         _isRestaurantSearchLoading = false;
//         _showRestaurantSearchDropdown = false;
//         _restaurantSearchResults = [];
//         filteredList = List.of(_lastNonSearchFilteredList);
//         errorMessage = '';
//       });
//       _buildCollapsedMarkers();
//       await _refreshMapMarkers();
//       return;
//     }

//     if (_lastNonSearchFilteredList.isEmpty && filteredList.isNotEmpty) {
//       _lastNonSearchFilteredList = List.of(filteredList);
//     }

//     final requestId = ++_restaurantSearchRequestId;
//     setState(() {
//       _isRestaurantSearchLoading = true;
//       _showRestaurantSearchDropdown = true;
//       errorMessage = '';
//     });

//     final response = await restaurantService.searchRestaurants(
//       name: query,
//       lat: _currentLat,
//       lng: _currentLng,
//     );

//     if (!mounted || requestId != _restaurantSearchRequestId) return;

//     final results = response.restaurant;
//     setState(() {
//       _restaurantSearchResults = results;
//       filteredList = results;
//       _isRestaurantSearchLoading = false;
//       _showRestaurantSearchDropdown = true;
//       errorMessage = response.status ? '' : 'Unable to search restaurants';
//     });
//     _buildCollapsedMarkers();
//     await _refreshMapMarkers();
//   }

//   Future<void> _handleRestaurantSearchSubmitted(String value) async {
//     if (_restaurantSearchResults.length == 1) {
//       await _selectMainSearchRestaurant(_restaurantSearchResults.first);
//       return;
//     }

//     if (value.trim().isNotEmpty) {
//       setState(() => _showRestaurantSearchDropdown = true);
//     }
//   }

//   Future<void> _selectMainSearchRestaurant(RestaurantModel restaurant) async {
//     _setRestaurantSearchText(restaurant.name);

//     setState(() {
//       filteredList = [restaurant];
//       _restaurantSearchResults = [restaurant];
//       _showRestaurantSearchDropdown = false;
//       errorMessage = '';
//     });

//     _buildCollapsedMarkers();
//     await _refreshMapMarkers();

//     final position = _restaurantPosition(restaurant);
//     if (position != null && _collapsedMapControllerService.isReady) {
//       await _collapsedMapControllerService.animateTo(position, zoom: 14.5);
//     }
//   }

//   Future<void> _handleExpandedMapSearchResults(
//     List<RestaurantModel> results,
//   ) async {
//     if (!mounted) return;
//     setState(() {
//       filteredList = results;
//       errorMessage = '';
//     });
//     _lastMarkerSignature = '';
//     _buildCollapsedMarkers();
//     await _refreshMapMarkers();
//   }

//   Future<void> _handleExpandedMapSearchCleared() async {
//     if (!mounted) return;
//     final restoredList = _lastNonSearchFilteredList.isNotEmpty
//         ? _lastNonSearchFilteredList
//         : _applyDistanceFilter(restaurantsList, selectedDistance);

//     setState(() {
//       filteredList = List.of(restoredList);
//       errorMessage = '';
//     });
//     await _clearMapRestaurantSelection();
//     _lastMarkerSignature = '';
//     _buildCollapsedMarkers();
//     await _refreshMapMarkers();
//   }

//   Future<void> _handleExpandedMapRestaurantSelected(
//     RestaurantModel restaurant,
//   ) async {
//     if (!filteredList.any((item) => item.uuid == restaurant.uuid)) {
//       setState(() => filteredList = [restaurant, ...filteredList]);
//     }

//     _lastMarkerSignature = '';
//     await _refreshMapMarkers();
//     await _selectMapRestaurant(restaurant);
//   }

//   LatLng? _restaurantPosition(RestaurantModel restaurant) {
//     final lat = double.tryParse(restaurant.lat);
//     final lng = double.tryParse(restaurant.lng);
//     if (lat == null || lng == null) return null;
//     return LatLng(lat, lng);
//   }

//   void _setRestaurantSearchText(String text) {
//     _ignoreRestaurantSearchChange = true;
//     _restaurantSearchController.value = TextEditingValue(
//       text: text,
//       selection: TextSelection.collapsed(offset: text.length),
//     );
//     _ignoreRestaurantSearchChange = false;
//   }

//   int? _selectedOfferPercentage() {
//     if (selectedDiscountIndex == null) return null;
//     if (selectedDiscountIndex! < 0 || selectedDiscountIndex! > 7) {
//       return null;
//     }
//     return (selectedDiscountIndex! + 1) * 10;
//   }

//   Future<void> getAllRestaurtantList() async {
//     if (!mounted) return;
//     setState(() => isLoading = true);
//     try {
//       final RestaurantListResponse response = await restaurantService
//           .getRestaurantList(
//             lat: _currentLat,
//             lng: _currentLng,
//             searchRadiusKm: selectedDistance,
//             dateTime: selectedDateTime,
//           );
//       if (!mounted) return;
//       setState(() {
//         restaurantsList = response.restaurant;
//         filteredList = _applyDistanceFilter(
//           response.restaurant,
//           selectedDistance,
//         );
//         if (!_hasActiveRestaurantSearch) {
//           _lastNonSearchFilteredList = List.of(filteredList);
//         }
//         isLoading = false;
//         errorMessage = '';
//       });
//       _buildCollapsedMarkers();
//       await _refreshMapMarkers();
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         isLoading = false;
//         errorMessage = e.toString();
//       });
//     }
//   }

//   Future<void> _checkLocationPermission() async {
//     LocationPermission permission = await Geolocator.checkPermission();

//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }

//     if (!mounted) return;

//     setState(() {
//       _hasMapPermission =
//           permission == LocationPermission.always ||
//           permission == LocationPermission.whileInUse;
//     });
//   }

//   /// Builds simple default Google Maps pins for the collapsed preview.
//   /// These are cheap: no async bitmap rendering needed.
//   Future<void> _buildCollapsedMarkers() async {
//     if (!mounted) return;

//     final markers = <Marker>{};
//     for (final restaurant in filteredList) {
//       if (restaurant.lat.isEmpty || restaurant.lng.isEmpty) continue;
//       if (restaurant.offers.isEmpty) continue;

//       final bestOffer = restaurant.offers.reduce(
//         (a, b) => a.discountPercentage >= b.discountPercentage ? a : b,
//       );
//       final position = LatLng(
//         double.tryParse(restaurant.lat) ?? 0,
//         double.tryParse(restaurant.lng) ?? 0,
//       );

//       final icon = await _markerBitmapService.buildOfferMarker(
//         context,
//         label: '-${bestOffer.discountPercentage.toStringAsFixed(0)}%',
//         isSelected: false,
//         isDimmed: false,
//         scale: 0.41,
//       );

//       markers.add(
//         Marker(
//           markerId: MarkerId(restaurant.uuid),
//           position: position,
//           icon: icon,
//           anchor: const Offset(.5, .94),
//           onTap: _expandMap,
//         ),
//       );
//     }

//     if (!mounted) return;
//     ref.read(collapsedMarkersProvider.notifier).state = markers;
//   }

//   Future<void> applyFilters(
//     int? discountIndex,
//     int? typeIndex,
//     double distance,
//   ) async {
//     setState(() {
//       selectedDiscountIndex = discountIndex;
//       selectedTypeIndex = typeIndex;
//       selectedDistance = distance;
//       _isFilterLoading = true;
//       errorMessage = '';
//     });

//     await _cacheFilterSelection(discountIndex, typeIndex, distance);

//     final types = ["Restaurant", "Cafe", "Cool Bar", "Bar", "Buffet"];
//     final bool hasValidTypeIndex =
//         typeIndex != null && typeIndex >= 0 && typeIndex < types.length;
//     final String? selectedType = hasValidTypeIndex ? types[typeIndex] : null;

//     final bool hasLocation = await _ensureFilterLocation();
//     if (!hasLocation || _currentLat == null || _currentLng == null) {
//       if (!mounted) return;
//       setState(() {
//         _isFilterLoading = false;
//         errorMessage = 'Location is required to apply backend filters';
//         filteredList = [];
//       });
//       return;
//     }

//     final request = RestaurantFilterRequest(
//       lat: _currentLat!,
//       lng: _currentLng!,
//       searchRadiusKm: distance,
//       type: selectedType,
//       offerPercentage: _selectedOfferPercentage(),
//       dateTime: selectedDateTime,
//     );

//     try {
//       final response = await restaurantService.filterRestaurants(request);
//       if (!mounted) return;
//       setState(() {
//         filteredList = _applyDistanceFilter(response.restaurant, distance);
//         if (!_hasActiveRestaurantSearch) {
//           _lastNonSearchFilteredList = List.of(filteredList);
//         }
//         _isFilterLoading = false;
//         errorMessage = '';
//       });
//       _buildCollapsedMarkers();
//       await _refreshMapMarkers();
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _isFilterLoading = false;
//         errorMessage = e.toString();
//       });
//     }
//   }

//   Future<void> _applyDateTimeFilter(DateTime dateTime) async {
//     setState(() => selectedDateTime = dateTime);
//     await applyFilters(
//       selectedDiscountIndex,
//       selectedTypeIndex,
//       selectedDistance,
//     );
//   }

//   void _showFiltersClearedSnackBar() {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: appButtonColor,
//         content: const AppText(
//           text: 'Filters cleared',
//           size: 13,
//           fontWeight: FontWeight.w500,
//           color: Colors.white,
//         ),
//       ),
//     );
//   }

//   Future<void> _handleRefresh() async {
//     final hasActiveFilters =
//         selectedDiscountIndex != null ||
//         selectedTypeIndex != null ||
//         selectedDistance != 10;

//     if (hasActiveFilters) {
//       await applyFilters(
//         selectedDiscountIndex,
//         selectedTypeIndex,
//         selectedDistance,
//       );
//     } else {
//       await getAllRestaurtantList();
//     }
//   }

//   List<RestaurantModel> _applyDistanceFilter(
//     List<RestaurantModel> restaurants,
//     double distanceKm,
//   ) {
//     final List<RestaurantModel> result = distanceKm <= 0
//         ? List.of(restaurants)
//         : restaurants.where((r) {
//             final double? d = r.distance;
//             return d != null && d <= distanceKm;
//           }).toList();

//     result.sort((a, b) {
//       final double aD = a.distance ?? double.infinity;
//       final double bD = b.distance ?? double.infinity;
//       return aD.compareTo(bD);
//     });
//     return result;
//   }

//   Future<bool> _ensureFilterLocation() async {
//     if (_currentLat != null && _currentLng != null) return true;
//     try {
//       final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) return false;
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         return false;
//       }
//       final Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       if (!mounted) return false;
//       setState(() {
//         _currentLat = position.latitude;
//         _currentLng = position.longitude;
//       });
//       ref.read(userLocationProvider.notifier).state = LatLng(
//         position.latitude,
//         position.longitude,
//       ); // ← here
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }

//   Future<void> _fetchLocation() async {
//     if (mounted) setState(() => _isLocationLoading = true);
//     try {
//       LocationPermission permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         setState(() => _currentCity = "Location denied");
//         return;
//       }
//       final Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       setState(() {
//         _currentLat = position.latitude;
//         _currentLng = position.longitude;
//       });
//       ref.read(userLocationProvider.notifier).state = LatLng(
//         position.latitude,
//         position.longitude,
//       ); // ← here
//       final List<Placemark> placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );
//       if (placemarks.isNotEmpty) {
//         final p = placemarks.first;
//         _setLocation(
//           p.locality ?? p.subLocality ?? p.name ?? "Unknown",
//           position.latitude,
//           position.longitude,
//         );
//       }
//     } catch (e) {
//       setState(() => _currentCity = "Unknown");
//     } finally {
//       if (mounted) setState(() => _isLocationLoading = false);
//     }
//   }

//   //   Future<void> _expandMap() async {
//   //   if (ref.read(mapExpandedProvider)) return;

//   //   _mapControllerService.reset();

//   //   ref.read(mapExpandedProvider.notifier).state = true;

//   //   await _refreshMapMarkers();

//   //   // Small delay so map first opens at user location
//   //   await Future.delayed(const Duration(milliseconds: 800));

//   //   final restaurants = _mapRestaurants;

//   //   if (restaurants.isNotEmpty) {
//   //     await _mapControllerService.fitRestaurants(
//   //       restaurants.map((r) => r.position),
//   //     );
//   //   }
//   // }
//   Future<void> _expandMap() async {
//     if (ref.read(mapExpandedProvider)) return;
//     ref.read(mapExpandedProvider.notifier).state = true;
//     try {
//       await _refreshMapMarkers();
//       if (!mounted) return;

//       await Navigator.push(
//         context,
//         PageRouteBuilder(
//           transitionDuration: const Duration(milliseconds: 600),
//           reverseTransitionDuration: const Duration(milliseconds: 500),
//           pageBuilder: (_, __, ___) => _ExpandedMapPage(
//             initialCameraPosition: _initialCameraPosition,
//             controllerService: _mapControllerService,
//             hasMapPermission: _hasMapPermission,
//             onClose: () => Navigator.pop(context),
//             currentCity: _currentCity,
//             currentLat: _currentLat,
//             currentLng: _currentLng,
//             selectedDateTime: selectedDateTime,
//             selectedDiscountIndex: selectedDiscountIndex,
//             selectedTypeIndex: selectedTypeIndex,
//             selectedDistance: selectedDistance,
//             onApplyFilters: applyFilters,
//             onApplyDateTime: _applyDateTimeFilter,
//             onClearSelectedRestaurant: _clearMapRestaurantSelection,
//             onSearchResultsChanged: _handleExpandedMapSearchResults,
//             onSearchCleared: _handleExpandedMapSearchCleared,
//             onRestaurantSelected: _handleExpandedMapRestaurantSelected,
//             onLocationChanged: (city, lat, lng) {
//               _setLocation(city, lat, lng);
//             },
//           ),
//           transitionsBuilder: (_, animation, __, child) {
//             return FadeTransition(
//               opacity: CurvedAnimation(
//                 parent: animation,
//                 curve: const Interval(0.5, 1.0),
//               ),
//               child: child,
//             );
//           },
//         ),
//       );
//     } finally {
//       if (mounted) _collapseMap();
//     }
//   }

//   Future<void> _refreshMapMarkersWithZoom(double zoom) async {
//     if (!ref.read(mapExpandedProvider) || !mounted) return;

//     final selectedRestaurant = ref.read(selectedRestaurantProvider);
//     final double scale = ((zoom - 10) / 8).clamp(0.3, 1.4);
//     final markers = <Marker>{};

//     for (final restaurant in filteredList) {
//       if (restaurant.lat.isEmpty || restaurant.lng.isEmpty) continue;
//       if (restaurant.offers.isEmpty) continue;

//       final bestOffer = restaurant.offers.reduce(
//         (a, b) => a.discountPercentage >= b.discountPercentage ? a : b,
//       );
//       final position = LatLng(
//         double.tryParse(restaurant.lat) ?? 0,
//         double.tryParse(restaurant.lng) ?? 0,
//       );
//       final isSelected = selectedRestaurant?.uuid == restaurant.uuid;
//       final isDimmed = selectedRestaurant != null && !isSelected;

//       final icon = await _markerBitmapService.buildOfferMarker(
//         context,
//         label: '-${bestOffer.discountPercentage.toStringAsFixed(0)}%',
//         isSelected: isSelected,
//         isDimmed: isDimmed,
//         scale: scale,
//       );

//       markers.add(
//         Marker(
//           markerId: MarkerId(restaurant.uuid),
//           position: position,
//           icon: icon,
//           anchor: const Offset(.5, .94),
//           zIndexInt: isSelected ? 2 : 1,
//           onTap: () => _selectMapRestaurant(restaurant),
//         ),
//       );
//     }

//     if (!mounted) return;
//     ref.read(mapMarkersProvider.notifier).state = markers;
//   }

//   void _collapseMap() {
//     ref.read(selectedRestaurantProvider.notifier).state = null;
//     ref.read(mapExpandedProvider.notifier).state = false;
//     ref.read(mapMarkersProvider.notifier).state = const <Marker>{};
//     _lastMarkerSignature = '';
//   }

//   // List<map_feature.Restaurant> get _mapRestaurants {
//   //   return filteredList
//   //       .where((r) => r.lat.isNotEmpty && r.lng.isNotEmpty)
//   //       .map(map_feature.Restaurant.fromLegacy)
//   //       .toList(growable: false);
//   // }

//   Future<void> _refreshMapMarkers() async {
//     if (!ref.read(mapExpandedProvider) || !mounted) return;

//     final zoom = ref.read(mapZoomProvider);
//     final double scale = ((zoom - 10) / 8).clamp(0.3, 1.4);
//     final selectedRestaurant = ref.read(selectedRestaurantProvider);

//     final signature = filteredList
//         .where((r) => r.offers.isNotEmpty)
//         .map((r) {
//           final best = r.offers.reduce(
//             (a, b) => a.discountPercentage >= b.discountPercentage ? a : b,
//           );
//           return '${r.uuid}:${best.discountPercentage}:${selectedRestaurant?.uuid}';
//         })
//         .join('|');

//     if (signature == _lastMarkerSignature) return;
//     _lastMarkerSignature = signature;

//     final markers = <Marker>{};
//     for (final restaurant in filteredList) {
//       if (restaurant.lat.isEmpty || restaurant.lng.isEmpty) continue;
//       if (restaurant.offers.isEmpty) continue;

//       final bestOffer = restaurant.offers.reduce(
//         (a, b) => a.discountPercentage >= b.discountPercentage ? a : b,
//       );
//       final position = LatLng(
//         double.tryParse(restaurant.lat) ?? 0,
//         double.tryParse(restaurant.lng) ?? 0,
//       );
//       final isSelected = selectedRestaurant?.uuid == restaurant.uuid;
//       final isDimmed = selectedRestaurant != null && !isSelected;

//       final icon = await _markerBitmapService.buildOfferMarker(
//         context,
//         label: '-${bestOffer.discountPercentage.toStringAsFixed(0)}%',
//         isSelected: isSelected,
//         isDimmed: isDimmed,
//         scale: scale,
//       );

//       markers.add(
//         Marker(
//           markerId: MarkerId(restaurant.uuid),
//           position: position,
//           icon: icon,
//           anchor: const Offset(.5, .94),
//           zIndexInt: isSelected ? 2 : 1,
//           onTap: () => _selectMapRestaurant(restaurant),
//         ),
//       );
//     }

//     if (!mounted) return;
//     ref.read(mapMarkersProvider.notifier).state = markers;
//   }

//   Future<void> _selectMapRestaurant(RestaurantModel restaurant) async {
//     ref.read(selectedRestaurantProvider.notifier).state = restaurant;
//     _lastMarkerSignature = '';
//     await _refreshMapMarkers();
//     await _mapControllerService.focusRestaurant(
//       LatLng(
//         double.tryParse(restaurant.lat) ?? 0,
//         double.tryParse(restaurant.lng) ?? 0,
//       ),
//     );
//   }

//   Future<void> _clearMapRestaurantSelection() async {
//     if (ref.read(selectedRestaurantProvider) == null) return;

//     ref.read(selectedRestaurantProvider.notifier).state = null;
//     _lastMarkerSignature = '';
//     await _refreshMapMarkers();
//   }

//   @override
//   Widget build(BuildContext context) {
//     ref.listen(mapZoomProvider, (previous, next) {
//       if (previous == next) return;
//       _zoomDebounce?.cancel();
//       _zoomDebounce = Timer(const Duration(milliseconds: 300), () {
//         _lastMarkerSignature = '';
//         _refreshMapMarkersWithZoom(next);
//       });
//     });
//     final double filterHeaderHeight = 72.h;
//     final bool isMapExpanded = ref.watch(mapExpandedProvider);
//     final RestaurantModel? selectedMapRestaurant = ref.watch(
//       selectedRestaurantProvider,
//     );
//     final collapsedMarkers = ref.watch(collapsedMarkersProvider);

//     return Scaffold(
//       backgroundColor: const Color(0xfffdf8f5),
//       body: SafeArea(
//         child: Stack(
//           children: [
//             Column(
//               children: [
//                 // Search bar stays fixed at top.
//                 Padding(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: 30.w,
//                     vertical: 25.h,
//                   ),
//                   child: AppSearchBar(
//                     city: _currentCity,
//                     isLocationLoading: _isLocationLoading,
//                     searchController: _restaurantSearchController,
//                     searchHintText: 'Search restaurants...',
//                     onSearchChanged: _handleRestaurantSearchChanged,
//                     onSearchSubmitted: _handleRestaurantSearchSubmitted,
//                     onLocationTap: _showLocationPicker,
//                   ),
//                 ),

//                 Expanded(
//                   child: RefreshIndicator(
//                     color: appButtonColor,
//                     onRefresh: _handleRefresh,
//                     child: CustomScrollView(
//                       physics: const AlwaysScrollableScrollPhysics(
//                         parent: BouncingScrollPhysics(),
//                       ),
//                       slivers: [
//                         // Discount cards
//                         SliverToBoxAdapter(child: _discountBuilder()),

//                         SliverToBoxAdapter(
//                           child: _collapsedMapPreview(collapsedMarkers),
//                         ),

//                         // Filter row: sticky
//                         SliverPersistentHeader(
//                           pinned: true,
//                           delegate: _FilterHeaderDelegate(
//                             child: Container(
//                               color: const Color(0xfffdf8f5),
//                               child: SizedBox(
//                                 height: filterHeaderHeight,
//                                 child: _dropDownBuilder(),
//                               ),
//                             ),
//                             height: filterHeaderHeight,
//                           ),
//                         ),

//                         // Restaurant list
//                         if (isLoading || _isFilterLoading)
//                           SliverToBoxAdapter(
//                             child: SizedBox(
//                               height: 220.h,
//                               child: const Center(
//                                 child: CircularProgressIndicator(),
//                               ),
//                             ),
//                           )
//                         else if (errorMessage.isNotEmpty)
//                           SliverToBoxAdapter(
//                             child: SizedBox(
//                               height: 220.h,
//                               child: Center(
//                                 child: AppText(
//                                   text: 'Error: $errorMessage',
//                                   size: 14,
//                                   fontWeight: FontWeight.w400,
//                                   color: Colors.red,
//                                 ),
//                               ),
//                             ),
//                           )
//                         else if (filteredList.isEmpty)
//                           SliverToBoxAdapter(
//                             child: SizedBox(
//                               height: 260.h,
//                               child: Center(
//                                 child: Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     const Icon(
//                                       Icons.search_off,
//                                       size: 60,
//                                       color: Colors.grey,
//                                     ),
//                                     SizedBox(height: 10.h),
//                                     AppText(
//                                       text: "No restaurants found",
//                                       size: 16,
//                                       fontWeight: FontWeight.w500,
//                                       color: Colors.grey,
//                                     ),
//                                     SizedBox(height: 10.h),
//                                     GestureDetector(
//                                       onTap: () {
//                                         _setRestaurantSearchText('');
//                                         setState(() {
//                                           filteredList = restaurantsList;
//                                           _lastNonSearchFilteredList = List.of(
//                                             filteredList,
//                                           );
//                                           _restaurantSearchResults = [];
//                                           _restaurantSearchQuery = '';
//                                           _showRestaurantSearchDropdown = false;
//                                           selectedDiscountIndex = null;
//                                           selectedTypeIndex = null;
//                                           selectedDistance = 10;
//                                         });
//                                         _showFiltersClearedSnackBar();
//                                         _buildCollapsedMarkers();
//                                       },
//                                       child: AppText(
//                                         text: "Clear filters",
//                                         size: 14,
//                                         fontWeight: FontWeight.w500,
//                                         color: appTextColor3,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           )
//                         else
//                           SliverList(
//                             delegate: SliverChildBuilderDelegate((
//                               context,
//                               index,
//                             ) {
//                               final restaurant = filteredList[index];
//                               return InkWell(
//                                 onTap: () async {
//                                   final result = await Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => RestaurantProfile(
//                                         uuid: restaurant.uuid,
//                                         deliveryServiceArea:
//                                             restaurant.deliveryServiceArea,
//                                         averageReview: restaurant.averageReview,
//                                         distance: restaurant.distance,
//                                         isFavourite: restaurant.isFavorite,
//                                       ),
//                                     ),
//                                   );
//                                   if (result is bool) {
//                                     if (!mounted) return;
//                                     setState(() {
//                                       restaurantsList = restaurantsList
//                                           .map(
//                                             (r) => r.uuid == restaurant.uuid
//                                                 ? r.copyWith(isFavorite: result)
//                                                 : r,
//                                           )
//                                           .toList();
//                                       filteredList = filteredList
//                                           .map(
//                                             (r) => r.uuid == restaurant.uuid
//                                                 ? r.copyWith(isFavorite: result)
//                                                 : r,
//                                           )
//                                           .toList();
//                                     });
//                                   }
//                                 },
//                                 child: RestaurantCard(
//                                   uuid: restaurant.uuid,
//                                   name: restaurant.name,
//                                   type: restaurant.type,
//                                   address: restaurant.address,
//                                   phone: restaurant.phone,
//                                   lat: restaurant.lat,
//                                   lng: restaurant.lng,
//                                   description: restaurant.description,
//                                   availableDishes: restaurant.availableDishes,
//                                   takeAwayService: restaurant.takeAwayService,
//                                   deliveryService: restaurant.deliveryService,
//                                   deliveryServiceArea:
//                                       restaurant.deliveryServiceArea,
//                                   averageReview: restaurant.averageReview,
//                                   distance: restaurant.distance,
//                                   restaurantType: restaurant.restaurantType,
//                                   status: restaurant.status,
//                                   isFavourite: restaurant.isFavorite,
//                                   image: restaurant.image,
//                                   offers: restaurant.offers,
//                                   onRatingOnClick: () => Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (_) => RatingPage(
//                                         restaurantId: restaurant.uuid,
//                                         restaurantName: restaurant.name,
//                                         restaurantAddress: restaurant.address,
//                                       ),
//                                     ),
//                                   ),
//                                   onBoxClicked:
//                                       (String? offerId, OfferModel? offer) {
//                                         final selectedOffers = restaurant.offers
//                                             .where(
//                                               (offer) => offer.uuid == offerId,
//                                             )
//                                             .toList();
//                                         setState(
//                                           () => isBookingModalOpen =
//                                               !isBookingModalOpen,
//                                         );
//                                         if (isBookingModalOpen) {
//                                           showModalBottomSheet(
//                                             backgroundColor: Colors.white,
//                                             context: context,
//                                             isScrollControlled: true,
//                                             shape: const RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.vertical(
//                                                     top: Radius.circular(25),
//                                                   ),
//                                             ),
//                                             builder: (_) => NumberOfPeopleModal(
//                                               uuid: restaurant.uuid,
//                                               reservationDate: selectedDateTime,
//                                               offerId: offerId,
//                                               offer:
//                                                   offer ??
//                                                   (selectedOffers.isEmpty
//                                                       ? null
//                                                       : selectedOffers.first),
//                                             ),
//                                           );
//                                         }
//                                       },
//                                 ),
//                               );
//                             }, childCount: filteredList.length),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             if (_shouldShowRestaurantSearchDropdown)
//               Positioned(
//                 top: 25.h + 68.h,
//                 left: 30.w,
//                 right: 30.w,
//                 child: _RestaurantSearchDropdown(
//                   query: _restaurantSearchQuery,
//                   restaurants: _restaurantSearchResults,
//                   isLoading: _isRestaurantSearchLoading,
//                   onSelected: (restaurant) {
//                     FocusScope.of(context).unfocus();
//                     unawaited(_selectMainSearchRestaurant(restaurant));
//                   },
//                 ),
//               ),

//             // if (isMapExpanded) _expandedMapOverlay(),

//             // if (isMapExpanded)
//             //   Positioned(
//             //     left: 16.w,
//             //     top: MediaQuery.paddingOf(context).top + 16.h,
//             //     child: Material(
//             //       color: Colors.white,
//             //       shape: const CircleBorder(),
//             //       elevation: 8,
//             //       shadowColor: const Color(0x26000000),
//             //       child: IconButton(
//             //         onPressed: _collapseMap,
//             //         icon: const Icon(Icons.close_rounded),
//             //       ),
//             //     ),
//             //   ),

//             // if (isMapExpanded && selectedMapRestaurant != null)
//             //   RestaurantBottomSheet(restaurant: selectedMapRestaurant),
//           ],
//         ),
//       ),
//     );
//   }

//   CameraPosition get _initialCameraPosition {
//     return CameraPosition(
//       target: LatLng(_currentLat ?? 10.8505, _currentLng ?? 76.2711),
//       zoom: _currentLat == null ? 7.4 : 15.5,
//     );
//   }

//   CameraPosition get _collapsedMapCameraPosition {
//     return CameraPosition(
//       target: LatLng(_currentLat ?? 10.8505, _currentLng ?? 76.2711),
//       zoom: _currentLat == null ? 10 : 12.5,
//     );
//   }

//   // Replace _collapsedMapPreview with this:
//   Widget _collapsedMapPreview(Set<Marker> collapsedMarkers) {
//     final size = MediaQuery.sizeOf(context);
//     final isWideShortPhone =
//         !Breakpoints.isTablet(size.width) &&
//         size.width >= 500 &&
//         size.height <= 760;
//     final previewHeight = isWideShortPhone ? 82.0 : 100.h;

//     return Padding(
//       key: _mapPreviewKey,
//       padding: EdgeInsets.symmetric(
//         horizontal: isWideShortPhone ? 28.0 : 20.w,
//         vertical: isWideShortPhone ? 14.0 : 20.h,
//       ),
//       child: Hero(
//         tag: 'map-expand',
//         flightShuttleBuilder: (_, animation, __, fromContext, ___) {
//           // During flight: animate the border radius from rounded → 0
//           return AnimatedBuilder(
//             animation: animation,
//             builder: (_, __) {
//               final radius = Tween<double>(begin: 20, end: 0).evaluate(
//                 CurvedAnimation(
//                   parent: animation,
//                   curve: Curves.easeInOutCubic,
//                 ),
//               );
//               return Material(
//                 color: Colors.black,
//                 borderRadius: BorderRadius.circular(radius),
//                 clipBehavior: Clip.antiAlias,
//                 child: Container(color: Colors.black87),
//               );
//             },
//           );
//         },
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20.r),
//           child: Container(
//             decoration: BoxDecoration(
//               boxShadow: [
//                 BoxShadow(
//                   color: const Color(0xFF000000).withValues(alpha: 0.25),
//                   offset: const Offset(0, 0), // X = 0, Y = 0
//                   blurRadius: 15, // Blur = 15
//                   spreadRadius: 0, // Spread = 0
//                 ),
//               ],
//               borderRadius: BorderRadius.circular(18.r),
//             ),
//             height: previewHeight,
//             width: double.infinity,
//             child: Stack(
//               fit: StackFit.expand,
//               children: [
//                 if (kIsWeb)
//                   _staticCollapsedMapPreview()
//                 else
//                   PersistentGoogleMap(
//                     key: const ValueKey('home-collapsed-google-map'),
//                     initialCameraPosition: _collapsedMapCameraPosition,
//                     controllerService: _collapsedMapControllerService,
//                     onMapTap: _expandMap,
//                     gesturesEnabled: false,
//                     overrideMarkers: collapsedMarkers,
//                     showMyLocation: _hasMapPermission,
//                   ),
//                 Positioned.fill(
//                   child: Material(
//                     color: Colors.transparent,
//                     child: InkWell(onTap: _expandMap),
//                   ),
//                 ),
//                 // DecoratedBox(
//                 //   decoration: BoxDecoration(
//                 //     gradient: LinearGradient(
//                 //       begin: Alignment.topCenter,
//                 //       end: Alignment.bottomCenter,
//                 //       colors: [
//                 //         Colors.transparent,
//                 //         Colors.black.withOpacity(.40),
//                 //       ],
//                 //     ),
//                 //   ),
//                 //   child: Align(
//                 //     alignment: Alignment.bottomLeft,
//                 //     child: Padding(
//                 //       padding: EdgeInsets.all(12.w),
//                 //       child: Container(
//                 //         padding: EdgeInsets.symmetric(
//                 //           horizontal: 12.w,
//                 //           vertical: 7.h,
//                 //         ),
//                 //         decoration: BoxDecoration(
//                 //           color: Colors.white,
//                 //           borderRadius: BorderRadius.circular(999),
//                 //         ),
//                 //         child: Text(
//                 //           'View offers on map',
//                 //           style: TextStyle(
//                 //             color: const Color(0xFF172018),
//                 //             fontSize: 11.sp,
//                 //             fontWeight: FontWeight.w900,
//                 //           ),
//                 //         ),
//                 //       ),
//                 //     ),
//                 //   ),
//                 // ),
//                 if (!kIsWeb)
//                   Positioned.fill(
//                     child: GestureDetector(
//                       behavior: HitTestBehavior.opaque,
//                       onTap: _expandMap,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _staticCollapsedMapPreview() {
//     return DecoratedBox(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Color(0xFFEFE7DE), Color(0xFFDDEAD6)],
//         ),
//       ),
//       child: Stack(
//         children: [
//           Positioned(
//             left: 22,
//             top: 16,
//             child: _mapPreviewPin(const Color(0xFFF87B0D), 16),
//           ),
//           Positioned(
//             right: 34,
//             top: 24,
//             child: _mapPreviewPin(const Color(0xFF417629), 12),
//           ),
//           Positioned(
//             left: 110,
//             bottom: 16,
//             child: _mapPreviewPin(const Color(0xFFF87B0D), 10),
//           ),
//           Center(
//             child: Icon(
//               Icons.map_outlined,
//               color: appButtonColor.withValues(alpha: 0.7),
//               size: 30,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _mapPreviewPin(Color color, double size) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         color: color,
//         shape: BoxShape.circle,
//         border: Border.all(color: Colors.white, width: 2),
//         boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
//       ),
//     );
//   }

//   Widget _expandedMapOverlay() {
//     // Grab the card's position on screen
//     Rect cardRect = Rect.fromLTWH(
//       20.w,
//       0,
//       MediaQuery.sizeOf(context).width - 40.w,
//       90.h,
//     );
//     final RenderObject? ro = _mapPreviewKey.currentContext?.findRenderObject();
//     if (ro is RenderBox && ro.hasSize) {
//       final Offset topLeft = ro.localToGlobal(Offset.zero);
//       cardRect = topLeft & ro.size;
//     }

//     final Size screen = MediaQuery.sizeOf(context);
//     final Rect fullRect = Rect.fromLTWH(0, 0, screen.width, screen.height);

//     return Positioned.fill(
//       child: TweenAnimationBuilder<double>(
//         tween: Tween<double>(begin: 0, end: 1),
//         duration: const Duration(milliseconds: 520),
//         curve: Curves.easeInOutCubic,
//         onEnd: () {
//           if (mounted) setState(() => _mapExpandProgress = 1.0);
//         },
//         builder: (context, value, child) {
//           // Sync progress for fading the collapsed preview
//           if ((_mapExpandProgress - value).abs() > 0.01) {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (mounted) setState(() => _mapExpandProgress = value);
//             });
//           }

//           // Interpolate from card rect → full screen
//           final Rect animRect = Rect.lerp(cardRect, fullRect, value)!;
//           // Border radius 20 → 0
//           final double radius = lerpDouble(20.r, 0, value)!;

//           return Stack(
//             children: [
//               Positioned(
//                 left: animRect.left,
//                 top: animRect.top,
//                 width: animRect.width,
//                 height: animRect.height,
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(radius),
//                   child: Opacity(
//                     opacity: value.clamp(0.3, 1.0), // start slightly visible
//                     child: child,
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
//         child: PersistentGoogleMap(
//           key: const ValueKey('home-expanded-google-map'),
//           initialCameraPosition: _initialCameraPosition,
//           controllerService: _mapControllerService,
//           onMapTap: _expandMap,
//           showMyLocation: _hasMapPermission,
//         ),
//       ),
//     );
//   }

//   Widget _dropDownBuilder() {
//     final width = MediaQuery.sizeOf(context).width;
//     final height = MediaQuery.sizeOf(context).height;
//     final isTablet = Breakpoints.isTablet(width);
//     final isCompactPhone = width < 390 || height < 700;
//     final tabletSheetWidth = width * 0.88;
//     final chipHorizontalPadding = isTablet ? 16.0 : 14.w;
//     final chipVerticalPadding = isTablet ? 11.0 : 10.h;
//     final chipIconSize = isTablet ? 18.0 : 15.w;
//     final chipTextSize = isTablet
//         ? 13.0
//         : isCompactPhone
//         ? 10.0
//         : 10.sp;
//     final dateTextSize = isTablet
//         ? 14.0
//         : isCompactPhone
//         ? 12.0
//         : 13.sp;
//     final chipGap = isTablet ? 12.0 : 10.w;

//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           GestureDetector(
//             onTap: () {
//               showModalBottomSheet(
//                 backgroundColor: Colors.white,
//                 context: context,
//                 isScrollControlled: true,
//                 constraints: isTablet
//                     ? BoxConstraints(
//                         minWidth: tabletSheetWidth,
//                         maxWidth: tabletSheetWidth,
//                       )
//                     : null,
//                 shape: const RoundedRectangleBorder(
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//                 ),
//                 builder: (context) => FilterBottomModal(
//                   onApply: applyFilters,
//                   initialDiscountIndex: selectedDiscountIndex,
//                   initialTypeIndex: selectedTypeIndex,
//                   initialDistance: selectedDistance,
//                   onClear: _showFiltersClearedSnackBar,
//                 ),
//               );
//             },
//             child: Container(
//               padding: EdgeInsets.symmetric(
//                 horizontal: chipHorizontalPadding,
//                 vertical: chipVerticalPadding,
//               ),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10.r),
//                 border: Border.all(color: Colors.grey.shade300),
//                 boxShadow: [
//                   BoxShadow(
//                     color: const Color(0xFF000000).withValues(alpha: 0.10),
//                     offset: const Offset(0, 0),
//                     blurRadius: 10,
//                     spreadRadius: 2,
//                   ),
//                 ],
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Image.asset(
//                     filterIcon,
//                     width: chipIconSize,
//                     height: chipIconSize,
//                     color: Colors.black87,
//                   ),
//                   SizedBox(width: 6.w),
//                   AppText(
//                     text: "Filter",
//                     size: chipTextSize,
//                     fontWeight: FontWeight.w400,
//                     color: Colors.black87.withValues(alpha: 0.8),
//                   ),
//                   SizedBox(width: 6.w),
//                   Icon(
//                     Icons.keyboard_arrow_down,
//                     size: isTablet ? 18.0 : 16.w,
//                     color: Colors.black54,
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           SizedBox(width: chipGap),

//           Flexible(
//             fit: FlexFit.loose,
//             child: GestureDetector(
//               onTap: () {
//                 showModalBottomSheet(
//                   backgroundColor: Colors.white,
//                   context: context,
//                   isScrollControlled: true,
//                   constraints: isTablet
//                       ? BoxConstraints(
//                           minWidth: tabletSheetWidth,
//                           maxWidth: tabletSheetWidth,
//                         )
//                       : null,
//                   shape: const RoundedRectangleBorder(
//                     borderRadius: BorderRadius.vertical(
//                       top: Radius.circular(25),
//                     ),
//                   ),
//                   builder: (context) => TimeBottomModal(
//                     initialDateTime: selectedDateTime,
//                     onApply: _applyDateTimeFilter,
//                   ),
//                 );
//               },
//               child: Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: chipHorizontalPadding,
//                   vertical: chipVerticalPadding,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(10.r),
//                   border: Border.all(color: Colors.grey.shade300),
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color(0xFF000000).withValues(alpha: 0.10),
//                       offset: const Offset(0, 0),
//                       blurRadius: 10,
//                       spreadRadius: 2,
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Image.asset(
//                           filtercalenderIcon,
//                           width: chipIconSize,
//                           height: chipIconSize,
//                           color: Colors.black87,
//                         ),
//                         SizedBox(width: 6.w),
//                         Flexible(
//                           child: AppText(
//                             text:
//                                 "${DateFormat('d MMM').format(selectedDateTime)} at ${DateFormat('h:mma').format(selectedDateTime)}",
//                             size: dateTextSize,
//                             fontWeight: FontWeight.w400,
//                             color: Colors.black87.withValues(alpha: 0.8),

//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(width: 6.w),
//                     Icon(
//                       Icons.keyboard_arrow_down,
//                       size: isTablet ? 18.0 : 16.w,
//                       color: Colors.black54,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _discountBuilder() {
//     final colors = [
//       {'color2': const Color(0xFF6CCB3F), 'color1': const Color(0XFF36651F)},
//       {'color2': const Color(0xFF3FB2CB), 'color1': const Color(0xFF1F5965)},
//       {'color2': const Color(0xFF9E3FCB), 'color1': const Color(0xFF4F1F65)},
//       {'color2': const Color(0xFFCBAC3F), 'color1': const Color(0xFF65561F)},
//     ];
//     final discountDetails = [
//       {
//         'offer_range': "10%-20%",
//         'discount_tag': "assets/images/discount_tag1.png",
//       },
//       {
//         'offer_range': "20%-30%",
//         'discount_tag': "assets/images/discount_tag2.png",
//       },
//       {
//         'offer_range': "30%-40%",
//         'discount_tag': "assets/images/discount_tag3.png",
//       },
//       {
//         'offer_range': "40%-50%",
//         'discount_tag': "assets/images/discount_tag4.png",
//       },
//     ];

//     final size = MediaQuery.sizeOf(context);
//     final isTablet = Breakpoints.isTablet(size.width);
//     final isWideShortPhone =
//         !isTablet && size.width >= 500 && size.height <= 760;
//     final isCompactPhone = size.width < 390 || size.height < 700;
//     final stripHeight = isTablet
//         ? 210.0
//         : isWideShortPhone
//         ? 170.0
//         : isCompactPhone
//         ? 150.0
//         : 180.h;
//     final cardWidth = isTablet
//         ? 150.0
//         : isWideShortPhone
//         ? 168.0
//         : isCompactPhone
//         ? 104.0
//         : 120.w;
//     final cardHeight = isTablet
//         ? 200.0
//         : isWideShortPhone
//         ? 152.0
//         : isCompactPhone
//         ? 142.0
//         : 180.h;
//     final cardGap = isTablet
//         ? 8.0
//         : isWideShortPhone
//         ? 5.0
//         : isCompactPhone
//         ? 4.0
//         : 5.w;
//     final radius = isTablet
//         ? 22.0
//         : isWideShortPhone
//         ? 18.0
//         : isCompactPhone
//         ? 16.0
//         : 20.0;
//     final borderWidth = isTablet
//         ? 2.0
//         : isWideShortPhone
//         ? 1.5
//         : isCompactPhone
//         ? 1.5
//         : 2.w;
//     final offerTextSize = isTablet
//         ? 22.0
//         : isWideShortPhone
//         ? 22.0
//         : isCompactPhone
//         ? 16.0
//         : 20.sp;
//     final discountTextSize = isTablet
//         ? 19.0
//         : isWideShortPhone
//         ? 19.0
//         : isCompactPhone
//         ? 14.5
//         : 18.sp;
//     final tagSize = isTablet
//         ? 82.0
//         : isWideShortPhone
//         ? 58.0
//         : isCompactPhone
//         ? 54.0
//         : 70.w;

//     Widget buildDiscountCard(int index) {
//       final color1 = colors[index]['color1']!;
//       final color2 = colors[index]['color2']!;
//       final filterDiscountIndex = index;
//       final isSelected = selectedDiscountIndex == filterDiscountIndex;

//       return Padding(
//         padding: EdgeInsets.symmetric(horizontal: cardGap),
//         child: GestureDetector(
//           onTap: _isFilterLoading
//               ? null
//               : () => applyFilters(
//                   isSelected ? null : filterDiscountIndex,
//                   selectedTypeIndex,
//                   selectedDistance,
//                 ),
//           child: Container(
//             height: cardHeight,
//             width: cardWidth,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(radius),
//               border: Border.all(
//                 color: isSelected ? appButtonColor : Colors.transparent,
//                 width: borderWidth,
//               ),
//               gradient: LinearGradient(
//                 colors: [color1, color2],
//                 begin: Alignment.bottomCenter,
//                 end: Alignment.topCenter,
//               ),
//             ),
//             clipBehavior: Clip.antiAlias,
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 Positioned.fill(
//                   child: Image.asset(
//                     'assets/images/boxbg.png',
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 Padding(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: isCompactPhone ? 8.0 : 10.0,
//                     vertical: isWideShortPhone
//                         ? 8.0
//                         : isCompactPhone
//                         ? 10.0
//                         : 14.0,
//                   ),
//                   child: FittedBox(
//                     fit: BoxFit.scaleDown,
//                     child: SizedBox(
//                       width: cardWidth - 20,
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           AppText(
//                             text: discountDetails[index]['offer_range']!,
//                             size: offerTextSize,
//                             fontWeight: FontWeight.w700,
//                             color: Colors.white,
//                             maxLines: 1,
//                             isboxShadow: const [
//                               BoxShadow(
//                                 color: Color(0x4D000000),
//                                 offset: Offset(0, 3),
//                                 blurRadius: 5,
//                                 spreadRadius: 0,
//                               ),
//                             ],
//                           ),
//                           SizedBox(height: isCompactPhone ? 2.0 : 4.0),
//                           AppText(
//                             text: "Discount",
//                             size: discountTextSize,
//                             fontWeight: FontWeight.w400,
//                             color: Colors.white,
//                             maxLines: 1,
//                           ),
//                           SizedBox(
//                             height: isWideShortPhone
//                                 ? 5.0
//                                 : isCompactPhone
//                                 ? 4.0
//                                 : 8.0,
//                           ),
//                           Image.asset(
//                             discountDetails[index]['discount_tag']!,
//                             height: tagSize,
//                             width: tagSize,
//                             fit: BoxFit.contain,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     return SizedBox(
//       height: stripHeight,
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           final totalCardWidth = colors.length * (cardWidth + cardGap * 2);

//           if (isTablet && totalCardWidth <= constraints.maxWidth) {
//             return Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(colors.length, buildDiscountCard),
//             );
//           }

//           return ListView.builder(
//             itemCount: colors.length,
//             scrollDirection: Axis.horizontal,
//             physics: const BouncingScrollPhysics(),
//             itemBuilder: (context, index) => buildDiscountCard(index),
//           );
//         },
//       ),
//     );
//   }

//   Future<void> _showLocationPicker() async {
//     final MapService mapService = MapService();
//     List<MapPlacesResponse> locations = [];
//     bool isSearchLoading = false;
//     final TextEditingController searchController = TextEditingController();
//     final screenWidth = MediaQuery.sizeOf(context).width;
//     final isTabletSheet = Breakpoints.isTablet(screenWidth);
//     final tabletSheetWidth = screenWidth * 0.88;

//     // Debounce timer
//     Timer? _debounce; // 👈 add: import 'dart:async';

//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       constraints: isTabletSheet
//           ? BoxConstraints(
//               minWidth: tabletSheetWidth,
//               maxWidth: tabletSheetWidth,
//             )
//           : null,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
//       ),
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             return LayoutBuilder(
//               builder: (context, constraints) {
//                 final width = constraints.maxWidth;
//                 final height = MediaQuery.sizeOf(context).height;
//                 final isTablet = Breakpoints.isTablet(width);
//                 final isCompactPhone = width < 390 || height < 700;
//                 final sheetHorizontalPadding = isTablet
//                     ? width * 0.06
//                     : isCompactPhone
//                     ? 16.0
//                     : 20.0;
//                 final titleSize = isTablet
//                     ? AppDimensions.title(context)
//                     : isCompactPhone
//                     ? 16.0
//                     : 18.0;
//                 final actionTextSize = isTablet
//                     ? AppDimensions.body(context)
//                     : isCompactPhone
//                     ? 13.0
//                     : 14.0;
//                 final subtitleSize = isTablet
//                     ? AppDimensions.caption(context)
//                     : isCompactPhone
//                     ? 11.0
//                     : 12.0;
//                 final iconSize = isTablet
//                     ? 22.0
//                     : isCompactPhone
//                     ? 18.0
//                     : 20.0;
//                 final topGap = isTablet ? 20.0 : 16.h;
//                 final innerGap = isTablet ? 18.0 : 16.h;

//                 return Padding(
//                   padding: EdgeInsets.only(
//                     bottom: MediaQuery.of(context).viewInsets.bottom,
//                     left: sheetHorizontalPadding,
//                     right: sheetHorizontalPadding,
//                     top: topGap,
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         width: isTablet ? 48.0 : 40.w,
//                         height: isTablet ? 5.0 : 4.h,
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                       SizedBox(height: innerGap),
//                       AppText(
//                         text: "Select Location",
//                         size: titleSize,
//                         fontWeight: FontWeight.w600,
//                         color: appTextColor3,
//                       ),
//                       SizedBox(height: innerGap),
//                       GestureDetector(
//                         onTap: () {
//                           Navigator.pop(context);
//                           _fetchLocation();
//                         },
//                         child: Container(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: isTablet ? 18.0 : 16.w,
//                             vertical: isTablet ? 14.0 : 12.h,
//                           ),
//                           decoration: BoxDecoration(
//                             color: appButtonColor.withValues(alpha: 0.1),
//                             borderRadius: BorderRadius.circular(10.r),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.my_location,
//                                 color: appButtonColor,
//                                 size: iconSize,
//                               ),
//                               SizedBox(width: isTablet ? 12.0 : 10.w),
//                               AppText(
//                                 text: "Use current location",
//                                 size: actionTextSize,
//                                 fontWeight: FontWeight.w500,
//                                 color: appButtonColor,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       SizedBox(height: innerGap),
//                       TextField(
//                         controller: searchController,
//                         style: TextStyle(fontSize: actionTextSize),
//                         decoration: InputDecoration(
//                           hintText: "Search location...",
//                           hintStyle: TextStyle(fontSize: actionTextSize),
//                           prefixIcon: Icon(
//                             Icons.search,
//                             color: appTextColor3,
//                             size: iconSize,
//                           ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10.r),
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10.r),
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                         ),
//                         onChanged: (val) {
//                           _debounce?.cancel();
//                           if (val.length < 2) {
//                             setModalState(() => locations = []);
//                             return;
//                           }
//                           _debounce = Timer(
//                             const Duration(milliseconds: 400),
//                             () async {
//                               setModalState(() => isSearchLoading = true);
//                               final response = await mapService.listPlaces(
//                                 val,
//                                 lat: _currentLat,
//                                 lng: _currentLng,
//                               );
//                               setModalState(() {
//                                 locations = response;
//                                 isSearchLoading = false;
//                               });
//                             },
//                           );
//                         },
//                       ),
//                       SizedBox(height: isTablet ? 12.0 : 10.h),
//                       if (isSearchLoading)
//                         Padding(
//                           padding: EdgeInsets.all(isTablet ? 18.0 : 16.h),
//                           child: const CircularProgressIndicator(),
//                         )
//                       else
//                         ListView.builder(
//                           shrinkWrap: true,
//                           physics: const NeverScrollableScrollPhysics(),
//                           itemCount: locations.length,
//                           itemBuilder: (context, index) {
//                             final place = locations[index];
//                             return ListTile(
//                               leading: Icon(
//                                 Icons.location_on,
//                                 color: appTextColor3,
//                                 size: iconSize,
//                               ),
//                               title: Text(
//                                 place.mainText ?? '',
//                                 style: TextStyle(fontSize: actionTextSize),
//                               ),
//                               subtitle: Text(
//                                 place.secondaryText ?? '',
//                                 style: TextStyle(
//                                   fontSize: subtitleSize,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                               onTap: () async {
//                                 final placeId = place.placeId ?? '';
//                                 try {
//                                   final coords = await mapService.getPlace(
//                                     placeId,
//                                   );
//                                   if (!mounted) return;
//                                   _setLocation(
//                                     place.mainText ?? '',
//                                     coords.lat,
//                                     coords.lng,
//                                   );
//                                 } catch (e) {
//                                   if (!mounted) return;
//                                   _setLocation(
//                                     place.mainText ?? '',
//                                     null,
//                                     null,
//                                   );
//                                 }
//                                 if (!context.mounted) return;
//                                 Navigator.pop(context);
//                               },
//                             );
//                           },
//                         ),
//                       SizedBox(height: isTablet ? 24.0 : 20.h),
//                     ],
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       },
//     );

//     _debounce?.cancel(); // clean up on sheet close
//   }

//   // Future<void> _showLocationPicker() async {
//   //   final MapService mapService = MapService();
//   //   List<String> places = [];
//   //   List<MapPlacesResponse> locations = [];
//   //   bool isSearchLoading = false;
//   //   final TextEditingController searchController = TextEditingController();

//   //   await showModalBottomSheet(
//   //     context: context,
//   //     isScrollControlled: true,
//   //     backgroundColor: Colors.white,
//   //     shape: RoundedRectangleBorder(
//   //       borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
//   //     ),
//   //     builder: (context) {
//   //       return StatefulBuilder(
//   //         builder: (context, setModalState) {
//   //           return Padding(
//   //             padding: EdgeInsets.only(
//   //               bottom: MediaQuery.of(context).viewInsets.bottom,
//   //               left: 20.w,
//   //               right: 20.w,
//   //               top: 20.h,
//   //             ),
//   //             child: Column(
//   //               mainAxisSize: MainAxisSize.min,
//   //               children: [
//   //                 Container(
//   //                   width: 40.w,
//   //                   height: 4.h,
//   //                   decoration: BoxDecoration(
//   //                     color: Colors.grey[300],
//   //                     borderRadius: BorderRadius.circular(2),
//   //                   ),
//   //                 ),
//   //                 SizedBox(height: 16.h),
//   //                 AppText(
//   //                   text: "Select Location",
//   //                   size: 18,
//   //                   fontWeight: FontWeight.w600,
//   //                   color: appTextColor3,
//   //                 ),
//   //                 SizedBox(height: 16.h),
//   //                 GestureDetector(
//   //                   onTap: () {
//   //                     Navigator.pop(context);
//   //                     _fetchLocation();
//   //                   },
//   //                   child: Container(
//   //                     padding: EdgeInsets.symmetric(
//   //                       horizontal: 16.w,
//   //                       vertical: 12.h,
//   //                     ),
//   //                     decoration: BoxDecoration(
//   //                       color: appButtonColor.withOpacity(0.1),
//   //                       borderRadius: BorderRadius.circular(10.r),
//   //                     ),
//   //                     child: Row(
//   //                       children: [
//   //                         Icon(
//   //                           Icons.my_location,
//   //                           color: appButtonColor,
//   //                           size: 20.w,
//   //                         ),
//   //                         SizedBox(width: 10.w),
//   //                         AppText(
//   //                           text: "Use current location",
//   //                           size: 14,
//   //                           fontWeight: FontWeight.w500,
//   //                           color: appButtonColor,
//   //                         ),
//   //                       ],
//   //                     ),
//   //                   ),
//   //                 ),
//   //                 SizedBox(height: 16.h),
//   //                 TextField(
//   //                   controller: searchController,
//   //                   decoration: InputDecoration(
//   //                     hintText: "Search location...",
//   //                     prefixIcon: Icon(Icons.search, color: appTextColor3),
//   //                     border: OutlineInputBorder(
//   //                       borderRadius: BorderRadius.circular(10.r),
//   //                       borderSide: BorderSide(color: Colors.grey.shade300),
//   //                     ),
//   //                     enabledBorder: OutlineInputBorder(
//   //                       borderRadius: BorderRadius.circular(10.r),
//   //                       borderSide: BorderSide(color: Colors.grey.shade300),
//   //                     ),
//   //                   ),
//   //                   onChanged: (val) async {
//   //                     if (val.length >= 2) {
//   //                       setModalState(() => isSearchLoading = true);
//   //                       final response = await mapService.listPlaces(val);
//   //                       setModalState(() {
//   //                         places = response
//   //                             .map((p) => p.mainText ?? '')
//   //                             .toList();
//   //                         locations = response;
//   //                         isSearchLoading = false;
//   //                       });
//   //                     }
//   //                   },
//   //                 ),
//   //                 SizedBox(height: 10.h),
//   //                 if (isSearchLoading)
//   //                   Padding(
//   //                     padding: EdgeInsets.all(16.h),
//   //                     child: const CircularProgressIndicator(),
//   //                   )
//   //                 else
//   //                   ListView.builder(
//   //                     shrinkWrap: true,
//   //                     physics: const NeverScrollableScrollPhysics(),
//   //                     itemCount: places.length,
//   //                     itemBuilder: (context, index) {
//   //                       return ListTile(
//   //                         leading: Icon(
//   //                           Icons.location_on,
//   //                           color: appTextColor3,
//   //                         ),
//   //                         title: Text(places[index]),
//   //                         onTap: () async {
//   //                           final placeId = locations[index].placeId ?? '';
//   //                           final selectedPlace = places[index];
//   //                           try {
//   //                             final coords = await mapService.getPlace(placeId);
//   //                             if (!mounted) return;
//   //                             setState(() {
//   //                               _currentCity = selectedPlace;
//   //                               _currentLat = double.tryParse(
//   //                                 coords.lat.toString(),
//   //                               );
//   //                               _currentLng = double.tryParse(
//   //                                 coords.lng.toString(),
//   //                               );
//   //                             });
//   //                           } catch (e) {
//   //                             if (!mounted) return;
//   //                             setState(() => _currentCity = selectedPlace);
//   //                           }
//   //                           if (!context.mounted) return;
//   //                           Navigator.pop(context);
//   //                         },
//   //                       );
//   //                     },
//   //                   ),
//   //                 SizedBox(height: 20.h),
//   //               ],
//   //             ),
//   //           );
//   //         },
//   //       );
//   //     },
//   //   );
//   // }
// }

// class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
//   final Widget child;
//   final double height;

//   _FilterHeaderDelegate({required this.child, required this.height});

//   @override
//   double get minExtent => height;

//   @override
//   double get maxExtent => height;

//   @override
//   Widget build(
//     BuildContext context,
//     double shrinkOffset,
//     bool overlapsContent,
//   ) {
//     return child;
//   }

//   @override
//   bool shouldRebuild(_FilterHeaderDelegate oldDelegate) =>
//       oldDelegate.child != child || oldDelegate.height != height;
// }

// // ─── Replace _ExpandedMapPage class ──────────────────────────────────────────
// class _ExpandedMapPage extends ConsumerStatefulWidget {
//   final CameraPosition initialCameraPosition;
//   final MapControllerService controllerService;
//   final bool hasMapPermission;
//   final VoidCallback onClose;
//   final String currentCity;
//   final double? currentLat;
//   final double? currentLng;
//   final DateTime? selectedDateTime;
//   final int? selectedDiscountIndex;
//   final int? selectedTypeIndex;
//   final double selectedDistance;
//   final Future<void> Function(int?, int?, double) onApplyFilters;
//   final Future<void> Function(DateTime) onApplyDateTime;
//   final Future<void> Function() onClearSelectedRestaurant;
//   final Future<void> Function(List<RestaurantModel>) onSearchResultsChanged;
//   final Future<void> Function() onSearchCleared;
//   final Future<void> Function(RestaurantModel) onRestaurantSelected;
//   // Callback so Home stays in sync when user picks a new location on the map
//   final void Function(String city, double? lat, double? lng) onLocationChanged;

//   const _ExpandedMapPage({
//     required this.initialCameraPosition,
//     required this.controllerService,
//     required this.hasMapPermission,
//     required this.onClose,
//     required this.currentCity,
//     required this.currentLat,
//     required this.currentLng,
//     required this.selectedDateTime,
//     required this.selectedDiscountIndex,
//     required this.selectedTypeIndex,
//     required this.selectedDistance,
//     required this.onApplyFilters,
//     required this.onApplyDateTime,
//     required this.onClearSelectedRestaurant,
//     required this.onSearchResultsChanged,
//     required this.onSearchCleared,
//     required this.onRestaurantSelected,
//     required this.onLocationChanged,
//   });

//   @override
//   ConsumerState<_ExpandedMapPage> createState() => _ExpandedMapPageState();
// }

// class _ExpandedMapPageState extends ConsumerState<_ExpandedMapPage> {
//   final RestaurantService _restaurantService = RestaurantService();
//   final TextEditingController _restaurantSearchController =
//       TextEditingController();
//   late String _city;
//   late double? _lat;
//   late double? _lng;
//   late DateTime _selectedDateTime;
//   late int? _selectedDiscountIndex;
//   late int? _selectedTypeIndex;
//   late double _selectedDistance;
//   bool _isLocationLoading = false;
//   bool _isRestaurantSearchLoading = false;
//   bool _showRestaurantSearchDropdown = false;
//   bool _ignoreRestaurantSearchChange = false;
//   String _restaurantSearchQuery = '';
//   int _restaurantSearchRequestId = 0;
//   List<RestaurantModel> _restaurantSearchResults = [];

//   @override
//   void initState() {
//     super.initState();
//     _city = widget.currentCity;
//     _lat = widget.currentLat;
//     _lng = widget.currentLng;
//     _selectedDateTime = widget.selectedDateTime ?? DateTime.now();
//     _selectedDiscountIndex = widget.selectedDiscountIndex;
//     _selectedTypeIndex = widget.selectedTypeIndex;
//     _selectedDistance = widget.selectedDistance;
//   }

//   @override
//   void dispose() {
//     _restaurantSearchController.dispose();
//     super.dispose();
//   }

//   bool get _hasActiveRestaurantSearch =>
//       _restaurantSearchQuery.trim().isNotEmpty;

//   bool get _shouldShowRestaurantSearchDropdown =>
//       _hasActiveRestaurantSearch &&
//       (_showRestaurantSearchDropdown || _isRestaurantSearchLoading);

//   Future<void> _handleRestaurantSearchChanged(String value) async {
//     if (_ignoreRestaurantSearchChange) return;

//     final query = value.trim();
//     _restaurantSearchQuery = query;

//     if (query.isEmpty) {
//       _restaurantSearchRequestId++;
//       if (!mounted) return;
//       setState(() {
//         _isRestaurantSearchLoading = false;
//         _showRestaurantSearchDropdown = false;
//         _restaurantSearchResults = [];
//       });
//       await widget.onSearchCleared();
//       return;
//     }

//     final requestId = ++_restaurantSearchRequestId;
//     setState(() {
//       _isRestaurantSearchLoading = true;
//       _showRestaurantSearchDropdown = true;
//     });

//     final response = await _restaurantService.searchRestaurants(
//       name: query,
//       lat: _lat,
//       lng: _lng,
//     );

//     if (!mounted || requestId != _restaurantSearchRequestId) return;

//     final results = response.restaurant;
//     setState(() {
//       _restaurantSearchResults = results;
//       _isRestaurantSearchLoading = false;
//       _showRestaurantSearchDropdown = true;
//     });
//     await widget.onSearchResultsChanged(results);
//   }

//   Future<void> _handleRestaurantSearchSubmitted(String value) async {
//     if (_restaurantSearchResults.length == 1) {
//       await _selectSearchRestaurant(_restaurantSearchResults.first);
//       return;
//     }

//     if (value.trim().isNotEmpty) {
//       setState(() => _showRestaurantSearchDropdown = true);
//     }
//   }

//   Future<void> _selectSearchRestaurant(RestaurantModel restaurant) async {
//     _setRestaurantSearchText(restaurant.name);
//     setState(() {
//       _restaurantSearchResults = [restaurant];
//       _showRestaurantSearchDropdown = false;
//     });

//     await widget.onSearchResultsChanged(_restaurantSearchResults);
//     await widget.onRestaurantSelected(restaurant);
//   }

//   Future<void> _applyDateTimeFilter(DateTime dateTime) async {
//     setState(() => _selectedDateTime = dateTime);
//     await widget.onApplyDateTime(dateTime);
//   }

//   Future<void> _applyFilters(
//     int? discountIndex,
//     int? typeIndex,
//     double distance,
//   ) async {
//     setState(() {
//       _selectedDiscountIndex = discountIndex;
//       _selectedTypeIndex = typeIndex;
//       _selectedDistance = distance;
//     });
//     await widget.onApplyFilters(discountIndex, typeIndex, distance);
//   }

//   void _showFiltersClearedSnackBar() {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: appButtonColor,
//         content: const AppText(
//           text: 'Filters cleared',
//           size: 13,
//           fontWeight: FontWeight.w500,
//           color: Colors.white,
//         ),
//       ),
//     );
//   }

//   void _setRestaurantSearchText(String text) {
//     _ignoreRestaurantSearchChange = true;
//     _restaurantSearchController.value = TextEditingValue(
//       text: text,
//       selection: TextSelection.collapsed(offset: text.length),
//     );
//     _ignoreRestaurantSearchChange = false;
//   }

//   // Same location-picker logic as Home, but runs inside the map page
//   Future<void> _showLocationPicker() async {
//     final MapService mapService = MapService();
//     List<String> places = [];
//     List<MapPlacesResponse> locations = [];
//     bool isSearchLoading = false;
//     final TextEditingController searchController = TextEditingController();

//     await showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
//       ),
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             return Padding(
//               padding: EdgeInsets.only(
//                 bottom: MediaQuery.of(context).viewInsets.bottom,
//                 left: 20.w,
//                 right: 20.w,
//                 top: 20.h,
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 40.w,
//                     height: 4.h,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                   SizedBox(height: 16.h),
//                   AppText(
//                     text: "Select Location",
//                     size: 18,
//                     fontWeight: FontWeight.w600,
//                     color: appTextColor3,
//                   ),
//                   SizedBox(height: 16.h),
//                   // Use current GPS location
//                   GestureDetector(
//                     onTap: () async {
//                       Navigator.pop(context);
//                       await _fetchAndApplyCurrentLocation();
//                     },
//                     child: Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: 16.w,
//                         vertical: 12.h,
//                       ),
//                       decoration: BoxDecoration(
//                         color: appButtonColor.withValues(alpha: 0.1),
//                         borderRadius: BorderRadius.circular(10.r),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.my_location,
//                             color: appButtonColor,
//                             size: 20.w,
//                           ),
//                           SizedBox(width: 10.w),
//                           AppText(
//                             text: "Use current location",
//                             size: 14,
//                             fontWeight: FontWeight.w500,
//                             color: appButtonColor,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 16.h),
//                   TextField(
//                     controller: searchController,
//                     decoration: InputDecoration(
//                       hintText: "Search location...",
//                       prefixIcon: Icon(Icons.search, color: appTextColor3),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10.r),
//                         borderSide: BorderSide(color: Colors.grey.shade300),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10.r),
//                         borderSide: BorderSide(color: Colors.grey.shade300),
//                       ),
//                     ),
//                     onChanged: (val) async {
//                       if (val.length >= 2) {
//                         setModalState(() => isSearchLoading = true);
//                         final response = await mapService.listPlaces(val);
//                         setModalState(() {
//                           places = response
//                               .map((p) => p.mainText ?? '')
//                               .toList();
//                           locations = response;
//                           isSearchLoading = false;
//                         });
//                       }
//                     },
//                   ),
//                   SizedBox(height: 10.h),
//                   if (isSearchLoading)
//                     Padding(
//                       padding: EdgeInsets.all(16.h),
//                       child: const CircularProgressIndicator(),
//                     )
//                   else
//                     ListView.builder(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: places.length,
//                       itemBuilder: (context, index) {
//                         return ListTile(
//                           leading: Icon(
//                             Icons.location_on,
//                             color: appTextColor3,
//                           ),
//                           title: Text(places[index]),
//                           onTap: () async {
//                             final placeId = locations[index].placeId ?? '';
//                             final selectedPlace = places[index];
//                             try {
//                               final coords = await mapService.getPlace(placeId);
//                               final lat = double.tryParse(
//                                 coords.lat.toString(),
//                               );
//                               final lng = double.tryParse(
//                                 coords.lng.toString(),
//                               );
//                               if (!mounted) return;
//                               // Update local state (search bar city label)
//                               setState(() {
//                                 _city = selectedPlace;
//                                 _lat = lat;
//                                 _lng = lng;
//                               });
//                               // Move the map camera to the new location
//                               if (lat != null && lng != null) {
//                                 widget.controllerService.animateTo(
//                                   LatLng(lat, lng),
//                                   zoom: 14,
//                                 );
//                               }
//                               // Keep Home in sync
//                               widget.onLocationChanged(selectedPlace, lat, lng);
//                             } catch (_) {
//                               if (!mounted) return;
//                               setState(() => _city = selectedPlace);
//                               widget.onLocationChanged(
//                                 selectedPlace,
//                                 null,
//                                 null,
//                               );
//                             }
//                             if (!context.mounted) return;
//                             Navigator.pop(context);
//                           },
//                         );
//                       },
//                     ),
//                   SizedBox(height: 20.h),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Future<void> _fetchAndApplyCurrentLocation() async {
//     if (mounted) setState(() => _isLocationLoading = true);
//     try {
//       final Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//       final List<Placemark> placemarks = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );
//       final city = placemarks.isNotEmpty
//           ? (placemarks.first.locality ??
//                 placemarks.first.subLocality ??
//                 placemarks.first.name ??
//                 "Unknown")
//           : "Unknown";

//       if (!mounted) return;
//       setState(() {
//         _city = city;
//         _lat = position.latitude;
//         _lng = position.longitude;
//       });
//       ref.read(userLocationProvider.notifier).state = LatLng(
//         position.latitude,
//         position.longitude,
//       ); // ← here
//       widget.controllerService.animateTo(
//         LatLng(position.latitude, position.longitude),
//         zoom: 15.5,
//       );
//       widget.onLocationChanged(city, position.latitude, position.longitude);
//     } catch (_) {
//       if (!mounted) return;
//       setState(() => _city = "Unknown");
//     } finally {
//       if (mounted) setState(() => _isLocationLoading = false);
//     }
//   }

//   Future<void> _handleBack() async {
//     if (ref.read(selectedRestaurantProvider) != null) {
//       await widget.onClearSelectedRestaurant();
//       return;
//     }

//     widget.onClose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // ← WidgetRef via ConsumerState
//     final selectedMapRestaurant = ref.watch(selectedRestaurantProvider);
//     final topPad = MediaQuery.paddingOf(context).top;
//     final mapSize = MediaQuery.sizeOf(context);
//     final isTablet = Breakpoints.isTablet(mapSize.width);
//     final isCompactPhone = mapSize.width < 390 || mapSize.height < 700;
//     final cardHorizontalInset = isTablet
//         ? 24.0
//         : isCompactPhone
//         ? 8.0
//         : 12.0;
//     final cardBottomInset = isTablet
//         ? mapSize.height * 0.10
//         : isCompactPhone
//         ? mapSize.height * 0.12
//         : mapSize.height * 0.15;
//     final double cardMaxWidth = isTablet
//         ? 720.0
//         : (mapSize.width - (cardHorizontalInset * 2))
//               .clamp(0.0, 560.0)
//               .toDouble();
//     final cardMaxHeight = mapSize.height * (isTablet ? 0.58 : 0.55);

//     return WillPopScope(
//       onWillPop: () async {
//         await _handleBack();
//         return false;
//       },
//       child: Scaffold(
//         body: Stack(
//           fit: StackFit.expand,
//           children: [
//             Hero(
//               tag: 'map-expand',
//               child: PersistentGoogleMap(
//                 key: const ValueKey('home-expanded-google-map'),
//                 initialCameraPosition: widget.initialCameraPosition,
//                 controllerService: widget.controllerService,
//                 onMapTap: () {
//                   unawaited(widget.onClearSelectedRestaurant());
//                 },
//                 gesturesEnabled: true,
//                 showMyLocation: widget.hasMapPermission,
//               ),
//             ),

//             // Search bar — uses local _city so it updates instantly
//             Positioned(
//               top: topPad + 10.h,
//               left: 16.w,
//               right: 16.w,
//               child: AppSearchBar(
//                 city: _city,
//                 isLocationLoading: _isLocationLoading,
//                 searchController: _restaurantSearchController,
//                 searchHintText: 'Search restaurants...',
//                 onSearchChanged: _handleRestaurantSearchChanged,
//                 onSearchSubmitted: _handleRestaurantSearchSubmitted,
//                 onBackTap: () => unawaited(_handleBack()),
//                 onLocationTap: _showLocationPicker, // ← opens picker in-map
//               ),
//             ),

//             // Filter row
//             Positioned(
//               top: topPad + 10.h + 60.h + 10.h,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: _MapFilterRow(
//                   selectedDateTime: _selectedDateTime,
//                   selectedDiscountIndex: _selectedDiscountIndex,
//                   selectedTypeIndex: _selectedTypeIndex,
//                   selectedDistance: _selectedDistance,
//                   onApplyFilters: _applyFilters,
//                   onApplyDateTime: _applyDateTimeFilter,
//                   onClearFilters: _showFiltersClearedSnackBar,
//                 ),
//               ),
//             ),

//             if (_shouldShowRestaurantSearchDropdown)
//               Positioned(
//                 top: topPad + 10.h + 68.h,
//                 left: 16.w,
//                 right: 16.w,
//                 child: _RestaurantSearchDropdown(
//                   query: _restaurantSearchQuery,
//                   restaurants: _restaurantSearchResults,
//                   isLoading: _isRestaurantSearchLoading,
//                   onSelected: (restaurant) {
//                     FocusScope.of(context).unfocus();
//                     unawaited(_selectSearchRestaurant(restaurant));
//                   },
//                 ),
//               ),

//             if (selectedMapRestaurant != null)
//               Positioned(
//                 left: cardHorizontalInset,
//                 right: cardHorizontalInset,
//                 bottom: cardBottomInset,
//                 child: Center(
//                   child: ConstrainedBox(
//                     constraints: BoxConstraints(
//                       maxWidth: cardMaxWidth,
//                       maxHeight: cardMaxHeight,
//                     ),
//                     child: AnimatedSwitcher(
//                       duration: const Duration(milliseconds: 350),
//                       transitionBuilder: (child, animation) {
//                         final slide =
//                             Tween<Offset>(
//                               begin: const Offset(0, 1),
//                               end: Offset.zero,
//                             ).animate(
//                               CurvedAnimation(
//                                 parent: animation,
//                                 curve: Curves.easeOutCubic,
//                               ),
//                             );
//                         return SlideTransition(
//                           position: slide,
//                           child: FadeTransition(
//                             opacity: animation,
//                             child: child,
//                           ),
//                         );
//                       },

//                       child: Material(
//                         color: Colors.transparent,
//                         child: SingleChildScrollView(
//                           child: InkWell(
//                             onTap: () async {
//                               await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => RestaurantProfile(
//                                     uuid: selectedMapRestaurant.uuid,
//                                     deliveryServiceArea: selectedMapRestaurant
//                                         .deliveryServiceArea,
//                                     averageReview:
//                                         selectedMapRestaurant.averageReview,
//                                     distance: selectedMapRestaurant.distance,
//                                     isFavourite:
//                                         selectedMapRestaurant.isFavorite,
//                                   ),
//                                 ),
//                               );
//                               // if (result is bool) {
//                               //   if (!mounted) return;
//                               //   setState(() {
//                               //     restaurantsList = restaurantsList
//                               //         .map(
//                               //           (r) => r.uuid == restaurant.uuid
//                               //               ? r.copyWith(isFavorite: result)
//                               //               : r,
//                               //         )
//                               //         .toList();
//                               //     filteredList = filteredList
//                               //         .map(
//                               //           (r) => r.uuid == restaurant.uuid
//                               //               ? r.copyWith(isFavorite: result)
//                               //               : r,
//                               //         )
//                               //         .toList();
//                               //   });
//                               // }
//                             },
//                             child: RestaurantMapCard(
//                               uuid: selectedMapRestaurant.uuid,
//                               name: selectedMapRestaurant.name,
//                               type: selectedMapRestaurant.type,
//                               address: selectedMapRestaurant.address,
//                               phone: selectedMapRestaurant.phone,
//                               lat: selectedMapRestaurant.lat,
//                               lng: selectedMapRestaurant.lng,
//                               description: selectedMapRestaurant.description,
//                               availableDishes:
//                                   selectedMapRestaurant.availableDishes,
//                               takeAwayService:
//                                   selectedMapRestaurant.takeAwayService,
//                               deliveryService:
//                                   selectedMapRestaurant.deliveryService,
//                               deliveryServiceArea:
//                                   selectedMapRestaurant.deliveryServiceArea,
//                               averageReview:
//                                   selectedMapRestaurant.averageReview,
//                               distance: selectedMapRestaurant.distance,
//                               restaurantType:
//                                   selectedMapRestaurant.restaurantType,
//                               status: selectedMapRestaurant.status,
//                               isFavourite: selectedMapRestaurant.isFavorite,
//                               image: selectedMapRestaurant.image,
//                               offers: selectedMapRestaurant.offers,
//                               isFavoriteBox: false,
//                               onRatingOnClick: () => Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (_) => RatingPage(
//                                     restaurantId: selectedMapRestaurant.uuid,
//                                     restaurantName: selectedMapRestaurant.name,
//                                     restaurantAddress:
//                                         selectedMapRestaurant.address,
//                                   ),
//                                 ),
//                               ),
//                               onBoxClicked:
//                                   (String? offerId, OfferModel? offer) {
//                                     final selectedOffers = selectedMapRestaurant
//                                         .offers
//                                         .where((offer) => offer.uuid == offerId)
//                                         .toList();
//                                     showModalBottomSheet(
//                                       backgroundColor: Colors.white,
//                                       context: context,
//                                       isScrollControlled: true,
//                                       shape: const RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.vertical(
//                                           top: Radius.circular(25),
//                                         ),
//                                       ),
//                                       builder: (_) => NumberOfPeopleModal(
//                                         uuid: selectedMapRestaurant.uuid,
//                                         reservationDate: _selectedDateTime,
//                                         offerId: offerId,
//                                         offer:
//                                             offer ??
//                                             (selectedOffers.isEmpty
//                                                 ? null
//                                                 : selectedOffers.first),
//                                       ),
//                                     );
//                                   },
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─── Filter row widget ────────────────────────────────────────────────────────
// class _RestaurantSearchDropdown extends StatelessWidget {
//   const _RestaurantSearchDropdown({
//     required this.query,
//     required this.restaurants,
//     required this.isLoading,
//     required this.onSelected,
//   });

//   final String query;
//   final List<RestaurantModel> restaurants;
//   final bool isLoading;
//   final ValueChanged<RestaurantModel> onSelected;

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.sizeOf(context);
//     final isTablet = Breakpoints.isTablet(size.width);
//     final isCompactPhone = size.width < 390 || size.height < 700;
//     final maxHeight = isTablet
//         ? 360.0
//         : isCompactPhone
//         ? 260.0
//         : 310.0;
//     final itemImageSize = isTablet
//         ? 52.0
//         : isCompactPhone
//         ? 42.0
//         : 46.0;
//     final titleSize = isTablet
//         ? 14.0
//         : isCompactPhone
//         ? 12.0
//         : 13.sp;
//     final metaSize = isTablet
//         ? 12.0
//         : isCompactPhone
//         ? 10.5
//         : 11.sp;

//     return Material(
//       color: Colors.transparent,
//       child: Container(
//         constraints: BoxConstraints(maxHeight: maxHeight),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14.r),
//           border: Border.all(color: const Color(0xFFF0E1D6)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.16),
//               blurRadius: 18,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         clipBehavior: Clip.antiAlias,
//         child: _buildContent(
//           context,
//           imageSize: itemImageSize,
//           titleSize: titleSize,
//           metaSize: metaSize,
//         ),
//       ),
//     );
//   }

//   Widget _buildContent(
//     BuildContext context, {
//     required double imageSize,
//     required double titleSize,
//     required double metaSize,
//   }) {
//     if (isLoading && restaurants.isEmpty) {
//       return SizedBox(
//         height: 86.h,
//         child: Center(
//           child: SizedBox(
//             width: 22,
//             height: 22,
//             child: CircularProgressIndicator(
//               strokeWidth: 2.4,
//               color: appButtonColor,
//             ),
//           ),
//         ),
//       );
//     }

//     if (restaurants.isEmpty) {
//       return SizedBox(
//         height: 92.h,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.search_off_rounded,
//               color: appButtonColor.withValues(alpha: 0.78),
//               size: 21,
//             ),
//             SizedBox(width: 8.w),
//             Flexible(
//               child: Text(
//                 'No restaurants found for "$query"',
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   color: locationTextColor.withValues(alpha: 0.72),
//                   fontSize: metaSize + 1,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.separated(
//       padding: EdgeInsets.symmetric(vertical: 6.h),
//       shrinkWrap: true,
//       itemCount: restaurants.length,
//       separatorBuilder: (_, __) => Divider(
//         height: 1,
//         indent: imageSize + 26.w,
//         endIndent: 14.w,
//         color: const Color(0xFFF2E8DF),
//       ),
//       itemBuilder: (context, index) {
//         final restaurant = restaurants[index];
//         final distanceLabel = restaurant.distance == null
//             ? null
//             : '${restaurant.distance!.toStringAsFixed(restaurant.distance! % 1 == 0 ? 0 : 1)} km';

//         return InkWell(
//           onTap: () => onSelected(restaurant),
//           child: Padding(
//             padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
//             child: Row(
//               children: [
//                 _SearchRestaurantImage(
//                   imageUrl: restaurant.image,
//                   size: imageSize,
//                 ),
//                 SizedBox(width: 11.w),
//                 Expanded(
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(
//                               restaurant.name,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 color: appTextColor3,
//                                 fontSize: titleSize,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ),
//                           if (distanceLabel != null) ...[
//                             SizedBox(width: 8.w),
//                             Container(
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: 7.w,
//                                 vertical: 3.h,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: appButtonColor.withValues(alpha: 0.1),
//                                 borderRadius: BorderRadius.circular(999),
//                               ),
//                               child: Text(
//                                 distanceLabel,
//                                 style: TextStyle(
//                                   color: appButtonColor,
//                                   fontSize: metaSize,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                       SizedBox(height: 3.h),
//                       Text(
//                         restaurant.type.isNotEmpty
//                             ? restaurant.type
//                             : restaurant.restaurantType,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           color: locationTextColor.withValues(alpha: 0.7),
//                           fontSize: metaSize,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       SizedBox(height: 2.h),
//                       Text(
//                         restaurant.address,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           color: locationTextColor.withValues(alpha: 0.52),
//                           fontSize: metaSize,
//                           fontWeight: FontWeight.w400,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(width: 8.w),
//                 Icon(
//                   Icons.near_me_rounded,
//                   color: appButtonColor,
//                   size: titleSize + 7,
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class _SearchRestaurantImage extends StatelessWidget {
//   const _SearchRestaurantImage({required this.imageUrl, required this.size});

//   final String? imageUrl;
//   final double size;

//   @override
//   Widget build(BuildContext context) {
//     final fallback = Container(
//       width: size,
//       height: size,
//       color: appButtonColor.withValues(alpha: 0.1),
//       child: Icon(
//         Icons.restaurant_rounded,
//         color: appButtonColor,
//         size: size * 0.48,
//       ),
//     );

//     return ClipRRect(
//       borderRadius: BorderRadius.circular(10.r),
//       child: imageUrl == null || imageUrl!.isEmpty
//           ? fallback
//           : Image.network(
//               imageUrl!,
//               width: size,
//               height: size,
//               fit: BoxFit.cover,
//               errorBuilder: (_, __, ___) => fallback,
//             ),
//     );
//   }
// }

// class _MapFilterRow extends StatelessWidget {
//   final DateTime? selectedDateTime;
//   final int? selectedDiscountIndex;
//   final int? selectedTypeIndex;
//   final double selectedDistance;
//   final Future<void> Function(int?, int?, double) onApplyFilters;
//   final Future<void> Function(DateTime) onApplyDateTime;
//   final VoidCallback onClearFilters;

//   const _MapFilterRow({
//     required this.selectedDateTime,
//     required this.selectedDiscountIndex,
//     required this.selectedTypeIndex,
//     required this.selectedDistance,
//     required this.onApplyFilters,
//     required this.onApplyDateTime,
//     required this.onClearFilters,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.sizeOf(context).width;
//     final height = MediaQuery.sizeOf(context).height;
//     final isTablet = Breakpoints.isTablet(width);
//     final isCompactPhone = width < 390 || height < 700;
//     final tabletSheetWidth = width * 0.88;
//     final iconSize = isTablet ? 18.0 : 14.w;
//     final gap = isTablet ? 12.0 : 8.w;

//     return Row(
//       mainAxisSize: MainAxisSize.min,

//       children: [
//         // Filter button
//         GestureDetector(
//           onTap: () {
//             showModalBottomSheet(
//               backgroundColor: Colors.white,
//               context: context,
//               isScrollControlled: true,
//               constraints: isTablet
//                   ? BoxConstraints(
//                       minWidth: tabletSheetWidth,
//                       maxWidth: tabletSheetWidth,
//                     )
//                   : null,
//               shape: const RoundedRectangleBorder(
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//               ),
//               builder: (_) => FilterBottomModal(
//                 onApply: onApplyFilters,
//                 initialDiscountIndex: selectedDiscountIndex,
//                 initialTypeIndex: selectedTypeIndex,
//                 initialDistance: selectedDistance,
//                 onClear: onClearFilters,
//               ),
//             );
//           },
//           child: _filterChip(
//             context,
//             icon: Image.asset(
//               filterIcon,
//               width: iconSize,
//               height: iconSize,
//               color: Colors.black87,
//             ),
//             label: 'Filter',
//             isTablet: isTablet,
//             isCompactPhone: isCompactPhone,
//           ),
//         ),

//         SizedBox(width: gap),

//         // Date / time button
//         GestureDetector(
//           onTap: () {
//             showModalBottomSheet(
//               backgroundColor: Colors.white,
//               context: context,
//               isScrollControlled: true,
//               constraints: isTablet
//                   ? BoxConstraints(
//                       minWidth: tabletSheetWidth,
//                       maxWidth: tabletSheetWidth,
//                     )
//                   : null,
//               shape: const RoundedRectangleBorder(
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//               ),
//               builder: (_) => TimeBottomModal(
//                 initialDateTime: selectedDateTime ?? DateTime.now(),
//                 onApply: onApplyDateTime,
//               ),
//             );
//           },
//           child: _filterChip(
//             context,
//             icon: Image.asset(
//               filtercalenderIcon,
//               width: iconSize,
//               height: iconSize,
//               color: Colors.black87,
//             ),
//             label: selectedDateTime != null
//                 ? "${DateFormat('d MMM').format(selectedDateTime!)} at ${DateFormat('h:mma').format(selectedDateTime!)}"
//                 : "${DateFormat('d MMM').format(DateTime.now())} at ${DateFormat('h:mma').format(DateTime.now())}",
//             isTablet: isTablet,
//             isCompactPhone: isCompactPhone,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _filterChip(
//     BuildContext context, {
//     required Widget icon,
//     required String label,
//     required bool isTablet,
//     required bool isCompactPhone,
//   }) {
//     final horizontalPadding = isTablet ? 14.0 : 12.w;
//     final verticalPadding = isTablet ? 10.0 : 9.h;
//     final textSize = isTablet
//         ? 13.0
//         : isCompactPhone
//         ? 11.0
//         : 12.sp;
//     final arrowSize = isTablet ? 17.0 : 15.w;

//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: horizontalPadding,
//         vertical: verticalPadding,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10.r),
//         border: Border.all(color: Colors.grey.shade300),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF000000).withValues(alpha: 0.10),
//             blurRadius: 10,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           icon,
//           SizedBox(width: 6.w),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: textSize,
//               fontWeight: FontWeight.w400,
//               color: Colors.black87,
//             ),
//           ),
//           SizedBox(width: 4.w),
//           Icon(
//             Icons.keyboard_arrow_down,
//             size: arrowSize,
//             color: Colors.black54,
//           ),
//         ],
//       ),
//     );
//   }
// }
