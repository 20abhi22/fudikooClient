import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fudikoclient/features/map/widgets/offer_marker_widget.dart';

class MarkerBitmapService {
  const MarkerBitmapService();

  Future<BitmapDescriptor> buildOfferMarker(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required bool isDimmed,
    double scale = 1.0,   // ← new
  }) async {
    final boundaryKey = GlobalKey();
    final overlay = Overlay.of(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: -120,
        left: -120,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: boundaryKey,
            child: Transform.scale(
              scale: scale,   // ← pass scale
              child: OfferMarkerWidget(
                label: label,
                isSelected: isSelected,
                isDimmed: isDimmed,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
    } finally {
      entry.remove();
    }
  }
}
