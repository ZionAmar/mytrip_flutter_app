// lib/screens/edit_trip_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart' as typeAhead;
import '../models/trip_model.dart';
import '../services/places_service.dart';

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
  late TextEditingController _cityController; // Use a dedicated controller for the TypeAheadField

  DateTime? _startDate;
  DateTime? _endDate;

  final PlacesService _placesService = PlacesService('e91e6d0030124c03b3c5feec6722eccc');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip.name);
    _cityController = TextEditingController(text: widget.trip.destinationCity); // Initialize here
    _startDate = widget.trip.startDate;
    _endDate = widget.trip.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose(); // Dispose the controller you created
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final updatedTrip = widget.trip.copyWith(
        name: _nameController.text,
        destinationCity: _cityController.text, // Use your own controller's text
        startDate: _startDate!,
        endDate: _endDate!,
        lastModifiedDate: DateTime.now(),
      );
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
                // Pass your own controller directly to the TypeAheadField
                controller: _cityController,
                builder: (context, controller, focusNode) {
                  // No need to reassign _cityController here
                  return TextFormField(
                    controller: controller, // Use the controller provided by the builder (which is _cityController)
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
                  // Update your controller directly
                  _cityController.text = suggestion.toString();
                  // No setState needed as TextEditingController updates cause rebuilds
                },
                // The validator here is not necessary because you've defined it inside the TextFormField in the builder
              ),

              const SizedBox(height: 16),
              _buildDatePickerField(
                label: 'תאריך התחלה',
                selectedDate: _startDate,
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2000), // Allow selection of past dates for existing trips
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
                    firstDate: _startDate ?? DateTime(2000), // Should not be before start date
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _endDate = date);
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
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