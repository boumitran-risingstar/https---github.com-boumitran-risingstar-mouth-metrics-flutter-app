import 'package:flutter/material.dart';
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

  final LocationService _locationService = LocationService();
  final BusinessService _businessService = BusinessService();

  @override
  void initState() {
    super.initState();
    _fetchNearbyClinics();
  }

  Future<void> _fetchNearbyClinics() async {
    try {
      // 1. Get current location
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

      // 2. Fetch nearby businesses from the backend
      final businesses = await _businessService.findNearbyBusinesses(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      
      if (mounted) {
        setState(() {
          _businesses = businesses;
          _isLoading = false;
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
  
  // Function to calculate the distance
  String _getDistance(double lat, double lng) {
    if (_currentPosition == null) return '';
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    );
    // Convert to miles
    final distanceInMiles = distance * 0.000621371;
    return '${distanceInMiles.toStringAsFixed(1)} miles';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Dental Clinics'),
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
