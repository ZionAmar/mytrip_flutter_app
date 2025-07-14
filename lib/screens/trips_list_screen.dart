import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/trip_model.dart';
import 'home_screen.dart';

class TripsListScreen extends StatefulWidget {
  @override
  _TripsListScreenState createState() => _TripsListScreenState();
}

class _TripsListScreenState extends State<TripsListScreen> {
  List<Trip> _trips = [];
  var uuid = Uuid();
  // הוספנו מפתח ל-RefreshIndicator
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _sortTrips() {
    setState(() {
      _trips.sort((a, b) => b.lastModifiedDate.compareTo(a.lastModifiedDate));
    });
  }

  Future<void> _loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tripsString = prefs.getString('trips_list');
    if (tripsString != null) {
      final List<dynamic> jsonList = jsonDecode(tripsString);
      if (mounted) {
        _trips = jsonList.map((json) => Trip.fromJson(json)).toList();
        _sortTrips();
      }
    }
  }

  Future<void> _saveTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
    _trips.map((trip) => trip.toJson()).toList();
    await prefs.setString('trips_list', jsonEncode(jsonList));
  }

  void _updateAndSaveTrip(Trip updatedTrip) {
    final index = _trips.indexWhere((trip) => trip.id == updatedTrip.id);
    if (index != -1) {
      updatedTrip.lastModifiedDate = DateTime.now();
      setState(() {
        _trips[index] = updatedTrip;
      });
      _sortTrips();
      _saveTrips();
    }
  }

  void _addTrip(Trip trip) {
    setState(() {
      _trips.add(trip);
    });
    _sortTrips();
    _saveTrips();
  }

  void _deleteTrip(int index) {
    setState(() {
      _trips.removeAt(index);
    });
    _saveTrips();
  }

  Future<void> _showDeleteConfirmationDialog(int index) async {
    final trip = _trips[index];
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('אישור מחיקה'),
          content: Text('האם למחוק את הטיול "${trip.name}"?'),
          actions: <Widget>[
            TextButton(
              child: Text('ביטול'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('מחק', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteTrip(index);
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
    );
  }

  void _showAddTripDialog() {
    final _nameController = TextEditingController();
    DateTime? _startDate;
    DateTime? _endDate;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('יצירת טיול חדש'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'שם הטיול'),
                  ),
                  SizedBox(height: 16),
                  Column(
                    children: [
                      TextButton.icon(
                        icon: Icon(Icons.calendar_today),
                        label: Text(_startDate == null ? 'תאריך התחלה' : DateFormat('dd/MM/yy').format(_startDate!)),
                        onPressed: () async {
                          final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (date != null) setDialogState(() => _startDate = date);
                        },
                      ),
                      TextButton.icon(
                        icon: Icon(Icons.calendar_today),
                        label: Text(_endDate == null ? 'תאריך סיום' : DateFormat('dd/MM/yy').format(_endDate!)),
                        onPressed: () async {
                          final date = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: _startDate ?? DateTime.now(), lastDate: DateTime(2030));
                          if (date != null) setDialogState(() => _endDate = date);
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty && _startDate != null && _endDate != null) {
                    final newTrip = Trip(
                      id: uuid.v4(),
                      name: _nameController.text,
                      startDate: _startDate!,
                      endDate: _endDate!,
                      lastModifiedDate: DateTime.now(),
                    );
                    _addTrip(newTrip);
                    Navigator.pop(context);
                  }
                },
                child: Text('צור טיול'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('הטיולים שלי'),
        centerTitle: true,
      ),
      // עטיפת גוף המסך ב-RefreshIndicator
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadTrips, // הפעולה שתתבצע ברענון
        child: _trips.isEmpty
            ? Center(child: Text('עדיין לא יצרת טיולים.\nלחץ על + או משוך למטה לרענון.'))
            : ListView.builder(
          itemCount: _trips.length,
          itemBuilder: (context, index) {
            final trip = _trips[index];
            return Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                leading: Icon(Icons.airplanemode_active, color: Colors.teal),
                title: Text(trip.name, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                  tooltip: 'מחק טיול',
                  onPressed: () => _showDeleteConfirmationDialog(index),
                ),
                onTap: () => _navigateToTripDashboard(trip),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTripDialog,
        child: Icon(Icons.add),
        tooltip: 'טיול חדש',
      ),
    );
  }
}