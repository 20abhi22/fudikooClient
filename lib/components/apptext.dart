import 'package:flutter/material.dart';
// `intl` exports its own `TextDirection`, which would shadow the Flutter enum.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:fudikoclient/utils/constants.dart';
import 'package:fudikoclient/utils/translator_service.dart';

class AppText extends StatefulWidget {
  final String text;
  final double size;
  final FontWeight fontWeight;
  final Color? color;
  final bool? isCentered;
  final TextAlign? textAlign;
  final double? lineSpacing;
  final bool? isShadow;
  final List<Shadow>? isboxShadow;
  final int? maxLines;
  final TextOverflow overflow;
  final bool softWrap;

  const AppText({
    super.key,
    required this.text,
    required this.size,
    required this.fontWeight,
    this.color,
    this.isCentered,
    this.textAlign,
    this.lineSpacing,
    this.isShadow,
    this.isboxShadow,
    // Defaulted here rather than in build() so an explicit `maxLines: null`
    // means "as many lines as the text needs".
    this.maxLines = 2,
    this.overflow = TextOverflow.visible,
    this.softWrap = true,
  });

  @override
  State<AppText> createState() => _AppTextState();
}

class _AppTextState extends State<AppText> {
  String _translated = '';

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(AppText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _resolve();
  }

  /// Paints a warm translation on the first frame when there is one, so a
  /// pre-warmed screen never shows English and then swaps it out. Only a
  /// phrase the cache has not seen falls back to the async round-trip.
  void _resolve() {
    final cached = TranslatorService.cached(widget.text);
    if (cached != null) {
      _translated = cached;
      return;
    }

    _translated = '';
    _translate();
  }

  Future<void> _translate() async {
    final sourceText = widget.text;
    final result = await TranslatorService.translate(sourceText);
    if (mounted && sourceText == widget.text) {
      setState(() => _translated = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSize = _clampFontSize(widget.size);
    final resolvedText = _translated.isEmpty ? widget.text : _translated;

    return Text(
      resolvedText,
      softWrap: widget.softWrap,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
      // Laid out by what the words actually are, not by the app locale, which
      // stays English while the copy is translated. Without this an Arabic
      // sentence keeps a left-to-right paragraph and its trailing punctuation
      // lands on the wrong side.
      textDirection: Bidi.detectRtlDirectionality(resolvedText)
          ? TextDirection.rtl
          : TextDirection.ltr,
      textAlign:
          widget.textAlign ??
          (widget.isCentered ?? false ? TextAlign.center : TextAlign.start),
      style: TextStyle(
        fontSize: resolvedSize,
        fontWeight: widget.fontWeight,
        color: widget.color ?? appTextColor,
        height: widget.lineSpacing ?? 1.2,
        shadows:
            widget.isboxShadow ??
            (widget.isShadow == true
                ? const [
                    Shadow(
                      blurRadius: 4,
                      color: Color(0x66000000),
                      offset: Offset(1.5, 1.5),
                    ),
                  ]
                : null),
      ),
    );
  }

  double _clampFontSize(double size) {
    if (size <= 0) return 12;
    return size.clamp(8, 64).toDouble();
  }
}

/// Translates [text] and hands the result to [builder].
///
/// Use this where the UI needs a plain [String] rather than a widget — hint
/// text, tooltips, labels — so those strings get translated the same way
/// [AppText] does. The source text is shown until the translation resolves.
class TranslatedBuilder extends StatefulWidget {
  final String text;
  final Widget Function(BuildContext context, String text) builder;

  const TranslatedBuilder({
    super.key,
    required this.text,
    required this.builder,
  });

  @override
  State<TranslatedBuilder> createState() => _TranslatedBuilderState();
}

class _TranslatedBuilderState extends State<TranslatedBuilder> {
  String _translated = '';

  @override
  void initState() {
    super.initState();
    _translate();
  }

  @override
  void didUpdateWidget(TranslatedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _translate();
  }

  Future<void> _translate() async {
    final sourceText = widget.text;

    final cached = TranslatorService.cached(sourceText);
    if (cached != null) {
      _translated = cached;
      return;
    }

    final result = await TranslatorService.translate(sourceText);
    if (mounted && sourceText == widget.text) {
      setState(() => _translated = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _translated.isEmpty ? widget.text : _translated,
    );
  }
}
