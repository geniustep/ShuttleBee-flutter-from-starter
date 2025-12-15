import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// مثال على شاشة تستخدم Google Maps
class GoogleMapScreen extends StatefulWidget {
  const GoogleMapScreen({super.key});

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  GoogleMapController? _mapController;

  // الموقع الافتراضي (القاهرة، مصر)
  static const LatLng _initialPosition = LatLng(30.0444, 31.2357);

  // مجموعة من العلامات على الخريطة
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _addMarker();
  }

  void _addMarker() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('initial_marker'),
          position: _initialPosition,
          infoWindow: const InfoWindow(
            title: 'الموقع الافتراضي',
            snippet: 'القاهرة، مصر',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خريطة Google Maps'),
        centerTitle: true,
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(
          target: _initialPosition,
          zoom: 12.0,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
        mapType: MapType.normal,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in',
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.zoomIn(),
              );
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'zoom_out',
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.zoomOut(),
              );
            },
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'reset',
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_initialPosition, 12.0),
              );
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
