import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  late double currentLatitude;
  late double currentLongitude;
  late double currentZoomLevel;
  late double currentTiltLevel;
  late double currentBearing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
          compassEnabled: true,
          onCameraMove: (CameraPosition position) {
            currentLatitude = position.target.latitude;
            currentLongitude = position.target.longitude;
            currentZoomLevel = position.zoom;
            currentTiltLevel = position.tilt;
            currentBearing = position.bearing;

          },
          mapType: MapType.hybrid,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
        ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 16.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, [currentLatitude, currentLongitude]);
                },

                child: const Text('Select Location'),
              )
            ],
          ),
        )
      ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _reset,
            tooltip: 'Zoom Out',
            child: const Icon(Icons.zoom_out),
          ),

          const SizedBox(height: 16),

          FloatingActionButton(
            onPressed: _tiltCamera,
            tooltip: 'Tilt Camera',
            child: const Icon(Icons.trending_up),
          )
        ],
      ),
    );
  }

Future<void> _reset() async {
  final GoogleMapController controller = await _controller.future;
  await controller.animateCamera(CameraUpdate.zoomOut());
}

Future<void> _tiltCamera() async {
  final GoogleMapController controller = await _controller.future;

  await controller.animateCamera(CameraUpdate.newCameraPosition(
    CameraPosition(
      target: LatLng(currentLatitude, currentLongitude),
      zoom: currentZoomLevel,
      tilt: currentTiltLevel += 15, 
      bearing: currentBearing,
    )
    ));
}

}

