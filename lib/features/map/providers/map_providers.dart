import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fudikoclient/features/map/models/marker_spec.dart';
import 'package:fudikoclient/service/restaurant/restaurant-service.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';

final mapExpandedProvider = StateProvider<bool>((ref) => false);

final selectedRestaurantProvider = StateProvider<RestaurantModel?>((ref) => null);
final userLocationProvider = StateProvider<LatLng?>((ref) => null);
final mapZoomProvider = StateProvider<double>((ref) => 15.5);
final userLocationIconProvider = StateProvider<BitmapDescriptor?>((ref) => null);

final mapMarkersProvider = StateProvider<Set<Marker>>(
  (ref) => const <Marker>{},
);

final collapsedMarkersProvider = StateProvider<Set<Marker>>(
  (ref) => const <Marker>{},
);

// Now returns List<RestaurantModel> — single source of truth
final nearbyRestaurantsProvider = FutureProvider<List<RestaurantModel>>((ref) async {
  final response = await RestaurantService().getRestaurantList();
  return response.restaurant
      .where((r) => r.lat.isNotEmpty && r.lng.isNotEmpty)
      .toList();
});

final markerSpecsProvider = Provider<List<MarkerSpec>>((ref) {
  final isExpanded = ref.watch(mapExpandedProvider);
  if (!isExpanded) return const <MarkerSpec>[];

  final restaurants = ref.watch(nearbyRestaurantsProvider).valueOrNull ?? [];
  final selected = ref.watch(selectedRestaurantProvider);

  final specs = <MarkerSpec>[];
  for (final r in restaurants) {
    if (r.offers.isEmpty) continue;
    if (r.lat.isEmpty || r.lng.isEmpty) continue;

    final bestOffer = r.offers.reduce(
      (a, b) => a.discountPercentage >= b.discountPercentage ? a : b,
    );

    specs.add(MarkerSpec(
      restaurantId: r.uuid,
      position: LatLng(
        double.tryParse(r.lat) ?? 0,
        double.tryParse(r.lng) ?? 0,
      ),
      discountLabel: '-${bestOffer.discountPercentage.toStringAsFixed(0)}%',
      isSelected: selected?.uuid == r.uuid,
      isDimmed: selected != null && selected.uuid != r.uuid,
    ));
  }
  return specs;
});