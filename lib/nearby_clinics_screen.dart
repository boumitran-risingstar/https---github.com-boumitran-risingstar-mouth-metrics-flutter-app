import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/business_model.dart';
import '../services/location_service.dart';
import '../services/business_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;

class NearbyClinicsScreen extends StatefulWidget {
  const NearbyClinicsScreen({super.key});

  @override
  State<NearbyClinicsScreen> createState() => _NearbyClinicsScreenState();
}

class _NearbyClinicsScreenState extends State<NearbyClinicsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Business> _businesses = [];
  Position? _currentPosition;
  bool _isMapView = true; // Default to map view

  final LocationService _locationService = LocationService();
  final BusinessService _businessService = BusinessService();
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchNearbyClinics();
  }

  Future<void> _fetchNearbyClinics() async {
    try {
      _currentPosition = await _locationService.getCurrentLocation();
      if (_currentPosition == null) {
        if (mounted) {
          setState(() {
            _error = 'Could not determine your location. Please ensure location services are enabled.';
            _isLoading = false;
          });
        }
        return;
      }

      final businesses = await _businessService.findNearbyBusinesses(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      if (mounted) {
        setState(() {
          _businesses = businesses;
          _isLoading = false;
          _updateMarkers();
        });
      }

    } catch (e, s) {
      developer.log('Error fetching nearby clinics', error: e, stackTrace: s, name: 'com.example.myapp.nearby');
      if (mounted) {
        setState(() {
          _error = 'Failed to find nearby clinics. Please try again later.';
          _isLoading = false;
        });
      }
    }
  }

  void _updateMarkers() {
    if (!mounted) return;
    final markers = <Marker>{};
    for (final business in _businesses) {
      markers.add(
        Marker(
          markerId: MarkerId(business.id),
          position: LatLng(business.location.latitude, business.location.longitude),
          infoWindow: InfoWindow(
            title: business.name,
            snippet: business.category,
          ),
        ),
      );
    }
    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  String _getDistance(double lat, double lng) {
    if (_currentPosition == null) return '';
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
    final distanceInMiles = distance * 0.000621371;
    return '${distanceInMiles.toStringAsFixed(1)} miles';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Dental Clinics'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
            tooltip: _isMapView ? 'List View' : 'Map View',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    if (_businesses.isEmpty) {
      return const Center(
        child: Text(
          'No dental clinics found nearby.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return _isMapView ? _buildMapView() : _buildListView();
  }

  Widget _buildMapView() {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: _currentPosition != null 
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) 
            : const LatLng(37.7749, -122.4194), // Default to SF
        zoom: 12,
      ),
      onMapCreated: (GoogleMapController controller) {
        if (!_controller.isCompleted) {
          _controller.complete(controller);
        }
      },
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _businesses.length,
      itemBuilder: (context, index) {
        final business = _businesses[index];
        final distance = _getDistance(business.location.latitude, business.location.longitude);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(business.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(business.category),
            trailing: Text(distance, style: const TextStyle(color: Colors.grey)),
            onTap: () {
              // TODO: Navigate to a business details screen
            },
          ),
        );
      },
    );
  }
}
