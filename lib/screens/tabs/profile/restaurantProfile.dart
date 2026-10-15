import 'package:fudikoclient/screens/tabs/home/addnumberofpeople.dart';

import 'package:flutter/material.dart';
import 'package:fudikoclient/components/error_state.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appbutton.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/model/restaurant/restaurant_liked.dart';
import 'package:fudikoclient/model/restaurant/restaurant_profile_model.dart';
import 'package:fudikoclient/screens/tabs/home/rating.dart';
import 'package:fudikoclient/screens/tabs/profile/menu.dart';
import 'package:fudikoclient/service/restaurant/restaurant-service.dart';
import 'package:fudikoclient/service/restaurant/restaurant_profile_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/snackbar.dart';

class RestaurantProfile extends StatefulWidget {
  final String uuid;
  final String? deliveryServiceArea;
  final double? averageReview;
  final double? distance;
  final bool isFavourite;
  const RestaurantProfile({
    super.key,
    required this.uuid,
    this.deliveryServiceArea,
    this.averageReview,
    this.distance,
    this.isFavourite = false,
  });

  @override
  State<RestaurantProfile> createState() => _RestaurantProfileState();
}

class _RestaurantProfileState extends State<RestaurantProfile> {
  bool _isLiked = false;
  final RestaurantService _restaurantService = RestaurantService();
  bool isMenuOpen = false;
  Restaurant? restaurant;
  bool isLoading = true;
  String _loadError = '';

