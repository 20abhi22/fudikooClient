import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/components/mapPicker.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/auth/complete-registration.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/home/homepage.dart';
import 'package:fudikoclient/screens/auth/login.dart';
import 'package:fudikoclient/service/auth/registration-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tokens.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fudikoclient/utils/snackbar.dart';

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
      MaterialPageRoute(
        builder: (_) => MapPickerPage(authToken: widget.authToken),
      ),
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
      showErrorSnack(context, 'Please enter contact number');
      return;
    }

    if (_selectedLat == null || _selectedLng == null) {
      showErrorSnack(context, 'Please select a location on the map');
      return;
    }

    setState(() => isLoading = true);

    final details = CompleteRegistrationModel(
      phone: phoneController.text,
      lat: _selectedLat.toString(),
      lng: _selectedLng.toString(),
      profilePicturePath: _profilePhoto?.path,
    );

    final CompleteRegistrationModelResponse response;
    try {
      response = await registrationAuthService.completeRegistration(
        details,
        tokenOverride: widget.authToken,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showErrorSnack(context, 'Something went wrong. Please try again.');
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = false);

    showStatusSnack(context, response.status, response.message);

    if (response.status) {
      if (widget.authToken != null && widget.authToken!.isNotEmpty) {
        await saveToken(widget.authToken!);
        await clearCachedLocation();
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
