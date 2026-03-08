import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptextfeild.dart';
import 'package:fudikoclient/model/favorite/favoraite_model.dart';
import 'package:fudikoclient/screens/tabs/components/restaurantCard.dart';
import 'package:fudikoclient/service/favourite/favourite_service.dart';
import 'package:fudikoclient/utils/constants.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {

  FavouriteRestaurantService favouriteRestaurantService = FavouriteRestaurantService();
  List<FavouriteRestaurantModel> restaurantsList = [];

  @override
  void initState() {
    loadFavouriteRestaurants();
    super.initState();
  }

  Future<void> loadFavouriteRestaurants() async{
    FavouriteRestaurantModelResponse response = await favouriteRestaurantService.getFavouriteRestaurants();
    if(response.status){
      setState(() {
        restaurantsList = response.restaurant;
      });
    }else{
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

                return GestureDetector(
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
                    isFavoriteBox: true,

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
