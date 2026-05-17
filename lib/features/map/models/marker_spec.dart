import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerSpec {
  const MarkerSpec({
    required this.restaurantId,
    required this.position,
    required this.discountLabel,
    required this.isSelected,
    required this.isDimmed,
  });

  final String restaurantId;
  final LatLng position;
  final String discountLabel;
  final bool isSelected;
  final bool isDimmed;
}
