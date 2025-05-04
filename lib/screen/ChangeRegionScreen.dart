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
            _currentAddress = '위치 권한이 거부되었습니다.';
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
      print('위치 가져오기 실패: $e');
      setState(() {
        _currentAddress = '위치를 가져오는 데 실패했습니다.';
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
        title: const Text('Change Your Region'),
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
                  ? '현재 계정의 동네\n'
                  '$_savedAddress\n'
                  '현재 계신 동네는 \n'
                  '$_currentAddress \n'
                  '내 동네를 현재 주소로 변경하시겠습니까?'
                  : '위치를 불러오는 중입니다...',
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
                        title: const Text('동네 변경 완료'),
                        content: Text('내 동네가 $_currentAddress 로 변경되었습니다!'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pop(); // Close the dialog
                              Navigator.of(context)
                                  .pop(); // Pop ChangeRegionScreen
                            },
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: const Text('변경'),
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