import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/screens/tabs/components/restaurantCard.dart';

class RestaurantBottomSheet extends ConsumerWidget {
  const RestaurantBottomSheet({super.key, required this.restaurant});

final RestaurantModel restaurant;  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      minChildSize: 0.26,
      initialChildSize: 0.34,
      maxChildSize: 0.74,
      snap: true,
      snapSizes: const [0.34, 0.74],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 32,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 28.h),
            children: [
              Center(
                child: Container(
                  width: 42.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: _SheetImage(imageUrl: restaurant.image),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          restaurant.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF666666),
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF4A51C),
                              size: 20,
                            ),
                            Text(
                              "4.8",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                restaurant.availableDishes,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF666666),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 22.h),
              Text(
                'Offers',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                height: 118.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  separatorBuilder: (_, __) => SizedBox(width: 10.w),
                 itemCount: restaurant.offers.length,
itemBuilder: (context, index) {
  final offer = restaurant.offers[index];
  return GestureDetector(
    onTap: () {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: SingleChildScrollView(
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
                isFavourite: restaurant.isFavorite,
                image: restaurant.image,
                offers: restaurant.offers,
                onBoxClicked: (offerId) => Navigator.pop(context),
                onRatingOnClick: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      );
    },
    child: Container(
      width: 128.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E6B3B),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '-${offer.discountPercentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'for ${offer.applicableFor}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            offer.startTime,
            style: TextStyle(
              color: Colors.white.withOpacity(.76),
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}, 
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 220.ms).slideY(begin: .18, end: 0);
      },
    );
  }
}

class _SheetImage extends StatelessWidget {
  const _SheetImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = Image.asset(
      'assets/images/restaurantBanner.png',
      width: 104.w,
      height: 104.w,
      fit: BoxFit.cover,
    );

    if (imageUrl == null || imageUrl!.isEmpty) return fallback;

    return Image.network(
      imageUrl!,
      width: 104.w,
      height: 104.w,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
