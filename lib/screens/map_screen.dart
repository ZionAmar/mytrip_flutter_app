// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // <--- CORRECTED THIS IMPORT
import 'package:geocoding/geocoding.dart';
import '../models/trip_model.dart';

/// This screen displays a map of the trip location.
class MapScreen extends StatefulWidget {
  final Trip trip;

  const MapScreen({super.key, required this.trip});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<LatLng?> _coordinatesFuture;

  @override
  void initState() {
    super.initState();
    _coordinatesFuture = _getCoordinatesForCity();
  }

  Future<LatLng?> _getCoordinatesForCity() async {
    try {
      print('DEBUG: Attempting to get coordinates for: ${widget.trip.destinationCity}');
      List<Location> locations = await locationFromAddress(widget.trip.destinationCity);
      if (locations.isNotEmpty) {
        final LatLng center = LatLng(locations.first.latitude, locations.first.longitude);
        print('DEBUG: Coordinates found: ${center.latitude}, ${center.longitude}');
        return center;
      } else {
        print('DEBUG: No coordinates found for ${widget.trip.destinationCity}');
        throw Exception('לא נמצאו קואורדינטות עבור ${widget.trip.destinationCity}');
      }
    } catch (e) {
      print('DEBUG: Error getting coordinates: $e');
      throw Exception('שגיאה בקבלת קואורדינטות: ${e.toString().contains('timeout') ? 'פג תוקף הבקשה' : e}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('מפת היעד: ${widget.trip.destinationCity}'),
        centerTitle: true,
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
                          _coordinatesFuture = _getCoordinatesForCity();
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
              markers: {
                Marker(
                  markerId: MarkerId(widget.trip.destinationCity),
                  position: center,
                  infoWindow: InfoWindow(title: widget.trip.destinationCity),
                ),
              },
            );
          } else {
            return const Center(
              child: Text('משהו השתבש בטעינת המפה.'),
            );
          }
        },
      ),
    );
  }
}