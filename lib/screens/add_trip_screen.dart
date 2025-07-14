// lib/screens/add_trip_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart' as typeAhead;
import '../models/trip_model.dart';
import '../services/places_service.dart';
import '../services/weather_service.dart'; // <--- NEW: Import WeatherService
import '../models/weather_model.dart'; // <--- NEW: Import DailyWeather model

class AddTripScreen extends StatefulWidget {
  @override
  _AddTripScreenState createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late TextEditingController _cityControllerFromTypeAhead;

  DateTime? _startDate;
  DateTime? _endDate;

  final PlacesService _placesService = PlacesService('e91e6d0030124c03b3c5feec6722eccc');
  // NEW: Initialize WeatherService
  final WeatherService _weatherService = WeatherService('8c8d50cc8e3c472c07c13bf9a8498eef'); // <--- REPLACE with your OpenWeatherMap API key!

  bool _isSavingTrip = false; // NEW: State to manage loading during save

  @override
  void dispose() {
    _nameController.dispose();
    // _cityControllerFromTypeAhead.dispose(); // This line remains commented out as per our previous discussion.
    super.dispose();
  }

  Future<void> _submitForm() async { // <--- CHANGE: Made async
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        // Show an error if dates are not selected
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('יש לבחור תאריכי התחלה וסיום לטיול.')),
        );
        return;
      }

      setState(() {
        _isSavingTrip = true; // Show loading indicator
      });

      List<DailyWeather>? weatherForecast;
      try {
        // Fetch weather forecast
        final fetchedFullForecast = await _weatherService.fetchDailyForecast(_cityControllerFromTypeAhead.text);

        // Filter forecast to trip dates
        weatherForecast = fetchedFullForecast.where((dailyWeather) {
          final forecastDate = DateUtils.dateOnly(dailyWeather.date);
          final startDateOnly = DateUtils.dateOnly(_startDate!);
          final endDateOnly = DateUtils.dateOnly(_endDate!);
          return !forecastDate.isBefore(startDateOnly) && !forecastDate.isAfter(endDateOnly);
        }).toList();

      } catch (e) {
        print('Error fetching weather during trip creation: $e');
        // Optionally show a warning to the user, but still allow trip creation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('אזהרה: לא ניתן היה לטעון תחזית מזג אוויר. הטיול יישמר ללא תחזית.')),
        );
      }

      final newTrip = Trip(
        id: Uuid().v4(),
        name: _nameController.text,
        destinationCity: _cityControllerFromTypeAhead.text,
        startDate: _startDate!,
        endDate: _endDate!,
        lastModifiedDate: DateTime.now(),
        savedWeatherForecast: weatherForecast, // <--- NEW: Assign fetched weather
      );

      // Important: You need to save this newTrip object to your persistent storage.
      // This part is missing in your current code. Assuming you have a TripRepository
      // or similar mechanism. Example placeholder:
      // await TripRepository().saveTrip(newTrip);

      setState(() {
        _isSavingTrip = false; // Hide loading indicator
      });

      Navigator.pop(context, newTrip);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('יצירת טיול חדש'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'שם הטיול',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.card_travel),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'יש להזין שם לטיול' : null,
              ),
              SizedBox(height: 16),

              typeAhead.TypeAheadField<Place>(
                builder: (context, controller, focusNode) {
                  _cityControllerFromTypeAhead = controller;
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'עיר יעד',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'יש לבחור עיר מהרשימה';
                      }
                      return null;
                    },
                  );
                },
                suggestionsCallback: (pattern) async {
                  return await _placesService.searchPlaces(pattern);
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion.toString()),
                  );
                },
                onSelected: (suggestion) {
                  _cityControllerFromTypeAhead.text = suggestion.toString();
                },
              ),

              SizedBox(height: 16),
              _buildDatePickerField(
                label: 'תאריך התחלה',
                selectedDate: _startDate,
                onPressed: () async {
                  final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
                  if (date != null) setState(() => _startDate = date);
                },
              ),
              SizedBox(height: 16),
              _buildDatePickerField(
                label: 'תאריך סיום',
                selectedDate: _endDate,
                onPressed: () async {
                  final date = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: _startDate ?? DateTime.now(), lastDate: DateTime(2030));
                  if (date != null) setState(() => _endDate = date);
                },
              ),
              SizedBox(height: 32),
              _isSavingTrip // Show loading indicator if saving
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                icon: Icon(Icons.add_circle_outline),
                label: Text('צור טיול'),
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onPressed,
  }) {
    return FormField<DateTime>(
      initialValue: selectedDate,
      validator: (value) => (selectedDate == null) ? 'יש לבחור תאריך' : null,
      builder: (state) {
        return InkWell(
          onTap: onPressed,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_today),
              errorText: state.errorText,
            ),
            child: Text(
              selectedDate == null ? 'בחר תאריך' : DateFormat('dd/MM/yyyy').format(selectedDate),
            ),
          ),
        );
      },
    );
  }
}