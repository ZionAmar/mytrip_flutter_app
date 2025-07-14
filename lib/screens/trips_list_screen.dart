// lib/screens/trips_list_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';
import '../models/weather_model.dart'; // <--- החזרנו ייבוא
import '../services/weather_service.dart'; // <--- החזרנו ייבוא
import 'home_screen.dart';
import 'add_trip_screen.dart';

class TripsListScreen extends StatefulWidget {
  @override
  _TripsListScreenState createState() => _TripsListScreenState();
}

class _TripsListScreenState extends State<TripsListScreen> {
  List<Trip> _allTrips = [];
  List<Trip> _futureTrips = []; // <--- נשמור את ההפרדה לרשימות
  List<Trip> _pastTrips = []; // <--- נשמור את ההפרדה לרשימות

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  final _weatherService = WeatherService('8c8d50cc8e3c472c07c13bf9a8498eef'); // <--- החזרנו את שירות מזג האוויר (ודא שמפתח ה-API תקין)

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  // Changed to async because it might fetch weather data
  Future<void> _separateAndSortTrips() async {
    final now = DateTime.now();
    _allTrips.sort((a, b) => b.lastModifiedDate.compareTo(a.lastModifiedDate));

    _futureTrips = _allTrips.where((trip) => trip.endDate.isAfter(now.subtract(const Duration(days: 1)))).toList();
    _pastTrips = _allTrips.where((trip) => !trip.endDate.isAfter(now.subtract(const Duration(days: 1)))).toList();

    // Loop through past trips to fetch and save weather if not already present
    for (int i = 0; i < _pastTrips.length; i++) {
      final trip = _pastTrips[i];
      // Check if weather forecast is not already saved for this past trip
      if (trip.savedWeatherForecast == null || trip.savedWeatherForecast!.isEmpty) {
        try {
          // Fetch the full forecast from the weather service
          final fullForecast = await _weatherService.fetchDailyForecast(trip.destinationCity);

          // Filter the forecast to only include dates relevant to the trip duration
          final tripForecast = fullForecast.where((dailyWeather) {
            final forecastDate = DateUtils.dateOnly(dailyWeather.date);
            final startDate = DateUtils.dateOnly(trip.startDate);
            final endDate = DateUtils.dateOnly(trip.endDate);
            return !forecastDate.isBefore(startDate) && !forecastDate.isAfter(endDate);
          }).toList();

          // If a forecast was retrieved, update the trip object with it
          if (tripForecast.isNotEmpty) {
            // Find the original trip in _allTrips list and update it
            final indexInAllTrips = _allTrips.indexWhere((t) => t.id == trip.id);
            if (indexInAllTrips != -1) {
              _allTrips[indexInAllTrips] = _allTrips[indexInAllTrips].copyWith(
                savedWeatherForecast: tripForecast, // Save the fetched forecast
                lastModifiedDate: DateTime.now(), // Mark as recently modified
              );
              // Also update the trip reference in the _pastTrips list
              _pastTrips[i] = _allTrips[indexInAllTrips];
              await _saveTrips(); // Save the entire list to SharedPreferences
            }
          }
        } catch (e) {
          print('Error fetching weather for past trip ${trip.name}: $e');
          // Optionally, you can show a Snackbar or a dialog to the user
          // if weather fetching failed for a past trip.
        }
      }
    }
    setState(() {});
  }

  Future<void> _loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tripsString = prefs.getString('trips_list');
    if (tripsString != null) {
      final List<dynamic> jsonList = jsonDecode(tripsString);
      if (mounted) {
        _allTrips = jsonList.map((json) => Trip.fromJson(json)).toList();
        await _separateAndSortTrips(); // Await this to ensure weather data is populated before rendering
      }
    }
  }

  Future<void> _saveTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
    _allTrips.map((trip) => trip.toJson()).toList();
    await prefs.setString('trips_list', jsonEncode(jsonList));
  }

  void _updateAndSaveTrip(Trip updatedTrip) {
    final index = _allTrips.indexWhere((trip) => trip.id == updatedTrip.id);
    if (index != -1) {
      updatedTrip.lastModifiedDate = DateTime.now();
      _allTrips[index] = updatedTrip;
      _separateAndSortTrips(); // This will now trigger weather fetch for new past trips
      _saveTrips();
    }
  }

  void _addTrip(Trip trip) {
    _allTrips.add(trip);
    _separateAndSortTrips();
    _saveTrips();
  }

  void _deleteTrip(int index, bool isFutureTrip) { // <--- החזרנו isFutureTrip
    final tripToDelete = isFutureTrip ? _futureTrips[index] : _pastTrips[index];
    _allTrips.removeWhere((trip) => trip.id == tripToDelete.id);
    _separateAndSortTrips();
    _saveTrips();
  }

  Future<void> _showDeleteConfirmationDialog(int index, bool isFutureTrip) async { // <--- החזרנו isFutureTrip
    final trip = isFutureTrip ? _futureTrips[index] : _pastTrips[index];
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('אישור מחיקה'),
          content: Text('האם למחוק את הטיול "${trip.name}"?'),
          actions: <Widget>[
            TextButton(child: const Text('ביטול'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: const Text('מחק', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteTrip(index, isFutureTrip); // <--- משתמש ב-isFutureTrip
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToTripDashboard(Trip trip) { // <--- לא מעבירים isPastTrip ל-HomeScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          trip: trip,
          onTripUpdated: _updateAndSaveTrip,
          // Removed: isPastTrip parameter from HomeScreen
        ),
      ),
    ).then((_) {
      _separateAndSortTrips();
    });
  }

  void _navigateToAddTripScreen() async {
    final newTrip = await Navigator.push<Trip>(
      context,
      MaterialPageRoute(builder: (context) => AddTripScreen()),
    );

    if (newTrip != null) {
      _addTrip(newTrip);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('הטיולים שלי')),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadTrips,
        child: _allTrips.isEmpty
            ? const Center(child: Text('עדיין לא יצרת טיולים.\nלחץ על + או משוך למטה לרענון.', textAlign: TextAlign.center))
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_futureTrips.isNotEmpty) // <--- מציג את החלוקה לרשימות
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('טיולים עתידיים', style: Theme.of(context).textTheme.headlineSmall),
                ),
              ListView.builder(
                itemCount: _futureTrips.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final trip = _futureTrips[index];
                  return _buildTripCard(trip, index, true); // <--- מעביר isFutureTrip
                },
              ),
              if (_pastTrips.isNotEmpty) // <--- מציג את החלוקה לרשימות
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('טיולים שעברו', style: Theme.of(context).textTheme.headlineSmall),
                ),
              ListView.builder(
                itemCount: _pastTrips.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final trip = _pastTrips[index];
                  return _buildTripCard(trip, index, false); // <--- מעביר isFutureTrip
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTripScreen,
        child: const Icon(Icons.add),
        tooltip: 'טיול חדש',
      ),
    );
  }

  Widget _buildTripCard(Trip trip, int index, bool isFutureTrip) { // <--- החזרנו isFutureTrip
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: ListTile(
        leading: Icon(isFutureTrip ? Icons.flight : Icons.history, color: Colors.teal), // <--- אייקון לפי סוג טיול
        title: Text(trip.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}'),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red[700]),
          onPressed: () => _showDeleteConfirmationDialog(index, isFutureTrip), // <--- משתמש ב-isFutureTrip
        ),
        onTap: () => _navigateToTripDashboard(trip), // <--- לא מעביר isPastTrip ל-HomeScreen
      ),
    );
  }
}