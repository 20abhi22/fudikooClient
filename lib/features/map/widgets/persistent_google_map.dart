import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fudikoclient/features/map/providers/map_providers.dart';
import 'package:fudikoclient/features/map/services/map_controller_service.dart';

class PersistentGoogleMap extends ConsumerWidget {
  const PersistentGoogleMap({
    super.key,
    required this.initialCameraPosition,
    required this.controllerService,
    required this.onMapTap,
    this.gesturesEnabled = true,
    this.showMyLocation = false,

    /// When provided the widget uses this marker set instead of
    /// [mapMarkersProvider].  Used for the collapsed preview so it can show
    /// simple dot-pins without touching the expanded marker state.
    this.overrideMarkers,
  });

  final CameraPosition initialCameraPosition;
  final MapControllerService controllerService;
  final VoidCallback onMapTap;
  final bool gesturesEnabled;
  final Set<Marker>? overrideMarkers;
  final bool showMyLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<Marker> providerMarkers =
        overrideMarkers ?? ref.watch(mapMarkersProvider);
         final userLocation = ref.watch(userLocationProvider); // ← new

         final Set<Marker> allMarkers = {
      ...providerMarkers,
      if (userLocation != null)
        Marker(
          markerId: const MarkerId('__user_location__'),
          position: userLocation,
          icon: ref.watch(userLocationIconProvider) ?? BitmapDescriptor.defaultMarkerWithHue(30), // fallback orange
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 99,
          consumeTapEvents: true,
        ),
    };

    return GoogleMap(
      initialCameraPosition: initialCameraPosition,
       markers: allMarkers,  
           myLocationButtonEnabled: false,  // ← disable native button
      myLocationEnabled: false,         // ← disable blue dot
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      scrollGesturesEnabled: gesturesEnabled,
      zoomGesturesEnabled: gesturesEnabled,
      rotateGesturesEnabled: gesturesEnabled,
      tiltGesturesEnabled: gesturesEnabled,
      minMaxZoomPreference: const MinMaxZoomPreference(10, 19),
      
      onMapCreated: controllerService.attach,
      onTap: (_) => onMapTap(),
       onCameraMove: (position) {
    ref.read(mapZoomProvider.notifier).state = position.zoom;
  },
      
      gestureRecognizers: gesturesEnabled
          ? <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            }
          : const <Factory<OneSequenceGestureRecognizer>>{},
    );
  }
}
