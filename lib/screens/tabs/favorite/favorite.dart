import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/model/favorite/favoraite_model.dart';
import 'package:fudikoclient/screens/tabs/components/restaurantCard.dart';
import 'package:fudikoclient/screens/tabs/home/addnumberofpeople.dart';
import 'package:fudikoclient/screens/tabs/home/rating.dart';
import 'package:fudikoclient/service/favourite/favourite_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/screens/tabs/profile/restaurantProfile.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  FavouriteRestaurantService favouriteRestaurantService =
      FavouriteRestaurantService();
  List<FavouriteRestaurantModel> restaurantsList = [];
  bool isBookingModalOpen = false;

  @override
  void initState() {
    super.initState();
    loadFavouriteRestaurants();
  }

  Future<void> loadFavouriteRestaurants() async {
    FavouriteRestaurantModelResponse response =
        await favouriteRestaurantService.getFavouriteRestaurants();
    if (response.status) {
      setState(() {
        restaurantsList = response.restaurant;
      });
    } else {
      print('Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 30, right: 30, top: 30),
              child: AppTextFeild(
                text: "Search Restaurant",
                textColor: appTextColor,
                isTextCenter: true,
              ),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              itemCount: restaurantsList.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
  final restaurant = restaurantsList[index];

  return InkWell(
    onTap: () async {
      final result = await Navigator.push(   // ← await the result
        context,
        MaterialPageRoute(
          builder: (_) => RestaurantProfile(
            uuid: restaurant.uuid,
            deliveryServiceArea: restaurant.deliveryServiceArea,
            isFavourite: true,
          ),
        ),
      );
      // If user unfavourited it, remove from list
      if (result is bool && result == false) {
        if (!mounted) return;
        setState(() {
          restaurantsList.removeAt(index);
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
      restaurantType: restaurant.restaurantType,
      status: restaurant.status,
      isFavourite: true,
      isFavoriteBox: false,
      offers: const [],
      onRatingOnClick: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RatingPage()),
      ),
      onBoxClicked: (String? offerId) {
        setState(() => isBookingModalOpen = !isBookingModalOpen);
        if (isBookingModalOpen) {
          showModalBottomSheet(
            backgroundColor: Colors.white,
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            builder: (_) => NumberOfPeopleModal(
              uuid: restaurant.uuid,
              offerId: offerId,
            ),
          );
        }
      },
    ),
  );
},
             ),
          ],
        ),
      ),
    );
  }
}