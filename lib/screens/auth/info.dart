import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/auth/complete-registration.dart';
import 'package:fudikoclient/model/auth/mapplace-model.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/home/homepage.dart';
import 'package:fudikoclient/screens/auth/login.dart';
import 'package:fudikoclient/service/auth/registration-service.dart';
import 'package:fudikoclient/service/auth/map-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tokens.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key, this.authToken});

  final String? authToken;

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final RegistrationAuthService registrationAuthService =
      RegistrationAuthService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  bool isLoading = false;
  File? _profilePhoto;
  double? _selectedLat;
  double? _selectedLng;
  String _selectedPlaceName = '';

  @override
  void dispose() {
    phoneController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto(ImageSource source) async {
    final pickedImage = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 65,
    );

    if (pickedImage == null || !mounted) return;

    setState(() {
      _profilePhoto = File(pickedImage.path);
    });
  }

  void _showProfilePhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.padding(context),
              vertical: AppDimensions.gap(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.photo_camera, color: appButtonColor),
                  title: const Text('Take photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickProfilePhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: appButtonColor),
                  title: const Text('Upload from gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickProfilePhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const _MapPickerPage()),
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedLat = result['lat'] as double?;
      _selectedLng = result['lng'] as double?;
      _selectedPlaceName = (result['place'] ?? '').toString();
      locationController.text = _selectedPlaceName;
    });
  }

  Future<void> completeRegistration() async {
    if (phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter contact number')),
      );
      return;
    }

    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }

    setState(() => isLoading = true);

    final details = CompleteRegistrationModel(
      phone: phoneController.text,
      lat: _selectedLat.toString(),
      lng: _selectedLng.toString(),
      profilePicturePath: _profilePhoto?.path,
    );

    final response = await registrationAuthService.completeRegistration(
      details,
      tokenOverride: widget.authToken,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response.message)));

    if (response.status) {
      if (widget.authToken != null && widget.authToken!.isNotEmpty) {
        await saveToken(widget.authToken!);
        if (!mounted) return;
        pushWidgetWhileRemove(newPage: const HomePage(), context: context);
        return;
      }
      pushWidgetWhileRemove(newPage: const Login(), context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final size = MediaQuery.sizeOf(context);
                final height = size.height;
                final isMobileDevice = Breakpoints.isMobileDevice(size);
                final isMobile = isMobileDevice && Breakpoints.isMobile(width);
                final isTablet = Breakpoints.isTabletDevice(size);
                final isWideShortPhone =
                    isMobileDevice &&
                    orientation == Orientation.landscape &&
                    width >= 500 &&
                    height <= 760;

                final form = _InfoForm(
                  phoneController: phoneController,
                  locationController: locationController,
                  selectedPlaceName: _selectedPlaceName,
                  isLoading: isLoading,
                  isMobile: isMobile,
                  isWideShortPhone: isWideShortPhone,
                  onLocationTap: _openMapPicker,
                  onContinue: completeRegistration,
                );

                final avatar = _ProfilePhotoPicker(
                  photo: _profilePhoto,
                  isMobile: isMobile,
                  isWideShortPhone: isWideShortPhone,
                  onTap: _showProfilePhotoOptions,
                );

                if (isTablet && orientation == Orientation.landscape) {
                  return _TabletLandscapeInfoLayout(avatar: avatar, form: form);
                }

                return _StackedInfoLayout(
                  avatar: avatar,
                  form: form,
                  isMobile: isMobile,
                  isWideShortPhone: isWideShortPhone,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StackedInfoLayout extends StatelessWidget {
  const _StackedInfoLayout({
    required this.avatar,
    required this.form,
    required this.isMobile,
    required this.isWideShortPhone,
  });

  final Widget avatar;
  final Widget form;
  final bool isMobile;
  final bool isWideShortPhone;

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);
    final safeHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).vertical;
    final formWidth = isWideShortPhone
        ? 0.58
        : isMobile
        ? 0.84
        : 0.52;
    final avatarFormGap = isWideShortPhone
        ? 10.0
        : isMobile
        ? 20.0
        : AppDimensions.margin(context);

    return SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (safeHeight - padding.vertical)
              .clamp(0.0, double.infinity)
              .toDouble(),
          minWidth: double.infinity,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            avatar,
            SizedBox(height: avatarFormGap),
            Align(
              alignment: Alignment.center,
              child: FractionallySizedBox(widthFactor: formWidth, child: form),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabletLandscapeInfoLayout extends StatelessWidget {
  const _TabletLandscapeInfoLayout({required this.avatar, required this.form});

  final Widget avatar;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    final padding = AppDimensions.pagePadding(context);

    return SingleChildScrollView(
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight:
              (MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical -
                      padding.vertical)
                  .clamp(0.0, double.infinity)
                  .toDouble(),
          minWidth: double.infinity,
        ),
        child: Row(
          children: [
            Expanded(flex: 5, child: Center(child: avatar)),
            SizedBox(width: AppDimensions.margin(context)),
            Expanded(
              flex: 5,
              child: Center(
                child: FractionallySizedBox(widthFactor: 0.8, child: form),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhotoPicker extends StatelessWidget {
  const _ProfilePhotoPicker({
    required this.photo,
    required this.isMobile,
    required this.isWideShortPhone,
    required this.onTap,
  });

  final File? photo;
  final bool isMobile;
  final bool isWideShortPhone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatarSize = isWideShortPhone
        ? 96.0
        : isMobile
        ? 150.0
        : 170.0;
    final cameraSize = isWideShortPhone
        ? 28.0
        : isMobile
        ? 36.0
        : 42.0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipOval(
            child: photo == null
                ? Image.asset(
                    'assets/images/avatar.png',
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    photo!,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: cameraSize,
              height: cameraSize,
              decoration: BoxDecoration(
                color: appButtonColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: isWideShortPhone
                    ? 15
                    : isMobile
                    ? 18
                    : 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoForm extends StatelessWidget {
  const _InfoForm({
    required this.phoneController,
    required this.locationController,
    required this.selectedPlaceName,
    required this.isLoading,
    required this.isMobile,
    required this.isWideShortPhone,
    required this.onLocationTap,
    required this.onContinue,
  });

  final TextEditingController phoneController;
  final TextEditingController locationController;
  final String selectedPlaceName;
  final bool isLoading;
  final bool isMobile;
  final bool isWideShortPhone;
  final VoidCallback onLocationTap;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final gap = isWideShortPhone
        ? 10.0
        : isMobile
        ? 20.0
        : AppDimensions.gap(context) * 1.25;
    final fieldHeight = isWideShortPhone
        ? 48.0
        : isMobile
        ? 55.0
        : 60.0;
    final textSize = isWideShortPhone
        ? 13.0
        : isMobile
        ? 15.0
        : AppDimensions.body(context);
    final sectionGap = isWideShortPhone
        ? 16.0
        : isMobile
        ? 40.0
        : AppDimensions.margin(context);
    final buttonHeight = isWideShortPhone
        ? 50.0
        : isMobile
        ? 60.0
        : 62.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextFeild(
          text: "Contact Number",
          iconImagePath: phoneIcon,
          controller: phoneController,
          keyboardType: TextInputType.phone,
          height: fieldHeight,
          size: textSize,
        ),
        SizedBox(height: gap),
        GestureDetector(
          onTap: onLocationTap,
          child: AbsorbPointer(
            child: AppTextFeild(
              text: selectedPlaceName.isEmpty ? "Location" : selectedPlaceName,
              iconImagePath: mappingIcon,
              controller: locationController,
              suffixIcon: Icons.map_outlined,
              height: fieldHeight,
              size: textSize,
            ),
          ),
        ),
        SizedBox(height: sectionGap),
        AppButton(
          text: 'Continue',
          isLoading: isLoading,
          onPressed: isLoading ? null : onContinue,
          buttonheight: buttonHeight,
          size: textSize,
        ),
      ],
    );
  }
}

class _MapPickerPage extends StatefulWidget {
  const _MapPickerPage();

  @override
  State<_MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<_MapPickerPage> {
  final MapService _mapService = MapService();
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng _pickedLocation = const LatLng(10.8505, 76.2711);
  String _placeName = 'Kerala, India';
  bool _isGeocoding = false;
  bool _isFetchingCurrentLocation = false;
  bool _isSearching = false;
  Set<Marker> _markers = {};
  List<MapPlacesResponse> _searchResults = [];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (_isFetchingCurrentLocation) return;
    if (mounted) setState(() => _isFetchingCurrentLocation = true);

    try {
      final isLocationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        _showLocationSnackBar(
          'Turn on location services to use your current location',
          actionLabel: 'Settings',
          onAction: Geolocator.openLocationSettings,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showLocationSnackBar('Location permission was denied');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationSnackBar(
          'Location permission is permanently denied',
          actionLabel: 'Settings',
          onAction: Geolocator.openAppSettings,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _pickedLocation = latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      await _reverseGeocode(latLng);
      _updateMarker(latLng);
    } catch (_) {
      if (!mounted) return;
      setState(() => _placeName = 'Unable to fetch current location');
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel == null || onAction == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                onPressed: () {
                  onAction();
                },
              ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (!mounted || query != _searchController.text.trim()) return;
    setState(() => _isSearching = true);

    try {
      final places = await _mapService.listPlaces(
        query,
        lat: _pickedLocation.latitude,
        lng: _pickedLocation.longitude,
      );
      if (!mounted || query != _searchController.text.trim()) return;
      setState(() => _searchResults = places);
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchResults = []);
    } finally {
      if (mounted && query == _searchController.text.trim()) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _selectPlace(MapPlacesResponse place) async {
    final placeId = place.placeId;
    if (placeId == null || placeId.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final coordinates = await _mapService.getPlace(placeId);
      final lat = coordinates.lat;
      final lng = coordinates.lng;
      if (!mounted || lat == null || lng == null) return;

      final location = LatLng(lat, lng);
      setState(() => _pickedLocation = location);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 16),
      );
      _updateMarker(location);
      await _reverseGeocode(location);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((part) => part != null && part.isNotEmpty).toList();

        setState(() {
          _placeName = parts.isEmpty
              ? '${latLng.latitude}, ${latLng.longitude}'
              : parts.join(', ');
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _placeName = '${latLng.latitude}, ${latLng.longitude}');
    }

    if (!mounted) return;
    setState(() => _isGeocoding = false);
  }

  void _updateMarker(LatLng latLng) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('picked'),
          position: latLng,
          draggable: true,
          onDragEnd: (newPosition) async {
            setState(() => _pickedLocation = newPosition);
            await _reverseGeocode(newPosition);
            _updateMarker(newPosition);
          },
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'lat': _pickedLocation.latitude,
                'lng': _pickedLocation.longitude,
                'place': _placeName,
              });
            },
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final size = MediaQuery.sizeOf(context);
              final isTablet = Breakpoints.isTabletDevice(size);
              final map = _MapCanvas(
                pickedLocation: _pickedLocation,
                markers: _markers,
                onMapCreated: (controller) {
                  _mapController = controller;
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_pickedLocation, 15),
                  );
                },
                onLocationPicked: (latLng) async {
                  setState(() => _pickedLocation = latLng);
                  _updateMarker(latLng);
                  await _reverseGeocode(latLng);
                },
              );

              if (isTablet && orientation == Orientation.landscape) {
                return Row(
                  children: [
                    Expanded(child: _buildMapWithSearch(map)),
                    SizedBox(
                      width: 280,
                      child: _MapLocationPanel(
                        placeName: _placeName,
                        isGeocoding: _isGeocoding,
                      ),
                    ),
                  ],
                );
              }

              return Stack(
                children: [
                  _buildMapWithSearch(map),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      top: false,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          widthFactor: isTablet ? 0.72 : 1,
                          child: _MapLocationBar(
                            placeName: _placeName,
                            isGeocoding: _isGeocoding,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMapWithSearch(Widget map) {
    return Stack(
      children: [
        map,
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search for a place',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: Tooltip(
                        message: 'Use current location',
                        child: IconButton(
                          onPressed: _isFetchingCurrentLocation
                              ? null
                              : _getCurrentLocation,
                          icon: _isFetchingCurrentLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 240),
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(
                            place.mainText ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: place.secondaryText?.isNotEmpty == true
                              ? Text(
                                  place.secondaryText!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          onTap: () => _selectPlace(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({
    required this.pickedLocation,
    required this.markers,
    required this.onMapCreated,
    required this.onLocationPicked,
  });

  final LatLng pickedLocation;
  final Set<Marker> markers;
  final ValueChanged<GoogleMapController> onMapCreated;
  final Future<void> Function(LatLng latLng) onLocationPicked;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: pickedLocation, zoom: 14),
      onMapCreated: onMapCreated,
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onTap: onLocationPicked,
    );
  }
}

class _MapLocationBar extends StatelessWidget {
  const _MapLocationBar({required this.placeName, required this.isGeocoding});

  final String placeName;
  final bool isGeocoding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: AppDimensions.padding(context),
        right: AppDimensions.padding(context),
        bottom: AppDimensions.gap(context),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.padding(context),
        vertical: AppDimensions.gap(context),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: _MapLocationContent(
        placeName: placeName,
        isGeocoding: isGeocoding,
      ),
    );
  }
}

class _MapLocationPanel extends StatelessWidget {
  const _MapLocationPanel({required this.placeName, required this.isGeocoding});

  final String placeName;
  final bool isGeocoding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.padding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected location',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: AppDimensions.title(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: AppDimensions.gap(context)),
              _MapLocationContent(
                placeName: placeName,
                isGeocoding: isGeocoding,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapLocationContent extends StatelessWidget {
  const _MapLocationContent({
    required this.placeName,
    required this.isGeocoding,
  });

  final String placeName;
  final bool isGeocoding;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on, color: Colors.orange),
        SizedBox(width: AppDimensions.gap(context)),
        Expanded(
          child: isGeocoding
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  placeName,
                  style: TextStyle(
                    fontSize: AppDimensions.body(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ],
    );
  }
}
