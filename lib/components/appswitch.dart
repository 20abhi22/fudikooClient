import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:fudikoclient/utils/constants.dart';

class AppSwitch extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool> onToggle;

  const AppSwitch({
    Key? key,
    required this.initialValue,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<AppSwitch> createState() => _AppSwitchState();
}

class _AppSwitchState extends State<AppSwitch> {
  late bool isOn;

  @override
  void initState() {
    super.initState();
    isOn = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: appToggleColor, width: 1),
        borderRadius: BorderRadius.circular(
          30.0,
        ),
      ),
      child: FlutterSwitch(
        value: isOn,
        onToggle: (val) {
          setState(() => isOn = val);
          widget.onToggle(val);
        },
        width: 50.0,
        height: 20.0,
        toggleSize: 18.0,
        padding: 0.5,
        activeColor: appToggleColor,
        inactiveColor: Colors.white,
        toggleColor: Colors.white,
        inactiveToggleColor: appToggleColor,
        borderRadius: 30.0,
        showOnOff: false,
        toggleBorder: Border.all(color: appToggleColor, width: 1.0),
      ),
    );
  }

}
