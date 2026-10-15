import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/features/map/providers/map_providers.dart';
import 'package:fudikoclient/model/auth/mapplace-model.dart';
import 'package:fudikoclient/service/auth/map-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/snackbar.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:shared_preferences/shared_preferences.dart';

/// Full-screen map with a search bar on top and a radius panel at the bottom.
///
/// Hands the chosen point and radius back through [returndata] as
/// `(lat, lng, km)` strings — the contract the inquiry screens already use.
class LocationSelect extends ConsumerStatefulWidget {
  final Function(String, String, String) returndata;
  final double? initialLat;
  final double? initialLng;
  final double? initialDistance;

  const LocationSelect({
    super.key,
    required this.returndata,
    this.initialLat,
    this.initialLng,
    this.initialDistance,
  });

  @override
  ConsumerState<LocationSelect> createState() => _LocationSelectState();
}

class _LocationSelectState extends ConsumerState<LocationSelect> {
  static const Color _accent = Color(0xFFF87B0D);
  static const Color _searchIconColor = Color(0xFFD3690E);
  static const LatLng _fallbackCenter = LatLng(12.9716, 77.5946);
  static const String _cacheKeyLat = 'cached_lat';
  static const String _cacheKeyLng = 'cached_lng';
  static const double _placedZoom = 14;
  static const double _emptyZoom = 11;
  static const double _minDistance = 0;
  static const double _maxDistance = 100;

  final MapService _mapService = MapService();
  final loc.Location _location = loc.Location();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  GoogleMapController? _mapController;
  Timer? _searchDebounce;

  /// Bumped on every suggestion request, so a slow earlier response cannot
  /// overwrite the list a later keystroke has already filled in.
  int _searchRequestId = 0;

  LatLng _initialCenter = _fallbackCenter;
  LatLng? _selected;
  String? _selectedTitle;
  double _distance = 10;

  List<MapPlacesResponse> _suggestions = const [];

  /// Shown in place of the list: 'no places found', or why the lookup failed.
  String? _searchError;
  bool _isSearching = false;
  bool _isLocating = false;

  /// Real height of the bottom panel once it has been laid out. It moves with
  /// text scale and the gesture inset, so the map padding and the suggestion
  /// list read it rather than assuming it.
  double? _panelHeight;

  /// What Apply returns and what search results are biased towards: the
  /// picked point, or the map's starting centre before anything is picked.
  LatLng get _target => _selected ?? _initialCenter;

  Set<Marker> get _markers {
    final selected = _selected;
    if (selected == null) return const {};

    final title = _selectedTitle;
    return {
      Marker(
        // One stable id: re-keying the marker per source (search, tap,
        // GPS) makes the map drop and re-add it on every change.
        markerId: const MarkerId('selected_location'),
        position: selected,
        infoWindow: title == null || title.isEmpty
            ? InfoWindow.noText
            : InfoWindow(title: title),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    };
  }

  Set<Circle> get _circles {
    final selected = _selected;
    if (selected == null || _distance <= 0) return const {};

    return {
      Circle(
        circleId: const CircleId('selected_radius'),
        center: selected,
        radius: _distance * 1000,
        strokeColor: _accent,
        strokeWidth: 1,
        fillColor: _accent.withValues(alpha: 0.08),
      ),
    };
  }

  @override
  void initState() {
    super.initState();
    // Clamped: the slider asserts if it is handed a value outside its
    // range, and the radius arrives as a parsed string from the caller.
    _distance = (widget.initialDistance ?? _distance).clamp(
      _minDistance,
      _maxDistance,
    );
    _seedLocation();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // ── starting point ────────────────────────────────────────────────────────

  /// Where the map opens: what the caller passed in, else the home location
  /// the user already chose, else the last cached fix.
  void _seedLocation() {
    final lat = widget.initialLat;
    final lng = widget.initialLng;
    if (lat != null && lng != null) {
      _initialCenter = LatLng(lat, lng);
      _selected = _initialCenter;
      return;
    }

    final home = ref.read(selectedLocationProvider);
    if (home?.latitude != null && home?.longitude != null) {
      _initialCenter = LatLng(home!.latitude!, home.longitude!);
      _selected = _initialCenter;
      return;
    }

    unawaited(_loadCachedLocation());
  }

  Future<void> _loadCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_cacheKeyLat);
    final lng = prefs.getDouble(_cacheKeyLng);
    if (lat == null || lng == null || !mounted) return;
    // A tap or a search that landed while prefs were loading wins over the
    // cache — this arrives late by definition.
    if (_selected != null) return;

    final cached = LatLng(lat, lng);
    setState(() {
      _initialCenter = cached;
      _selected = cached;
    });
    _moveCamera(cached, _placedZoom);
  }

