import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';

class MenuCard extends StatelessWidget {
  final String url;
  final String name;
  final String price;
  final String description;
  final String category;

  const MenuCard({
    super.key,
    required this.url,
    this.name = '',
    this.price = '',
    this.description = '',
    this.category = '',
  });

  @override
  Widget build(BuildContext context) {
    final metrics = _MenuCardMetrics.fromContext(context);

    return Container(
      margin: EdgeInsets.only(bottom: metrics.bottomMargin),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(metrics.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: metrics.shadowBlur,
            offset: Offset(0, metrics.shadowOffset),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(metrics.radius),
              bottomLeft: Radius.circular(metrics.radius),
            ),
            child: SizedBox(
              width: metrics.imageWidth,
              height: metrics.imageHeight,
              child: _buildImage(metrics),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: metrics.contentHorizontalPadding,
                vertical: metrics.contentVerticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AppText(
                    text: name,
                    size: metrics.nameSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  SizedBox(height: metrics.namePriceGap),
                  AppText(
                    text: price,
                    size: metrics.priceSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  SizedBox(height: metrics.priceDescriptionGap),
                  AppText(
                    text: description,
                    size: metrics.descriptionSize,
                    fontWeight: FontWeight.w400,
                    color: Colors.black54,
                    lineSpacing: 1.3,
                    maxLines: metrics.descriptionMaxLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(_MenuCardMetrics metrics) {
    if (url.trim().isEmpty) {
      return Image.asset(
        'assets/images/dish.png',
        fit: BoxFit.cover,
        width: metrics.imageWidth,
        height: metrics.imageHeight,
      );
    }

    final parsed = Uri.tryParse(url);
    final isNetworkImage = parsed != null && parsed.scheme.startsWith('http');

    if (isNetworkImage) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: metrics.imageWidth,
        height: metrics.imageHeight,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/dish.png',
          fit: BoxFit.cover,
          width: metrics.imageWidth,
          height: metrics.imageHeight,
        ),
      );
    }

    return Image.asset(
      url,
      fit: BoxFit.cover,
      width: metrics.imageWidth,
      height: metrics.imageHeight,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/dish.png',
        fit: BoxFit.cover,
        width: metrics.imageWidth,
        height: metrics.imageHeight,
      ),
    );
  }
}

class _MenuCardMetrics {
  const _MenuCardMetrics({
    required this.bottomMargin,
    required this.radius,
    required this.shadowBlur,
    required this.shadowOffset,
    required this.imageWidth,
    required this.imageHeight,
    required this.contentHorizontalPadding,
    required this.contentVerticalPadding,
    required this.nameSize,
    required this.namePriceGap,
    required this.priceSize,
    required this.priceDescriptionGap,
    required this.descriptionSize,
    required this.descriptionMaxLines,
  });

  final double bottomMargin;
  final double radius;
  final double shadowBlur;
  final double shadowOffset;
  final double imageWidth;
  final double imageHeight;
  final double contentHorizontalPadding;
  final double contentVerticalPadding;
  final double nameSize;
  final double namePriceGap;
  final double priceSize;
  final double priceDescriptionGap;
  final double descriptionSize;
  final int descriptionMaxLines;

  factory _MenuCardMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      return const _MenuCardMetrics(
        bottomMargin: 20,
        radius: 18,
        shadowBlur: 10,
        shadowOffset: 3,
        imageWidth: 180,
        imageHeight: 200,
        contentHorizontalPadding: 20,
        contentVerticalPadding: 18,
        nameSize: 22,
        namePriceGap: 6,
        priceSize: 19,
        priceDescriptionGap: 12,
        descriptionSize: 14,
        descriptionMaxLines: 4,
      );
    }

    if (isWideShortPhone) {
      // Shorter image height than the standard-phone tier since height is
      // the constrained dimension in landscape — keeps card height down so
      // more of the list is visible without scrolling.
      return const _MenuCardMetrics(
        bottomMargin: 10,
        radius: 14,
        shadowBlur: 6,
        shadowOffset: 2,
        imageWidth: 110,
        imageHeight: 100,
        contentHorizontalPadding: 12,
        contentVerticalPadding: 8,
        nameSize: 13.5,
        namePriceGap: 3,
        priceSize: 12,
        priceDescriptionGap: 5,
        descriptionSize: 10,
        descriptionMaxLines: 2,
      );
    }

    if (isCompactPhone) {
      return const _MenuCardMetrics(
        bottomMargin: 12,
        radius: 14,
        shadowBlur: 7,
        shadowOffset: 2,
        imageWidth: 116,
        imageHeight: 136,
        contentHorizontalPadding: 11,
        contentVerticalPadding: 11,
        nameSize: 14.5,
        namePriceGap: 3,
        priceSize: 13,
        priceDescriptionGap: 6,
        descriptionSize: 10,
        descriptionMaxLines: 3,
      );
    }

    return const _MenuCardMetrics(
      bottomMargin: 16,
      radius: 16,
      shadowBlur: 8,
      shadowOffset: 2,
      imageWidth: 140,
      imageHeight: 160,
      contentHorizontalPadding: 14,
      contentVerticalPadding: 14,
      nameSize: 17,
      namePriceGap: 4,
      priceSize: 15,
      priceDescriptionGap: 8,
      descriptionSize: 11,
      descriptionMaxLines: 3,
    );
  }
}
