import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CheckoutLocationPickerPage extends StatefulWidget {
  const CheckoutLocationPickerPage({super.key});

  @override
  State<CheckoutLocationPickerPage> createState() =>
      _CheckoutLocationPickerPageState();
}

class _CheckoutLocationPickerPageState
    extends State<CheckoutLocationPickerPage> {
  static const LatLng _fallbackLatLng = LatLng(31.9539, 35.9106); // Amman

  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;
  LatLng? _currentLatLng;
  bool _permissionDenied = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _permissionDenied = true;
          _currentLatLng = _fallbackLatLng;
          _selectedLatLng = _fallbackLatLng;
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final userLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _permissionDenied = false;
        _currentLatLng = userLatLng;
        _selectedLatLng ??= userLatLng;
        _isLoading = false;
      });
    } catch (e) {
      //fall back to a default city if GPS fails
      setState(() {
        _permissionDenied = true;
        _currentLatLng = _fallbackLatLng;
        _selectedLatLng ??= _fallbackLatLng;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap on the map to choose a location.'),
        ),
      );
      return;
    }
    Navigator.pop(context, _selectedLatLng);
  }

  Future<void> _recenter() async {
    final target = _currentLatLng ?? _fallbackLatLng;
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 14),
      ),
    );
    setState(() {
      _selectedLatLng = target;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Select Location'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cameraTarget = _selectedLatLng ?? _currentLatLng ?? _fallbackLatLng;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: cameraTarget,
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: (latLng) {
              setState(() {
                _selectedLatLng = latLng;
              });
            },
            markers: _selectedLatLng == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('selected-location'),
                      position: _selectedLatLng!,
                      draggable: false,
                    ),
                  },
            myLocationEnabled: !_permissionDenied,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          if (_permissionDenied)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.white,
                elevation: 2,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    'Location permission denied. Drag the map to choose a spot in Amman.',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              onPressed: _recenter,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              child: const Icon(Icons.my_location),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A3D),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
