import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fudikoclient/components/apptext.dart';
import 'package:fudikoclient/core/responsive/app_dimensions.dart';
import 'package:fudikoclient/core/responsive/breakpoints.dart';
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/translator_service.dart';

class AppTextFeild extends StatefulWidget {
  final String? text;
  final bool? enableInteractiveSelection;
  final VoidCallback? onSuffixTap;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  final IconData? icon;
  final IconData? secondIcon;
  final IconData? suffixIcon;

  final String? iconImagePath;
  final String? secondIconImagePath;

  final Color? iconImagecolor;
  final Color? secondIconImageColor;

  final Color? iconColor;
  final Color? secondIconColor;

  final int? maxlines;
  final double? size;
  final bool? isObscure;
  final Color? textColor;
  final bool? isTextCenter;
  final VoidCallback? iconOnTap;
  final VoidCallback? suffixIconOnTap;
  final VoidCallback? onboxTap;
  final bool? isreadonly;
  final TextInputType? keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final double? fieldBorderRadius;
  final bool? isRequired;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final double? sideIconSlotWidth;
  final double? sideSpacing;
  final EdgeInsetsGeometry? inputContentPadding;
  final double? requiredTop;
  final double? requiredRight;
  final TextStyle? requiredTextStyle;
  final Widget? requiredIndicator;

  final bool? expands;
  final InputDecoration? decoration;
  final TextAlignVertical? textAlignVertical;

  final bool? isDateTimeField;
  final String? secondText;

  const AppTextFeild({
    super.key,
    this.text,
    this.controller,
    this.icon,
    this.secondIcon,
    this.enableInteractiveSelection,
    this.onSuffixTap,
    this.suffixIcon,
    this.maxlines,
    this.size,
    this.validator,
    this.iconColor,
    this.secondIconColor,
    this.isObscure,
    this.textColor,
    this.isTextCenter,
    this.iconOnTap,
    this.isreadonly,
    this.suffixIconOnTap,
    this.onboxTap,
    this.keyboardType,
    this.maxLength,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.textInputAction,
    this.iconImagecolor,
    this.secondIconImageColor,
    this.iconImagePath,
    this.secondIconImagePath,
    this.fieldBorderRadius,
    this.isRequired,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.boxShadow,
    this.sideIconSlotWidth,
    this.sideSpacing,
    this.inputContentPadding,
    this.requiredTop,
    this.requiredRight,
    this.requiredTextStyle,
    this.requiredIndicator,
    this.expands,
    this.decoration,
    this.textAlignVertical,
    this.isDateTimeField,
    this.secondText,
  });

  @override
  State<AppTextFeild> createState() => _AppTextFeildState();
}

class _AppTextFeildState extends State<AppTextFeild> {
  String _translated = '';

  @override
  void initState() {
    super.initState();
    _translate();
  }

