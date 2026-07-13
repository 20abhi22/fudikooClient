import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/restaurant/restaurant_liked.dart';
import 'package:fudikoclient/service/restaurant/restaurant-service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';

class RestaurantCard extends StatefulWidget {
  final VoidCallback? onRatingOnClick;
  // Change callback type to carry an optional offerId
  final void Function(String? offerId, OfferModel? offer)? onBoxClicked;
  final String uuid;
  final String name;
  final String type;
  final String address;
  final String phone;
  final String lat;
  final String lng;
  final String description;
  final String availableDishes;
  final int takeAwayService;
  final int deliveryService;
  final String deliveryServiceArea;
  final String restaurantType;
  final String status;
  final bool? isFavourite;
  final bool isFavoriteBox;
  final double? averageReview;
  final double? distance;
  final List<OfferModel> offers;
  final String? image;

  const RestaurantCard({
    super.key,
    this.onRatingOnClick,
    this.onBoxClicked,
    required this.uuid,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.description,
    required this.availableDishes,
    required this.takeAwayService,
    required this.deliveryService,
    required this.deliveryServiceArea,
    required this.restaurantType,
    required this.status,
    this.isFavourite,
    this.isFavoriteBox = false,
    this.averageReview,
    this.distance,
    required this.offers, // ← add
    this.image,
  });

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  bool isLiked = false;
  RestaurantService restaurantService = RestaurantService();
  @override
  void initState() {
    super.initState();
    isLiked = widget.isFavourite ?? false;
  }

