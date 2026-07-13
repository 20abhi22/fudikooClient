import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/screens/reliability/donutPercentage.dart';
import 'package:fudikoclient/utils/constants.dart';

class ReliabilityInfo extends StatelessWidget {
  final double rating;

  const ReliabilityInfo({super.key, this.rating = 0});

  @override
  Widget build(BuildContext context) {
    final metrics = _ReliabilityInfoMetrics.fromContext(context);
    final percentage = (rating / 100).clamp(0.0, 1.0).toDouble();

    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: SizedBox(
              width: metrics.contentWidth,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.horizontalPadding,
                  vertical: metrics.verticalPadding,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          backOrange,
                          width: metrics.backIconSize,
                          height: metrics.backIconSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: metrics.chartTopGap),
                    SizedBox(
                      width: metrics.chartSize,
                      height: metrics.chartSize,
                      child: DonutChartStatic(percentage: percentage),
                    ),
                    SizedBox(height: metrics.messageTopGap),
                    AppText(
                      text: "Your current reliability rating is",
                      size: metrics.bodyTextSize,
                      fontWeight: FontWeight.w400,
                      color: appTextColor2,
                      isCentered: true,
                    ),
                    SizedBox(height: metrics.messageLineGap),
                    AppText(
                      text: "${rating.toStringAsFixed(1)}%",
                      size: metrics.ratingTextSize,
                      fontWeight: FontWeight.w700,
                      color: appTextColor3,
                      isCentered: true,
                    ),
                    SizedBox(height: metrics.cardTopGap),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(metrics.cardPadding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(metrics.cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: metrics.cardShadowBlur,
                            offset: Offset(0, metrics.cardShadowOffset),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          AppText(
                            text: "What is Reliability Rating",
                            size: metrics.titleTextSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            isCentered: true,
                          ),
                          SizedBox(height: metrics.cardTextGap),
                          AppText(
                            text:
                                "Reliability Rating reflects how consistently you complete your orders without cancellations. It is calculated based on your successful orders compared to cancellations of confirmed ones. A higher percentage means you are a reliable customer, which helps restaurants serve you better.",
                            size: metrics.bodyTextSize,
                            fontWeight: FontWeight.w400,
                            color: appTextColor2,
                            lineSpacing: 1.5,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: metrics.bottomGap),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReliabilityInfoMetrics {
  const _ReliabilityInfoMetrics({
    required this.contentWidth,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.backIconSize,
    required this.chartTopGap,
    required this.chartSize,
    required this.messageTopGap,
    required this.messageLineGap,
    required this.ratingTextSize,
    required this.bodyTextSize,
    required this.cardTopGap,
    required this.cardPadding,
    required this.cardRadius,
    required this.cardShadowBlur,
    required this.cardShadowOffset,
    required this.titleTextSize,
    required this.cardTextGap,
    required this.bottomGap,
  });

  final double contentWidth;
  final double horizontalPadding;
  final double verticalPadding;
  final double backIconSize;
  final double chartTopGap;
  final double chartSize;
  final double messageTopGap;
  final double messageLineGap;
  final double ratingTextSize;
  final double bodyTextSize;
  final double cardTopGap;
  final double cardPadding;
  final double cardRadius;
  final double cardShadowBlur;
  final double cardShadowOffset;
  final double titleTextSize;
  final double cardTextGap;
  final double bottomGap;

  factory _ReliabilityInfoMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTablet(size.width);
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final contentWidth = (size.width * 0.62).clamp(560.0, 760.0).toDouble();
      final scale = (contentWidth / 640).clamp(1.0, 1.14).toDouble();
      double s(double value) => value * scale;

      return _ReliabilityInfoMetrics(
        contentWidth: contentWidth,
        horizontalPadding: s(36),
        verticalPadding: s(34),
        backIconSize: s(30),
        chartTopGap: s(70),
        chartSize: s(340),
        messageTopGap: s(42),
        messageLineGap: s(8),
        ratingTextSize: s(24),
        bodyTextSize: s(18),
        cardTopGap: s(44),
        cardPadding: s(34),
        cardRadius: s(24),
        cardShadowBlur: s(12),
        cardShadowOffset: s(4),
        titleTextSize: s(20),
        cardTextGap: s(22),
        bottomGap: s(34),
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.86, 1.0).toDouble();
      double s(double value) => value * scale;

      return _ReliabilityInfoMetrics(
        contentWidth: double.infinity,
        horizontalPadding: s(22),
        verticalPadding: s(22),
        backIconSize: s(23),
        chartTopGap: s(48),
        chartSize: s(230),
        messageTopGap: s(28),
        messageLineGap: s(6),
        ratingTextSize: s(19),
        bodyTextSize: s(13.5),
        cardTopGap: s(30),
        cardPadding: s(22),
        cardRadius: s(16),
        cardShadowBlur: s(8),
        cardShadowOffset: s(3),
        titleTextSize: s(15),
        cardTextGap: s(16),
        bottomGap: s(24),
      );
    }

    return const _ReliabilityInfoMetrics(
      contentWidth: double.infinity,
      horizontalPadding: 30,
      verticalPadding: 30,
      backIconSize: 26,
      chartTopGap: 80,
      chartSize: 300,
      messageTopGap: 40,
      messageLineGap: 8,
      ratingTextSize: 20,
      bodyTextSize: 16,
      cardTopGap: 40,
      cardPadding: 30,
      cardRadius: 20,
      cardShadowBlur: 10,
      cardShadowOffset: 4,
      titleTextSize: 16,
      cardTextGap: 20,
      bottomGap: 30,
    );
  }
}
