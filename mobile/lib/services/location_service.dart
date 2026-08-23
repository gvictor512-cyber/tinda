import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Default max distance in km
  static const double DEFAULT_MAX_DISTANCE_KM = 50.0;

  // Location update distance filter in meters
  static const int LOCATION_UPDATE_DISTANCE_FILTER = 100;

  // Default location accuracy
  static const LocationAccuracy DEFAULT_LOCATION_ACCURACY = LocationAccuracy.high;

  // Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  // Request location permissions
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // Get current position
  Future<Position> getCurrentPosition() async {
    bool hasPermission = await hasLocationPermission();
    
    if (!hasPermission) {
      hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: DEFAULT_LOCATION_ACCURACY,
    );
  }

  // Get continuous position updates
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: DEFAULT_LOCATION_ACCURACY,
        distanceFilter: LOCATION_UPDATE_DISTANCE_FILTER,
      ),
    );
  }

  // Calculate distance between two positions in km
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000;
  }

  // Save user location to Firestore
  Future<void> saveUserLocation(Position position) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final geoPoint = GeoPoint(position.latitude, position.longitude);

      await _firestore.collection('users').doc(currentUser.uid).update({
        'preferences.location': geoPoint,
        'preferences.locationTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving user location: $e');
      rethrow;
    }
  }

  // Get user location from Firestore
  Future<GeoPoint?> getUserLocation(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      
      return userData?['preferences']?['location'] as GeoPoint?;
    } catch (e) {
      debugPrint('Error getting user location: $e');
      return null;
    }
  }

  // Get current user's location
  Future<GeoPoint?> getCurrentUserLocation() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');
    
    return await getUserLocation(currentUser.uid);
  }

  // Find users within a specific radius
  Future<List<Map<String, dynamic>>> findUsersWithinRadius({
    required double radiusKm,
    required GeoPoint center,
    String? userType,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Get all users (in production, use geoqueries)
      QuerySnapshot usersSnapshot;
      
      if (userType != null) {
        usersSnapshot = await _firestore
            .collection('users')
            .where('userType', isEqualTo: userType)
            .where('uid', isNotEqualTo: currentUser.uid)
            .get();
      } else {
        usersSnapshot = await _firestore
            .collection('users')
            .where('uid', isNotEqualTo: currentUser.uid)
            .get();
      }

      List<Map<String, dynamic>> usersWithinRadius = [];

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        final userLocation = userData['preferences']?['location'] as GeoPoint?;

        if (userLocation != null) {
          final distance = calculateDistance(
            center.latitude,
            center.longitude,
            userLocation.latitude,
            userLocation.longitude,
          );

          if (distance <= radiusKm) {
            userData['distance'] = distance;
            userData['documentId'] = doc.id;
            usersWithinRadius.add(userData);
          }
        }
      }

      // Sort by distance (closest first)
      usersWithinRadius.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      return usersWithinRadius;
    } catch (e) {
      debugPrint('Error finding users within radius: $e');
      rethrow;
    }
  }

  // Update location preferences
  Future<void> updateLocationPreferences({
    required double maxDistance,
    required bool locationEnabled,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(currentUser.uid).update({
        'preferences.maxDistance': maxDistance,
        'preferences.locationEnabled': locationEnabled,
      });
    } catch (e) {
      debugPrint('Error updating location preferences: $e');
      rethrow;
    }
  }

  // Get location preferences
  Future<Map<String, dynamic>?> getLocationPreferences() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      
      return {
        'maxDistance': userData?['preferences']?['maxDistance'] ?? DEFAULT_MAX_DISTANCE_KM,
        'locationEnabled': userData?['preferences']?['locationEnabled'] ?? false,
        'location': userData?['preferences']?['location'],
      };
    } catch (e) {
      debugPrint('Error getting location preferences: $e');
      return null;
    }
  }

  // Start location tracking in background
  Future<void> startLocationTracking() async {
    bool hasPermission = await hasLocationPermission();
    
    if (!hasPermission) {
      hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }
    }

    // Request background location permission (Android)
    if (await Permission.locationAlways.isDenied) {
      await Permission.locationAlways.request();
    }

    getPositionStream().listen((position) {
      saveUserLocation(position);
    });
  }

  // Stop location tracking
  void stopLocationTracking() {
    // In a real implementation, you would cancel the stream subscription
  }

  // Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.country}';
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }
    return null;
  }

  // Get coordinates from address (geocoding)
  Future<geocoding.Location?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await geocoding.locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first;
      }
    } catch (e) {
      debugPrint('Error getting coordinates: $e');
    }
    return null;
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  // Get current position and save it to Firestore
  Future<void> updateAndSaveCurrentLocation() async {
    try {
      final position = await getCurrentPosition();
      await saveUserLocation(position);
    } catch (e) {
      debugPrint('Could not update current location: $e');
    }
  }
}
