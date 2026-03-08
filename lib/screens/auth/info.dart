import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/components/locationDropDown.dart';
import 'package:fudikoclient/model/auth/complete-registration.dart';
import 'package:fudikoclient/model/auth/mapplace-model.dart';
import 'package:fudikoclient/screens/auth/otp.dart';
import 'package:fudikoclient/service/auth/map-service.dart';
import 'package:fudikoclient/service/auth/registration-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/tokens.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  MapService mapService = MapService();
  RegistrationAuthService registrationAuthService = RegistrationAuthService();
  late List<String> places = [];
  late List<MapPlacesResponse> locations = [];
  bool isLoading = false;

  TextEditingController phoneController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  void test() async{
    print(await getToken());
  }

  @override
  initState() {
    super.initState();
    test();
  }

  Future<void> listMapPlace(String text) async {
    setState(() {
      isLoading = true;
    });
    List<MapPlacesResponse> response = await mapService.listPlaces(text);

    setState(() {
      places = response.map((place) => place.mainText ?? '').toList();
      locations = response;
      isLoading = false;
    });

    print(places);
  }

  Future<void> completeRegistration() async {
    if (phoneController.text.isNotEmpty && locationController.text.isNotEmpty) {
      MapCoordinatesResponse location = await mapService.getPlace(
        locationController.text,
      );
      print(location.lat.toString());
      print(location.lng.toString());
      CompleteRegistrationModel details = CompleteRegistrationModel(
        phone: phoneController.text,
        lat: location.lat.toString(),
        lng: location.lng.toString(),
      );

      CompleteRegistrationModelResponse response = await registrationAuthService
          .completeRegistration(details);
      if (response.status) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Otp()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }

    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
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
                  icon: Icons.phone,
                  controller: phoneController,
                ),
                SizedBox(height: 20.h),
                LocationDropdown(
                  icon: Icons.location_on,
                  fontSize: 16,
                  hintText: "Location",
                  locations: places,
                  type: 'loc',
                  isLoading: isLoading,
                  onLocationSelected: (location) {
                    print("Selected: $location");
                    setState(() {
                      locationController.text =
                          locations[places.indexOf(location)].placeId ?? '';
                    });
                  },
                  onChange: (loc) {
                    listMapPlace(loc);
                  },
                ),
                SizedBox(height: 40.h),
                AppButton(
                  text: 'Continue',
                  onPressed: () {
                    completeRegistration();
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => Otp()),
                    // );
                  },
                ),
                SizedBox(height: 60.h),
              ],
            ),
          );
        },
      ),
    );
  }
}