  String _todayShortName() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // DateTime.weekday: 1=Mon … 7=Sun
    return days[DateTime.now().weekday - 1];
  }

  Future<void> onLikeOnTap() async {
    RestaurantLikedDislikedModel data = RestaurantLikedDislikedModel(
      uuid: widget.uuid,
    );
    RestaurantLikedDislikedResponseModel response = await restaurantService
        .changeStatus(data);
    if (response.status) {
      setState(() {
        isLiked = !isLiked;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isLiked ? Colors.green : Colors.red,
          content: AppText(
            text: isLiked ? 'Add to favourites' : 'Removed from favourites',
            size: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: AppText(
            text: 'Something went wrong',
            size: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String distanceLabel = widget.distance != null
        ? '${widget.distance!.toStringAsFixed(widget.distance! % 1 == 0 ? 0 : 1)} km'
        : '${widget.deliveryServiceArea} km';

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _RestaurantCardMetrics.fromLayout(context, constraints);

        return Card(
          color: Colors.white,
          margin: EdgeInsets.symmetric(
            horizontal: metrics.cardHorizontalMargin,
            vertical: metrics.cardVerticalMargin,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(metrics.cardRadius),
          ),
          elevation: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(metrics.cardRadius),
                    ),
                    child: Stack(
                      children: [
                        widget.image != null
                            ? Image.network(
                                widget.image!,
                                height: metrics.bannerHeight,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/restaurantBanner.png',
                                  height: metrics.bannerHeight,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.asset(
                                'assets/images/restaurantBanner.png',
                                height: metrics.bannerHeight,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                        Container(
                          height: metrics.bannerHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: metrics.bannerInset,
                    left: metrics.bannerInset,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: metrics.distanceHorizontalPadding,
                        vertical: metrics.distanceVerticalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xfff87b0d),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            pin_to_pinIcon,
                            width: metrics.smallIconSize,
                            height: metrics.smallIconSize,
                            color: Colors.white,
                          ),
                          SizedBox(width: metrics.tinyGap),
                          AppText(
                            text: distanceLabel,
                            size: metrics.distanceTextSize,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  widget.isFavoriteBox
                      ? const SizedBox.shrink()
                      : Positioned(
                          top: metrics.bannerInset,
                          right: metrics.bannerInset,
                          child: InkWell(
                            onTap: onLikeOnTap,
                            child: Icon(
                              Icons.favorite,
                              color: isLiked
                                  ? const Color(0XFFf87b0d)
                                  : Colors.grey[200],
                              size: metrics.favoriteIconSize,
                            ),
                          ),
                        ),
                  Positioned(
                    bottom: metrics.bannerBottomInset,
                    left: metrics.bannerInset,
                    right: metrics.bannerInset,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: "${widget.name} ",
                          size: metrics.nameTextSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        AppText(
                          text: "${widget.type} ",
                          size: metrics.typeTextSize,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(metrics.contentPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 4,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    locationpinIcon,
                                    width: metrics.infoIconSize,
                                    height: metrics.infoIconSize,
                                    color: appTextColor3,
                                  ),
                                  SizedBox(width: metrics.infoIconGap),
                                  Expanded(
                                    child: AppText(
                                      text: widget.address,
                                      color: appTextColor3,
                                      size: metrics.bodyTextSize,
                                      fontWeight: FontWeight.w400,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: metrics.rowGap), // Add some spacing
                            GestureDetector(
                              onTap: widget.onRatingOnClick,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: metrics.ratingHorizontalPadding,
                                  vertical: metrics.ratingVerticalPadding,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0XFFf87b0d),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      reviewStarIcon,
                                      width: metrics.infoIconSize,
                                      height: metrics.infoIconSize,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: metrics.tinyGap),
                                    Text(
                                      widget.averageReview != null
                                          ? widget.averageReview!
                                                .toStringAsFixed(1)
                                          : 'N/A',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: metrics.ratingTextSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: metrics.infoRowGap),
                        Row(
                          children: [
                            Image.asset(
                              dishIcon,
                              width: metrics.infoIconSize,
                              height: metrics.infoIconSize,
                              color: appTextColor3,
                            ),
                            SizedBox(width: metrics.infoIconGap),
                            Expanded(
                              child: AppText(
                                text: widget.availableDishes
                                    .split(',')
                                    .map((e) => e.trim())
                                    .join(' - '),

                                color: appTextColor3,
                                size: metrics.bodyTextSize,
                                fontWeight: FontWeight.w400,

                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: metrics.offersHeight,
                    child: widget.offers.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: metrics.contentPadding,
                              vertical: metrics.offerBottomPadding,
                            ),
                            child: Center(
                              child: AppText(
                                text: 'No offers available',
                                color: Colors.grey,
                                size: metrics.emptyOfferTextSize,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.only(
                              left: metrics.contentPadding,
                              right: metrics.contentPadding,
                              bottom: metrics.offerBottomPadding,
                            ),
                            itemCount: _offerSlotTickets.length,
                            itemBuilder: (context, index) {
                              final ticket = _offerSlotTickets[index];
                              final offer = ticket.offer;
                              final discountStr =
                                  '-${offer.discountPercentage.toStringAsFixed(0)}%';
                              final forText = 'for ${offer.applicableFor}';
                              final timeStr = ticket.startTime;
                              final today = _todayShortName();
                              final days = offer.activeDays
                                  .split(',')
                                  .map((d) => d.trim())
                                  .toList();
                              final dateLabel = days.contains(today)
                                  ? 'TODAY'
                                  : days.first.toUpperCase();

                              return GestureDetector(
                                onTap: () => widget.onBoxClicked?.call(
                                  offer.uuid,
                                  ticket.offerForBooking,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: metrics.offerGap,
                                  ),
                                  child: Container(
                                    width: metrics.offerWidth,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF417629),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(
                                          metrics.offerTopRadius,
                                        ),
                                        topRight: Radius.circular(
                                          metrics.offerTopRadius,
                                        ),
                                        bottomLeft: Radius.circular(
                                          metrics.offerBottomRadius,
                                        ),
                                        bottomRight: Radius.circular(
                                          metrics.offerBottomRadius,
                                        ),
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(
                                            metrics.offerPadding,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                children: [
                                                  AppText(
                                                    text: discountStr,
                                                    size: metrics
                                                        .offerDiscountSize,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    maxLines: 1,
                                                  ),
                                                  SizedBox(
                                                    height: metrics.tinyGap,
                                                  ),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: Text(
                                                      forText,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: metrics
                                                            .offerForSize,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: List.generate(
                                                  15,
                                                  (i) => Expanded(
                                                    child: Container(
                                                      height: metrics
                                                          .ticketDashHeight,
                                                      color: i % 2 == 0
                                                          ? Colors.white
                                                          : Colors.transparent,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Column(
                                                children: [
                                                  SizedBox(
                                                    height: metrics.tinyGap / 2,
                                                  ),
                                                  AppText(
                                                    text: dateLabel,
                                                    size: metrics.offerDateSize,
                                                    color: Colors.white70,
                                                    fontWeight: FontWeight.w500,
                                                    maxLines: 1,
                                                  ),
                                                  SizedBox(
                                                    height:
                                                        metrics.offerDateGap,
                                                  ),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: metrics
                                                          .offerTimeHorizontalPadding,
                                                      vertical: metrics
                                                          .offerTimeVerticalPadding,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            metrics
                                                                .offerTimeRadius,
                                                          ),
                                                    ),
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: Text(
                                                        timeStr,
                                                        maxLines: 1,
                                                        softWrap: false,
                                                        overflow: TextOverflow
                                                            .visible,
                                                        style: TextStyle(
                                                          fontSize: metrics
                                                              .offerTimeSize,
                                                          color: Colors
                                                              .green
                                                              .shade700,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          left: -metrics.ticketHoleSize / 2,
                                          top: 20,
                                          bottom: 0,
                                          child: Center(
                                            child: Container(
                                              width: metrics.ticketHoleSize,
                                              height: metrics.ticketHoleSize,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: -metrics.ticketHoleSize / 2,
                                          top: 20,
                                          bottom: 0,
                                          child: Center(
                                            child: Container(
                                              width: metrics.ticketHoleSize,
                                              height: metrics.ticketHoleSize,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                shape: BoxShape.circle,
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
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<_OfferSlotTicket> get _offerSlotTickets {
    return widget.offers.expand((offer) {
      final slots = offer.slots
          .where((slot) => slot.startTime.trim().isNotEmpty)
          .toList();
      if (slots.isEmpty) {
        return [
          _OfferSlotTicket(
            offer: offer,
            startTime: offer.startTime,
            endTime: offer.endTime,
          ),
        ];
      }

      return slots.map(
        (slot) => _OfferSlotTicket(
          offer: offer,
          startTime: slot.startTime,
          endTime: slot.endTime,
        ),
      );
    }).toList();
  }
}

class _OfferSlotTicket {
  const _OfferSlotTicket({
    required this.offer,
    required this.startTime,
    required this.endTime,
  });

  final OfferModel offer;
  final String startTime;
  final String endTime;

  OfferModel get offerForBooking =>
      offer.copyWith(startTime: startTime, endTime: endTime);
}

class _RestaurantCardMetrics {
  const _RestaurantCardMetrics({
    required this.cardHorizontalMargin,
    required this.cardVerticalMargin,
    required this.cardRadius,
    required this.bannerHeight,
    required this.bannerInset,
    required this.bannerBottomInset,
    required this.distanceHorizontalPadding,
    required this.distanceVerticalPadding,
    required this.smallIconSize,
    required this.tinyGap,
    required this.distanceTextSize,
    required this.favoriteIconSize,
    required this.nameTextSize,
    required this.typeTextSize,
    required this.contentPadding,
    required this.infoIconSize,
    required this.infoIconGap,
    required this.bodyTextSize,
    required this.rowGap,
    required this.ratingHorizontalPadding,
    required this.ratingVerticalPadding,
    required this.ratingTextSize,
    required this.infoRowGap,
    required this.offersHeight,
    required this.offerBottomPadding,
    required this.emptyOfferTextSize,
    required this.offerGap,
    required this.offerWidth,
    required this.offerTopRadius,
    required this.offerBottomRadius,
    required this.offerPadding,
    required this.offerDiscountSize,
    required this.offerForSize,
    required this.ticketDashHeight,
    required this.offerDateSize,
    required this.offerDateGap,
    required this.offerTimeHorizontalPadding,
    required this.offerTimeVerticalPadding,
    required this.offerTimeRadius,
    required this.offerTimeSize,
    required this.ticketHoleSize,
  });

  final double cardHorizontalMargin;
  final double cardVerticalMargin;
  final double cardRadius;
  final double bannerHeight;
  final double bannerInset;
  final double bannerBottomInset;
  final double distanceHorizontalPadding;
  final double distanceVerticalPadding;
  final double smallIconSize;
  final double tinyGap;
  final double distanceTextSize;
  final double favoriteIconSize;
  final double nameTextSize;
  final double typeTextSize;
  final double contentPadding;
  final double infoIconSize;
  final double infoIconGap;
  final double bodyTextSize;
  final double rowGap;
  final double ratingHorizontalPadding;
  final double ratingVerticalPadding;
  final double ratingTextSize;
  final double infoRowGap;
  final double offersHeight;
  final double offerBottomPadding;
  final double emptyOfferTextSize;
  final double offerGap;
  final double offerWidth;
  final double offerTopRadius;
  final double offerBottomRadius;
  final double offerPadding;
  final double offerDiscountSize;
  final double offerForSize;
  final double ticketDashHeight;
  final double offerDateSize;
  final double offerDateGap;
  final double offerTimeHorizontalPadding;
  final double offerTimeVerticalPadding;
  final double offerTimeRadius;
  final double offerTimeSize;
  final double ticketHoleSize;

  factory _RestaurantCardMetrics.fromLayout(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final size = MediaQuery.sizeOf(context);
    final layoutWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : size.width;
    final isLandscape = size.width > size.height;
    final isCompactLandscape = isLandscape && size.height < 500;
    final isTablet = Breakpoints.isTabletDevice(size);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone =
        size.width < 390 || size.height < 700 || layoutWidth < 390;

    if (isTablet) {
      final scale = (layoutWidth / 900).clamp(0.88, 1.10).toDouble();
      double s(double value) => value * scale;
      final offerWidth = (layoutWidth / (isLandscape ? 8.8 : 9.4))
          .clamp(isLandscape ? 90.0 : 98.0, isLandscape ? 108.0 : 118.0)
          .toDouble();

      return _RestaurantCardMetrics(
        cardHorizontalMargin: s(isLandscape ? 20 : 28),
        cardVerticalMargin: s(isLandscape ? 12 : 18),
        cardRadius: s(isLandscape ? 18 : 22),
        bannerHeight: s(isLandscape ? 180 : 230),
        bannerInset: s(isLandscape ? 16 : 22),
        bannerBottomInset: s(isLandscape ? 10 : 14),
        distanceHorizontalPadding: s(isLandscape ? 8 : 10),
        distanceVerticalPadding: s(isLandscape ? 4 : 5),
        smallIconSize: s(isLandscape ? 16 : 20),
        tinyGap: s(isLandscape ? 4 : 5),
        distanceTextSize: s(isLandscape ? 11.5 : 13),
        favoriteIconSize: s(isLandscape ? 24 : 30),
        nameTextSize: s(isLandscape ? 26 : 34),
        typeTextSize: s(isLandscape ? 18 : 22),
        contentPadding: s(isLandscape ? 14 : 22),
        infoIconSize: s(isLandscape ? 17 : 21),
        infoIconGap: s(isLandscape ? 5 : 7),
        bodyTextSize: s(isLandscape ? 13.5 : 16),
        rowGap: s(isLandscape ? 8 : 12),
        ratingHorizontalPadding: s(isLandscape ? 10 : 12),
        ratingVerticalPadding: s(isLandscape ? 4 : 5),
        ratingTextSize: s(isLandscape ? 13.5 : 16),
        infoRowGap: s(isLandscape ? 6 : 8),
        offersHeight: s(isLandscape ? 120 : 158),
        offerBottomPadding: s(isLandscape ? 12 : 18),
        emptyOfferTextSize: s(isLandscape ? 12.5 : 14),
        offerGap: s(isLandscape ? 6 : 8),
        offerWidth: offerWidth,
        offerTopRadius: s(isLandscape ? 5 : 6),
        offerBottomRadius: s(isLandscape ? 10 : 12),
        offerPadding: s(isLandscape ? 8 : 10),
        offerDiscountSize: s(isLandscape ? 15 : 18),
        offerForSize: s(isLandscape ? 9.5 : 11),
        ticketDashHeight: s(isLandscape ? 1.0 : 1.2),
        offerDateSize: s(isLandscape ? 6.5 : 7),
        offerDateGap: s(isLandscape ? 5 : 7),
        offerTimeHorizontalPadding: s(isLandscape ? 7 : 9),
        offerTimeVerticalPadding: s(isLandscape ? 3.5 : 4.5),
        offerTimeRadius: s(isLandscape ? 6 : 7),
        offerTimeSize: s(isLandscape ? 10.5 : 12),
        ticketHoleSize: s(isLandscape ? 14 : 18),
      );
    }

    if (isCompactLandscape) {
      final scale = (layoutWidth / 520).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;
      final offerWidth = (layoutWidth / 5.9).clamp(70.0, 82.0).toDouble();

      return _RestaurantCardMetrics(
        cardHorizontalMargin: s(10),
        cardVerticalMargin: s(10),
        cardRadius: s(14),
        bannerHeight: s(122),
        bannerInset: s(10),
        bannerBottomInset: s(6),
        distanceHorizontalPadding: s(6),
        distanceVerticalPadding: s(3),
        smallIconSize: s(13),
        tinyGap: s(3),
        distanceTextSize: s(10.5),
        favoriteIconSize: s(18),
        nameTextSize: s(18),
        typeTextSize: s(13),
        contentPadding: s(10),
        infoIconSize: s(13),
        infoIconGap: s(4),
        bodyTextSize: s(10.5),
        rowGap: s(5),
        ratingHorizontalPadding: s(7),
        ratingVerticalPadding: s(3),
        ratingTextSize: s(11),
        infoRowGap: s(4),
        offersHeight: s(94),
        offerBottomPadding: s(8),
        emptyOfferTextSize: s(11),
        offerGap: s(4),
        offerWidth: offerWidth,
        offerTopRadius: s(4),
        offerBottomRadius: s(8),
        offerPadding: s(5),
        offerDiscountSize: s(11.5),
        offerForSize: s(7.5),
        ticketDashHeight: s(0.9),
        offerDateSize: s(5.2),
        offerDateGap: s(3),
        offerTimeHorizontalPadding: s(5),
        offerTimeVerticalPadding: s(2.5),
        offerTimeRadius: s(4.5),
        offerTimeSize: s(8.5),
        ticketHoleSize: s(12),
      );
    }

    if (isWideShortPhone) {
      final scale = (layoutWidth / 540).clamp(0.9, 1.0).toDouble();
      double s(double value) => value * scale;
      final offerWidth = (layoutWidth / 5.7).clamp(82.0, 92.0).toDouble();

      return _RestaurantCardMetrics(
        cardHorizontalMargin: s(28),
        cardVerticalMargin: s(14),
        cardRadius: s(16),
        bannerHeight: s(154),
        bannerInset: s(20),
        bannerBottomInset: s(10),
        distanceHorizontalPadding: s(9),
        distanceVerticalPadding: s(4),
        smallIconSize: s(17),
        tinyGap: s(4),
        distanceTextSize: s(12),
        favoriteIconSize: s(28),
        nameTextSize: s(27),
        typeTextSize: s(19),
        contentPadding: s(22),
        infoIconSize: s(18),
        infoIconGap: s(7),
        bodyTextSize: s(14),
        rowGap: s(10),
        ratingHorizontalPadding: s(10),
        ratingVerticalPadding: s(4),
        ratingTextSize: s(14),
        infoRowGap: s(6),
        offersHeight: s(112),
        offerBottomPadding: s(12),
        emptyOfferTextSize: s(13),
        offerGap: s(7),
        offerWidth: offerWidth,
        offerTopRadius: s(5),
        offerBottomRadius: s(10),
        offerPadding: s(7),
        offerDiscountSize: s(20),
        offerForSize: s(10),
        ticketDashHeight: s(1),
        offerDateSize: s(5.5),
        offerDateGap: s(4),
        offerTimeHorizontalPadding: s(6),
        offerTimeVerticalPadding: s(3),
        offerTimeRadius: s(6),
        offerTimeSize: s(9),
        ticketHoleSize: s(15),
      );
    }

    if (isCompactPhone) {
      final scale = (layoutWidth / 390).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;
      final offerWidth = (layoutWidth / 5).clamp(68.0, 74.0).toDouble();

      return _RestaurantCardMetrics(
        cardHorizontalMargin: s(12),
        cardVerticalMargin: s(12),
        cardRadius: s(16),
        bannerHeight: s(145),
        bannerInset: s(14),
        bannerBottomInset: s(8),
        distanceHorizontalPadding: s(7),
        distanceVerticalPadding: s(3),
        smallIconSize: s(15),
        tinyGap: s(3),
        distanceTextSize: s(11),
        favoriteIconSize: s(22),
        nameTextSize: s(22),
        typeTextSize: s(15),
        contentPadding: s(12),
        infoIconSize: s(15),
        infoIconGap: s(4),
        bodyTextSize: s(12.5),
        rowGap: s(6),
        ratingHorizontalPadding: s(8),
        ratingVerticalPadding: s(3),
        ratingTextSize: s(12),
        infoRowGap: s(4),
        offersHeight: s(112),
        offerBottomPadding: s(10),
        emptyOfferTextSize: s(12),
        offerGap: s(4),
        offerWidth: offerWidth,
        offerTopRadius: s(4),
        offerBottomRadius: s(8),
        offerPadding: s(6),
        offerDiscountSize: s(13),
        offerForSize: s(8.5),
        ticketDashHeight: s(1),
        offerDateSize: s(5.5),
        offerDateGap: s(4),
        offerTimeHorizontalPadding: s(6),
        offerTimeVerticalPadding: s(3),
        offerTimeRadius: s(5),
        offerTimeSize: s(9.5),
        ticketHoleSize: s(14),
      );
    }

    final normalScale = (layoutWidth / 430).clamp(0.96, 1.04).toDouble();
    double s(double value) => value * normalScale;

    return _RestaurantCardMetrics(
      cardHorizontalMargin: s(20.w),
      cardVerticalMargin: s(20.w),
      cardRadius: s(20.r),
      bannerHeight: s(180.h),
      bannerInset: s(20),
      bannerBottomInset: s(10),
      distanceHorizontalPadding: s(8.w),
      distanceVerticalPadding: s(4.h),
      smallIconSize: s(18.w),
      tinyGap: s(4.w),
      distanceTextSize: s(12),
      favoriteIconSize: s(25.w),
      nameTextSize: s(30),
      typeTextSize: s(20),
      contentPadding: s(15.w),
      infoIconSize: s(18.w),
      infoIconGap: s(5.w),
      bodyTextSize: s(14),
      rowGap: s(8.w),
      ratingHorizontalPadding: s(10.w),
      ratingVerticalPadding: s(4.h),
      ratingTextSize: s(14.sp),
      infoRowGap: s(5.h),
      offersHeight: s(135.h),
      offerBottomPadding: s(15.h),
      emptyOfferTextSize: s(13),
      offerGap: s(5.w),
      offerWidth: (layoutWidth / 5).clamp(82.0, 90.0).toDouble(),
      offerTopRadius: s(5.r),
      offerBottomRadius: s(10.r),
      offerPadding: s(8.w),
      offerDiscountSize: s(16.sp),
      offerForSize: s(10.sp),
      ticketDashHeight: s(1.h),
      offerDateSize: s(6.sp),
      offerDateGap: s(6.h),
      offerTimeHorizontalPadding: s(6.w),
      offerTimeVerticalPadding: s(4.h),
      offerTimeRadius: s(6.r),
      offerTimeSize: s(9.5.sp),
      ticketHoleSize: s(16.w),
    );
  }
}
