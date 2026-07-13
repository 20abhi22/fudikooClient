import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/auth/mapplace-model.dart';
import 'package:fudikoclient/model/profile/customer-profile-model.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/badge/badgeinfo.dart';
import 'package:fudikoclient/screens/customerProfile/donutPercentage.dart';
import 'package:fudikoclient/screens/earnPoints/earnPoints.dart';
import 'package:fudikoclient/screens/reliability/reliabilityinfo.dart';
import 'package:fudikoclient/service/profile/customer-profile-service.dart';
import 'package:fudikoclient/service/auth/map-service.dart';
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
      final apiPlace = data.place.trim();
      final hasApiPlace = apiPlace.isNotEmpty && apiPlace != '-';
      final resolvedPlace = hasApiPlace
          ? apiPlace
          : await _placeFromCoordinates(data.lat, data.lng);
      final coordinateFallback =
          data.lat.isNotEmpty && data.lng.isNotEmpty
              ? '${data.lat}, ${data.lng}'
              : 'Location unavailable';
      if (!mounted) return;
      setState(() {
        // Prefer the address supplied by the API. When it is absent, derive
        // a display address from the latitude and longitude.
        profile = data.copyWith(place: resolvedPlace ?? coordinateFallback);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<String?> _placeFromCoordinates(String lat, String lng) async {
    final latitude = double.tryParse(lat);
    final longitude = double.tryParse(lng);
    if (latitude == null || longitude == null) return null;
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final details =
          [
                place.street,
                place.subLocality,
                place.locality,
                place.administrativeArea,
                place.postalCode,
                place.country,
              ]
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList();

      return details.isEmpty ? null : details.join(', ');
    } catch (_) {
      return null;
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
                        color: Colors.black.withValues(alpha: 0.25),
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
      // context: context,
      // isScrollControlled: true,
      // backgroundColor: Colors.transparent,
      // builder: (context) {
        context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  constraints: Breakpoints.isTabletContext(context)
      ? const BoxConstraints(maxWidth: 600)
      : null,
  builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Center(
              child: ConstrainedBox(
                    constraints: const BoxConstraints(
      maxWidth: 600,
    ),

                child: Padding(
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
                          color: Colors.black.withValues(alpha: 0.2),
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
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
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

if (Breakpoints.isTabletContext(context) &&
    MediaQuery.of(context).orientation == Orientation.landscape) ...[
  Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _editField(
          "Name",
          nameController,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _editField(
          "Email",
          emailController,
          readOnly: true,
        ),
      ),
    ],
  ),

  const SizedBox(height: 15),

  Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _editField(
          "Place",
          placeController,
          readOnly: true,
          onTap: () => openMapPicker(modalSetState),
          suffixIcon: Icons.map_outlined,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _editField(
          "Contact Info",
          contactController,
          keyboardType: TextInputType.phone,
        ),
      ),
    ],
  ),
] else ...[
  _editField(
    "Name",
    nameController,
  ),

  const SizedBox(height: 15),

  _editField(
    "Email",
    emailController,
    readOnly: true,
  ),

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
],

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
    final metrics = _CustomerProfileMetrics.fromContext(context);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final double statusBarHeight = MediaQuery.paddingOf(context).top;

    return Scaffold(
      // allow body to draw beneath status bar
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
            builder: (context, constraints) {
  
          return SingleChildScrollView(
            child: ConstrainedBox(
               constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
          ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // expand banner to include statusBar area so it visually blends
                        Image.asset(
                          'assets/images/banner1.png',
                          height: metrics.bannerHeight + statusBarHeight,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: -metrics.avatarOverlap,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: metrics.avatarSize,
                              height: metrics.avatarSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: metrics.avatarShadowBlur,
                                    offset: Offset(0, metrics.avatarShadowOffset),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(metrics.avatarBorderPadding),
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
                        ),
                      ],
                    ),
                    SizedBox(height: metrics.avatarBottomGap),
                    AppText(
                      text: profile?.name ?? '-',
                      size: metrics.nameTextSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      isCentered: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: metrics.nameEmailGap),
                    AppText(
                      text: profile?.email ?? '-',
                      size: metrics.emailTextSize,
                      fontWeight: FontWeight.w200,
                      color: Colors.black,
                      isCentered: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: metrics.sectionGap),
                
                    // Badge + Rating card
                    Center(
                      child: SizedBox(
                        width: metrics.contentWidth,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: metrics.badgeCardHorizontalPadding,
                          ),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(metrics.cardRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: metrics.cardShadowBlur,
                                  offset: Offset(0, metrics.cardShadowOffset),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(metrics.badgeCardPadding),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: metrics.statColumnMinHeight,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          GestureDetector(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => BadgeInfo(),
                                              ),
                                            ),
                                            child: profile?.badgeImage != null
                                                ? Image.network(
                                                    profile!.badgeImage!,
                                                    height: metrics.badgeImageSize,
                                                    width: metrics.badgeImageSize,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, __, ___) =>
                                                        Image.asset(
                                                          'assets/images/badge1.png',
                                                          height:
                                                              metrics.badgeImageSize,
                                                          width:
                                                              metrics.badgeImageSize,
                                                          fit: BoxFit.contain,
                                                        ),
                                                  )
                                                : Image.asset(
                                                    'assets/images/badge1.png',
                                                    height: metrics.badgeImageSize,
                                                    width: metrics.badgeImageSize,
                                                    fit: BoxFit.contain,
                                                  ),
                                          ),
                                          SizedBox(height: metrics.smallGap),
                                          AppText(
                                            text: profile?.badge == '-'
                                                ? "No Badge"
                                                : profile?.badge ?? '-',
                                            size: metrics.labelTextSize,
                                            fontWeight: FontWeight.w400,
                                            color: appButtonColor2,
                                            isCentered: true,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          AppText(
                                            text: "Badge",
                                            size: metrics.labelTextSize,
                                            fontWeight: FontWeight.w400,
                                            color: appButtonColor2,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: metrics.dividerHeight,
                                    color: appTextColor3,
                                  ),
                                  Expanded(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: metrics.statColumnMinHeight,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          GestureDetector(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ReliabilityInfo(
                                                  rating: profile?.rating ?? 0,
                                                ),
                                              ),
                                            ),
                                            child: SizedBox(
                                              width: metrics.chartSize,
                                              height: metrics.chartSize,
                                              child: DonutChart(
                                                percentage:
                                                    (profile?.rating ?? 0) / 100,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: metrics.smallGap),
                                          AppText(
                                            text: "Reliability",
                                            size: metrics.labelTextSize,
                                            fontWeight: FontWeight.w400,
                                            color: appButtonColor2,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          AppText(
                                            text: "Rating",
                                            size: metrics.labelTextSize,
                                            fontWeight: FontWeight.w400,
                                            color: appButtonColor2,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                
                    // Info card
                    Center(
                      child: SizedBox(
                        width: metrics.contentWidth,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: metrics.infoHorizontalPadding,
                            right: metrics.infoHorizontalPadding,
                            top: metrics.infoTopGap,
                            bottom: metrics.infoBottomGap,
                          ),
                          child: Container(
                            padding: EdgeInsets.all(metrics.infoPadding),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(metrics.infoRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: metrics.cardShadowBlur,
                                  offset: Offset(0, metrics.cardShadowOffset),
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
                                      child: Image.asset(
                                        editIcon,
                                        width: metrics.editIconSize,
                                        height: metrics.editIconSize,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: metrics.infoRowGap),
                                _infoRow("Place", profile?.place ?? '-', metrics),
                                SizedBox(height: metrics.infoRowGap),
                                _infoRow(
                                  "Contact Info",
                                  profile?.contactInfo ?? '-',
                                  metrics,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                
                    SizedBox(height: metrics.inviteTopGap),
                    Center(
                      child: InkWell(
                        onTap: () =>
                            slideRightWidget(context: context, newPage: EarnPoints()),
                        child: SizedBox(
                          width: metrics.contentWidth,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: metrics.inviteHorizontalPadding,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                metrics.inviteRadius,
                              ),
                              child: Image.asset(
                                'assets/images/inviteimage.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: metrics.inviteHeight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: metrics.bottomGap),
                  ],
                ),
              ),
            ),
          );
  },
  ),
      ),
    );
  }

  Widget _infoRow(String label, String value, _CustomerProfileMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText(
              text: label,
              size: metrics.infoLabelTextSize,
              fontWeight: FontWeight.w600,
              color: appTextColor2,
            ),
            SizedBox(width: metrics.infoDividerGap),
            Expanded(child: Container(height: 0.5, color: appTextColor3)),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(
            top: metrics.infoValueTopPadding,
            left: metrics.infoValueLeftPadding,
            bottom: metrics.infoValueBottomPadding,
          ),
          child: AppText(
            text: value,
            size: metrics.infoValueTextSize,
            fontWeight: FontWeight.w400,
            color: appTextColor2,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CustomerProfileMetrics {
  const _CustomerProfileMetrics({
    required this.contentWidth,
    required this.bannerHeight,
    required this.avatarSize,
    required this.avatarOverlap,
    required this.avatarBottomGap,
    required this.avatarBorderPadding,
    required this.avatarShadowBlur,
    required this.avatarShadowOffset,
    required this.nameTextSize,
    required this.emailTextSize,
    required this.nameEmailGap,
    required this.sectionGap,
    required this.badgeCardHorizontalPadding,
    required this.badgeCardPadding,
    required this.cardRadius,
    required this.cardShadowBlur,
    required this.cardShadowOffset,
    required this.badgeImageSize,
    required this.chartSize,
    required this.dividerHeight,
    required this.statColumnMinHeight,
    required this.labelTextSize,
    required this.smallGap,
    required this.infoHorizontalPadding,
    required this.infoTopGap,
    required this.infoBottomGap,
    required this.infoPadding,
    required this.infoRadius,
    required this.editIconSize,
    required this.infoRowGap,
    required this.infoLabelTextSize,
    required this.infoValueTextSize,
    required this.infoDividerGap,
    required this.infoValueTopPadding,
    required this.infoValueLeftPadding,
    required this.infoValueBottomPadding,
    required this.inviteTopGap,
    required this.inviteHorizontalPadding,
    required this.inviteRadius,
    required this.inviteHeight,
    required this.bottomGap,
  });

  final double contentWidth;
  final double bannerHeight;
  final double avatarSize;
  final double avatarOverlap;
  final double avatarBottomGap;
  final double avatarBorderPadding;
  final double avatarShadowBlur;
  final double avatarShadowOffset;
  final double nameTextSize;
  final double emailTextSize;
  final double nameEmailGap;
  final double sectionGap;
  final double badgeCardHorizontalPadding;
  final double badgeCardPadding;
  final double cardRadius;
  final double cardShadowBlur;
  final double cardShadowOffset;
  final double badgeImageSize;
  final double chartSize;
  final double dividerHeight;
  final double statColumnMinHeight;
  final double labelTextSize;
  final double smallGap;
  final double infoHorizontalPadding;
  final double infoTopGap;
  final double infoBottomGap;
  final double infoPadding;
  final double infoRadius;
  final double editIconSize;
  final double infoRowGap;
  final double infoLabelTextSize;
  final double infoValueTextSize;
  final double infoDividerGap;
  final double infoValueTopPadding;
  final double infoValueLeftPadding;
  final double infoValueBottomPadding;
  final double inviteTopGap;
  final double inviteHorizontalPadding;
  final double inviteRadius;
  final double inviteHeight;
  final double bottomGap;

  factory _CustomerProfileMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;
    final isLandscape = size.width > size.height;

    if (isTablet) {
      final contentWidth = (size.width * 0.68).clamp(620.0, 860.0).toDouble();
      final scale = (contentWidth / 720).clamp(1.0, 1.14).toDouble();
      double s(double value) => value * scale;

      return _CustomerProfileMetrics(
        contentWidth: contentWidth,
        // bannerHeight: s(220),
bannerHeight: isLandscape
    ? s(180)
    : s(220),
        // avatarSize: s(230),
        // avatarOverlap: s(115),
        // avatarBottomGap: s(140),
        avatarSize: isLandscape
    ? s(180)
    : s(230),

avatarOverlap: isLandscape
    ? s(90)
    : s(115),

avatarBottomGap: isLandscape
    ? s(110)
    : s(140),

sectionGap: isLandscape
    ? s(24)
    : s(36),
        avatarBorderPadding: s(5),
        avatarShadowBlur: s(12),
        avatarShadowOffset: s(4),
        nameTextSize: s(25),
        emailTextSize: s(18),
        nameEmailGap: s(7),
        // sectionGap: s(36),
        // badgeCardHorizontalPadding: s(70),
        badgeCardHorizontalPadding:
    size.width > size.height
        ? s(40)
        : s(70),
        badgeCardPadding: s(26),
        cardRadius: s(26),
        cardShadowBlur: s(12),
        cardShadowOffset: s(4),
        badgeImageSize: s(96),
        chartSize: s(118),
        dividerHeight: s(118),
        statColumnMinHeight: s(158),
        labelTextSize: s(14),
        smallGap: s(7),
        infoHorizontalPadding: s(42),
        infoTopGap: s(70),
        infoBottomGap: s(24),
        infoPadding: s(34),
        infoRadius: s(22),
        editIconSize: s(24),
        infoRowGap: s(14),
        infoLabelTextSize: s(14),
        infoValueTextSize: s(14),
        infoDividerGap: s(18),
        infoValueTopPadding: s(7),
        infoValueLeftPadding: s(34),
        infoValueBottomPadding: s(7),
        inviteTopGap: s(48),
        inviteHorizontalPadding: s(18),
        inviteRadius: s(50),
        // inviteHeight: s(190),
        inviteHeight:
    size.width > size.height
        ? s(150)
        : s(190),
        bottomGap: s(24),
      );
    }

    if (isWideShortPhone) {
      return const _CustomerProfileMetrics(
        contentWidth: double.infinity,
        bannerHeight: 130,
        avatarSize: 150,
        avatarOverlap: 72,
        avatarBottomGap: 86,
        avatarBorderPadding: 4,
        avatarShadowBlur: 8,
        avatarShadowOffset: 3,
        nameTextSize: 19,
        emailTextSize: 13,
        nameEmailGap: 4,
        sectionGap: 22,
        badgeCardHorizontalPadding: 70,
        badgeCardPadding: 16,
        cardRadius: 18,
        cardShadowBlur: 8,
        cardShadowOffset: 3,
        badgeImageSize: 64,
        chartSize: 78,
        dividerHeight: 84,
        statColumnMinHeight: 108,
        labelTextSize: 11,
        smallGap: 4,
        infoHorizontalPadding: 42,
        infoTopGap: 42,
        infoBottomGap: 14,
        infoPadding: 22,
        infoRadius: 16,
        editIconSize: 18,
        infoRowGap: 8,
        infoLabelTextSize: 11,
        infoValueTextSize: 11,
        infoDividerGap: 12,
        infoValueTopPadding: 4,
        infoValueLeftPadding: 22,
        infoValueBottomPadding: 4,
        inviteTopGap: 24,
        inviteHorizontalPadding: 28,
        inviteRadius: 36,
        inviteHeight: 118,
        bottomGap: 18,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.82, 0.96).toDouble();
      double s(double value) => value * scale;

      return _CustomerProfileMetrics(
        contentWidth: double.infinity,
        bannerHeight: s(135),
        avatarSize: s(160),
        avatarOverlap: s(78),
        avatarBottomGap: s(92),
        avatarBorderPadding: s(4),
        avatarShadowBlur: s(8),
        avatarShadowOffset: s(3),
        nameTextSize: s(18),
        emailTextSize: s(13),
        nameEmailGap: s(4),
        sectionGap: s(24),
        badgeCardHorizontalPadding: s(36),
        badgeCardPadding: s(16),
        cardRadius: s(20),
        cardShadowBlur: s(8),
        cardShadowOffset: s(3),
        badgeImageSize: s(64),
        chartSize: s(78),
        dividerHeight: s(86),
        statColumnMinHeight: s(110),
        labelTextSize: s(10.5),
        smallGap: s(4),
        infoHorizontalPadding: s(20),
        infoTopGap: s(46),
        infoBottomGap: s(16),
        infoPadding: s(22),
        infoRadius: s(16),
        editIconSize: s(18),
        infoRowGap: s(8),
        infoLabelTextSize: s(11),
        infoValueTextSize: s(11),
        infoDividerGap: s(12),
        infoValueTopPadding: s(4),
        infoValueLeftPadding: s(22),
        infoValueBottomPadding: s(4),
        inviteTopGap: s(26),
        inviteHorizontalPadding: s(8),
        inviteRadius: s(36),
        inviteHeight: s(120),
        bottomGap: s(18),
      );
    }

    return _CustomerProfileMetrics(
      contentWidth: double.infinity,
      bannerHeight: 150,
      avatarSize: 200,
      avatarOverlap: 100,
      avatarBottomGap: 120,
      avatarBorderPadding: 4,
      avatarShadowBlur: 10,
      avatarShadowOffset: 4,
      nameTextSize: 20,
      emailTextSize: 15,
      nameEmailGap: 5,
      sectionGap: 30,
      badgeCardHorizontalPadding: 60,
      badgeCardPadding: 20,
      cardRadius: 25,
      cardShadowBlur: 10,
      cardShadowOffset: 4,
      badgeImageSize: 80,
      chartSize: 100,
      dividerHeight: 100,
      statColumnMinHeight: 134,
      labelTextSize: 12,
      smallGap: 5,
      infoHorizontalPadding: 30,
      infoTopGap: 60,
      infoBottomGap: 20,
      infoPadding: 30,
      infoRadius: 20,
      editIconSize: 20,
      infoRowGap: 10,
      infoLabelTextSize: 12,
      infoValueTextSize: 12,
      infoDividerGap: 15,
      infoValueTopPadding: 5,
      infoValueLeftPadding: 30,
      infoValueBottomPadding: 5,
      inviteTopGap: 40,
      inviteHorizontalPadding: 10,
      inviteRadius: 50,
      inviteHeight: 150,
      bottomGap: 20,
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
  final MapService _mapService = MapService();
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  late LatLng _pickedLocation;
  String _placeName = 'Fetching location...';
  bool _isGeocoding = false;
  bool _isFetchingCurrentLocation = false;
  bool _isSearching = false;
  Set<Marker> _markers = {};
  List<MapPlacesResponse> _searchResults = [];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _pickedLocation = widget.initialLocation ?? const LatLng(10.8505, 76.2711);
    _updateMarker(_pickedLocation);

    if (widget.initialLocation == null) {
      _getCurrentLocation();
    } else {
      _reverseGeocode(_pickedLocation);
    }
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
      _updateMarker(latLng);
      await _reverseGeocode(latLng);
    } catch (_) {
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
            onMapCreated: (controller) {
              _mapController = controller;
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(_pickedLocation, 15),
              );
            },
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
