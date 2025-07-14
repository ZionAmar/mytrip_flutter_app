// lib/screens/edit_trip_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart' as typeAhead;
import '../models/trip_model.dart';
import '../services/places_service.dart';
import '../services/weather_service.dart'; // <--- NEW: Import WeatherService
import '../models/weather_model.dart'; // <--- NEW: Import DailyWeather model

class EditTripScreen extends StatefulWidget {
  final Trip trip;

  const EditTripScreen({
    super.key,
    required this.trip,
  });

  @override
  _EditTripScreenState createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _cityController;

  DateTime? _startDate;
  DateTime? _endDate;

  final PlacesService _placesService = PlacesService('e91e6d0030124c03b3c5feec6722eccc');
  // NEW: Initialize WeatherService
  final WeatherService _weatherService = WeatherService('8c8d50cc8e3c472c07c13bf9a8498eef'); // <--- REPLACE with your OpenWeatherMap API key!

  bool _isSavingTrip = false; // NEW: State to manage loading during save

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip.name);
    _cityController = TextEditingController(text: widget.trip.destinationCity);
    _startDate = widget.trip.startDate;
    _endDate = widget.trip.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async { // <--- CHANGE: Made async
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('יש לבחור תאריכי התחלה וסיום לטיול.')),
        );
        return;
      }

      setState(() {
        _isSavingTrip = true; // Show loading indicator
      });

      List<DailyWeather>? weatherForecast;
      bool shouldFetchWeather = false;

      // Determine if weather needs to be re-fetched
      // Fetch if city, start date, or end date changed
      if (widget.trip.destinationCity != _cityController.text ||
          !DateUtils.dateOnly(widget.trip.startDate).isAtSameMomentAs(DateUtils.dateOnly(_startDate!)) ||
          !DateUtils.dateOnly(widget.trip.endDate).isAtSameMomentAs(DateUtils.dateOnly(_endDate!)) ||
          widget.trip.savedWeatherForecast == null || widget.trip.savedWeatherForecast!.isEmpty) {
        shouldFetchWeather = true;
      }

      if (shouldFetchWeather) {
        try {
          final fetchedFullForecast = await _weatherService.fetchDailyForecast(_cityController.text);
          weatherForecast = fetchedFullForecast.where((dailyWeather) {
            final forecastDate = DateUtils.dateOnly(dailyWeather.date);
            final startDateOnly = DateUtils.dateOnly(_startDate!);
            final endDateOnly = DateUtils.dateOnly(_endDate!);
            return !forecastDate.isBefore(startDateOnly) && !forecastDate.isAfter(endDateOnly);
          }).toList();
        } catch (e) {
          print('Error fetching weather during trip update: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('אזהרה: לא ניתן היה לטעון תחזית מזג אוויר. הטיול יישמר עם התחזית הקודמת (אם קיימת).')),
          );
          weatherForecast = widget.trip.savedWeatherForecast; // Retain old forecast if fetch fails
        }
      } else {
        weatherForecast = widget.trip.savedWeatherForecast; // Keep existing forecast if no change
      }

      final updatedTrip = widget.trip.copyWith(
        name: _nameController.text,
        destinationCity: _cityController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        lastModifiedDate: DateTime.now(),
        savedWeatherForecast: weatherForecast, // <--- NEW: Assign (potentially updated) weather
      );

      // Important: You need to save this updatedTrip object to your persistent storage.
      // This part is missing in your current code. Assuming you have a TripRepository
      // or similar mechanism. Example placeholder:
      // await TripRepository().updateTrip(updatedTrip);

      setState(() {
        _isSavingTrip = false; // Hide loading indicator
      });

      Navigator.pop(context, updatedTrip);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('עריכת פרטי טיול'),
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
                decoration: const InputDecoration(
                  labelText: 'שם הטיול',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.card_travel),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'יש להזין שם לטיול' : null,
              ),
              const SizedBox(height: 16),

              typeAhead.TypeAheadField<Place>(
                controller: _cityController,
                builder: (context, controller, focusNode) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
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
                  _cityController.text = suggestion.toString();
                },
              ),

              const SizedBox(height: 16),
              _buildDatePickerField(
                label: 'תאריך התחלה',
                selectedDate: _startDate,
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _startDate = date);
                },
              ),
              const SizedBox(height: 16),
              _buildDatePickerField(
                label: 'תאריך סיום',
                selectedDate: _endDate,
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? _startDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime(2000),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _endDate = date);
                },
              ),
              const SizedBox(height: 32),
              _isSavingTrip // Show loading indicator if saving
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('שמור שינויים'),
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
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
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.calendar_today),
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