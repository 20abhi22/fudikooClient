import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/routetransitions.dart';
import 'package:fudikoclient/screens/home/homepage.dart';
import 'package:fudikoclient/utils/constants.dart';

class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.city = 'Locating...',
    this.onLocationTap,
    this.onBackTap,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.searchController,
    this.searchHintText = 'Search',
    this.isLocationLoading = false,
  }); 

  final String city;
  final VoidCallback? onLocationTap;
  final VoidCallback? onBackTap;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final TextEditingController? searchController;
  final String searchHintText;
  final bool isLocationLoading;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _internalController;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isSearching = false;
  bool _showSwipeHint = false;
  bool _hasTypedDuringSession = false;
  double _searchDragOffset = 0;
  bool? _skipNextIconAnimation = false;

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController();
    _controller = widget.searchController ?? _internalController;
    _controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      _controller.removeListener(_handleTextChanged);
      _controller = widget.searchController ?? _internalController;
      _controller.addListener(_handleTextChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _focusNode.dispose();
    _internalController.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;

    if (hasText) {
      _hasTypedDuringSession = true;
      _showSwipeHint = false;
    } else if (_isSearching && _hasTypedDuringSession) {
      _showSwipeHint = true;
    }

    setState(() {});
    widget.onSearchChanged?.call(_controller.text);
  }

  void _activateSearch() {
    if (_isSearching) {
      _focusNode.requestFocus();
      return;
    }

    setState(() {
      _isSearching = true;
      _showSwipeHint = false;
      _hasTypedDuringSession = _controller.text.trim().isNotEmpty;
      _searchDragOffset = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _closeSearch({bool skipIconAnimation = false}) {
    _focusNode.unfocus();
    setState(() {
      _isSearching = false;
      _showSwipeHint = false;
      _hasTypedDuringSession = false;
      _searchDragOffset = 0;
      _skipNextIconAnimation = skipIconAnimation;
    });

    if (skipIconAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _skipNextIconAnimation = false);
      });
    }
  }

  void _handleSearchDragUpdate(DragUpdateDetails details) {
    if (!_isSearching) return;

    setState(() {
      _searchDragOffset = (_searchDragOffset + details.delta.dx).clamp(
        0.0,
        double.infinity,
      );
    });
  }

  void _handleSearchDragEnd(DragEndDetails details, double closeDragThreshold) {
    if (_searchDragOffset >= closeDragThreshold) {
      _closeSearch(skipIconAnimation: true);
      return;
    }

    setState(() => _searchDragOffset = 0);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final isTablet = Breakpoints.isTablet(width);
    final isCompactPhone = width < 390 || height < 700;
    final isLocationLoading =
        widget.isLocationLoading || widget.city.trim() == 'Locating...';

    final metrics = _AppSearchBarMetrics(
      horizontalPadding: isTablet
          ? 24.0
          : isCompactPhone
          ? 14.0
          : 20.0,
      verticalPadding: isTablet
          ? 14.0
          : isCompactPhone
          ? 8.0
          : 10.0,
      borderRadius: isTablet ? 18.0 : 15.0,
      shadowBlur: isTablet ? 10.0 : 8.0,
      shadowOffsetY: isTablet ? 5.0 : 4.0,
      backIconSize: isTablet
          ? 24.0
          : isCompactPhone
          ? 20.0
          : 22.0,
      searchIconSize: isTablet
          ? 23.0
          : isCompactPhone
          ? 19.0
          : 21.0,
      cityLabelSize: isTablet ? 12.0 : 11.0,
      cityTextSize: isTablet
          ? AppDimensions.body(context)
          : isCompactPhone
          ? 12.0
          : 13.0,
      searchTextSize: isTablet
          ? AppDimensions.body(context)
          : isCompactPhone
          ? 12.0
          : 13.0,
      iconTextGap: isTablet ? 6.0 : 4.0,
      sideMinWidth: isTablet ? 34.0 : 28.0,
      middleHorizontalGap: isTablet ? 14.0 : 10.0,
      animationWidthFactor: isTablet ? 0.88 : 1.0,
      barHeight: isTablet
          ? 64.0
          : isCompactPhone
          ? 60.0
          : 64.0,
    );
    final content = Container(
      height: metrics.barHeight,
      padding: EdgeInsets.symmetric(
        horizontal: metrics.horizontalPadding,
        vertical: metrics.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(metrics.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: metrics.shadowBlur,
            offset: Offset(0, metrics.shadowOffsetY),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, contentConstraints) {
          final maxDragDistance = _isSearching
              ? (contentConstraints.maxWidth - metrics.sideMinWidth).clamp(
                  0.0,
                  double.infinity,
                )
              : 0.0;
          final effectiveDragOffset = _searchDragOffset.clamp(
            0.0,
            maxDragDistance,
          );
          final closeDragThreshold = maxDragDistance * 0.9;
          final dragProgress = maxDragDistance == 0
              ? 0.0
              : (effectiveDragOffset / maxDragDistance).clamp(0.0, 1.0);
          final defaultOpacity = _isSearching ? dragProgress : 1.0;
          final searchOpacity = _isSearching ? 1.0 - dragProgress : 0.0;

          return Stack(
            alignment: Alignment.center,
            children: [
              IgnorePointer(
                ignoring: _isSearching,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  opacity: defaultOpacity,
                  child: _DefaultModeContent(
                    city: widget.city,
                    onLocationTap: widget.onLocationTap,
                    isLocationLoading: isLocationLoading,
                    cityLabelSize: metrics.cityLabelSize,
                    cityTextSize: metrics.cityTextSize,
                    iconTextGap: metrics.iconTextGap,
                    sideMinWidth: metrics.sideMinWidth,
                    middleHorizontalGap: metrics.middleHorizontalGap,
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: !_isSearching,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  opacity: searchOpacity,
                  child: _SearchModeContent(
                    controller: _controller,
                    focusNode: _focusNode,
                    hintText: _showSwipeHint
                        ? 'Swipe icon right to close'
                        : widget.searchHintText,
                    textSize: metrics.searchTextSize,
                    sideMinWidth: metrics.sideMinWidth,
                    onSubmitted: widget.onSearchSubmitted,
                    onClear: () {
                      _controller.clear();
                      _focusNode.requestFocus();
                    },
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: AnimatedAlign(
                    duration: _skipNextIconAnimation == true
                        ? Duration.zero
                        : const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    alignment: _isSearching
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: SizedBox(
                      width: metrics.sideMinWidth,
                      child: Align(
                        alignment: _isSearching
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _isSearching ? null : _activateSearch,
                          onHorizontalDragUpdate: _isSearching
                              ? _handleSearchDragUpdate
                              : null,
                          onHorizontalDragEnd: _isSearching
                              ? (details) => _handleSearchDragEnd(
                                  details,
                                  closeDragThreshold,
                                )
                              : null,
                          child: Transform.translate(
                            offset: Offset(
                              _isSearching ? effectiveDragOffset : 0,
                              0,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              child: Image.asset(
                                searchOrange,
                                width: metrics.searchIconSize,
                                height: metrics.searchIconSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!_isSearching || dragProgress > 0)
                Positioned(
                  left: 0,
                  child: SizedBox(
                    width: metrics.sideMinWidth,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _isSearching ? dragProgress : 1.0,
                        child: GestureDetector(
                          onTap: _isSearching
                              ? null
                              : widget.onBackTap ??
                                    () => slideLeftWidget(
                                      newPage: HomePage(),
                                      context: context,
                                    ),
                          child: Image.asset(
                            backOrange,
                            width: metrics.backIconSize,
                            height: metrics.backIconSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    if (!isTablet) {
      return content;
    }

    return FractionallySizedBox(
      widthFactor: metrics.animationWidthFactor,
      child: content,
    );
  }
}

class _DefaultModeContent extends StatelessWidget {
  const _DefaultModeContent({
    required this.city,
    required this.onLocationTap,
    required this.isLocationLoading,
    required this.cityLabelSize,
    required this.cityTextSize,
    required this.iconTextGap,
    required this.sideMinWidth,
    required this.middleHorizontalGap,
  });

  final String city;
  final VoidCallback? onLocationTap;
  final bool isLocationLoading;
  final double cityLabelSize;
  final double cityTextSize;
  final double iconTextGap;
  final double sideMinWidth;
  final double middleHorizontalGap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: sideMinWidth),
        SizedBox(width: middleHorizontalGap),
        Expanded(
          child: GestureDetector(
            onTap: onLocationTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  text: 'City',
                  size: cityLabelSize,
                  fontWeight: FontWeight.w600,
                  color: locationTextColor.withValues(alpha: 0.7),
                  isCentered: true,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: cityTextSize + 2,
                      height: cityTextSize + 2,
                      child: isLocationLoading
                          ? CircularProgressIndicator(
                              strokeWidth: 2,
                              color: appButtonColor,
                            )
                          : Icon(
                              Icons.location_on,
                              size: cityTextSize + 2,
                              color: appButtonColor,
                            ),
                    ),
                    SizedBox(width: iconTextGap),
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final adjustedSize = _resolveCityFontSize(
                            city: city,
                            baseSize: cityTextSize,
                            maxWidth: constraints.maxWidth,
                          );

                          return Text(
                            city,
                            maxLines: 2,
                            softWrap: true,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: adjustedSize,
                              fontWeight: FontWeight.w400,
                              color: locationTextColor.withValues(alpha: 0.7),
                              height: 1.0,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: middleHorizontalGap),
        SizedBox(width: sideMinWidth),
      ],
    );
  }

  double _resolveCityFontSize({
    required String city,
    required double baseSize,
    required double maxWidth,
  }) {
    final trimmedCity = city.trim();
    if (trimmedCity.isEmpty) return baseSize;

    final minSize = baseSize.clamp(9.0, baseSize).toDouble() - 4.0;
    var resolvedSize = baseSize;

    while (resolvedSize > minSize) {
      final painter = TextPainter(
        text: TextSpan(
          text: trimmedCity,
          style: TextStyle(fontSize: resolvedSize, fontWeight: FontWeight.w400),
        ),
        maxLines: 2,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      if (!painter.didExceedMaxLines) {
        break;
      }

      resolvedSize -= 0.5;
    }

    return resolvedSize.clamp(9.0, baseSize).toDouble();
  }
}

class _SearchModeContent extends StatelessWidget {
  const _SearchModeContent({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.textSize,
    required this.sideMinWidth,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final double textSize;
  final double sideMinWidth;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: sideMinWidth + 8),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              isCollapsed: true,
              hintStyle: TextStyle(
                color: locationTextColor.withValues(alpha: 0.55),
                fontSize: textSize,
              ),
            ),
            style: TextStyle(
              color: locationTextColor,
              fontSize: textSize,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(
          width: sideMinWidth + 8,
          child: controller.text.trim().isEmpty
              ? const SizedBox.shrink()
              : Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: onClear,
                    child: Icon(
                      Icons.close,
                      size: textSize + 6,
                      color: locationTextColor.withValues(alpha: 0.75),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _AppSearchBarMetrics {
  const _AppSearchBarMetrics({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
    required this.shadowBlur,
    required this.shadowOffsetY,
    required this.backIconSize,
    required this.searchIconSize,
    required this.cityLabelSize,
    required this.cityTextSize,
    required this.searchTextSize,
    required this.iconTextGap,
    required this.sideMinWidth,
    required this.middleHorizontalGap,
    required this.animationWidthFactor,
    required this.barHeight,
  });

  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
  final double shadowBlur;
  final double shadowOffsetY;
  final double backIconSize;
  final double searchIconSize;
  final double cityLabelSize;
  final double cityTextSize;
  final double searchTextSize;
  final double iconTextGap;
  final double sideMinWidth;
  final double middleHorizontalGap;
  final double animationWidthFactor;
  final double barHeight;
}
