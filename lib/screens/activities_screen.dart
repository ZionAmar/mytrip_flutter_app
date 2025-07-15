// lib/screens/activities_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../models/activity_model.dart';
import '../models/trip_model.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:flutter_typeahead/flutter_typeahead.dart' as typeAhead;
import '../services/places_service.dart';
import 'package:geocoding/geocoding.dart'; // Import for geocoding

class ActivitiesScreen extends StatefulWidget {
  final Trip trip;
  final Function(Trip) onTripUpdated;

  const ActivitiesScreen({
    super.key,
    required this.trip,
    required this.onTripUpdated,
  });

  @override
  _ActivitiesScreenState createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  late List<Activity> _activities;
  final PlacesService _placesService = PlacesService('e91e6d0030124c03b3c5feec6722eccc');

  @override
  void initState() {
    super.initState();
    _activities = List<Activity>.from(widget.trip.activities);
    _sortActivities();
  }

  void _sortActivities() {
    _activities.sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime));
  }

  void _updateTripData() {
    widget.trip.activities = _activities;
    widget.onTripUpdated(widget.trip);
  }

  Future<void> _showDeleteConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('אישור מחיקה'),
          content: Text('האם למחוק את הפעילות "${_activities[index].name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('ביטול'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('מחק', style: TextStyle(color: Colors.red)),
              onPressed: () {
                setState(() {
                  _activities.removeAt(index);
                });
                _updateTripData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showActivityDialog({Activity? existingActivity, int? index}) {
    final _nameController = TextEditingController(text: existingActivity?.name);
    final _descriptionController = TextEditingController(text: existingActivity?.description);
    DateTime? _selectedDate = existingActivity?.date;
    TimeOfDay? _selectedTime = existingActivity?.startTime;

    final _locationNameController = TextEditingController(text: existingActivity?.locationName);
    final _addressController = TextEditingController(text: existingActivity?.address);
    final _contactInfoController = TextEditingController(text: existingActivity?.contactInfo);
    final _notesController = TextEditingController(text: existingActivity?.notes);
    final _reservationDetailsController = TextEditingController(text: existingActivity?.reservationDetails);
    final _websiteController = TextEditingController(text: existingActivity?.website);
    final _costController = TextEditingController(text: existingActivity?.cost?.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> _pickDate() async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? widget.trip.startDate,
                firstDate: widget.trip.startDate,
                lastDate: widget.trip.endDate,
              );
              if (pickedDate != null) setDialogState(() => _selectedDate = pickedDate);
            }

            Future<void> _pickTime() async {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: _selectedTime ?? TimeOfDay.now(),
              );
              if (pickedTime != null) setDialogState(() => _selectedTime = pickedTime);
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text(existingActivity == null ? 'הוספת פעילות' : 'עריכת פעילות'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'שם הפעילות', border: OutlineInputBorder()),
                        validator: (value) => (value == null || value.isEmpty) ? 'שם פעילות נדרש' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'תיאור (אופציונלי)', border: OutlineInputBorder()),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(_selectedDate == null ? 'בחר תאריך' : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                              onPressed: _pickDate,
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.access_time),
                              label: Text(_selectedTime == null ? 'בחר שעה' : _selectedTime!.format(context)),
                              onPressed: _pickTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      /// שדה "שם המקום" - רגיל
                      TextFormField(
                        controller: _locationNameController,
                        decoration: const InputDecoration(
                          labelText: 'שם המקום',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.place),
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// autocomplete לשדה "כתובת"
                      typeAhead.TypeAheadField<Place>(
                        controller: _addressController,
                        builder: (context, controller, focusNode) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'כתובת',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            maxLines: 2,
                          );
                        },
                        suggestionsCallback: (pattern) async {
                          if (pattern.length < 2) return [];
                          return await _placesService.searchPlaces(pattern);
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            title: Text(suggestion.fullAddress ?? suggestion.name),
                            subtitle: Text(suggestion.name),
                          );
                        },
                        onSelected: (suggestion) {
                          setDialogState(() {
                            _addressController.text = suggestion.fullAddress ?? '';
                            if (_locationNameController.text.trim().isEmpty) {
                              _locationNameController.text = suggestion.name;
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contactInfoController,
                        decoration: const InputDecoration(labelText: 'איש קשר / טלפון', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reservationDetailsController,
                        decoration: const InputDecoration(labelText: 'פרטי הזמנה', border: OutlineInputBorder(), prefixIcon: Icon(Icons.assignment)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _websiteController,
                        decoration: const InputDecoration(labelText: 'אתר אינטרנט', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link)),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _costController,
                        decoration: const InputDecoration(labelText: 'עלות (₪)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.money)),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'הערות נוספות', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isNotEmpty && _selectedDate != null && _selectedTime != null) {
                        final newOrUpdatedActivity = Activity(
                          name: name,
                          description: _descriptionController.text.trim(),
                          date: _selectedDate!,
                          startTime: _selectedTime!,
                          isDone: existingActivity?.isDone ?? false,
                          locationName: _locationNameController.text.trim().isEmpty ? null : _locationNameController.text.trim(),
                          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
                          contactInfo: _contactInfoController.text.trim().isEmpty ? null : _contactInfoController.text.trim(),
                          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                          reservationDetails: _reservationDetailsController.text.trim().isEmpty ? null : _reservationDetailsController.text.trim(),
                          website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
                          cost: double.tryParse(_costController.text.trim()),
                        );

                        setState(() {
                          if (existingActivity == null) {
                            _activities.add(newOrUpdatedActivity);
                          } else {
                            _activities[index!] = newOrUpdatedActivity;
                          }
                          _sortActivities();
                        });
                        _updateTripData();
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('אנא הזן שם פעילות, תאריך ושעה.')),
                        );
                      }
                    },
                    child: Text(existingActivity == null ? 'הוסף' : 'שמור'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      _nameController.dispose();
      _descriptionController.dispose();
      _locationNameController.dispose();
      _addressController.dispose();
      _contactInfoController.dispose();
      _notesController.dispose();
      _reservationDetailsController.dispose();
      _websiteController.dispose();
      _costController.dispose();
    });
  }

  // Function to launch Google Maps for navigation
  Future<void> _launchNavigation(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final double lat = locations.first.latitude;
        final double lng = locations.first.longitude;
        final String googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
        final Uri uri = Uri.parse(googleMapsUrl);
        if (await launcher.canLaunchUrl(uri)) {
          await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('לא ניתן לפתוח את מפות Google לניווט.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('לא ניתן למצוא קואורדינטות עבור הכתובת הזו.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בניווט: $e')),
      );
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isLink = false, String? navigationAddress}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                ),
                GestureDetector(
                  onTap: isLink && value.isNotEmpty ? () => launcher.launchUrl(Uri.parse(value), mode: launcher.LaunchMode.externalApplication) : null,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: isLink ? Colors.blue : Colors.black87,
                      decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (navigationAddress != null && navigationAddress.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.navigation, color: Colors.green),
              onPressed: () => _launchNavigation(navigationAddress),
              tooltip: 'נווט ליעד',
            ),
        ],
      ),
    );
  }

  void _showActivityDetailsDialog(Activity activity) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(activity.name),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.calendar_today, 'תאריך', DateFormat('dd/MM/yyyy').format(activity.date)),
                  _buildDetailRow(Icons.access_time, 'שעה', activity.startTime.format(context)),
                  if (activity.description != null && activity.description!.isNotEmpty)
                    _buildDetailRow(Icons.description, 'תיאור', activity.description!),
                  if (activity.locationName != null && activity.locationName!.isNotEmpty)
                    _buildDetailRow(Icons.place, 'שם המקום', activity.locationName!),
                  if (activity.address != null && activity.address!.isNotEmpty)
                  // Pass the address to _buildDetailRow for navigation button
                    _buildDetailRow(Icons.location_on, 'כתובת', activity.address!, navigationAddress: activity.address!),
                  if (activity.contactInfo != null && activity.contactInfo!.isNotEmpty)
                    _buildDetailRow(Icons.phone, 'איש קשר / טלפון', activity.contactInfo!),
                  if (activity.reservationDetails != null && activity.reservationDetails!.isNotEmpty)
                    _buildDetailRow(Icons.assignment, 'פרטי הזמנה', activity.reservationDetails!),
                  if (activity.website != null && activity.website!.isNotEmpty)
                    _buildDetailRow(Icons.link, 'אתר אינטרנט', activity.website!, isLink: true),
                  if (activity.cost != null)
                    _buildDetailRow(Icons.money, 'עלות', '${activity.cost!.toStringAsFixed(2)} ₪'),
                  if (activity.notes != null && activity.notes!.isNotEmpty)
                    _buildDetailRow(Icons.notes, 'הערות', activity.notes!),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('סגור')),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('פעילויות: ${widget.trip.name}'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _sortActivities();
          });
        },
        child: _activities.isEmpty
            ? const Center(child: Text('אין פעילויות לטיול זה. לחץ על + להוספה.'))
            : ListView.builder(
          itemCount: _activities.length,
          itemBuilder: (context, index) {
            final activity = _activities[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: InkWell(
                onTap: () => _showActivityDetailsDialog(activity),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CheckboxListTile(
                    title: Text(
                      activity.name,
                      style: TextStyle(
                        decoration: activity.isDone ? TextDecoration.lineThrough : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(activity.date)} - ${activity.startTime.format(context)}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                        if (activity.locationName != null && activity.locationName!.isNotEmpty)
                          Text(
                            'מיקום: ${activity.locationName!}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        if (activity.description != null && activity.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              activity.description!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (activity.address != null && activity.address!.isNotEmpty) // Display address in subtitle as well
                          Text(
                            'כתובת: ${activity.address!}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    value: activity.isDone,
                    onChanged: (bool? value) {
                      setState(() {
                        activity.isDone = value ?? false;
                      });
                      _updateTripData();
                    },
                    secondary: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (activity.address != null && activity.address!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.navigation, color: Colors.green),
                            onPressed: () => _launchNavigation(activity.address!),
                            tooltip: 'נווט ליעד',
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueGrey),
                          onPressed: () => _showActivityDialog(existingActivity: activity, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmationDialog(index),
                        ),
                      ],
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActivityDialog(),
        child: const Icon(Icons.add),
        tooltip: 'הוספת פעילות',
      ),
    );
  }
}