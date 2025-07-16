import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/trip_model.dart';
import '../models/memory_item_model.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import 'home_screen.dart';
import 'add_trip_screen.dart';

class TripsListScreen extends StatefulWidget {
  const TripsListScreen({super.key}); // Added const for consistency

  @override
  _TripsListScreenState createState() => _TripsListScreenState();
}

class _TripsListScreenState extends State<TripsListScreen> {
  List<Trip> _allTrips = [];
  List<Trip> _futureTrips = [];
  List<Trip> _pastTrips = [];

  final _weatherService = WeatherService('8c8d50cc8e3c472c07c13bf9a8498eef');

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _separateAndSortTrips() async {
    final now = DateTime.now();
    _allTrips.sort((a, b) => b.lastModifiedDate.compareTo(a.lastModifiedDate));
    if (mounted) {
      setState(() {
        // Correctly filter future and past trips
        // Future trips are those whose end date is *after* the current moment (or today).
        // Past trips are those whose end date is *before* the current moment (or today).
        _futureTrips = _allTrips.where((trip) => trip.endDate.isAfter(DateUtils.dateOnly(now).subtract(const Duration(days: 1)))).toList();
        _pastTrips = _allTrips.where((trip) => !trip.endDate.isAfter(DateUtils.dateOnly(now).subtract(const Duration(days: 1)))).toList();
      });
    }
    // No need to fetch weather for past trips here, as it's already handled during trip creation/editing
    // _fetchWeatherForPastTrips(); // This line is not needed here if weather is saved with the trip
  }

  // This function seems unused or meant for a different purpose if weather is saved with trip.
  // If it's intended to update weather for *all* past trips, it needs to be async and call _saveTrips.
  Future<void> _fetchWeatherForPastTrips() async {
    // Current weather fetching is already handled in AddTripScreen and EditTripScreen
    // and saved directly into the trip object.
    // This function would only be necessary if you wanted to periodically update
    // weather for trips already created, which is a more advanced feature
    // not currently indicated by the app's flow.
  }