  Future<void> fetchRestaurantDetails() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        _loadError = '';
      });
    }

    final service = RestaurantDetailsService();
    final response = await service.getRestaurantDetails(widget.uuid);
    if (!mounted) return;

    if (response.status && response.restaurant != null) {
      setState(() {
        restaurant = response.restaurant;
        isLoading = false;
        _loadError = '';
      });
    } else {
      setState(() {
        isLoading = false;
        _loadError = response.message.isNotEmpty
            ? response.message
            : 'We could not load this restaurant. Please try again.';
      });
    }
  }

  Future<void> _onFavouriteTap() async {
    final data = RestaurantLikedDislikedModel(uuid: widget.uuid);
    final response = await _restaurantService.changeStatus(data);
    if (response.status) {
      setState(() => _isLiked = !_isLiked);
      if (!mounted) return;
      showStatusSnack(
        context,
        _isLiked,
        _isLiked ? 'Added to favourites' : 'Removed from favourites',
      );
    }
  }

  void _openImagePreview(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _ImagePreviewGallery(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isFavourite;
    fetchRestaurantDetails();
  }

  @override
  Widget build(BuildContext context) {
    final distanceLabel = widget.distance != null
        ? '${widget.distance!.toStringAsFixed(widget.distance! % 1 == 0 ? 0 : 1)} km'
        : '${widget.deliveryServiceArea ?? restaurant?.deliveryServiceArea ?? 'N/A'} km';
    final reviewLabel =
        (restaurant?.averageReview ?? widget.averageReview)?.toStringAsFixed(
          1,
        ) ??
        'N/A';
    final metrics = _RestaurantProfileMetrics.fromContext(context);
    final topSafePadding = MediaQuery.paddingOf(context).top;
    final favoriteButtonSize = (metrics.favoriteIconSize + 16)
        .clamp(44.0, 64.0)
        .toDouble();
    final minFavoriteTop = topSafePadding + 8.0;
    final badgeBlockHeight =
        ((metrics.badgeIconSize > metrics.badgeTextSize
                    ? metrics.badgeIconSize
                    : metrics.badgeTextSize) +
                metrics.badgeVerticalPadding * 2) *
            2 +
        metrics.badgeGap;
    final maxFavoriteTop =
        (metrics.heroHeight -
                metrics.heroBottomInset -
                badgeBlockHeight -
                favoriteButtonSize -
                8.0)
            .clamp(minFavoriteTop, double.infinity)
            .toDouble();
    final favoriteTop = (topSafePadding + metrics.heroTopInset)
        .clamp(minFavoriteTop, maxFavoriteTop)
        .toDouble();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _isLiked);
      },
      child: Scaffold(
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError.isNotEmpty
            ? SafeArea(
                child: ErrorStateView(
                  message: _loadError,
                  onRetry: fetchRestaurantDetails,
                ),
              )
            : isMenuOpen
            ? Menu(restaurantId: widget.uuid)
            : SingleChildScrollView(
                child: Center(
                  child: SizedBox(
                    width: metrics.contentMaxWidth,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            restaurant?.image != null
                                ? Image.network(
                                    restaurant!.image!,
                                    height: metrics.heroHeight,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      'assets/images/restaurantBanner.png',
                                      height: metrics.heroHeight,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/restaurantBanner.png',
                                    height: metrics.heroHeight,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),

                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                            ),

                            Positioned(
                              top: favoriteTop,
                              right: metrics.heroSideInset,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.18),
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: _onFavouriteTap,
                                  child: SizedBox(
                                    width: favoriteButtonSize,
                                    height: favoriteButtonSize,
                                    child: Center(
                                      child: Icon(
                                        Icons.favorite,
                                        color: _isLiked
                                            ? const Color(0xFFf87b0d)
                                            : Colors.white,
                                        size: metrics.favoriteIconSize,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: metrics.heroBottomInset,
                              right: metrics.heroSideInset,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _badge(
                                    pin_to_pinIcon,
                                    distanceLabel,
                                    metrics.badgeIconSize,
                                    metrics,
                                  ),
                                  SizedBox(height: metrics.badgeGap),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => RatingPage(
                                            restaurantId: widget.uuid,
                                            restaurantName: restaurant?.name,
                                            restaurantAddress:
                                                restaurant?.address,
                                          ),
                                        ),
                                      );
                                    },
                                    child: _badge(
                                      reviewStarIcon,
                                      reviewLabel,
                                      metrics.badgeIconSize,
                                      metrics,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Positioned(
                              left: metrics.heroSideInset,
                              right: metrics.heroTextRightInset,
                              bottom: metrics.heroBottomInset,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    text: restaurant?.name ?? "",
                                    size: metrics.heroNameSize,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  AppText(
                                    text: restaurant?.type ?? "",
                                    size: metrics.heroTypeSize,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: metrics.heroInfoGap),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Image.asset(
                                        locationpinIcon,
                                        width: metrics.heroAddressIconSize,
                                        height: metrics.heroAddressIconSize,
                                      ),
                                      SizedBox(width: metrics.tinyGap),
                                      Expanded(
                                        child: AppText(
                                          text: restaurant?.address ?? "",
                                          size: metrics.heroAddressSize,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: metrics.sectionGap),

                        SizedBox(
                          height: metrics.offersHeight,
                          child:
                              restaurant?.offers == null ||
                                  restaurant!.offers.isEmpty
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
                                  itemCount: _offerSlotTickets(
                                    restaurant!.offers,
                                  ).length,
                                  itemBuilder: (context, index) {
                                    final ticket = _offerSlotTickets(
                                      restaurant!.offers,
                                    )[index];
                                    final offer = ticket.offer;
                                    final discountStr =
                                        '-${offer.discountPercentage.toStringAsFixed(0)}%';
                                    final forText =
                                        'for ${offer.applicableFor}';
                                    final timeStr = ticket.startTime;
                                    const days2 = [
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat',
                                      'Sun',
                                    ];
                                    final today =
                                        days2[DateTime.now().weekday - 1];
                                    final activeDays = offer.activeDays
                                        .split(',')
                                        .map((d) => d.trim())
                                        .where((d) => d.isNotEmpty)
                                        .toList();
                                    final dateLabel = activeDays.contains(today)
                                        ? 'TODAY'
                                        : activeDays.isNotEmpty
                                        ? activeDays.first.toUpperCase()
                                        : 'TODAY';
                                    final offerId = offer.uuid.isNotEmpty
                                        ? offer.uuid
                                        : null;

                                    return GestureDetector(
                                      onTap: () => _bookOffer(
                                        offerId: offerId,
                                        offer: ticket.offerForBooking,
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
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        AppText(
                                                          text: discountStr,
                                                          size: metrics
                                                              .offerDiscountSize,
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        SizedBox(
                                                          height:
                                                              metrics.tinyGap,
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              double.infinity,
                                                          child: Text(
                                                            forText,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: metrics
                                                                  .offerForSize,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
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
                                                                : Colors
                                                                      .transparent,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Column(
                                                      children: [
                                                        SizedBox(
                                                          height:
                                                              metrics.tinyGap /
                                                              2,
                                                        ),
                                                        AppText(
                                                          text: dateLabel,
                                                          size: metrics
                                                              .offerDateSize,
                                                          color: Colors.white70,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        SizedBox(
                                                          height: metrics
                                                              .offerDateGap,
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
                                                            fit: BoxFit
                                                                .scaleDown,
                                                            child: Text(
                                                              timeStr,
                                                              maxLines: 1,
                                                              softWrap: false,
                                                              overflow:
                                                                  TextOverflow
                                                                      .visible,
                                                              style: TextStyle(
                                                                fontSize: metrics
                                                                    .offerTimeSize,
                                                                color: Colors
                                                                    .green
                                                                    .shade700,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
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
                                                left:
                                                    -metrics.ticketHoleSize / 2,
                                                top: 20,
                                                bottom: 0,
                                                child: Center(
                                                  child: Container(
                                                    width:
                                                        metrics.ticketHoleSize,
                                                    height:
                                                        metrics.ticketHoleSize,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade100,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                right:
                                                    -metrics.ticketHoleSize / 2,
                                                top: 20,
                                                bottom: 0,
                                                child: Center(
                                                  child: Container(
                                                    width:
                                                        metrics.ticketHoleSize,
                                                    height:
                                                        metrics.ticketHoleSize,
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade100,
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
                        SizedBox(height: metrics.galleryTopGap),
                        SizedBox(
                          height: metrics.galleryHeight,
                          child: restaurant?.images.isEmpty ?? true
                              ? Center(
                                  child: AppText(
                                    color: Colors.grey,
                                    size: metrics.emptyOfferTextSize,
                                    text: 'No images available',
                                    fontWeight: FontWeight.w400,
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: restaurant!.images.length,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: metrics.pagePadding,
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: metrics.galleryGap,
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _openImagePreview(
                                          restaurant!.images,
                                          index,
                                        ),
                                        child: Hero(
                                          tag: 'restaurant-gallery-$index',
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              metrics.galleryRadius,
                                            ),
                                            child: Image.network(
                                              restaurant!.images[index],
                                              height: metrics.galleryHeight,
                                              width: metrics.galleryItemWidth,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Image.asset(
                                                    'assets/images/restaurantPic.png',
                                                    height:
                                                        metrics.galleryHeight,
                                                    fit: BoxFit.cover,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),

                        Padding(
                          padding: EdgeInsets.all(metrics.pagePadding),
                          child: Container(
                            padding: EdgeInsets.all(metrics.infoCardPadding),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                metrics.infoCardRadius,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: metrics.infoCardShadowBlur,
                                  offset: Offset(
                                    0,
                                    metrics.infoCardShadowOffset,
                                  ),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: metrics.infoSectionGap),
                                Row(
                                  children: [
                                    AppText(
                                      text: "About",
                                      size: metrics.sectionTitleSize,
                                      fontWeight: FontWeight.bold,
                                      color: appTextColor2,
                                    ),
                                    SizedBox(width: metrics.infoTitleGap),
                                    Expanded(
                                      child: Container(
                                        height: 0.5,
                                        color: appTextColor3,
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: metrics.infoTextVerticalPadding,
                                    right: metrics.infoTextHorizontalPadding,
                                    left: metrics.infoTextHorizontalPadding,
                                    bottom: metrics.infoTextVerticalPadding,
                                  ),
                                  child: AppText(
                                    text: restaurant?.description ?? "",
                                    size: metrics.infoTextSize,
                                    fontWeight: FontWeight.w400,
                                    color: appTextColor2,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    AppText(
                                      text: "Cuisine",
                                      size: metrics.sectionTitleSize,
                                      fontWeight: FontWeight.bold,
                                      color: appTextColor2,
                                    ),
                                    SizedBox(width: metrics.infoTitleGap),
                                    Expanded(
                                      child: Container(
                                        height: 0.5,
                                        color: appTextColor3,
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: metrics.infoTextVerticalPadding,
                                    right: metrics.infoTextHorizontalPadding,
                                    left: metrics.infoTextHorizontalPadding,
                                    bottom: metrics.infoTextVerticalPadding,
                                  ),
                                  child: AppText(
                                    text: restaurant?.restaurantType ?? "",
                                    size: metrics.infoTextSize,
                                    fontWeight: FontWeight.w400,
                                    color: appTextColor2,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    AppText(
                                      text: "Address",
                                      size: metrics.sectionTitleSize,
                                      fontWeight: FontWeight.bold,
                                      color: appTextColor2,
                                    ),
                                    SizedBox(width: metrics.infoTitleGap),
                                    Expanded(
                                      child: Container(
                                        height: 0.5,
                                        color: appTextColor3,
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: metrics.infoTextVerticalPadding,
                                    right: metrics.infoTextHorizontalPadding,
                                    left: metrics.infoTextHorizontalPadding,
                                    bottom: metrics.infoTextVerticalPadding,
                                  ),
                                  child: AppText(
                                    text: restaurant?.address ?? "",
                                    size: metrics.infoTextSize,
                                    fontWeight: FontWeight.w400,
                                    color: appTextColor2,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    AppText(
                                      text: "Contact Info",
                                      size: metrics.sectionTitleSize,
                                      fontWeight: FontWeight.bold,
                                      color: appTextColor2,
                                    ),
                                    SizedBox(width: metrics.infoTitleGap),
                                    Expanded(
                                      child: Container(
                                        height: 0.5,
                                        color: appTextColor3,
                                      ),
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    top: metrics.infoTextVerticalPadding,
                                    right: metrics.infoTextHorizontalPadding,
                                    left: metrics.infoTextHorizontalPadding,
                                    bottom: metrics.infoTextVerticalPadding,
                                  ),
                                  child: AppText(
                                    text: restaurant?.phone ?? "",
                                    size: metrics.infoTextSize,
                                    fontWeight: FontWeight.w400,
                                    color: appTextColor2,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: metrics.menuButtonWidth,
                          height: metrics.menuButtonHeight,
                          child: AppButton(
                            imageIconPath: menuBookIcon,
                            iconSize: metrics.menuButtonIconSize,
                            bgColor1: appButtonColor,
                            bgColor2: Color(0xFF934808),
                            text: " View Menu",
                            size: metrics.menuButtonTextSize,
                            borderRadius: metrics.menuButtonRadius,
                            onPressed: () {
                              setState(() {
                                isMenuOpen = !isMenuOpen;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: metrics.bottomGap),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  List<_OfferSlotTicket> _offerSlotTickets(List<OfferModel> offers) {
    return offers.expand((offer) {
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

  void _bookOffer({
    required String? offerId,
    required OfferModel? offer,
    DateTime? reservationDate,
  }) {
    final sheetSize = MediaQuery.sizeOf(context);
    final isTabletSheet = Breakpoints.isTabletDevice(sheetSize);
    final tabletSheetWidth = sheetSize.width * 0.88;
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      constraints: isTabletSheet
          ? BoxConstraints(
              minWidth: tabletSheetWidth,
              maxWidth: tabletSheetWidth,
            )
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => NumberOfPeopleModal(
        uuid: widget.uuid,
        reservationDate: reservationDate,
        allowSlotSelection: false,
        offerId: offerId,
        offer: offer,
      ),
    );
  }

  Widget _offerTimeChip(
    String label,
    _RestaurantProfileMetrics metrics,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: metrics.offerTimeHorizontalPadding,
          vertical: metrics.offerTimeVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(metrics.offerTimeRadius),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: metrics.offerTimeSize,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(
    String? imageIconPath,
    String text,
    double? iconSize,
    _RestaurantProfileMetrics metrics,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.badgeHorizontalPadding,
        vertical: metrics.badgeVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: const Color(0xfff87b0d),
        borderRadius: BorderRadius.circular(metrics.badgeRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          imageIconPath != null
              ? Image.asset(
                  imageIconPath,
                  width: iconSize ?? metrics.badgeIconSize,
                  height: iconSize ?? metrics.badgeIconSize,
                )
              : Icon(
                  Icons.info,
                  size: iconSize ?? metrics.badgeIconSize,
                  color: Colors.white,
                ),
          SizedBox(width: metrics.tinyGap),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: metrics.badgeTextSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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

class _RestaurantProfileMetrics {
  const _RestaurantProfileMetrics({
    required this.contentMaxWidth,
    required this.pagePadding,
    required this.heroHeight,
    required this.heroTopInset,
    required this.heroSideInset,
    required this.heroBottomInset,
    required this.heroTextRightInset,
    required this.favoriteIconSize,
    required this.heroNameSize,
    required this.heroTypeSize,
    required this.heroAddressSize,
    required this.heroAddressIconSize,
    required this.heroInfoGap,
    required this.badgeHorizontalPadding,
    required this.badgeVerticalPadding,
    required this.badgeRadius,
    required this.badgeIconSize,
    required this.badgeTextSize,
    required this.badgeGap,
    required this.sectionGap,
    required this.contentPadding,
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
    required this.galleryTopGap,
    required this.galleryHeight,
    required this.galleryItemWidth,
    required this.galleryGap,
    required this.galleryRadius,
    required this.infoCardPadding,
    required this.infoCardRadius,
    required this.infoCardShadowBlur,
    required this.infoCardShadowOffset,
    required this.infoSectionGap,
    required this.sectionTitleSize,
    required this.infoTitleGap,
    required this.infoTextVerticalPadding,
    required this.infoTextHorizontalPadding,
    required this.infoTextSize,
    required this.menuButtonWidth,
    required this.menuButtonHeight,
    required this.menuButtonIconSize,
    required this.menuButtonTextSize,
    required this.menuButtonRadius,
    required this.bottomGap,
    required this.tinyGap,
  });

  final double contentMaxWidth;
  final double pagePadding;
  final double heroHeight;
  final double heroTopInset;
  final double heroSideInset;
  final double heroBottomInset;
  final double heroTextRightInset;
  final double favoriteIconSize;
  final double heroNameSize;
  final double heroTypeSize;
  final double heroAddressSize;
  final double heroAddressIconSize;
  final double heroInfoGap;
  final double badgeHorizontalPadding;
  final double badgeVerticalPadding;
  final double badgeRadius;
  final double badgeIconSize;
  final double badgeTextSize;
  final double badgeGap;
  final double sectionGap;
  final double contentPadding;
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
  final double galleryTopGap;
  final double galleryHeight;
  final double galleryItemWidth;
  final double galleryGap;
  final double galleryRadius;
  final double infoCardPadding;
  final double infoCardRadius;
  final double infoCardShadowBlur;
  final double infoCardShadowOffset;
  final double infoSectionGap;
  final double sectionTitleSize;
  final double infoTitleGap;
  final double infoTextVerticalPadding;
  final double infoTextHorizontalPadding;
  final double infoTextSize;
  final double menuButtonWidth;
  final double menuButtonHeight;
  final double menuButtonIconSize;
  final double menuButtonTextSize;
  final double menuButtonRadius;
  final double bottomGap;
  final double tinyGap;

  factory _RestaurantProfileMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenHeight = size.height;
    final isTablet = Breakpoints.isTabletDevice(size);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final contentWidth = size.width;
      final scale = (contentWidth / 1024).clamp(1.0, 1.18).toDouble();
      double s(double value) => value * scale;

      // Dynamic hero: 30–36% of screen height, clamped to a sensible range
      final heroHeight = (screenHeight * 0.33).clamp(280.0, 480.0);

      return _RestaurantProfileMetrics(
        contentMaxWidth: contentWidth,
        pagePadding: s(42),
        heroHeight: heroHeight,
        heroTopInset: s(42),
        heroSideInset: s(46),
        heroBottomInset: s(38),
        heroTextRightInset: s(250),
        favoriteIconSize: s(42),
        heroNameSize: s(48),
        heroTypeSize: s(34),
        heroAddressSize: s(17),
        heroAddressIconSize: s(22),
        heroInfoGap: s(14),
        badgeHorizontalPadding: s(16),
        badgeVerticalPadding: s(10),
        badgeRadius: s(14),
        badgeIconSize: s(24),
        badgeTextSize: s(17),
        badgeGap: s(12),
        sectionGap: s(30),
        contentPadding: s(34),
        offersHeight: s(210),
        offerBottomPadding: s(24),
        emptyOfferTextSize: s(17),
        offerGap: s(12),
        offerWidth: s(140),
        offerTopRadius: s(8),
        offerBottomRadius: s(16),
        offerPadding: s(14),
        offerDiscountSize: s(24),
        offerForSize: s(14),
        ticketDashHeight: s(1.4),
        offerDateSize: s(9),
        offerDateGap: s(10),
        offerTimeHorizontalPadding: s(12),
        offerTimeVerticalPadding: s(6),
        offerTimeRadius: s(9),
        offerTimeSize: s(15),
        ticketHoleSize: s(22),
        galleryTopGap: s(18),
        galleryHeight: s(240),
        galleryItemWidth: s(170),
        galleryGap: s(16),
        galleryRadius: s(14),
        infoCardPadding: s(28),
        infoCardRadius: s(24),
        infoCardShadowBlur: s(16),
        infoCardShadowOffset: s(5),
        infoSectionGap: s(16),
        sectionTitleSize: s(18),
        infoTitleGap: s(16),
        infoTextVerticalPadding: s(13),
        infoTextHorizontalPadding: s(16),
        infoTextSize: s(17),
        menuButtonWidth: s(250),
        menuButtonHeight: s(68),
        menuButtonIconSize: s(44),
        menuButtonTextSize: s(22),
        menuButtonRadius: s(18),
        bottomGap: s(36),
        tinyGap: s(7),
      );
    }

    if (isWideShortPhone) {
      // Dynamic hero: ~22% of screen height, clamped for short wide phones.
      // Floor raised from 130 to 160 so the favorite icon (top-anchored) and
      // the distance/rating badges (bottom-anchored) both get enough room
      // instead of being squeezed to a few px of clearance from the top.
      final heroHeight = (screenHeight * 0.24).clamp(160.0, 200.0);

      return _RestaurantProfileMetrics(
        contentMaxWidth: double.infinity,
        pagePadding: 24,
        heroHeight: heroHeight,
        heroTopInset: 34,
        heroSideInset: 24,
        heroBottomInset: 16,
        heroTextRightInset: 128,
        favoriteIconSize: 28,
        heroNameSize: 28,
        heroTypeSize: 20,
        heroAddressSize: 11.5,
        heroAddressIconSize: 15,
        heroInfoGap: 6,
        badgeHorizontalPadding: 9,
        badgeVerticalPadding: 5,
        badgeRadius: 9,
        badgeIconSize: 16,
        badgeTextSize: 12,
        badgeGap: 7,
        sectionGap: 16,
        contentPadding: 22,
        offersHeight: 116,
        offerBottomPadding: 10,
        emptyOfferTextSize: 12.5,
        offerGap: 7,
        offerWidth: 86,
        offerTopRadius: 5,
        offerBottomRadius: 10,
        offerPadding: 7,
        offerDiscountSize: 18,
        offerForSize: 9.5,
        ticketDashHeight: 1,
        offerDateSize: 5.5,
        offerDateGap: 4,
        offerTimeHorizontalPadding: 6,
        offerTimeVerticalPadding: 3,
        offerTimeRadius: 6,
        offerTimeSize: 9,
        ticketHoleSize: 15,
        galleryTopGap: 8,
        galleryHeight: 128,
        galleryItemWidth: 100,
        galleryGap: 10,
        galleryRadius: 9,
        infoCardPadding: 16,
        infoCardRadius: 18,
        infoCardShadowBlur: 9,
        infoCardShadowOffset: 3,
        infoSectionGap: 9,
        sectionTitleSize: 12,
        infoTitleGap: 10,
        infoTextVerticalPadding: 7,
        infoTextHorizontalPadding: 10,
        infoTextSize: 12,
        menuButtonWidth: 170,
        menuButtonHeight: 48,
        menuButtonIconSize: 32,
        menuButtonTextSize: 16,
        menuButtonRadius: 14,
        bottomGap: 18,
        tinyGap: 4,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;

      // Dynamic hero: ~24% of screen height, clamped for compact phones
      final heroHeight = (screenHeight * 0.24).clamp(130.0, 200.0);

      return _RestaurantProfileMetrics(
        contentMaxWidth: double.infinity,
        pagePadding: s(14),
        heroHeight: heroHeight,
        heroTopInset: s(22),
        heroSideInset: s(14),
        heroBottomInset: s(12),
        heroTextRightInset: s(104),
        favoriteIconSize: s(24),
        heroNameSize: s(23),
        heroTypeSize: s(17),
        heroAddressSize: s(10.5),
        heroAddressIconSize: s(14),
        heroInfoGap: s(5),
        badgeHorizontalPadding: s(8),
        badgeVerticalPadding: s(4),
        badgeRadius: s(8),
        badgeIconSize: s(15),
        badgeTextSize: s(11),
        badgeGap: s(6),
        sectionGap: s(14),
        contentPadding: s(12),
        offersHeight: s(112),
        offerBottomPadding: s(10),
        emptyOfferTextSize: s(12),
        offerGap: s(4),
        offerWidth: s(72),
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
        galleryTopGap: s(8),
        galleryHeight: s(120),
        galleryItemWidth: s(82),
        galleryGap: s(8),
        galleryRadius: s(8),
        infoCardPadding: s(13),
        infoCardRadius: s(16),
        infoCardShadowBlur: s(8),
        infoCardShadowOffset: s(3),
        infoSectionGap: s(8),
        sectionTitleSize: s(11.5),
        infoTitleGap: s(8),
        infoTextVerticalPadding: s(6),
        infoTextHorizontalPadding: s(8),
        infoTextSize: s(11.5),
        menuButtonWidth: s(155),
        menuButtonHeight: s(44),
        menuButtonIconSize: s(30),
        menuButtonTextSize: s(15),
        menuButtonRadius: s(13),
        bottomGap: s(16),
        tinyGap: s(4),
      );
    }

    // Standard phones: dynamic hero = 28% of screen height, clamped 180–300px
    final heroHeight = (screenHeight * 0.28).clamp(180.0, 300.0);

    return _RestaurantProfileMetrics(
      contentMaxWidth: double.infinity,
      pagePadding: 20.r,
      heroHeight: heroHeight,
      heroTopInset: 30.h,
      heroSideInset: 20.w,
      heroBottomInset: 20.h,
      heroTextRightInset: 120.w,
      favoriteIconSize: 30.w,
      heroNameSize: 30,
      heroTypeSize: 25,
      heroAddressSize: 12,
      heroAddressIconSize: 16,
      heroInfoGap: 8.h,
      badgeHorizontalPadding: 10.w,
      badgeVerticalPadding: 6.h,
      badgeRadius: 10.r,
      badgeIconSize: 18.w,
      badgeTextSize: 13,
      badgeGap: 8.h,
      sectionGap: 20.h,
      contentPadding: 15.w,
      offersHeight: 135.h,
      offerBottomPadding: 15.h,
      emptyOfferTextSize: 13.sp,
      offerGap: 5.w,
      offerWidth: 85.w,
      offerTopRadius: 5.r,
      offerBottomRadius: 10.r,
      offerPadding: 8.w,
      offerDiscountSize: 16.sp,
      offerForSize: 10.sp,
      ticketDashHeight: 1.h,
      offerDateSize: 6.sp,
      offerDateGap: 6.h,
      offerTimeHorizontalPadding: 6.w,
      offerTimeVerticalPadding: 4.h,
      offerTimeRadius: 6.r,
      offerTimeSize: 9.5.sp,
      ticketHoleSize: 16.w,
      galleryTopGap: 10.h,
      galleryHeight: 150.h,
      galleryItemWidth: 100.w,
      galleryGap: 10.w,
      galleryRadius: 10.r,
      infoCardPadding: 16.r,
      infoCardRadius: 20.r,
      infoCardShadowBlur: 10.r,
      infoCardShadowOffset: 4.r,
      infoSectionGap: 10.h,
      sectionTitleSize: 12,
      infoTitleGap: 10.w,
      infoTextVerticalPadding: 8.h,
      infoTextHorizontalPadding: 10.w,
      infoTextSize: 12,
      menuButtonWidth: 175.w,
      menuButtonHeight: 50.h,
      menuButtonIconSize: 35.w,
      menuButtonTextSize: 17,
      menuButtonRadius: 15.r,
      bottomGap: 20.h,
      tinyGap: 4.w,
    );
  }
}

class _ImagePreviewGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ImagePreviewGallery({required this.images, required this.initialIndex});

  @override
  State<_ImagePreviewGallery> createState() => _ImagePreviewGalleryState();
}

class _ImagePreviewGalleryState extends State<_ImagePreviewGallery> {
  late final PageController _pageController;
  late final TransformationController _transformationController;
  late int _currentIndex;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController()
      ..addListener(_onTransformChanged);
  }

  void _onTransformChanged() {
    final zoomed = _transformationController.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            physics: _isZoomed
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            onPageChanged: (index) {
              _transformationController.value = Matrix4.identity();
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              final image = Center(
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/restaurantPic.png',
                    fit: BoxFit.contain,
                  ),
                ),
              );

              return InteractiveViewer(
                transformationController: index == _currentIndex
                    ? _transformationController
                    : null,
                panEnabled: index == _currentIndex && _isZoomed,
                minScale: 1,
                maxScale: 4,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!_isZoomed) Navigator.of(context).pop();
                  },
                  child: index == widget.initialIndex
                      ? Hero(tag: 'restaurant-gallery-$index', child: image)
                      : image,
                ),
              );
            },
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 24.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (index) {
                final isActive = index == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  height: 6.w,
                  width: isActive ? 18.w : 6.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: isActive ? 0.95 : 0.4,
                    ),
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
