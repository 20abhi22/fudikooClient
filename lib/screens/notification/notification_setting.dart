import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fudikoclient/components/appswitch.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/service/notification/notification_service.dart';
import 'package:fudikoclient/utils/constants.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
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
      if (settings != null) {
        _newOffers = settings.newOffers;
        _newPromotions = settings.newPromotions;
        _reservationReminders = settings.reservationReminders;
        _orderStatus = settings.orderStatus;
        _errorMessage = null;
      } else {
        _errorMessage = 'Unable to load notification settings.';
      }
    });
  }

  Future<void> _updateSetting({
    required void Function() updateLocalState,
  }) async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    updateLocalState();

    final bool success = await _notificationService.saveNotificationSettings(
      newOffers: _newOffers,
      newPromotions: _newPromotions,
      reservationReminders: _reservationReminders,
      orderStatus: _orderStatus,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Notification settings saved.'
              : 'Unable to save notification settings.',
        ),
      ),
    );

    if (!success) {
      await _loadNotificationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.only(top: 20.h, left: 30.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Image.asset(
  backOrange,
  width: 28.w,
  height: 28.h,
  fit: BoxFit.contain,
),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 60.h),
                Divider(color: appTextColor, thickness: 1, height: 20.h),
                _buildSwitchRow(
                  label: 'Get notified about new offers',
                  value: _newOffers,
                  onToggle: (val) => _updateSetting(
                    updateLocalState: () => _newOffers = val,
                  ),
                ),
                Divider(color: appTextColor, thickness: 1, height: 20.h),
                _buildSwitchRow(
                  label: 'Get notified about new Promotions',
                  value: _newPromotions,
                  onToggle: (val) => _updateSetting(
                    updateLocalState: () => _newPromotions = val,
                  ),
                ),
                Divider(color: appTextColor, thickness: 1, height: 20.h),
                _buildSwitchRow(
                  label: 'Reservation Reminders',
                  value: _reservationReminders,
                  onToggle: (val) => _updateSetting(
                    updateLocalState: () => _reservationReminders = val,
                  ),
                ),
                Divider(color: appTextColor, thickness: 1, height: 20.h),
                _buildSwitchRow(
                  label: 'Get notified the order status',
                  value: _orderStatus,
                  onToggle: (val) => _updateSetting(
                    updateLocalState: () => _orderStatus = val,
                  ),
                ),
                Divider(color: appTextColor, thickness: 1, height: 20.h),
                if (_errorMessage != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 12.h),
                    child: AppText(
                      text: _errorMessage!,
                      size: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                      isCentered: true,
                    ),
                  ),
              ],
            ),
            if (_isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66FFFFFF),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onToggle,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: AppText(
              text: label,
              size: 15,
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