  Future<void> _loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tripsString = prefs.getString('trips_list');
    if (tripsString != null) {
      final List<dynamic> jsonList = jsonDecode(tripsString);
      if (mounted) {
        _allTrips = jsonList.map((json) => Trip.fromJson(json)).toList();
        await _separateAndSortTrips(); // Separate and sort after loading
      }
    }
  }

  Future<void> _saveTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = _allTrips.map((trip) => trip.toJson()).toList();
    await prefs.setString('trips_list', jsonEncode(jsonList));
  }

  void _updateAndSaveTrip(Trip updatedTrip) {
    final index = _allTrips.indexWhere((trip) => trip.id == updatedTrip.id);
    if (index != -1) {
      // Ensure the updated trip's lastModifiedDate is set when updated from sub-screens
      updatedTrip.lastModifiedDate = DateTime.now();
      _allTrips[index] = updatedTrip;
      _separateAndSortTrips(); // Re-sort after updating a trip
      _saveTrips(); // Save the updated list
    }
  }

  void _addTrip(Trip trip) {
    _allTrips.add(trip);
    _separateAndSortTrips();
    _saveTrips();
  }

  void _deleteTrip(String tripId) async { // Make it async because _saveTrips is async
    setState(() {
      _allTrips.removeWhere((trip) => trip.id == tripId);
    });
    _separateAndSortTrips(); // Re-sort after deleting a trip
    await _saveTrips(); // Save the updated list after deletion
    _showSnackBar('הטיול נמחק בהצלחה!');
  }

  // חדש: פונקציה להצגת דיאלוג אישור מחיקה
  Future<void> _showDeleteConfirmationDialog(Trip trip) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // אפשר לסגור בלחיצה בצד
      builder: (BuildContext dialogContext) {
        return Directionality( // Add Directionality for RTL dialog
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Rounded corners
            title: const Text('אישור מחיקה', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text('האם למחוק את הטיול "${trip.name}"?', textDirection: TextDirection.rtl),
            actions: <Widget>[
              TextButton(
                child: const Text('ביטול', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // סוגר את הדיאלוג
                },
              ),
              TextButton(
                child: const Text('מחק', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onPressed: () {
                  _deleteTrip(trip.id);
                  Navigator.of(dialogContext).pop(); // סוגר את הדיאלוג
                },
              ),
            ],
          ),
        );
      },
    );
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

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textDirection: TextDirection.rtl),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('הטיולים שלי', style: TextStyle(color: Colors.white)), // Text color for AppBar title
          centerTitle: true,
          backgroundColor: colorScheme.primary, // AppBar background color
          elevation: 4,
          bottom: TabBar(
            indicatorColor: colorScheme.onPrimary, // הצבע של הקו מתחת ללשונית הפעילה (לבן על כחול כהה)
            labelColor: Colors.black, // <--- שינוי כאן: צבע הטקסט של הלשונית הפעילה (שחור)
            unselectedLabelColor: Colors.white, // <--- שינוי כאן: צבע הטקסט של הלשוניות הלא פעילות (לבן)
            tabs: const [
              Tab(text: 'טיולים קרובים'),
              Tab(text: 'טיולים שעברו'),
            ],
          ),
        ),
        body: Directionality( // Ensure RTL for the whole body
          textDirection: TextDirection.rtl,
          child: TabBarView(
            children: [
              _buildTripsTab(_futureTrips, true),
              _buildTripsTab(_pastTrips, false),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended( // Changed to extended for better look
          onPressed: _navigateToAddTripScreen,
          icon: const Icon(Icons.add),
          label: const Text('טיול חדש'),
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Rounded FAB
          tooltip: 'צור טיול חדש',
        ).animate().slideY(begin: 0.2, duration: 500.ms).fadeIn(duration: 500.ms), // Animate FAB
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Common FAB location
      ),
    );
  }

  Widget _buildTripsTab(List<Trip> trips, bool isFuture) {
    if (trips.isEmpty) {
      return _buildEmptyState(isFuture);
    }
    return RefreshIndicator(
      onRefresh: _loadTrips, // Pull to refresh calls load trips
      color: Theme.of(context).colorScheme.primary, // Refresh indicator color
      backgroundColor: Theme.of(context).colorScheme.surface, // Refresh indicator background
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works even with few items
        padding: const EdgeInsets.all(12.0),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _buildTripCard(trip);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isFuture) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView( // Added SingleChildScrollView to ensure pull-to-refresh works
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Animate(
                effects: [
                  FadeEffect(duration: 1000.ms),
                  SlideEffect(begin: const Offset(0, 0.1)),
                ],
                child: Lottie.asset(
                  'assets/travel_animation.json', // Assuming a suitable Lottie animation exists
                  height: 200,
                  repeat: true,
                  animate: true,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isFuture ? 'מוכנים להרפתקה הבאה?' : 'אין טיולים בארכיון',
                style: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isFuture ? 'הטיול הראשון שלך מתחיל בלחיצת כפתור' : 'כל טיול שתסיימו יופיע כאן',
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (isFuture) ...[
                const SizedBox(height: 24),
                // Optionally add a button here to directly create a new trip from empty state
                // ElevatedButton.icon(
                //   onPressed: _navigateToAddTripScreen,
                //   icon: const Icon(Icons.add_location_alt_outlined),
                //   label: const Text('צור טיול חדש'),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: colorScheme.secondary,
                //     foregroundColor: colorScheme.onSecondary,
                //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                //   ),
                // ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    final photoMemories = trip.memories
        ?.where((m) => m.type == MemoryType.photo && m.content.isNotEmpty)
        .toList() ?? [];

    final String imageUrl;
    if (photoMemories.isNotEmpty && File(photoMemories.first.content).existsSync()) {
      imageUrl = photoMemories.first.content;
    } else {
      imageUrl = 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1770&q=80';
    }

    ImageProvider imageProvider;
    if (imageUrl.startsWith('http')) {
      imageProvider = NetworkImage(imageUrl);
    } else {
      imageProvider = FileImage(File(imageUrl));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Hero(
        tag: 'trip_image_${trip.id}',
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  trip: trip,
                  onTripUpdated: _updateAndSaveTrip,
                ),
              ),
            ).then((_) {
              _loadTrips(); // Reload trips when returning from HomeScreen to ensure data freshness
            });
          },
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Card(
              elevation: 5,
              shadowColor: Colors.black45,
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black54, Colors.black87],
                        stops: [0.4, 0.7, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          trip.name,
                          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd.MM.yy').format(trip.startDate)} - ${DateFormat('dd.MM.yy').format(trip.endDate)}',
                          style: const TextStyle(fontSize: 14, color: Colors.white70, shadows: [Shadow(blurRadius: 2, color: Colors.black54)]),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(30),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.white70),
                        // שינוי: קריאה לפונקציה שמציגה את הדיאלוג
                        onPressed: () => _showDeleteConfirmationDialog(trip),
                        tooltip: 'מחק טיול',
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}