// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:fudikoclient/features/map/models/restaurant.dart';

// class RestaurantPreviewCard extends StatelessWidget {
//   const RestaurantPreviewCard({
//     super.key,
//     required this.restaurant,
//     required this.onTap,
//   });

//   final Restaurant restaurant;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final bestOffer = restaurant.bestOffer;

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 302.w,
//         margin: EdgeInsets.only(right: 14.w),
//         clipBehavior: Clip.antiAlias,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(18.r),
//           boxShadow: const [
//             BoxShadow(
//               color: Color(0x1A000000),
//               blurRadius: 22,
//               offset: Offset(0, 10),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             _RestaurantImage(imageUrl: restaurant.imageUrl),
//             Expanded(
//               child: Padding(
//                 padding: EdgeInsets.all(12.w),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             restaurant.name,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: TextStyle(
//                               fontSize: 15.sp,
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),
//                         ),
//                         const Icon(
//                           Icons.star_rounded,
//                           size: 17,
//                           color: Color(0xFFF4A51C),
//                         ),
//                         Text(
//                           restaurant.rating.toStringAsFixed(1),
//                           style: TextStyle(
//                             fontSize: 12.sp,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 6.h),
//                     Text(
//                       restaurant.cuisineTypes.take(3).join(' - '),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: const Color(0xFF686868),
//                         fontSize: 12.sp,
//                       ),
//                     ),
//                     SizedBox(height: 8.h),
//                     if (bestOffer != null)
//                       Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 10.w,
//                           vertical: 6.h,
//                         ),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFFFF0E1),
//                           borderRadius: BorderRadius.circular(999),
//                         ),
//                         child: Text(
//                           '${bestOffer.discountLabel} off available',
//                           style: TextStyle(
//                             color: const Color(0xFFE56F08),
//                             fontSize: 12.sp,
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ).animate().fadeIn(duration: 260.ms).slideY(begin: .08, end: 0),
//     );
//   }
// }

// class _RestaurantImage extends StatelessWidget {
//   const _RestaurantImage({this.imageUrl});

//   final String? imageUrl;

//   @override
//   Widget build(BuildContext context) {
//     final fallback = Image.asset(
//       'assets/images/restaurantBanner.png',
//       width: 96.w,
//       height: double.infinity,
//       fit: BoxFit.cover,
//     );

//     if (imageUrl == null || imageUrl!.isEmpty) {
//       return fallback;
//     }

//     return Image.network(
//       imageUrl!,
//       width: 96.w,
//       height: double.infinity,
//       fit: BoxFit.cover,
//       errorBuilder: (_, __, ___) => fallback,
//     );
//   }
// }
