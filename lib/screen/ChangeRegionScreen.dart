import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangeRegionScreen extends StatefulWidget {
  const ChangeRegionScreen({Key? key}) : super(key: key);

  @override
  _ChangeRegionScreenState createState() => _ChangeRegionScreenState();
}

class _ChangeRegionScreenState extends State<ChangeRegionScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  String _currentAddress = '';
  String _savedAddress = '';
  final loc.Location _location = loc.Location();

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      loc.PermissionStatus permission = await _location.hasPermission();
      if (permission == loc.PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != loc.PermissionStatus.granted) {
          setState(() {
            _currentAddress = 'Location permission was denied.';
          });
          return;
        }
      }

      final locationData = await _location.getLocation();
      final latLng = LatLng(locationData.latitude!, locationData.longitude!);

      // Get city and district from geocoding
      final placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      final placemark = placemarks.first;
      final city = placemark.administrativeArea ?? 'Unknown';
      final district = placemark.subAdministrativeArea ?? 'Unknown';

      setState(() {
        _currentLatLng = latLng;
      });

      _getAddressFromLatLng(latLng);

      // Fetch saved address from Firestore
      final currentUser = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      // Save location and region to Firestore
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
        'location': GeoPoint(latLng.latitude, latLng.longitude),
        'region': {
          'city': city,
          'district': district,
        }
      }, SetOptions(merge: true));

      dynamic regionField = userDoc['region'];
      Map<String, dynamic> region = {};

      if (regionField is Map<String, dynamic>) {
        region = regionField;
      } else {
        final parts = regionField.toString().split(',');
        final city = parts.length > 0 ? parts[0].trim() : 'unknown';
        final district = parts.length > 1 ? parts[1].trim() : 'unknown';
        region = {'city': city, 'district': district};
      }
      final savedCity = region['city'] ?? 'none';
      final savedDistrict = region['district'] ?? 'none';
      final String savedAddress = '$savedCity，$savedDistrict';
      setState(() {
        _savedAddress = savedAddress;
      });
    } catch (e) {
      print('Failed to get location: $e');
      setState(() {
        _currentAddress = 'Failed to get location.';
      });
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    final placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
    final placemark = placemarks.first;
    setState(() {
      _currentAddress = '${placemark.administrativeArea}，${placemark.subAdministrativeArea}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Location'),
        backgroundColor: Color(0xFF84C1FF),
      ),
      backgroundColor: const Color(0xFFEAF6FF),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.width, // 정사각형
              child: _currentLatLng == null
                  ? Center(child: CircularProgressIndicator())
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentLatLng!,
                        zoom: 16,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
            ),
            const SizedBox(height: 24),
            Text(
              _currentAddress.isNotEmpty
                  ? 'Your current saved location:\n'
                      '$_savedAddress\n\n'
                      'You are currently at:\n'
                      '$_currentAddress\n\n'
                      'Do you want to update your region to this address?'
                  : 'Loading...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                if (_currentAddress.isNotEmpty) {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null && _currentLatLng != null) {
                    final placemarks = await placemarkFromCoordinates(
                        _currentLatLng!.latitude, _currentLatLng!.longitude);
                    final placemark = placemarks.first;
                    final city = placemark.administrativeArea ?? 'Unknown';
                    final district = placemark.subAdministrativeArea ?? 'Unknown';

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .update({
                      'region': {
                        'city': city,
                        'district': district,
                      },
                    });

                    final userProducts = await FirebaseFirestore.instance
                        .collection('products')
                        .where('sellerUid', isEqualTo: currentUser.uid)
                        .get();

                    for (final doc in userProducts.docs) {
                      await doc.reference.update({
                        'region': {
                          'city': city,
                          'district': district,
                        },
                      });
                    }

                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Region Updated'),
                        content: Text('Your region has been updated to $_currentAddress!'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the dialog
                              Navigator.of(context).pop(true); // Pop ChangeRegionScreen with result
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4A90E2),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}