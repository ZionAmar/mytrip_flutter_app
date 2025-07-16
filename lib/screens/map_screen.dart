import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import '../models/trip_model.dart';
import '../models/activity_model.dart';
import 'package:permission_handler/permission_handler.dart';

/// This screen displays a map of the trip location and allows navigation.
class MapScreen extends StatefulWidget {
  final Trip trip;

  const MapScreen({super.key, required this.trip});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<LatLng?> _coordinatesFuture;
  final Set<Marker> _markers = {};
  bool _locationPermissionGranted = false; // Track permission status

  @override
  void initState() {
    super.initState();
    _checkLocationPermission(); // Check permission on init
    _coordinatesFuture = _getCoordinatesForCity();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) {
      setState(() {
        _locationPermissionGranted = true;
      });
    } else if (status.isDenied || status.isRestricted || status.isLimited) {
      _requestLocationPermission();
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      setState(() {
        _locationPermissionGranted = true;
      });
    } else if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _locationPermissionGranted = false;
      });
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    if (Navigator.of(context).canPop() && ModalRoute.of(context)?.isCurrent == true) {
      // Avoid showing if dialog already on screen
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('הרשאת מיקום נדרשת'),
          content: const Text('כדי להציג את מיקומך על המפה, יש לאפשר גישה למיקום בהגדרות המכשיר.'),
          actions: <Widget>[
            TextButton(
              child: const Text('בטל'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('פתח הגדרות'),
              onPressed: () {
                Navigator.of(context).pop();
                // You might want to open app settings here
                // openAppSettings();
              },
            ),
          ],
        ),
      );
    }
  }

// Helper to get coordinates for a given address
  Future<LatLng?> _getCoordinatesForAddress(String address, String markerId, String title) async {
    try {
      print('DEBUG: Attempting to get coordinates for: $address');
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final LatLng coordinates = LatLng(locations.first.latitude, locations.first.longitude);
        print('DEBUG: Coordinates found for $address: ${coordinates.latitude}, ${coordinates.longitude}');
        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(markerId),
              position: coordinates,
              infoWindow: InfoWindow(
                title: title,
                snippet: address,
                onTap: () => _launchGoogleMaps(address, coordinates), // Direct launch Google Maps
              ),
              onTap: () => _launchGoogleMaps(address, coordinates), // Direct launch Google Maps
            ),
          );
        });
        return coordinates;
      } else {
        print('DEBUG: No coordinates found for $address');
        return null;
      }
    } catch (e) {
      print('DEBUG: Error getting coordinates for $address: $e');
      throw Exception('שגיאה באחזור קואורדינטות עבור $address: $e'); // Throw specific error for better handling
    }
  }

// Main function to get coordinates for the destination city and activities
  Future<LatLng?> _getCoordinatesForCity() async {
    _markers.clear(); // Clear existing markers

// Get coordinates for the main destination city
    final LatLng? cityCoords = await _getCoordinatesForAddress(
      widget.trip.destinationCity,
      widget.trip.destinationCity,
      widget.trip.destinationCity,
    );

// Get coordinates for activities with addresses
    for (int i = 0; i < widget.trip.activities.length; i++) {
      final activity = widget.trip.activities[i];
      if (activity.address != null && activity.address!.isNotEmpty) {
        await _getCoordinatesForAddress(
          activity.address!,
          'activity_${activity.name}_$i',
          activity.name,
        );
      }
    }
    return cityCoords;
  }

// Function to launch Google Maps directly (simplified)
  Future<void> _launchGoogleMaps(String destinationAddress, LatLng destinationCoordinates) async {
    // Correct Google Maps URL format for launching with coordinates
    final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${destinationCoordinates.latitude},${destinationCoordinates.longitude}';
    final Uri uri = Uri.parse(googleMapsUrl);

    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('לא ניתן לפתוח את Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Prevents automatic back button
        title: Text('מפת היעד: ${widget.trip.destinationCity}'),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Colors.blue, // Use theme or default
        elevation: 0, // Remove shadow if desired

        // Back button (leading, typically on the right in RTL)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), // iOS style back arrow
          tooltip: 'חזרה',
          onPressed: () {
            Navigator.of(context).pop(); // Navigates back to the previous screen
          },
        ),
        // Home button (actions, typically on the left in RTL)
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.white), // Outlined home icon
            tooltip: 'למסך הבית',
            onPressed: () {
              // This will pop all routes until the first route (home screen or trips list)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: FutureBuilder<LatLng?>(
        future: _coordinatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _coordinatesFuture = _getCoordinatesForCity(); // Retry fetching coordinates
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('נסה שוב'),
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            final LatLng center = snapshot.data!;
            return GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                // You can save the map controller here if you need to control it later
              },
              initialCameraPosition: CameraPosition(
                target: center,
                zoom: 12.0,
              ),
              markers: _markers, // Use the markers set
              myLocationEnabled: _locationPermissionGranted, // Enable if permission granted
              myLocationButtonEnabled: _locationPermissionGranted, // Enable if permission granted
            );
          } else {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('משהו השתבש בטעינת המפה או שלא נמצאו קואורדינטות ליעד הראשי.'),
                  SizedBox(height: 20),
                  // No need for a separate button here, the FutureBuilder already handles retrying
                  // if the _coordinatesFuture is reset. The error state above already has one.
                ],
              ),
            );
          }
        },
      ),
      floatingActionButton: FutureBuilder<LatLng?>(
        future: _coordinatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data != null) {
            return FloatingActionButton.extended(
              onPressed: () => _launchGoogleMaps(widget.trip.destinationCity, snapshot.data!), // Direct launch
              label: const Text('נווט ליעד הראשי'),
              icon: const Icon(Icons.navigation),
            );
          }
          return Container(); // Hide button if coordinates aren't ready
        },
      ),
    );
  }
}