  @override
  void didUpdateWidget(covariant AppTextFeild oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      _translate();
    }
  }

  Future<void> _translate() async {
    if (widget.text == null) return;

    final result = await TranslatorService.translate(widget.text!);

    if (mounted) {
      setState(() {
        _translated = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final screenSize = MediaQuery.sizeOf(context);
        final isDesktop = Breakpoints.isDesktop(screenSize.width);
        final isTablet = Breakpoints.isTablet(screenSize.width);
        final isWideShortPhone =
            !isTablet && screenSize.width >= 500 && screenSize.height <= 760;
        final isCompactPhone =
            screenSize.width < 390 || screenSize.height < 700;
        final fieldHeight =
            widget.height ??
            (isWideShortPhone
                ? 48.0
                : isCompactPhone
                ? 54.0
                : 61.0);
        final iconSlot =
            widget.sideIconSlotWidth ??
            (isDesktop
                ? 26.0
                : isWideShortPhone
                ? 20.0
                : isCompactPhone
                ? 22.0
                : 24.0);
        final sideSpacing =
            widget.sideSpacing ??
            (isDesktop
                ? 14.0
                : isWideShortPhone
                ? 8.0
                : isCompactPhone
                ? 10.0
                : 12.0);
        final horizontalPadding = isWideShortPhone
            ? 14.0
            : isCompactPhone
            ? 16.0
            : AppDimensions.gap(context);
        final fontSize =
            widget.size ??
            (isWideShortPhone
                ? 13.0
                : isCompactPhone
                ? 14.0
                : AppDimensions.body(context));
        final radius =
            widget.fieldBorderRadius ??
            (isWideShortPhone
                ? 13.0
                : isCompactPhone
                ? 14.0
                : 15.0);
        final verticalContentPadding = isWideShortPhone
            ? fontSize * 0.55
            : isCompactPhone
            ? fontSize * 0.65
            : fontSize * 0.75;
        final translatedHint = _translated.isEmpty ? widget.text : _translated;

        return GestureDetector(
          onTap: widget.onboxTap,
          child: Stack(
            children: [
              Container(
                width: widget.width,
                height: fieldHeight,
                padding:
                    widget.padding ??
                    EdgeInsets.symmetric(horizontal: horizontalPadding),
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: widget.boxShadow ?? _defaultShadow(),
                ),
                child: widget.isDateTimeField == true
                    ? _DateTimeContent(
                        widget: widget,
                        translatedHint: translatedHint ?? 'Date',
                        iconSize: iconSlot,
                        gap: sideSpacing,
                        fontSize: fontSize,
                      )
                    : _TextFieldContent(
                        widget: widget,
                        translatedHint: translatedHint,
                        iconSlot: iconSlot,
                        sideSpacing: sideSpacing,
                        fontSize: fontSize,
                        fieldWidth: fieldWidth,
                        verticalContentPadding: verticalContentPadding,
                      ),
              ),
              if (widget.isRequired == true)
                Positioned(
                  right: widget.requiredRight ?? horizontalPadding / 2,
                  top: widget.requiredTop ?? 8,
                  child:
                      widget.requiredIndicator ??
                      Text(
                        '*',
                        style:
                            widget.requiredTextStyle ??
                            const TextStyle(
                              color: Color(0xFFF60505),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<BoxShadow> _defaultShadow() {
    return const [
      BoxShadow(
        color: Color(0x40000000),
        offset: Offset(0, 0),
        blurRadius: 10,
        spreadRadius: 0,
      ),
    ];
  }
}

class _TextFieldContent extends StatelessWidget {
  const _TextFieldContent({
    required this.widget,
    required this.translatedHint,
    required this.iconSlot,
    required this.sideSpacing,
    required this.fontSize,
    required this.fieldWidth,
    required this.verticalContentPadding,
  });

  final AppTextFeild widget;
  final String? translatedHint;
  final double iconSlot;
  final double sideSpacing;
  final double fontSize;
  final double fieldWidth;
  final double verticalContentPadding;

  @override
  Widget build(BuildContext context) {
    final hasLeadingIcon = widget.icon != null || widget.iconImagePath != null;
    final hasTrailingIcon = widget.suffixIcon != null;
    final keepCenteredTextBalanced = widget.isTextCenter == true;
    final canBalanceCenteredText = fieldWidth >= 260;
    final showLeadingSlot =
        hasLeadingIcon ||
        (keepCenteredTextBalanced && canBalanceCenteredText && hasTrailingIcon);
    final showTrailingSlot =
        hasTrailingIcon ||
        (keepCenteredTextBalanced && canBalanceCenteredText && hasLeadingIcon);

    return Row(
      children: [
        if (showLeadingSlot) ...[
          SizedBox(
            width: iconSlot,
            child: hasLeadingIcon
                ? _LeadingIcon(widget: widget, size: iconSlot)
                : const SizedBox.shrink(),
          ),
          SizedBox(width: sideSpacing),
        ],
        Expanded(
          child: TextFormField(
            onTap: widget.onboxTap,
            focusNode: widget.focusNode,
            readOnly: widget.isreadonly ?? false,
            maxLines: widget.expands == true ? null : (widget.maxlines ?? 1),
            expands: widget.expands ?? false,
            textAlignVertical: widget.textAlignVertical,
            maxLength: widget.maxLength,
            controller: widget.controller,
            cursorColor: appTextColor,
            obscureText: widget.isObscure ?? false,
            textAlign: widget.isTextCenter == true
                ? TextAlign.center
                : TextAlign.start,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            enableInteractiveSelection:
                widget.enableInteractiveSelection ?? true,
            onChanged: widget.onChanged,
            validator: widget.validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            inputFormatters: widget.maxLength == 1
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            decoration:
                widget.decoration ??
                InputDecoration(
                  counterText: '',
                  hintText: translatedHint,
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: widget.textColor ?? Colors.grey,
                    fontSize: fontSize,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding:
                      widget.inputContentPadding ??
                      EdgeInsets.symmetric(vertical: verticalContentPadding),
                ),
            style: TextStyle(
              color: widget.textColor ?? Colors.black,
              fontSize: fontSize,
            ),
          ),
        ),
        if (showTrailingSlot) ...[
          SizedBox(width: sideSpacing),
          SizedBox(
            width: iconSlot,
            child: hasTrailingIcon
                ? InkWell(
                    onTap: widget.onSuffixTap ?? widget.suffixIconOnTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Icon(
                      widget.suffixIcon,
                      color: Colors.grey,
                      size: iconSlot,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }
}

class _DateTimeContent extends StatelessWidget {
  const _DateTimeContent({
    required this.widget,
    required this.translatedHint,
    required this.iconSize,
    required this.gap,
    required this.fontSize,
  });

  final AppTextFeild widget;
  final String translatedHint;
  final double iconSize;
  final double gap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final textColor = widget.textColor ?? const Color.fromARGB(255, 8, 8, 8);
    final groupInset = gap * 0.65;

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: groupInset),
            child: _DateTimeGroup(
              imagePath: widget.iconImagePath,
              icon: widget.icon ?? Icons.calendar_today_sharp,
              imageColor: widget.iconImagecolor,
              iconColor: widget.iconColor,
              text: translatedHint,
              textColor: textColor,
              iconSize: iconSize,
              gap: gap,
              fontSize: fontSize,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: groupInset),
            child: _DateTimeGroup(
              imagePath: widget.secondIconImagePath,
              icon: widget.secondIcon ?? Icons.access_time_filled,
              imageColor: widget.secondIconImageColor,
              iconColor: widget.secondIconColor ?? widget.iconColor,
              text: widget.secondText ?? 'Time',
              textColor: textColor,
              iconSize: iconSize,
              gap: gap,
              fontSize: fontSize,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateTimeGroup extends StatelessWidget {
  const _DateTimeGroup({
    required this.imagePath,
    required this.icon,
    required this.imageColor,
    required this.iconColor,
    required this.text,
    required this.textColor,
    required this.iconSize,
    required this.gap,
    required this.fontSize,
  });

  final String? imagePath;
  final IconData icon;
  final Color? imageColor;
  final Color? iconColor;
  final String text;
  final Color textColor;
  final double iconSize;
  final double gap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DateIcon(
          imagePath: imagePath,
          icon: icon,
          imageColor: imageColor,
          iconColor: iconColor,
          size: iconSize,
        ),
        SizedBox(width: gap),
        Flexible(
          child: AppText(
            text: text,
            size: fontSize,
            fontWeight: FontWeight.w400,
            color: textColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.widget, required this.size});

  final AppTextFeild widget;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (widget.icon == null && widget.iconImagePath == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.iconOnTap,
      child: widget.iconImagePath != null
          ? SizedBox(
              width: size,
              height: size,
              child: Image.asset(
                widget.iconImagePath!,
                width: size,
                height: size,
                fit: BoxFit.contain,
                color: widget.iconImagecolor,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (ctx, err, st) => Icon(
                  Icons.image_not_supported,
                  size: size,
                  color: Colors.grey,
                ),
              ),
            )
          : Icon(
              widget.icon,
              color: widget.iconColor ?? Colors.grey,
              size: size,
            ),
    );
  }
}

class _DateIcon extends StatelessWidget {
  const _DateIcon({
    required this.imagePath,
    required this.icon,
    required this.imageColor,
    required this.iconColor,
    required this.size,
  });

  final String? imagePath;
  final IconData icon;
  final Color? imageColor;
  final Color? iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return Image.asset(
        imagePath!,
        width: size,
        height: size,
        color: imageColor ?? const Color.fromARGB(255, 8, 8, 8),
      );
    }

    return Icon(
      icon,
      size: size,
      color: iconColor ?? const Color.fromARGB(255, 8, 8, 8),
    );
  }
}
