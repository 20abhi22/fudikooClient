import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/model/profile/customer-profile-model.dart';
import 'package:fudikoclient/screens/badge/badgeinfo.dart';
import 'package:fudikoclient/screens/customerProfile/donutPercentage.dart';
import 'package:fudikoclient/screens/reliability/reliabilityinfo.dart';
import 'package:fudikoclient/service/profile/customer-profile-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

class CustomerProfile extends StatefulWidget {
  const CustomerProfile({super.key});

  @override
  State<CustomerProfile> createState() => _CustomerProfileState();
}

class _CustomerProfileState extends State<CustomerProfile> {
  CustomerProfileService profileService = CustomerProfileService();
  CustomerProfileModel? profile;
  bool isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // make status bar transparent so banner can blend beneath it
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => isLoading = true);
    try {
      final data = await profileService.getProfile();
      if (!mounted) return;
      setState(() {
        profile = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Widget _editField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: label,
          size: 12,
          fontWeight: FontWeight.w600,
          color: appTextColor2,
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F7F7),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
          ),
        ),
      ],
    );
  }

  Future<void> _showEditProfileModal() async {
    final nameController = TextEditingController(text: profile?.name ?? '');
    final emailController = TextEditingController(text: profile?.email ?? '');
    final placeController = TextEditingController(text: profile?.place ?? '');
    final contactController = TextEditingController(
      text: profile?.contactInfo ?? '',
    );
    double? selectedLat = double.tryParse(profile?.lat ?? '');
    double? selectedLng = double.tryParse(profile?.lng ?? '');
    String? selectedProfilePhotoPath;
    bool isSaving = false;

    Future<void> showAboveModalMessage(String message) async {
      if (!mounted) return;

      final mediaQuery = MediaQuery.of(context);
      final overlay = Navigator.of(context, rootNavigator: true).overlay;
      if (overlay == null) return;

      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (overlayContext) {
          return Positioned(
            left: 20,
            right: 20,
            top: mediaQuery.padding.top + 20,
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      overlay.insert(entry);
      await Future<void>.delayed(const Duration(seconds: 3));
      entry.remove();
    }

    Future<void> pickProfilePhoto(
      void Function(void Function()) modalSetState,
    ) async {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 65,
      );

      if (pickedImage == null) return;

      modalSetState(() {
        selectedProfilePhotoPath = pickedImage.path;
      });
    }

    Future<void> openMapPicker(
      void Function(void Function()) modalSetState,
    ) async {
      final initialLocation = selectedLat != null && selectedLng != null
          ? LatLng(selectedLat!, selectedLng!)
          : null;
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _ProfileMapPickerPage(initialLocation: initialLocation),
        ),
      );

      if (result == null) return;

      modalSetState(() {
        selectedLat = result['lat'] as double?;
        selectedLng = result['lng'] as double?;
        placeController.text = (result['place'] ?? '').toString();
      });
    }

    Future<void> saveProfile(
      void Function(void Function()) modalSetState,
    ) async {
      if (nameController.text.trim().isEmpty ||
          contactController.text.trim().isEmpty) {
        showAboveModalMessage('Please fill name and contact info');
        return;
      }

      if (selectedLat == null || selectedLng == null) {
        showAboveModalMessage('Please select a place on the map');
        return;
      }

      modalSetState(() => isSaving = true);

      final response = await profileService.updateProfile(
        name: nameController.text.trim(),
        phone: contactController.text.trim(),
        lat: selectedLat.toString(),
        lng: selectedLng.toString(),
        profilePicturePath: selectedProfilePhotoPath,
      );

      if (!mounted) return;

      modalSetState(() => isSaving = false);

      final status = response['status'] == true;
      final message =
          (response['message'] ??
                  (status
                      ? 'Profile updated successfully'
                      : 'Unable to update profile'))
              .toString();

      if (status) {
        Navigator.pop(context, message);
      } else {
        showAboveModalMessage(message);
      }
    }

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 45,
                          height: 4,
                          decoration: BoxDecoration(
                            color: appTextColor3,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppText(
                        text: "Edit Profile",
                        size: 18,
                        fontWeight: FontWeight.w600,
                        color: appTextColor,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: isSaving
                              ? null
                              : () => pickProfilePhoto(modalSetState),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(3),
                                child: ClipOval(
                                  child: selectedProfilePhotoPath != null
                                      ? Image.file(
                                          File(selectedProfilePhotoPath!),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        )
                                      : profile?.profilePicture != '-' &&
                                            profile?.profilePicture != null
                                      ? Image.network(
                                          profile!.profilePicture,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Image.asset(
                                                'assets/images/avatar2.png',
                                                fit: BoxFit.cover,
                                              ),
                                        )
                                      : Image.asset(
                                          'assets/images/avatar2.png',
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: 2,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: appButtonColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSaving
                                      ? const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _editField("Name", nameController),
                      const SizedBox(height: 15),
                      _editField("Email", emailController, readOnly: true),
                      const SizedBox(height: 15),
                      _editField(
                        "Place",
                        placeController,
                        readOnly: true,
                        onTap: () => openMapPicker(modalSetState),
                        suffixIcon: Icons.map_outlined,
                      ),
                      const SizedBox(height: 15),
                      _editField(
                        "Contact Info",
                        contactController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appButtonColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          onPressed: isSaving
                              ? null
                              : () => saveProfile(modalSetState),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Save Changes",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      await _fetchProfile();
      if (!mounted) return;
      showAboveModalMessage(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      // allow body to draw beneath status bar
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // expand banner to include statusBar area so it visually blends
                  Image.asset(
                    'assets/images/banner1.png',
                    height: 150 + statusBarHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: -screenWidth / 5,
                    left: screenWidth / 2 - 95,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child:
                            profile?.profilePicture != '-' &&
                                profile?.profilePicture != null
                            ? Image.network(
                                profile!.profilePicture,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/avatar2.png',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'assets/images/avatar2.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 120),
              AppText(
                text: profile?.name ?? '-',
                size: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                isCentered: true,
              ),
              const SizedBox(height: 5),
              AppText(
                text: profile?.email ?? '-',
                size: 15,
                fontWeight: FontWeight.w200,
                color: Colors.black,
                isCentered: true,
              ),
              const SizedBox(height: 30),

              // Badge + Rating card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BadgeInfo(),
                                  ),
                                ),
                                child: Image.asset(
                                  'assets/images/badge1.png',
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 5),
                              AppText(
                                text: profile?.badge == '-'
                                    ? "No Badge"
                                    : profile?.badge ?? '-',
                                size: 12,
                                fontWeight: FontWeight.w400,
                                color: appButtonColor2,
                                isCentered: true,
                              ),
                              AppText(
                                text: "Badge",
                                size: 12,
                                fontWeight: FontWeight.w400,
                                color: appButtonColor2,
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 100, color: appTextColor3),
                        Expanded(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReliabilityInfo(),
                                  ),
                                ),
                                child: SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: DonutChart(
                                    percentage: (profile?.rating ?? 0) / 100,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              AppText(
                                text: "Reliability",
                                size: 12,
                                fontWeight: FontWeight.w400,
                                color: appButtonColor2,
                              ),
                              AppText(
                                text: "Rating",
                                size: 12,
                                fontWeight: FontWeight.w400,
                                color: appButtonColor2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Info card
              Padding(
                padding: const EdgeInsets.only(
                  left: 30,
                  right: 30,
                  top: 60,
                  bottom: 20,
                ),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: _showEditProfileModal,
                            // child: 
                            child: Image.asset(
                              editIcon,
                              width: 20,
                              height: 20,
                              // color: appTextColor3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _infoRow("Place", profile?.place ?? '-'),
                      const SizedBox(height: 10),
                      _infoRow("Contact Info", profile?.contactInfo ?? '-'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    'assets/images/inviteimage.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 150,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText(
              text: label,
              size: 12,
              fontWeight: FontWeight.w600,
              color: appTextColor2,
            ),
            const SizedBox(width: 15),
            Expanded(child: Container(height: 0.5, color: appTextColor3)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 30, bottom: 5),
          child: AppText(
            text: value,
            size: 12,
            fontWeight: FontWeight.w400,
            color: appTextColor2,
          ),
        ),
      ],
    );
  }
}

class _ProfileMapPickerPage extends StatefulWidget {
  final LatLng? initialLocation;

  const _ProfileMapPickerPage({this.initialLocation});

  @override
  State<_ProfileMapPickerPage> createState() => _ProfileMapPickerPageState();
}

class _ProfileMapPickerPageState extends State<_ProfileMapPickerPage> {
  GoogleMapController? _mapController;
  late LatLng _pickedLocation;
  String _placeName = 'Fetching location...';
  bool _isGeocoding = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation ?? const LatLng(55.7558, 37.6173);
    _updateMarker(_pickedLocation);

    if (widget.initialLocation == null) {
      _getCurrentLocation();
    } else {
      _reverseGeocode(_pickedLocation);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);

      setState(() => _pickedLocation = latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      _updateMarker(latLng);
      await _reverseGeocode(latLng);
    } catch (e) {
      await _reverseGeocode(_pickedLocation);
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() => _isGeocoding = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

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
    } catch (e) {
      setState(() => _placeName = '${latLng.latitude}, ${latLng.longitude}');
    }

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
            _updateMarker(newPosition);
            await _reverseGeocode(newPosition);
          },
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Place'),
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
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onTap: (latLng) async {
              setState(() => _pickedLocation = latLng);
              _updateMarker(latLng);
              await _reverseGeocode(latLng);
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.orange),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _isGeocoding
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _placeName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
