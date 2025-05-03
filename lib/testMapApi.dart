import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class MapTestScreen extends StatefulWidget {
  const MapTestScreen({super.key});

  @override
  State<MapTestScreen> createState() => _MapTestScreenState();
}

class _MapTestScreenState extends State<MapTestScreen> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(25.033964, 121.564468); // 타이페이 101

  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      setState(() {
        _locationPermissionGranted = true;
      });
    } else {
      debugPrint("❌ 위치 권한 거부됨");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    debugPrint('✅ Google Map Loaded');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Test'),
      ),
      body: _locationPermissionGranted
          ? GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 15.0,
              ),
              myLocationEnabled: true,
              markers: {
                Marker(
                  markerId: const MarkerId('taipei101'),
                  position: _center,
                  infoWindow: const InfoWindow(title: 'Taipei 101'),
                ),
              },
            )
          : const Center(
              child: Text('Location permission not granted.'),
            ),
    );
  }
}