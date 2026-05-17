import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapControllerService {
  GoogleMapController? _controller;
  Completer<GoogleMapController> _controllerCompleter = Completer();

  bool get isReady => _controller != null;

  void attach(GoogleMapController controller) {
    _controller = controller;
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.complete(controller);
    }
  }

  void reset() {
    _controller = null;
    if (_controllerCompleter.isCompleted) {
      _controllerCompleter = Completer<GoogleMapController>();
    }
  }

  Future<GoogleMapController> get _readyController async {
    final controller = _controller;
    if (controller != null) return controller;
    return _controllerCompleter.future;
  }

  Future<void> focusRestaurant(
    LatLng target, {
    double zoom = 16,
    double bottomPadding = 0.0018,
  }) async {
    final controller = await _readyController;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(target.latitude - bottomPadding, target.longitude),
        zoom,
      ),
    );
  }

// Add this method
Future<void> onCameraMove(CameraPosition position) async {
  // called from onCameraMove in GoogleMap
}

  Future<void> animateTo(LatLng position, {double zoom = 15.0}) async {
  final controller = await _controllerCompleter.future;
  await controller.animateCamera(
    CameraUpdate.newLatLngZoom(position, zoom),
  );
}

  Future<void> expandAround(LatLng target) async {
    final controller = await _readyController;
    await controller.animateCamera(CameraUpdate.newLatLngZoom(target, 13.6));
  }

  Future<void> fitRestaurants(Iterable<LatLng> positions) async {
    final points = positions.toList(growable: false);
    if (points.isEmpty) return;
    if (points.length == 1) {
      await focusRestaurant(points.first, zoom: 14.5, bottomPadding: 0);
      return;
    }

    final controller = await _readyController;
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        72,
      ),
    );
  }

  Future<void> dispose() async {
    final controller = _controller;
    reset();
    if (controller == null) return;
    controller.dispose();
  }
}