  // ── map ───────────────────────────────────────────────────────────────────

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final selected = _selected;
    if (selected != null) _moveCamera(selected, _placedZoom);
  }

  /// A no-op until the map hands over its controller — search, suggestion
  /// taps and the locate button can all fire before the map finishes
  /// creating itself.
  void _moveCamera(LatLng target, double zoom) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  void _select(LatLng position, {String? title}) {
    setState(() {
      _selected = position;
      _selectedTitle = title;
    });
  }

  Future<void> _goToCurrentLocation() async {
    if (_isLocating) return;

    setState(() => _isLocating = true);
    try {
      final fix = await _location.getLocation();
      if (!mounted) return;

      final lat = fix.latitude;
      final lng = fix.longitude;
      if (lat == null || lng == null) {
        showErrorSnack(context, 'Could not read your current location');
        return;
      }

      final here = LatLng(lat, lng);
      _select(here);
      _moveCamera(here, 15);
    } catch (_) {
      // Permission denied or location services off: say so rather than
      // letting the failure surface as an unhandled exception.
      if (mounted) {
        showErrorSnack(context, 'Location unavailable. Check app permissions.');
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ── search ────────────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    final query = value.trim();
    if (query.isEmpty) {
      // Invalidate whatever is in flight, so a pending response cannot
      // repopulate a list the user has just emptied.
      _searchRequestId++;
      setState(() {
        _suggestions = const [];
        _searchError = null;
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _loadSuggestions(query),
    );
  }

  Future<void> _loadSuggestions(String query) async {
    final requestId = ++_searchRequestId;
    setState(() => _isSearching = true);

    try {
      final results = await _mapService.listPlaces(
        query,
        lat: _target.latitude,
        lng: _target.longitude,
      );
      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _suggestions = results;
        _searchError = results.isEmpty ? 'No places found' : null;
        _isSearching = false;
      });
    } catch (e) {
      // listPlaces throws on a network or API failure. Without this the
      // spinner spins forever and the error surfaces as an unhandled
      // exception instead of something the user can read.
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _suggestions = const [];
        _searchError = e is MapPlaceSearchException
            ? e.message
            : 'Could not load search suggestions. Please try again.';
        _isSearching = false;
      });
    }
  }

  Future<void> _selectSuggestion(MapPlacesResponse place) async {
    final placeId = place.placeId;
    if (placeId == null || placeId.isEmpty) return;

    _dismissKeyboard();
    setState(() => _isSearching = true);
    final coordinates = await _mapService.getPlace(placeId);
    if (!mounted) return;
    setState(() => _isSearching = false);

    final lat = coordinates.lat ?? 0;
    final lng = coordinates.lng ?? 0;
    // getPlace answers (0, 0) when the lookup fails rather than throwing.
    if (lat == 0 && lng == 0) {
      showErrorSnack(context, 'Could not open that place');
      return;
    }

    final target = LatLng(lat, lng);
    _searchController.text = place.mainText ?? _searchController.text;
    setState(() {
      _suggestions = const [];
      _searchError = null;
    });
    _select(target, title: place.mainText);
    _moveCamera(target, _placedZoom);
  }

  /// Enter on the keyboard: take the top suggestion if the list is up,
  /// otherwise geocode the raw text.
  Future<void> _submitSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (_suggestions.isNotEmpty) {
      await _selectSuggestion(_suggestions.first);
      return;
    }

    _dismissKeyboard();
    setState(() => _isSearching = true);
    try {
      final matches = await geo.locationFromAddress(query);
      if (!mounted) return;
      if (matches.isEmpty) {
        showErrorSnack(context, 'Location not found: $query');
        return;
      }

      final target = LatLng(matches.first.latitude, matches.first.longitude);
      _select(target, title: query);
      _moveCamera(target, _placedZoom);
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Location not found: $query');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchRequestId++;
    _searchController.clear();
    setState(() {
      _suggestions = const [];
      _searchError = null;
      _isSearching = false;
    });
  }

  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  void _onPanelHeightChanged(double height) {
    if (!mounted) return;
    setState(() => _panelHeight = height);
  }

  void _apply() {
    final target = _target;
    Navigator.pop(context);
    widget.returndata(
      target.latitude.toString(),
      target.longitude.toString(),
      _distance.toInt().toString(),
    );
  }

  // ── layout ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final metrics = _LocationSelectMetrics.of(context);
    // Read the keyboard from the root view rather than the ambient
    // MediaQuery. A Scaffold that resizes for the keyboard strips viewInsets
    // from everything in its body, so the ambient value reads 0 whenever this
    // screen is pushed inside one — which is exactly the case this screen was
    // getting wrong.
    final view = View.of(context);
    final keyboardInset = view.viewInsets.bottom / view.devicePixelRatio;

    return Scaffold(
      backgroundColor: appSecondaryBackgroundColor,
      // The keyboard comes up *over* the radius panel instead of shoving the
      // layout upwards: the map keeps its size, the slider and Apply button
      // stay exactly where they were, simply covered while the user types.
      //
      // This only holds while nothing above the screen shrinks it: a Scaffold
      // that resizes for the keyboard hands its body a shorter box, and every
      // route inside it is laid out in that box no matter what it sets here.
      // Hence the root-navigator pushes at the call sites — see ctInquery.dart.
      resizeToAvoidBottomInset: false,
      // No SafeArea around the map — it runs full bleed under the status bar.
      // The search bar and the panel inset themselves instead.
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(child: _map(metrics)),
              Positioned(
                left: metrics.horizontalPadding + metrics.leftInset,
                right: metrics.horizontalPadding + metrics.rightInset,
                top: metrics.searchTop,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _searchBar(metrics),
                    if (_suggestions.isNotEmpty || _searchError != null) ...[
                      SizedBox(height: metrics.suggestionsGap),
                      _searchResultsBox(metrics, constraints, keyboardInset),
                    ],
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                // The locate button rides in the same bottom-anchored column
                // as the panel, so it sits above it by construction — no
                // offset to keep in sync with the panel's height.
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        right: metrics.horizontalPadding + metrics.rightInset,
                        bottom: metrics.controlGap,
                      ),
                      child: _locateButton(metrics),
                    ),
                    _MeasuredHeight(
                      onChanged: _onPanelHeightChanged,
                      child: _panel(metrics),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _map(_LocationSelectMetrics metrics) {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _initialCenter,
        zoom: _selected == null ? _emptyZoom : _placedZoom,
      ),
      myLocationEnabled: true,
      // The screen carries its own locate button, and the map already
      // pinch-zooms.
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      // Keeps Google's logo and attribution clear of the overlays drawn on
      // top of the map.
      padding: EdgeInsets.only(
        top: metrics.searchTop + metrics.searchBarHeight,
        bottom: _panelHeight ?? metrics.estimatedPanelHeight,
        left: metrics.leftInset,
        right: metrics.rightInset,
      ),
      markers: _markers,
      circles: _circles,
      onTap: (position) {
        _dismissKeyboard();
        setState(() {
          _suggestions = const [];
          _searchError = null;
        });
        _select(position);
      },
    );
  }

  Widget _searchBar(_LocationSelectMetrics metrics) {
    return Container(
      height: metrics.searchBarHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: _floatingShadow,
      ),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Clears a search in progress first, and only leaves the screen
            // once there is nothing left to clear.
            onTap: () {
              if (_searchController.text.isEmpty && _suggestions.isEmpty) {
                Navigator.pop(context);
                return;
              }
              _clearSearch();
              _dismissKeyboard();
            },
            child: SizedBox(
              width: metrics.searchSlotWidth,
              height: metrics.searchBarHeight,
              child: Icon(
                Icons.close,
                size: 18,
                color: _searchIconColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: AppTextFeild(
              controller: _searchController,
              focusNode: _searchFocus,
              text: 'Search Location',
              height: metrics.searchBarHeight,
              size: metrics.searchTextSize,
              isTextCenter: true,
              textColor: _searchIconColor.withValues(alpha: 0.7),
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.zero,
              // The bar around it already casts the shadow; without this the
              // field falls back to AppTextFeild's default one and draws a
              // grey smudge inside the white bar.
              boxShadow: const [],
              fieldBorderRadius: 16,
              sideIconSlotWidth: 0,
              sideSpacing: 0,
              inputContentPadding: const EdgeInsets.symmetric(vertical: 14),
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onFieldSubmitted: (_) => _submitSearch(),
              // No `decoration:` on purpose. Supplying one replaces the
              // decoration AppTextFeild builds, and with it the translated
              // hint — the field would show English 'Search Location' in
              // every language.
            ),
          ),
          SizedBox(
            width: metrics.searchSlotWidth,
            child: _isSearching
                ? const Center(
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _accent,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  /// The dropdown under the search bar: the predictions, or the one-line
  /// message explaining why there are none.
  Widget _searchResultsBox(
    _LocationSelectMetrics metrics,
    BoxConstraints constraints,
    double keyboardInset,
  ) {
    // Whatever covers the bottom of the map is what the list has to stay
    // clear of: the keyboard while typing, the radius panel otherwise.
    // (Android is set to adjustNothing, so the inset only arrives on
    // platforms that report one — the panel height is the floor either way.)
    final occluded = math.max(
      keyboardInset,
      _panelHeight ?? metrics.estimatedPanelHeight,
    );
    final available =
        constraints.maxHeight -
        metrics.searchTop -
        metrics.searchBarHeight -
        metrics.suggestionsGap -
        occluded -
        metrics.controlGap;

    final error = _searchError;
    return Container(
      constraints: BoxConstraints(
        maxHeight: available.clamp(
          metrics.suggestionsMinHeight,
          metrics.suggestionsMaxHeight,
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _floatingShadow,
      ),
      child: _suggestions.isEmpty && error != null
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: AppText(
                text: error,
                size: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
                maxLines: 2,
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final place = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: _accent,
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
                  onTap: () => _selectSuggestion(place),
                );
              },
            ),
    );
  }

  Widget _locateButton(_LocationSelectMetrics metrics) {
    return SizedBox(
      width: metrics.locateButtonSize,
      height: metrics.locateButtonSize,
      child: FloatingActionButton(
        heroTag: 'location_select_my_location',
        backgroundColor: Colors.white,
        onPressed: _isLocating ? null : _goToCurrentLocation,
        child: _isLocating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.black,
                ),
              )
            : Icon(
                Icons.my_location,
                size: metrics.locateIconSize,
                color: appTextColor,
              ),
      ),
    );
  }

  Widget _panel(_LocationSelectMetrics metrics) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(metrics.panelRadius),
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
        padding: EdgeInsets.only(
          left: metrics.horizontalPadding + metrics.leftInset,
          right: metrics.horizontalPadding + metrics.rightInset,
          top: metrics.panelVerticalPadding,
          // The gesture inset is added on top of the padding rather than
          // replacing it, so the button is never sat on by the home bar.
          bottom: metrics.panelVerticalPadding + metrics.bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _accent,
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: _accent,
                      overlayColor: _accent.withValues(alpha: 0.2),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      min: _minDistance,
                      max: _maxDistance,
                      // Whole kilometres only — the readout beside it is an
                      // integer, so half-steps would just make it stutter.
                      divisions: (_maxDistance - _minDistance).toInt(),
                      value: _distance,
                      onChanged: (value) => setState(() => _distance = value),
                    ),
                  ),
                ),
                SizedBox(width: metrics.controlGap / 2),
                // Only the unit is translated, not the whole label: a label
                // per value would put 101 throwaway phrases through the
                // translator.
                TranslatedBuilder(
                  text: 'km',
                  builder: (context, unit) => ConstrainedBox(
                    // A floor on the width so the slider does not shift as
                    // the reading goes 9 → 10 → 100.
                    constraints: BoxConstraints(
                      minWidth: metrics.distanceLabelMinWidth,
                    ),
                    child: Text(
                      '${_distance.toInt()} $unit',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: metrics.distanceTextSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: metrics.panelGap),
            SizedBox(
              width: metrics.applyWidth,
              height: metrics.applyHeight,
              child: AppButton(
                text: 'Apply',
                onPressed: _apply,
                size: metrics.applyTextSize,
                borderRadius: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static final List<BoxShadow> _floatingShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Reports its child's laid-out height, once at first layout and again
/// whenever it changes. The panel's height moves with text scale and the
/// gesture inset, so it is measured rather than predicted.
class _MeasuredHeight extends StatefulWidget {
  const _MeasuredHeight({required this.child, required this.onChanged});

  final Widget child;
  final ValueChanged<double> onChanged;

  @override
  State<_MeasuredHeight> createState() => _MeasuredHeightState();
}

class _MeasuredHeightState extends State<_MeasuredHeight> {
  final GlobalKey _key = GlobalKey();
  double? _reported;

  @override
  void initState() {
    super.initState();
    // The first layout raises no size-change notification.
    WidgetsBinding.instance.addPostFrameCallback(_report);
  }

  void _report(Duration _) {
    if (!mounted) return;
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final height = box.size.height;
    if (_reported != null && (_reported! - height).abs() < 0.5) return;
    _reported = height;
    widget.onChanged(height);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        // Reading the box mid-layout is not allowed; do it once the frame
        // has settled.
        WidgetsBinding.instance.addPostFrameCallback(_report);
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: KeyedSubtree(key: _key, child: widget.child),
      ),
    );
  }
}

/// Every size on the screen, resolved once per build from the viewport.
class _LocationSelectMetrics {
  const _LocationSelectMetrics({
    required this.horizontalPadding,
    required this.searchTop,
    required this.searchBarHeight,
    required this.searchTextSize,
    required this.searchSlotWidth,
    required this.suggestionsGap,
    required this.suggestionsMinHeight,
    required this.suggestionsMaxHeight,
    required this.locateButtonSize,
    required this.locateIconSize,
    required this.controlGap,
    required this.panelRadius,
    required this.panelVerticalPadding,
    required this.panelGap,
    required this.bottomInset,
    required this.leftInset,
    required this.rightInset,
    required this.distanceTextSize,
    required this.distanceLabelMinWidth,
    required this.applyWidth,
    required this.applyHeight,
    required this.applyTextSize,
  });

  final double horizontalPadding;
  final double searchTop;
  final double searchBarHeight;
  final double searchTextSize;
  final double searchSlotWidth;
  final double suggestionsGap;
  final double suggestionsMinHeight;
  final double suggestionsMaxHeight;
  final double locateButtonSize;
  final double locateIconSize;

  /// Breathing room between the floating controls and whatever they sit above.
  final double controlGap;

  final double panelRadius;
  final double panelVerticalPadding;
  final double panelGap;
  final double bottomInset;

  /// Landscape cutout/navigation-bar insets. In landscape the system bar sits
  /// on one side of the screen, so every floating control has to be pushed in
  /// from that edge or it ends up underneath it.
  final double leftInset;
  final double rightInset;

  final double distanceTextSize;
  final double distanceLabelMinWidth;
  final double applyWidth;
  final double applyHeight;
  final double applyTextSize;

  /// Stand-in for the panel height on the very first frame, before it has
  /// been measured. Slider row + gap + button + padding.
  double get estimatedPanelHeight =>
      panelVerticalPadding * 2 + bottomInset + 48 + panelGap + applyHeight;

  factory _LocationSelectMetrics.of(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final isTablet = Breakpoints.isTabletDevice(size);
    // A short viewport is the tight case: the panel keeps its height while
    // the map shrinks, so everything floating has to tighten up.
    final isShort = size.height < 720;
    final isCompact = size.width < 390 || isShort;

    final topInset = media.viewPadding.top;
    // viewPadding, not padding: it keeps reporting the gesture inset while
    // the keyboard is up, so the panel does not change height underneath it.
    final bottomInset = media.viewPadding.bottom;
    final leftInset = media.viewPadding.left;
    final rightInset = media.viewPadding.right;

    if (isTablet) {
      return _LocationSelectMetrics(
        horizontalPadding: 28,
        searchTop: topInset + 24,
        searchBarHeight: 54,
        searchTextSize: 16,
        searchSlotWidth: 52,
        suggestionsGap: 10,
        suggestionsMinHeight: 120,
        suggestionsMaxHeight: 280,
        locateButtonSize: 60,
        locateIconSize: 26,
        controlGap: 20,
        panelRadius: 24,
        panelVerticalPadding: 32,
        panelGap: 24,
        bottomInset: bottomInset,
        leftInset: leftInset,
        rightInset: rightInset,
        distanceTextSize: 13,
        distanceLabelMinWidth: 66,
        applyWidth: 190,
        applyHeight: 48,
        applyTextSize: 17,
      );
    }

    if (isShort) {
      return _LocationSelectMetrics(
        horizontalPadding: 16,
        searchTop: topInset + 10,
        searchBarHeight: 40,
        searchTextSize: 13,
        searchSlotWidth: 38,
        suggestionsGap: 6,
        suggestionsMinHeight: 96,
        suggestionsMaxHeight: 150,
        locateButtonSize: 42,
        locateIconSize: 20,
        controlGap: 10,
        panelRadius: 18,
        panelVerticalPadding: 16,
        panelGap: 12,
        bottomInset: bottomInset,
        leftInset: leftInset,
        rightInset: rightInset,
        distanceTextSize: 10,
        distanceLabelMinWidth: 50,
        applyWidth: 130,
        applyHeight: 34,
        applyTextSize: 14,
      );
    }

    return _LocationSelectMetrics(
      horizontalPadding: 20,
      searchTop: topInset + (isCompact ? 14 : 20),
      searchBarHeight: 46,
      searchTextSize: 14,
      searchSlotWidth: 44,
      suggestionsGap: 8,
      suggestionsMinHeight: 96,
      suggestionsMaxHeight: 210,
      locateButtonSize: 52,
      locateIconSize: 24,
      controlGap: 16,
      panelRadius: 20,
      panelVerticalPadding: isCompact ? 24 : 30,
      panelGap: isCompact ? 16 : 22,
      bottomInset: bottomInset,
      leftInset: leftInset,
      rightInset: rightInset,
      distanceTextSize: 10,
      distanceLabelMinWidth: 52,
      applyWidth: 150,
      applyHeight: 40,
      applyTextSize: 15,
    );
  }
}
