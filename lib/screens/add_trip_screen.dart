import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart' as typeAhead;
import '../models/trip_model.dart';
import '../services/places_service.dart';

class AddTripScreen extends StatefulWidget {
  @override
  _AddTripScreenState createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  // אין צורך ב- _cityDisplayController יותר עבור תצוגה
  // אנחנו נשתמש ישירות בקונטרולר שמסופק ל-builder של TypeAheadField
  // אבל נשמור רפרנס אליו כדי שנוכל לגשת אליו מחוץ ל-builder.
  TextEditingController _cityControllerFromTypeAhead = TextEditingController();


  DateTime? _startDate;
  DateTime? _endDate;

  final PlacesService _placesService = PlacesService('e91e6d0030124c03b3c5feec6722eccc');

  @override
  void dispose() {
    _nameController.dispose();
    _cityControllerFromTypeAhead.dispose(); // חשוב לשחרר את הקונטרולר כשמסך נסגר
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newTrip = Trip(
        id: Uuid().v4(),
        name: _nameController.text,
        destinationCity: _cityControllerFromTypeAhead.text, // משתמשים בקונטרולר הנכון
        startDate: _startDate!,
        endDate: _endDate!,
        lastModifiedDate: DateTime.now(),
      );
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
                  // שמור רפרנס לקונטרולר של ה-TypeAheadField
                  _cityControllerFromTypeAhead = controller;
                  return TextFormField(
                    controller: controller, // השתמש בקונטרולר שהתקבל מה-builder
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
                  // כאן הקסם קורה: עדכן ישירות את הטקסט של הקונטרולר שמשויך ל-TextFormField הפנימי
                  _cityControllerFromTypeAhead.text = suggestion.toString();
                  // אין צורך ב-setState() מכיוון שעדכון של TextEditingController כבר גורם לרענון ה-UI
                },
                // ה-validator כאן לא נחוץ כי כבר הגדרנו אותו בתוך ה-TextFormField ב-builder
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
              ElevatedButton.icon(
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