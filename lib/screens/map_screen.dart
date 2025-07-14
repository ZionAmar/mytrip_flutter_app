// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // לייבוא יכולות המרת כתובת לקואורדינטות
import '../models/trip_model.dart'; // לייבוא מודל הטיול

/// This screen displays a map of the trip location.
class MapScreen extends StatefulWidget {
  final Trip trip; // קבל את אובייקט הטיול

  const MapScreen({super.key, required this.trip});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _center; // קואורדינטות מרכז המפה
  String? _errorMessage; // הודעת שגיאה

  @override
  void initState() {
    super.initState();
    _getCoordinatesForCity(); // נסה להביא קואורדינטות כשהמסך נטען
  }

  Future<void> _getCoordinatesForCity() async {
    try {
      // מנסה להמיר את שם העיר לקואורדינטות
      List<Location> locations = await locationFromAddress(widget.trip.destinationCity);
      if (locations.isNotEmpty) {
        setState(() {
          _center = LatLng(locations.first.latitude, locations.first.longitude);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'לא נמצאו קואורדינטות עבור ${widget.trip.destinationCity}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'שגיאה בקבלת קואורדינטות: $e';
      });
      print('Error getting coordinates: $e'); // להדפסה לדיבוג
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('מפת היעד: ${widget.trip.destinationCity}'), // הצג את עיר היעד
      ),
      body: _center == null && _errorMessage == null
          ? const Center(child: CircularProgressIndicator()) // טוען...
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      )
          : GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          // ניתן לשמור את הקונטרולר של המפה כאן אם תצטרך לשלוט בה מאוחר יותר
        },
        initialCameraPosition: CameraPosition(
          target: _center!, // מרכז המפה על עיר היעד
          zoom: 12.0, // רמת זום ראשונית (ניתן לשנות)
        ),
        markers: { // הוספת סמן (מרקר) על המיקום
          Marker(
            markerId: MarkerId(widget.trip.destinationCity),
            position: _center!,
            infoWindow: InfoWindow(title: widget.trip.destinationCity),
          ),
        },
      ),
    );
  }
}