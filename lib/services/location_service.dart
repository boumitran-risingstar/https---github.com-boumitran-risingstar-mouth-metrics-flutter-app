import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();

  // Check for service and permission, then get the current location.
  Future<LocationData?> getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // 1. Check if location services are enabled.
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        // Location services are not enabled, return null.
        return null;
      }
    }

    // 2. Check for location permissions.
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        // Permissions are denied, return null.
        return null;
      }
    }

    // 3. If we have permission, get the location.
    try {
      return await _location.getLocation();
    } catch (e) {
      // Handle any errors during location fetching.
      print('Could not get location: $e');
      return null;
    }
  }
}
