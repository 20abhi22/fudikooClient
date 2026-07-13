import 'package:flutter/material.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/translator_service.dart';

class DescriptionTextArea extends StatefulWidget {
  final String hintText;
  final int maxLength;
  final IconData icon;
  final void Function(String)? onChanged;
  final Color? iconColor;
  final int? maxLines;
  final double? height;
  final String? topHintText;
  final TextEditingController? controller;
  final String? imageIconPath;

  const DescriptionTextArea({
    super.key,
    required this.hintText,
    this.maxLength = 450,
    this.icon = Icons.list,
    this.onChanged,
    this.iconColor,
    this.maxLines,
    this.height,
    this.topHintText,
    this.controller, this.imageIconPath,
  });

  @override
  State<DescriptionTextArea> createState() => _DescriptionTextAreaState();
}

class _DescriptionTextAreaState extends State<DescriptionTextArea> {
  int _charCount = 0;
  late String _translatedHint;
  String? _translatedTopHint;

  @override
  void initState() {
    super.initState();
    _translatedHint = widget.hintText;
    _translatedTopHint = widget.topHintText;
    _charCount = widget.controller?.text.length ?? 0;
    _translateTexts();
  }

  @override
  void didUpdateWidget(covariant DescriptionTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hintText != widget.hintText ||
        oldWidget.topHintText != widget.topHintText) {
      _translateTexts();
    }
  }

  Future<void> _translateTexts() async {
    final hint = await TranslatorService.translate(widget.hintText);
    final topHint = widget.topHintText != null
        ? await TranslatorService.translate(widget.topHintText!)
        : null;

    if (mounted) {
      setState(() {
        _translatedHint = hint.isNotEmpty ? hint : widget.hintText;
        _translatedTopHint = (topHint != null && topHint.isNotEmpty)
            ? topHint
            : widget.topHintText;
      });
    }
  }

  Widget _buildTextField() {
    if (widget.height != null) {
      return Expanded(
        child: TextField(
          controller: widget.controller,
          maxLines: null,
          expands: true,
          maxLength: widget.maxLength,
          onChanged: (val) {
            setState(() => _charCount = val.length);
            if (widget.onChanged != null) widget.onChanged!(val);
          },
          decoration: InputDecoration(
            counterText: "",
            hintText: _translatedHint,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            border: InputBorder.none,
          ),
          textAlignVertical: TextAlignVertical.top,
        ),
      );
    }

    return TextField(
      controller: widget.controller,
      maxLines: widget.maxLines ?? 5,
      maxLength: widget.maxLength,
      onChanged: (val) {
        setState(() => _charCount = val.length);
        if (widget.onChanged != null) widget.onChanged!(val);
      },
      decoration: InputDecoration(
        counterText: "",
        hintText: _translatedHint,
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final width = screenSize.width;
    final height = screenSize.height;
    final isCompactPhone = width < 390 || height < 640;
    final isTablet = width >= 600;

    final containerPadding = isTablet ? 20.0 : isCompactPhone ? 14.0 : 16.0;
    final radius = isTablet ? 14.0 : 10.0;
    final iconSize = isTablet ? 22.0 : isCompactPhone ? 18.0 : 20.0;
    final headerGap = isTablet ? 12.0 : isCompactPhone ? 8.0 : 10.0;
    final topGap = isTablet ? 10.0 : 8.0;
    final titleSize = isTablet ? 15.0 : 14.0;
    final counterSize = isTablet ? 13.0 : 12.0;
    final hintSize = isTablet ? 13.0 : 12.0;

    return Container(
      height: widget.height,
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: isTablet ? 12 : 10,
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontSize: hintSize),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (widget.imageIconPath != null)
                  Image.asset(
                    widget.imageIconPath!,
                    width: iconSize,
                    height: iconSize,
                    color: widget.iconColor ?? const Color(0xFFC95F05),
                  )
                else
                  Icon(
                    widget.icon,
                    size: iconSize,
                    color: widget.iconColor ?? const Color(0xFFC95F05),
                  ),
                SizedBox(width: headerGap),
                if (_translatedTopHint != null)
                  Expanded(
                    child: AppText(
                      text: _translatedTopHint!,
                      size: titleSize,
                      fontWeight: FontWeight.w600,
                      color: appTextColor2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                if (_translatedTopHint != null) SizedBox(width: headerGap / 2),
                Text(
                  '$_charCount/${widget.maxLength}',
                  style: TextStyle(color: Colors.grey, fontSize: counterSize),
                ),
              ],
            ),
            SizedBox(height: topGap),
            Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  hintStyle: TextStyle(color: Colors.grey, fontSize: hintSize),
                ),
              ),
              child: _buildTextField(),
            ),
          ],
        ),
      ),
    );
  }
}
