import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/model/auth/complete-registration.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/auth/otp.dart';
import 'package:fudikoclient/service/auth/registration-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tokens.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  RegistrationAuthService registrationAuthService = RegistrationAuthService();
  bool isLoading = false;

  TextEditingController phoneController = TextEditingController();
  TextEditingController locationController = TextEditingController(); // shows place name

  double? _selectedLat;
  double? _selectedLng;
  String _selectedPlaceName = '';

  @override
  void initState() {
    super.initState();
    print(getToken());
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const _MapPickerPage()),
    );
    if (result != null) {
      setState(() {
        _selectedLat = result['lat'];
        _selectedLng = result['lng'];
        _selectedPlaceName = result['place'];
        locationController.text = _selectedPlaceName;
      });
    }
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

    CompleteRegistrationModel details = CompleteRegistrationModel(
      phone: phoneController.text,
      lat: _selectedLat.toString(),
      lng: _selectedLng.toString(),
    );

    CompleteRegistrationModelResponse response =
        await registrationAuthService.completeRegistration(details);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (response.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
     pushWidgetWhileRemove(newPage: const Otp(), context: context);
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (context) => const Otp()),
      //   (route) => false,
      // );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 60.h),
            ClipOval(
              child: Image.asset(
                'assets/images/avatar.png',
                width: 150.w,
                height: 150.h,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 20.h),
            AppTextFeild(
              text: "Contact Number",
              iconImagePath: phoneIcon,
              controller: phoneController,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20.h),

            // Location field — tap to open map
            GestureDetector(
              onTap: _openMapPicker,
              child: AbsorbPointer(
                child: AppTextFeild(
                  text: _selectedPlaceName.isEmpty
                      ? "Location"
                      : _selectedPlaceName,
                  // text: "Tap to select location",
                  iconImagePath:mappingIcon,
                  controller: locationController,
                  suffixIcon: Icons.map_outlined,
                ),
              ),
            ),

            SizedBox(height: 40.h),
            isLoading
                ? const CircularProgressIndicator()
                : AppButton(
                    text: 'Continue',
                    onPressed: completeRegistration,
                  ),
            SizedBox(height: 60.h),
          ],
        ),
      ),
    );
  }
}

// ─── Map Picker Page ───────────────────────────────────────────────
class _MapPickerPage extends StatefulWidget {
  const _MapPickerPage();

  @override
  State<_MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<_MapPickerPage> {
  GoogleMapController? _mapController;
  LatLng _pickedLocation = const LatLng(55.7558, 37.6173); // default Moscow
  String _placeName = 'Fetching location...';
  bool _isGeocoding = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _pickedLocation = latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      await _reverseGeocode(latLng);
      _updateMarker(latLng);
    } catch (e) {
      print('Location error: $e');
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() => _isGeocoding = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((s) => s != null && s.isNotEmpty).toList();
        setState(() => _placeName = parts.join(', '));
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
          onDragEnd: (newPos) async {
            setState(() => _pickedLocation = newPos);
            await _reverseGeocode(newPos);
            _updateMarker(newPos);
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

          // Location name bar at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.orange),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _isGeocoding
                        ? const SizedBox(
                            height: 16,
                            width: 16,
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



// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fudikoclient/components/appbutton.dart';
// import 'package:fudikoclient/components/apptextfeild.dart';
// import 'package:fudikoclient/components/locationDropDown.dart';
// import 'package:fudikoclient/model/auth/complete-registration.dart';
// import 'package:fudikoclient/model/auth/mapplace-model.dart';
// import 'package:fudikoclient/screens/auth/otp.dart';
// import 'package:fudikoclient/service/auth/map-service.dart';
// import 'package:fudikoclient/service/auth/registration-service.dart';
// import 'package:fudikoclient/utils/constants.dart';
// import 'package:fudikoclient/utils/tokens.dart';

// class InfoPage extends StatefulWidget {
//   const InfoPage({super.key});

//   @override
//   State<InfoPage> createState() => _InfoPageState();
// }

// class _InfoPageState extends State<InfoPage> {
//   MapService mapService = MapService();
//   RegistrationAuthService registrationAuthService = RegistrationAuthService();
//   late List<String> places = [];
//   late List<MapPlacesResponse> locations = [];
//   bool isLoading = false;

//   TextEditingController phoneController = TextEditingController();
//   TextEditingController locationController = TextEditingController();

//   void test() async{
//     print(await getToken());
//   }

//   @override
//   initState() {
//     super.initState();
//     test();
//   }

//   Future<void> listMapPlace(String text) async {
//     setState(() {
//       isLoading = true;
//     });
//     List<MapPlacesResponse> response = await mapService.listPlaces(text);

//     setState(() {
//       places = response.map((place) => place.mainText ?? '').toList();
//       locations = response;
//       isLoading = false;
//     });

//     print(places);
//   }

//   Future<void> completeRegistration() async {
//     if (phoneController.text.isNotEmpty && locationController.text.isNotEmpty) {
//       MapCoordinatesResponse location = await mapService.getPlace(
//         locationController.text,
//       );
//       print(location.lat.toString());
//       print(location.lng.toString());
//       CompleteRegistrationModel details = CompleteRegistrationModel(
//         phone: phoneController.text,
//         lat: location.lat.toString(),
//         lng: location.lng.toString(),
//       );

//       CompleteRegistrationModelResponse response = await registrationAuthService
//           .completeRegistration(details);
//       if (response.status) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(response.message)));
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (context) => Otp()),
//           (route) => false,
//         );
//       } else {
//         if (!mounted) return;
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(response.message)));
//       }

//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           return Padding(
//             padding: EdgeInsets.symmetric(horizontal: 30.w),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(height: 60.h),
//                 ClipOval(
//                   child: Image.asset(
//                     'assets/images/avatar.png',
//                     width: 150.w,
//                     height: 150.h,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 SizedBox(height: 20.h),
//                 AppTextFeild(
//                   text: "Contact Number",
//                   icon: Icons.phone,
//                   controller: phoneController,
//                 ),
//                 SizedBox(height: 20.h),
//                 LocationDropdown(
//                   icon: Icons.location_on,
//                   fontSize: 16,
//                   hintText: "Location",
//                   locations: places,
//                   type: 'loc',
//                   isLoading: isLoading,
//                   onLocationSelected: (location) {
//                     print("Selected: $location");
//                     setState(() {
//                       locationController.text =
//                           locations[places.indexOf(location)].placeId ?? '';
//                     });
//                   },
//                   onChange: (loc) {
//                     listMapPlace(loc);
//                   },
//                 ),
//                 SizedBox(height: 40.h),
//                 AppButton(
//                   text: 'Continue',
//                   onPressed: () {
//                     completeRegistration();
//                     // Navigator.push(
//                     //   context,
//                     //   MaterialPageRoute(builder: (context) => Otp()),
//                     // );
//                   },
//                 ),
//                 SizedBox(height: 60.h),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
