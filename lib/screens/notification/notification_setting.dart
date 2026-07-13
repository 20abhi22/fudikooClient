import 'package:flutter/material.dart';
import 'package:fudikoclient/components/appswitch.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/service/notification/notification_service.dart';
import 'package:fudikoclient/utils/constants.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _newOffers = false;
  bool _newPromotions = false;
  bool _reservationReminders = false;
  bool _orderStatus = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final settings = await _notificationService.fetchNotificationSettings();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (settings == null) {
        _errorMessage = 'Unable to load notification settings.';
        return;
      }

      _newOffers = settings.newOffers;
      _newPromotions = settings.newPromotions;
      _reservationReminders = settings.reservationReminders;
      _orderStatus = settings.orderStatus;
      _errorMessage = null;
    });
  }

  Future<void> _updateSetting({
    required void Function() updateLocalState,
  }) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      updateLocalState();
    });

    final success = await _notificationService.saveNotificationSettings(
      newOffers: _newOffers,
      newPromotions: _newPromotions,
      reservationReminders: _reservationReminders,
      orderStatus: _orderStatus,
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Notification settings saved.'
              : 'Unable to save notification settings.',
        ),
      ),
    );

    if (!success) await _loadNotificationSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final metrics = _SettingsLayoutMetrics.fromConstraints(
                  context: context,
                  constraints: constraints,
                  orientation: orientation,
                );

                return Stack(
                  children: [
                    Align(  
                      child:SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: FractionallySizedBox(
                              widthFactor: metrics.contentWidthFactor,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: metrics.backTop,
                                      left: metrics.horizontalPadding,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: Image.asset(
                                          backOrange,
                                          width: metrics.backSize,
                                          height: metrics.backSize,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: metrics.headerGap),
                                  _SettingsDivider(height: metrics.dividerHeight),
                                  _buildSwitchRow(
                                    label: 'Get notified about new offers',
                                    value: _newOffers,
                                    metrics: metrics,
                                    onToggle: (value) => _updateSetting(
                                      updateLocalState: () => _newOffers = value,
                                    ),
                                  ),
                                  _SettingsDivider(height: metrics.dividerHeight),
                                  _buildSwitchRow(
                                    label: 'Get notified about new Promotions',
                                    value: _newPromotions,
                                    metrics: metrics,
                                    onToggle: (value) => _updateSetting(
                                      updateLocalState: () =>
                                          _newPromotions = value,
                                    ),
                                  ),
                                  _SettingsDivider(height: metrics.dividerHeight),
                                  _buildSwitchRow(
                                    label: 'Reservation Reminders',
                                    value: _reservationReminders,
                                    metrics: metrics,
                                    onToggle: (value) => _updateSetting(
                                      updateLocalState: () =>
                                          _reservationReminders = value,
                                    ),
                                  ),
                                  _SettingsDivider(height: metrics.dividerHeight),
                                  _buildSwitchRow(
                                    label: 'Get notified the order status',
                                    value: _orderStatus,
                                    metrics: metrics,
                                    onToggle: (value) => _updateSetting(
                                      updateLocalState: () => _orderStatus = value,
                                    ),
                                  ),
                                  _SettingsDivider(height: metrics.dividerHeight),
                                  if (_errorMessage != null)
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: metrics.horizontalPadding,
                                        vertical: metrics.rowVerticalPadding,
                                      ),
                                      child: AppText(
                                        text: _errorMessage!,
                                        size: metrics.errorTextSize,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.red,
                                        isCentered: true,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_isLoading)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x66FFFFFF),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required _SettingsLayoutMetrics metrics,
    required ValueChanged<bool> onToggle,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: metrics.horizontalPadding,
        vertical: metrics.rowVerticalPadding,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: AppText(
              text: label,
              size: metrics.rowTextSize,
              fontWeight: FontWeight.w500,
              color: appTextColor3,
            ),
          ),
          AppSwitch(initialValue: value, onToggle: onToggle),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Divider(color: appTextColor, thickness: 1, height: height);
  }
}

class _SettingsLayoutMetrics {
  const _SettingsLayoutMetrics({
    required this.contentWidthFactor,
    required this.horizontalPadding,
    required this.backTop,
    required this.backSize,
    required this.headerGap,
    required this.dividerHeight,
    required this.rowVerticalPadding,
    required this.rowTextSize,
    required this.errorTextSize,
  });

  final double contentWidthFactor;
  final double horizontalPadding;
  final double backTop;
  final double backSize;
  final double headerGap;
  final double dividerHeight;
  final double rowVerticalPadding;
  final double rowTextSize;
  final double errorTextSize;

  factory _SettingsLayoutMetrics.fromConstraints({
    required BuildContext context,
    required BoxConstraints constraints,
    required Orientation orientation,
  }) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final isCompactPhone = width < 390 || height < 640;
    final isLandscape = orientation == Orientation.landscape;
    final isTablet = Breakpoints.isTabletDevice(MediaQuery.sizeOf(context));
    final isCompactLandscape = isLandscape && height < 500;

    return _SettingsLayoutMetrics(
      contentWidthFactor: isTablet && isLandscape ? 0.82 : 1.0,
      horizontalPadding: isTablet
          ? width * 0.055
        : isCompactLandscape
        ? width * 0.045
        : isCompactPhone
          ? width * 0.06
          : width * 0.075,
      backTop: isTablet
        ? (isLandscape ? 18.0 : 26.0)
        : isCompactLandscape
        ? 10.0
        : isCompactPhone
          ? 16.0
          : 20.0,
      backSize: isTablet
        ? (isLandscape ? 30.0 : 32.0)
        : isCompactLandscape
        ? 24.0
        : isCompactPhone
          ? 26.0
          : 28.0,
      headerGap: isTablet
        ? (isLandscape ? AppDimensions.gap(context) * 1.5 : AppDimensions.margin(context) * 1.4)
        : isCompactLandscape
        ? 20.0
        : isCompactPhone
          ? 42.0
          : 60.0,
      dividerHeight: isCompactLandscape ? 12.0 : isCompactPhone ? 16.0 : 20.0,
      rowVerticalPadding: isTablet
        ? (isLandscape ? AppDimensions.gap(context) * 0.6 : AppDimensions.gap(context))
        : isCompactLandscape
        ? 6.0
        : isCompactPhone
          ? 8.0
          : 10.0,
      rowTextSize: isTablet
        ? (isLandscape ? AppDimensions.caption(context) : AppDimensions.body(context))
        : isCompactLandscape
        ? 13.0
        : isCompactPhone
          ? 14.0
          : 15.0,
      errorTextSize: isTablet ? AppDimensions.caption(context) : 13.0,
    );
  }
}
