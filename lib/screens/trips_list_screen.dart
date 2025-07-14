import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';
import 'home_screen.dart';
import 'add_trip_screen.dart'; // 1. הוספנו ייבוא למסך החדש

class TripsListScreen extends StatefulWidget {
  @override
  _TripsListScreenState createState() => _TripsListScreenState();
}

class _TripsListScreenState extends State<TripsListScreen> {
  List<Trip> _allTrips = [];
  List<Trip> _futureTrips = [];
  List<Trip> _pastTrips = [];

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _separateAndSortTrips() {
    final now = DateTime.now();
    _allTrips.sort((a, b) => b.lastModifiedDate.compareTo(a.lastModifiedDate));
    _futureTrips = _allTrips.where((trip) => trip.endDate.isAfter(now)).toList();
    _pastTrips = _allTrips.where((trip) => !trip.endDate.isAfter(now)).toList();
    setState(() {});
  }

  Future<void> _loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tripsString = prefs.getString('trips_list');
    if (tripsString != null) {
      final List<dynamic> jsonList = jsonDecode(tripsString);
      if (mounted) {
        _allTrips = jsonList.map((json) => Trip.fromJson(json)).toList();
        _separateAndSortTrips();
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
      _separateAndSortTrips();
      _saveTrips();
    }
  }

  void _addTrip(Trip trip) {
    _allTrips.add(trip);
    _separateAndSortTrips();
    _saveTrips();
  }

  void _deleteTrip(int index, bool isFutureTrip) {
    final tripToDelete = isFutureTrip ? _futureTrips[index] : _pastTrips[index];
    _allTrips.removeWhere((trip) => trip.id == tripToDelete.id);
    _separateAndSortTrips();
    _saveTrips();
  }

  Future<void> _showDeleteConfirmationDialog(int index, bool isFutureTrip) async {
    final trip = isFutureTrip ? _futureTrips[index] : _pastTrips[index];
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('אישור מחיקה'),
          content: Text('האם למחוק את הטיול "${trip.name}"?'),
          actions: <Widget>[
            TextButton(child: Text('ביטול'), onPressed: () => Navigator.of(context).pop()),
            TextButton(
              child: Text('מחק', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteTrip(index, isFutureTrip);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToTripDashboard(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          trip: trip,
          onTripUpdated: _updateAndSaveTrip,
        ),
      ),
    ).then((_) {
      _separateAndSortTrips();
    });
  }

  // 2. החלפנו את הדיאלוג הקופץ בפונקציית ניווט למסך החדש
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
      appBar: AppBar(title: Text('הטיולים שלי')),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadTrips,
        child: _allTrips.isEmpty
            ? Center(child: Text('עדיין לא יצרת טיולים.\nלחץ על + או משוך למטה לרענון.'))
            : SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_futureTrips.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('טיולים עתידיים', style: Theme.of(context).textTheme.headlineSmall),
                ),
              ListView.builder(
                itemCount: _futureTrips.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final trip = _futureTrips[index];
                  return _buildTripCard(trip, index, true);
                },
              ),
              if (_pastTrips.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('טיולים שעברו', style: Theme.of(context).textTheme.headlineSmall),
                ),
              ListView.builder(
                itemCount: _pastTrips.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final trip = _pastTrips[index];
                  return _buildTripCard(trip, index, false);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTripScreen, // 3. הכפתור קורא לפונקציה החדשה
        child: Icon(Icons.add),
        tooltip: 'טיול חדש',
      ),
    );
  }

  Widget _buildTripCard(Trip trip, int index, bool isFutureTrip) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: ListTile(
        leading: Icon(Icons.airplanemode_active, color: Colors.teal),
        title: Text(trip.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}'),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red[700]),
          onPressed: () => _showDeleteConfirmationDialog(index, isFutureTrip),
        ),
        onTap: () => _navigateToTripDashboard(trip),
      ),
    );
  }
}