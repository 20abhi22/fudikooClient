import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/components/error_state.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/model/menu/menu_model.dart';
import 'package:fudikoclient/screens/tabs/profile/menucard.dart';
import 'package:fudikoclient/service/menu/menu_service.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class Menu extends StatefulWidget {
  final String restaurantId;
  const Menu({super.key, required this.restaurantId});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  String selectedStatus = "PDF Menu";
  String _previousStatus = "PDF Menu";
  bool isLoading = true;
  String _loadError = '';
  List<MenuPdfModel> pdfList = [];
  List<MenuItemModel> menuItems = [];

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        _loadError = '';
      });
    }

    final response = await MenuService().getMenu(widget.restaurantId);
    if (!mounted) return;
    setState(() {
      pdfList = response.pdfs;
      menuItems = response.individualMenu;
      isLoading = false;
      _loadError = response.status ? '' : response.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _MenuMetrics.fromContext(context);

    return SafeArea(
      child: Scaffold(
        backgroundColor: appSecondaryBackgroundColor,
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError.isNotEmpty
            ? ErrorStateView(message: _loadError, onRetry: _fetchMenu)
            : Center(
                child: SizedBox(
                  width: metrics.contentWidth,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: metrics.headerHorizontalPadding,
                          vertical: metrics.headerVerticalPadding,
                        ),
                        child: SizedBox(
                          height: metrics.tabHeight,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return _buildAnimatedStatusTabs(
                                width: constraints.maxWidth,
                                metrics: metrics,
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.headerBottomGap),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onHorizontalDragEnd: _handleTabSwipe,
                          child: ClipRect(child: _buildSlidingTabBody(metrics)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void _handleTabSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 250) return;

    if (velocity < 0 && selectedStatus == "PDF Menu") {
      _selectStatus("Single Menu");
    } else if (velocity > 0 && selectedStatus == "Single Menu") {
      _selectStatus("PDF Menu");
    }
  }

  Widget _buildSlidingTabBody(_MenuMetrics metrics) {
    final bool showPdfMenu = selectedStatus == "PDF Menu";
    const duration = Duration(milliseconds: 430);
    const curve = Curves.easeInOutCubic;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: AnimatedSlide(
            offset: showPdfMenu ? Offset.zero : const Offset(-1, 0),
            duration: duration,
            curve: curve,
            child: IgnorePointer(
              ignoring: !showPdfMenu,
              child: _pdfMenuBody(metrics),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedSlide(
            offset: showPdfMenu ? const Offset(1, 0) : Offset.zero,
            duration: duration,
            curve: curve,
            child: IgnorePointer(
              ignoring: showPdfMenu,
              child: _singleMenuBody(metrics),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pdfMenuBody(_MenuMetrics metrics) {
    if (pdfList.isEmpty) {
      return _emptyState('No PDF menus available', metrics);
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: metrics.listBottomPadding),
      itemCount: pdfList.length,
      separatorBuilder: (_, __) => SizedBox(height: metrics.pdfGap),
      itemBuilder: (context, index) {
        final pdf = pdfList[index];
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: metrics.listHorizontalPadding,
          ),
          child: GestureDetector(
            onTap: () async {
              final url = _resolvePdfUri(pdf.pdfPath);
              if (url == null) return;

              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
            child: _pdfBox(pdf.menuName, metrics),
          ),
        );
      },
    );
  }

  Widget _singleMenuBody(_MenuMetrics metrics) {
    if (menuItems.isEmpty) {
      return _emptyState('No menu items available', metrics);
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: metrics.listBottomPadding),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: metrics.listHorizontalPadding,
          ),
          child: MenuCard(
            url: item.itemImage ?? 'assets/images/dish.png',
            name: item.itemName,
            price: item.itemPrice,
            description: item.itemDescription,
            category: item.itemCategory,
          ),
        );
      },
    );
  }

  Widget _emptyState(String message, _MenuMetrics metrics) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: Colors.grey, fontSize: metrics.emptyTextSize),
      ),
    );
  }

  Uri? _resolvePdfUri(String rawPath) {
    final trimmedPath = rawPath.trim();
    if (trimmedPath.isEmpty) {
      return null;
    }

    final parsed = Uri.tryParse(trimmedPath);
    if (parsed != null && parsed.hasScheme) {
      return parsed;
    }

    final baseOrigin = Uri.parse(DioClient.dio.options.baseUrl).origin;
    final normalizedPath = trimmedPath.startsWith('/')
        ? trimmedPath
        : '/$trimmedPath';
    return Uri.parse('$baseOrigin$normalizedPath');
  }

  Widget _pdfBox(String text, _MenuMetrics metrics) {
    return Container(
      width: double.infinity,
      height: metrics.pdfBoxHeight,
      padding: EdgeInsets.all(metrics.pdfBoxPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(metrics.pdfBoxRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: metrics.pdfShadowBlur,
            offset: Offset(0, metrics.pdfShadowOffset),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: Image.asset(
              'assets/images/pdfLogo.png',
              height: metrics.pdfIconSize,
              width: metrics.pdfIconSize,
              fit: BoxFit.contain,
            ),
          ),
          Center(
            child: AppText(
              text: text,
              size: metrics.pdfTextSize,
              isCentered: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              color: const Color(0xFF545450).withValues(alpha: .9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _selectStatus(String text) {
    if (selectedStatus == text) return;

    setState(() {
      _previousStatus = selectedStatus;
      selectedStatus = text;
    });
  }

  Widget _buildAnimatedStatusTabs({
    required double width,
    required _MenuMetrics metrics,
  }) {
    final tabs = ["PDF Menu", "Single Menu"];

    return Stack(
      children: [
        _buildStatusIndicator(width: width, metrics: metrics),
        ...tabs.map(
          (tab) =>
              _buildPositionedStatusButton(tab, width: width, metrics: metrics),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator({
    required double width,
    required _MenuMetrics metrics,
  }) {
    final rect = _statusTabRect(selectedStatus, width: width, metrics: metrics);
    final bool isStatusSwitch = _previousStatus != selectedStatus;

    return AnimatedPositioned.fromRect(
      rect: rect,
      duration: Duration(milliseconds: isStatusSwitch ? 430 : 280),
      curve: Curves.easeInOutCubic,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEC7B2D), Color(0xFFF7A440)],
          ),
          borderRadius: BorderRadius.circular(metrics.tabRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: metrics.tabShadowBlur,
              offset: Offset(metrics.tabShadowOffset, metrics.tabShadowOffset),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionedStatusButton(
    String text, {
    required double width,
    required _MenuMetrics metrics,
  }) {
    final bool isSelected = selectedStatus == text;

    return Positioned.fromRect(
      rect: _statusTabRect(text, width: width, metrics: metrics),
      child: GestureDetector(
        onTap: () => _selectStatus(text),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          scale: isSelected ? 1.02 : 1,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Colors.transparent : Colors.white,
              borderRadius: BorderRadius.circular(metrics.tabRadius),
              boxShadow: isSelected
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: metrics.tabShadowBlur,
                        offset: Offset(
                          metrics.tabShadowOffset,
                          metrics.tabShadowOffset,
                        ),
                      ),
                    ],
            ),
            child: AppText(
              text: text,
              size: metrics.tabTextSize,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : appTextColor3,
            ),
          ),
        ),
      ),
    );
  }

  Rect _statusTabRect(
    String text, {
    required double width,
    required _MenuMetrics metrics,
  }) {
    final double tabWidth = (width - metrics.tabGap) / 2;

    switch (text) {
      case "Single Menu":
        return Rect.fromLTWH(
          tabWidth + metrics.tabGap,
          0,
          tabWidth,
          metrics.tabHeight,
        );
      case "PDF Menu":
      default:
        return Rect.fromLTWH(0, 0, tabWidth, metrics.tabHeight);
    }
  }
}

class _MenuMetrics {
  const _MenuMetrics({
    required this.contentWidth,
    required this.headerHorizontalPadding,
    required this.headerVerticalPadding,
    required this.headerBottomGap,
    required this.tabGap,
    required this.tabHeight,
    required this.tabRadius,
    required this.tabTextSize,
    required this.tabShadowBlur,
    required this.tabShadowOffset,
    required this.listHorizontalPadding,
    required this.listBottomPadding,
    required this.emptyTextSize,
    required this.pdfGap,
    required this.pdfBoxHeight,
    required this.pdfBoxPadding,
    required this.pdfBoxRadius,
    required this.pdfShadowBlur,
    required this.pdfShadowOffset,
    required this.pdfIconSize,
    required this.pdfTextSize,
  });

  final double contentWidth;
  final double headerHorizontalPadding;
  final double headerVerticalPadding;
  final double headerBottomGap;
  final double tabGap;
  final double tabHeight;
  final double tabRadius;
  final double tabTextSize;
  final double tabShadowBlur;
  final double tabShadowOffset;
  final double listHorizontalPadding;
  final double listBottomPadding;
  final double emptyTextSize;
  final double pdfGap;
  final double pdfBoxHeight;
  final double pdfBoxPadding;
  final double pdfBoxRadius;
  final double pdfShadowBlur;
  final double pdfShadowOffset;
  final double pdfIconSize;
  final double pdfTextSize;

  factory _MenuMetrics.fromContext(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = Breakpoints.isTabletDevice(size);
    final isWideShortPhone =
        !isTablet && size.width >= 500 && size.height <= 760;
    final isCompactPhone = size.width < 390 || size.height < 700;

    if (isTablet) {
      final contentWidth = (size.width * 0.78).clamp(620.0, 860.0).toDouble();
      final scale = (contentWidth / 760).clamp(1.0, 1.12).toDouble();
      double s(double value) => value * scale;

      return _MenuMetrics(
        contentWidth: contentWidth,
        headerHorizontalPadding: s(34),
        headerVerticalPadding: s(38),
        headerBottomGap: s(34),
        tabGap: s(16),
        tabHeight: s(48),
        tabRadius: s(13),
        tabTextSize: s(16),
        tabShadowBlur: s(8),
        tabShadowOffset: s(2.5),
        listHorizontalPadding: s(38),
        listBottomPadding: s(34),
        emptyTextSize: s(16),
        pdfGap: s(14),
        pdfBoxHeight: s(88),
        pdfBoxPadding: s(20),
        pdfBoxRadius: s(22),
        pdfShadowBlur: s(12),
        pdfShadowOffset: s(4),
        pdfIconSize: s(50),
        pdfTextSize: s(16),
      );
    }

    if (isWideShortPhone) {
      // Cap content width so PDF/menu cards don't stretch edge-to-edge
      // across the wide landscape viewport, and tighten vertical chrome
      // since height is the constrained dimension here.
      final contentWidth = (size.width * 0.72).clamp(380.0, 620.0).toDouble();

      return _MenuMetrics(
        contentWidth: contentWidth,
        headerHorizontalPadding: 24,
        headerVerticalPadding: 14,
        headerBottomGap: 14,
        tabGap: 10,
        tabHeight: 34,
        tabRadius: 10,
        tabTextSize: 12.5,
        tabShadowBlur: 5,
        tabShadowOffset: 1.5,
        listHorizontalPadding: 24,
        listBottomPadding: 16,
        emptyTextSize: 12.5,
        pdfGap: 8,
        pdfBoxHeight: 56,
        pdfBoxPadding: 12,
        pdfBoxRadius: 16,
        pdfShadowBlur: 7,
        pdfShadowOffset: 2.5,
        pdfIconSize: 32,
        pdfTextSize: 12.5,
      );
    }

    if (isCompactPhone) {
      final scale = (size.width / 390).clamp(0.88, 1.0).toDouble();
      double s(double value) => value * scale;

      return _MenuMetrics(
        contentWidth: double.infinity,
        headerHorizontalPadding: s(16),
        headerVerticalPadding: s(22),
        headerBottomGap: s(22),
        tabGap: s(8),
        tabHeight: s(32),
        tabRadius: s(9),
        tabTextSize: s(12),
        tabShadowBlur: s(5),
        tabShadowOffset: s(1.5),
        listHorizontalPadding: s(20),
        listBottomPadding: s(22),
        emptyTextSize: s(12),
        pdfGap: s(8),
        pdfBoxHeight: s(60),
        pdfBoxPadding: s(12),
        pdfBoxRadius: s(16),
        pdfShadowBlur: s(8),
        pdfShadowOffset: s(3),
        pdfIconSize: s(34),
        pdfTextSize: s(11.5),
      );
    }

    return _MenuMetrics(
      contentWidth: double.infinity,
      headerHorizontalPadding: 20.w,
      headerVerticalPadding: 30.h,
      headerBottomGap: 30.h,
      tabGap: 10.w,
      tabHeight: 35.h,
      tabRadius: 10.r,
      tabTextSize: 13.sp,
      tabShadowBlur: 6.r,
      tabShadowOffset: 2.r,
      listHorizontalPadding: 30.w,
      listBottomPadding: 30.h,
      emptyTextSize: 13.sp,
      pdfGap: 10.h,
      pdfBoxHeight: 70.h,
      pdfBoxPadding: 16.r,
      pdfBoxRadius: 20.r,
      pdfShadowBlur: 10.r,
      pdfShadowOffset: 4.r,
      pdfIconSize: 40.w,
      pdfTextSize: 12.sp,
    );
  }
}
