
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;

class LocationService {
  Future<Position?> getCurrentLocation() async {
    // For web, we directly try to get the position and let the browser handle permissions.
    // This avoids issues with permission APIs in non-secure contexts (http).
    if (kIsWeb) {
      try {
        return await Geolocator.getCurrentPosition();
      } catch (e) {
        developer.log('Could not get location on web: $e', name: 'com.example.myapp.location', error: e);
        return null;
      }
    }

    // For mobile, we follow the full check-flow.
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      developer.log('Location services are disabled.', name: 'com.example.myapp.location');
      return null;
    }

    // 2. Check for location permissions.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        developer.log('Location permissions are denied.', name: 'com.example.myapp.location');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      developer.log('Location permissions are permanently denied.', name: 'com.example.myapp.location');
      return null;
    }

    // 3. If we have permission, get the location.
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      developer.log('Could not get location on mobile: $e', name: 'com.example.myapp.location', error: e);
      return null;
    }
  }
}
