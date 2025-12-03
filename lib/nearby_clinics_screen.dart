import 'package:flutter/material.dart';
import '../models/business_model.dart';
import '../services/location_service.dart';
import '../services/business_service.dart';
import 'package:geolocator/geolocator.dart';

class NearbyClinicsScreen extends StatefulWidget {
  const NearbyClinicsScreen({Key? key}) : super(key: key);

  @override
  _NearbyClinicsScreenState createState() => _NearbyClinicsScreenState();
}

class _NearbyClinicsScreenState extends State<NearbyClinicsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Business> _businesses = [];

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
      final locationData = await _locationService.getCurrentLocation();
      if (locationData == null) {
        setState(() {
          _error = 'Could not determine your location. Please ensure location services are enabled.';
          _isLoading = false;
        });
        return;
      }

      // 2. Fetch nearby businesses from the backend
      final businesses = await _businessService.findNearbyBusinesses(
        locationData.latitude!,
        locationData.longitude!,
      );

      setState(() {
        _businesses = businesses;
        _isLoading = false;
      });

    } catch (e) {
      print('Error fetching nearby clinics: $e');
      setState(() {
        _error = 'Failed to find nearby clinics. Please try again later.';
        _isLoading = false;
      });
    }
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
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(business.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(business.category),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: Navigate to a business details screen
            },
          ),
        );
      },
    );
  }
}
