// lib/screens/activities_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:flutter_typeahead/flutter_typeahead.dart' as typeAhead; // שימוש בכינוי
import 'package:geocoding/geocoding.dart';

import '../models/trip_model.dart';
import '../models/activity_model.dart';
import '../services/places_service.dart'; // וודא שהנתיב נכון

// --- START: AddEditActivityForm Widget ---
// This widget handles the creation and editing of activities.
// It includes robust keyboard handling using an internal Scaffold.
class AddEditActivityForm extends StatefulWidget {
  final Trip trip;
  final Activity? existingActivity;
  final Function(Activity) onSave;

  const AddEditActivityForm({
    Key? key,
    required this.trip,
    this.existingActivity,
    required this.onSave,
  }) : super(key: key);

  @override
  _AddEditActivityFormState createState() => _AddEditActivityFormState();
}

class _AddEditActivityFormState extends State<AddEditActivityForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationNameController;
  late TextEditingController _addressController;
  late TextEditingController _contactInfoController;
  late TextEditingController _notesController;
  late TextEditingController _reservationDetailsController;
  late TextEditingController _websiteController;
  late TextEditingController _costController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // IMPORTANT: Replace 'YOUR_GOOGLE_PLACES_API_KEY' with your actual key!
  final PlacesService _placesService = PlacesService('e91e6d0030124c03b3c5feec6722eccc');

  bool get _isEditing => widget.existingActivity != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingActivity?.name);
    _descriptionController = TextEditingController(text: widget.existingActivity?.description);
    _locationNameController = TextEditingController(text: widget.existingActivity?.locationName);
    _addressController = TextEditingController(text: widget.existingActivity?.address);
    _contactInfoController = TextEditingController(text: widget.existingActivity?.contactInfo);
    _notesController = TextEditingController(text: widget.existingActivity?.notes);
    _reservationDetailsController = TextEditingController(text: widget.existingActivity?.reservationDetails);
    _websiteController = TextEditingController(text: widget.existingActivity?.website);
    _costController = TextEditingController(text: widget.existingActivity?.cost?.toStringAsFixed(0));

    _selectedDate = widget.existingActivity?.date;
    _selectedTime = widget.existingActivity?.startTime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationNameController.dispose();
    _addressController.dispose();
    _contactInfoController.dispose();
    _notesController.dispose();
    _reservationDetailsController.dispose();
    _websiteController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? widget.trip.startDate,
      firstDate: widget.trip.startDate,
      lastDate: widget.trip.endDate,
      locale: const Locale('he', 'IL'), // Ensure Hebrew localization if relevant
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Localizations.override(
          context: context,
          locale: const Locale('he', 'IL'), // Ensure Hebrew localization if relevant
          child: child,
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  InputDecoration _inputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // More rounded corners
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.6)), // Lighter color
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
      ),
      prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)), // Icon color
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16), // Increased internal padding
      filled: true,
      fillColor: Colors.grey.shade50, // Light background
    );
  }

  void _saveForm() {
    if (!mounted) return;

    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('אנא הזן תאריך ושעה לפעילות.')),
          );
        }
        return;
      }

      final newOrUpdatedActivity = Activity(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        date: _selectedDate!,
        startTime: _selectedTime!,
        isDone: widget.existingActivity?.isDone ?? false,
        locationName: _locationNameController.text.trim().isEmpty ? null : _locationNameController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        contactInfo: _contactInfoController.text.trim().isEmpty ? null : _contactInfoController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        reservationDetails: _reservationDetailsController.text.trim().isEmpty ? null : _reservationDetailsController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        cost: double.tryParse(_costController.text.trim()),
      );
      widget.onSave(newOrUpdatedActivity);
      Navigator.pop(context); // Close the sheet
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('אנא מלא את השדות הנדרשים.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Total screen height, minus system areas (status bar, navigation bar)
    final double screenHeight = MediaQuery.of(context).size.height;

    // Max height provided for the Modal Sheet.
    // Leaves enough space for the keyboard and keeps the top part of the screen visible.
    final double desiredHeight = screenHeight * 0.9; // Occupy 90% of screen height

    return Container(
      // The height of the outer Container for the Bottom Sheet.
      // Important to define a sufficient maximum height.
      // The inner Scaffold will handle keyboard padding.
      height: desiredHeight,
      // Background color and border styling
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor, // General app background color
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [ // Gentle shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect( // Clip for rounded corners
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Scaffold( // Wrapping with Scaffold is the most effective solution for keyboard in Bottom Sheet
          resizeToAvoidBottomInset: true, // This is key for automatic keyboard handling
          backgroundColor: Colors.transparent, // Transparent so Container's color appears
          body: Directionality(
            textDirection: TextDirection.rtl, // RTL text direction
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0), // Uniform internal padding
              child: Column(
                mainAxisSize: MainAxisSize.max, // Column will take all available height
                children: [
                  // Sheet Title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      _isEditing ? 'עריכת פעילות' : 'הוספת פעילות',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor), // Separator line
                  const SizedBox(height: 20), // Spacing

                  // Scrollable form body
                  Expanded( // Expanded makes SingleChildScrollView take all remaining height
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(), // Smoother scrolling
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: _inputDecoration('שם הפעילות', Icons.push_pin),
                              validator: (value) => (value == null || value.isEmpty) ? 'שם פעילות נדרש' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: _inputDecoration('תיאור (אופציונלי)', Icons.description),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.calendar_today),
                                    label: Text(_selectedDate == null ? 'בחר תאריך' : DateFormat('dd/MM/yyyy', 'he_IL').format(_selectedDate!)),
                                    onPressed: _pickDate,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      backgroundColor: Theme.of(context).colorScheme.surface, // Gentle background
                                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.access_time),
                                    label: Text(_selectedTime == null ? 'בחר שעה' : _selectedTime!.format(context)),
                                    onPressed: _pickTime,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      backgroundColor: Theme.of(context).colorScheme.surface,
                                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            typeAhead.TypeAheadField<Place>(
                              controller: _locationNameController,
                              builder: (context, controller, focusNode) {
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: _inputDecoration('שם המקום', Icons.place),
                                );
                              },
                              suggestionsCallback: (pattern) async {
                                if (pattern.length < 2) return [];
                                return await _placesService.searchPlaces(pattern);
                              },
                              itemBuilder: (context, suggestion) {
                                return ListTile(
                                  title: Text(suggestion.name),
                                  subtitle: Text(suggestion.fullAddress ?? ''),
                                );
                              },
                              onSelected: (suggestion) {
                                setState(() {
                                  _locationNameController.text = suggestion.name;
                                  _addressController.text = suggestion.fullAddress ?? '';
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              decoration: _inputDecoration('כתובת (מלאה, אופציונלי)', Icons.location_on),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _contactInfoController,
                              decoration: _inputDecoration('איש קשר / טלפון', Icons.phone),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _reservationDetailsController,
                              decoration: _inputDecoration('פרטי הזמנה', Icons.assignment),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _websiteController,
                              decoration: _inputDecoration('אתר אינטרנט', Icons.link),
                              keyboardType: TextInputType.url,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _costController,
                              decoration: _inputDecoration('עלות (₪)', Icons.money),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              decoration: _inputDecoration('הערות נוספות', Icons.notes),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 10), // Small spacing at the end of form fields
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Action buttons remain always visible at the bottom of the Sheet
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0), // Spacing from form above
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error, // Red for cancel button
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          child: const Text('ביטול'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _saveForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary, // Primary background color
                            foregroundColor: Theme.of(context).colorScheme.onPrimary, // Light text color
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          child: Text(_isEditing ? 'שמור' : 'הוסף'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// --- END: AddEditActivityForm Widget ---

// --- START: ActivitiesScreen (Main Screen) ---
// This widget displays the list of activities, grouped by day,
// and supports pull-to-refresh.
class ActivitiesScreen extends StatefulWidget {
  final Trip trip;
  final Function(Trip) onTripUpdated;

  const ActivitiesScreen({
    Key? key,
    required this.trip,
    required this.onTripUpdated,
  }) : super(key: key);

  @override
  _ActivitiesScreenState createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  late Trip _currentTrip;
  Map<DateTime, List<Activity>> _groupedActivities = {};

  @override
  void initState() {
    super.initState();
    _currentTrip = widget.trip;
    _groupAndSortActivities();
  }

  // --- Data Management Methods ---
  // This function can be async if it loads data from DB/API.
  // Currently, it just re-sorts the existing in-memory data.
  Future<void> _groupAndSortActivities() async {
    // If you fetch data from DB/API, perform the fetch here.
    // Example: await _someService.fetchActivitiesForTrip(_currentTrip.id);
    Map<DateTime, List<Activity>> data = {};
    for (var activity in _currentTrip.activities) {
      final date = DateUtils.dateOnly(activity.date);
      if (data[date] == null) {
        data[date] = [];
      }
      data[date]!.add(activity);
    }
    data.forEach((key, value) {
      value.sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime));
    });
    _groupedActivities = Map.fromEntries(
        data.entries.toList()..sort((e1, e2) => e1.key.compareTo(e2.key)));

    // Ensure the State is still mounted before calling setState
    if (mounted) {
      setState(() {});
    }
  }

  void _updateAndSaveTrip() {
    _currentTrip.activities = _groupedActivities.values.expand((list) => list).toList();
    widget.onTripUpdated(_currentTrip);
    _groupAndSortActivities(); // Call re-sort and re-group after changes
  }

  void _deleteActivity(Activity activityToDelete) {
    setState(() {
      final dayKey = DateUtils.dateOnly(activityToDelete.date);
      _groupedActivities[dayKey]?.remove(activityToDelete);
      if (_groupedActivities[dayKey]?.isEmpty ?? false) {
        _groupedActivities.remove(dayKey);
      }
    });
    _updateAndSaveTrip();
  }

  // --- UI Building Methods ---
  @override
  Widget build(BuildContext context) {
    final activityDays = _groupedActivities.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('מסלול: ${widget.trip.name}'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary, // AppBar color
        foregroundColor: Theme.of(context).colorScheme.onPrimary, // Text/icon color
        elevation: 0, // Remove shadow
        automaticallyImplyLeading: false, // מונע הופעת כפתור חזור אוטומטי
        leading: IconButton( // כפתור חזור (בחזית, צד ימין ב-RTL)
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          tooltip: 'חזרה למסך הבית',
          onPressed: () {
            Navigator.pop(context); // חוזר למסך הקודם (HomeScreen)
          },
        ),
        actions: [
          IconButton( // כפתור בית (בצד שמאל ב-RTL)
            icon: const Icon(Icons.home_outlined, color: Colors.white),
            tooltip: 'למסך הראשי של הטיולים',
            onPressed: () {
              // מנקה את מחסנית הניווט וחוזר למסך רשימת הטיולים
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          // You can add a manual refresh button in the AppBar if desired, in addition to Pull-to-Refresh
          // IconButton(
          //   icon: const Icon(Icons.refresh),
          //   onPressed: _groupAndSortActivities,
          //   tooltip: 'רענן פעילויות',
          // ),
        ],
      ),
      body: RefreshIndicator( // Add RefreshIndicator
        onRefresh: _groupAndSortActivities, // Calls the refresh function
        color: Theme.of(context).colorScheme.secondary, // Refresh icon color
        backgroundColor: Theme.of(context).colorScheme.surface, // Background color of the indicator
        child: _currentTrip.activities.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          // Important for RefreshIndicator with small content:
          // alwaysScrollableScrollPhysics ensures the scroll view can always be pulled
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          itemCount: activityDays.length,
          itemBuilder: (context, index) {
            final day = activityDays[index];
            final activitiesForDay = _groupedActivities[day]!;
            final dayNumber = day.difference(DateUtils.dateOnly(widget.trip.startDate)).inDays + 1;

            return _buildDaySection(day, dayNumber, activitiesForDay)
                .animate()
                .fadeIn(duration: 600.ms, delay: (150 * index).ms);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditActivityDialog(),
        backgroundColor: Theme.of(context).colorScheme.secondary, // Button color
        foregroundColor: Theme.of(context).colorScheme.onSecondary, // Icon color
        child: const Icon(Icons.add),
        tooltip: 'הוסף פעילות',
      ),
    );
  }

  Widget _buildDaySection(DateTime day, int dayNumber, List<Activity> activities) {
    final completedActivities = activities.where((a) => a.isDone).length;
    final totalActivities = activities.length;
    final progress = totalActivities > 0 ? completedActivities / totalActivities : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 6, // Deeper shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column( // Wrap in Column to add progress bar below ExpansionTile
        children: [
          ExpansionTile(
            key: PageStorageKey(day),
            initiallyExpanded: false, // <--- שינוי: ברירת מחדל מקופלת
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(
              'יום $dayNumber - ${DateFormat('EEEE, d MMM', 'he_IL').format(day)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20, // Larger font
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            trailing: Chip( // Small chip with activity count
              label: Text('$completedActivities/$totalActivities', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              backgroundColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
              labelStyle: TextStyle(color: Theme.of(context).colorScheme.tertiary),
            ),
            children: [
              // Timeline structure
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Stack(
                  children: [
                    // Vertical timeline line
                    Positioned(
                      left: 35,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 2, color: Colors.grey.shade300),
                    ),
                    Column(
                      children: activities.map((activity) {
                        return _buildActivityItem(activity) // This method is now defined!
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideX(begin: -0.1, curve: Curves.easeOut);
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10), // Spacing after activities
            ],
          ),
          // Day progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: progress == 1.0 ? Colors.green.shade600 : Theme.of(context).colorScheme.tertiary, // Green when completed
              minHeight: 8,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }

  // --- RESTORED: _buildActivityItem method ---
  Widget _buildActivityItem(Activity activity) {
    return InkWell(
      onTap: () => _showActivityDetailsDialog(activity),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time and Checkbox Column
            SizedBox(
              width: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.Hm().format(activity.fullDateTime),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: activity.isDone,
                      onChanged: (value) {
                        setState(() {
                          activity.isDone = value ?? false;
                        });
                        _updateAndSaveTrip();
                      },
                      visualDensity: VisualDensity.compact,
                      activeColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12), // Space between time/checkbox and content
            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: activity.isDone ? Colors.grey.shade500 : Colors.black87,
                      decoration: activity.isDone ? TextDecoration.lineThrough : null,
                      decorationThickness: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (activity.locationName != null && activity.locationName!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            activity.locationName!,
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (activity.cost != null && activity.cost! > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Chip(
                        label: Text('${activity.cost!.toStringAsFixed(0)} ₪'),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.teal.shade100,
                        labelStyle: TextStyle(color: Colors.teal.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  if (activity.description != null && activity.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        activity.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1, // Shortened description
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- END RESTORED: _buildActivityItem method ---


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/travel_animation.json',
            height: 250,
            repeat: true,
            animate: true,
          ),
          const SizedBox(height: 20),
          Text(
            'אין עדיין פעילויות',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'לחצו על כפתור הפלוס כדי להוסיף את הפעילות הראשונה למסלול שלכם',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // --- Dialogs and Navigation ---
  void _showActivityDetailsDialog(Activity activity) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Rounded corners for dialog
            title: Text(
              activity.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  _buildDetailRow(Icons.calendar_today, "תאריך", DateFormat('dd/MM/yyyy', 'he_IL').format(activity.date)),
                  _buildDetailRow(Icons.access_time, "שעה", activity.startTime.format(context)),
                  if (activity.description != null && activity.description!.isNotEmpty)
                    _buildDetailRow(Icons.description, "תיאור", activity.description!),
                  _buildDetailRow(Icons.place, "שם המקום", activity.locationName ?? "לא צוין"),
                  _buildDetailRow(Icons.location_on, "כתובת", activity.address ?? "לא צוין", navigationAddress: activity.address),
                  if (activity.contactInfo != null && activity.contactInfo!.isNotEmpty)
                    _buildDetailRow(Icons.phone, "איש קשר", activity.contactInfo!),
                  if (activity.cost != null && activity.cost! > 0)
                    _buildDetailRow(Icons.money, "עלות", '${activity.cost!.toStringAsFixed(2)} ₪'),
                  if (activity.reservationDetails != null && activity.reservationDetails!.isNotEmpty)
                    _buildDetailRow(Icons.confirmation_number, "פרטי הזמנה", activity.reservationDetails!),
                  if (activity.website != null && activity.website!.isNotEmpty)
                    _buildDetailRow(Icons.link, "אתר אינטרנט", activity.website!, isLink: true),
                  if (activity.notes != null && activity.notes!.isNotEmpty)
                    _buildDetailRow(Icons.note_alt, "הערות", activity.notes!),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.all(15), // Padding for buttons
            actions: [
              TextButton.icon(
                icon: Icon(Icons.delete, color: Colors.red.shade600),
                label: Text('מחק', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).pop(); // Close details dialog
                  _showDeleteConfirmationDialog(activity);
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.edit, color: Colors.blue),
                label: const Text('ערוך', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).pop(); // Close details dialog
                  _showAddEditActivityDialog(existingActivity: activity);
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('סגור', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(Activity activity) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('אישור מחיקה', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('האם למחוק את הפעילות "${activity.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('ביטול', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('מחק', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () {
                _deleteActivity(activity);
                Navigator.of(context).pop(); // Close delete confirmation dialog
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isLink = false, String? navigationAddress}) {
    final uri = isLink ? Uri.tryParse(value) : null;
    final canLaunch = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary), // Larger icon
          const SizedBox(width: 15), // More spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)), // Bold label
                const SizedBox(height: 4),
                InkWell(
                  onTap: canLaunch ? () => launcher.launchUrl(uri!, mode: launcher.LaunchMode.externalApplication) : null,
                  child: Text(
                    value,
                    style: TextStyle(
                        fontSize: 17, // Larger font
                        color: canLaunch ? Colors.blue.shade800 : Theme.of(context).colorScheme.onSurface, // Blue for links
                        decoration: canLaunch ? TextDecoration.underline : null),
                  ),
                ),
              ],
            ),
          ),
          if (navigationAddress != null && navigationAddress.isNotEmpty)
            IconButton(
              icon: Icon(Icons.navigation, color: Colors.green.shade600, size: 26), // Larger navigation icon
              onPressed: () async {
                await _launchNavigation(navigationAddress);
              },
              tooltip: 'נווט ליעד',
            ),
        ],
      ),
    );
  }

  Future<void> _launchNavigation(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        // Direct Google Maps navigation using address
        final Uri uri = Uri.parse('google.navigation:q=${Uri.encodeComponent(address)}');
        if (await launcher.canLaunchUrl(uri)) {
          await launcher.launchUrl(uri, mode: launcher.LaunchMode.externalApplication);
        } else {
          // Fallback to general search if direct navigation fails (less precise but more likely to work)
          final Uri fallbackUri = Uri.parse('https://maps.google.com/?q=${Uri.encodeComponent(address)}'); // Corrected Google Maps URL
          if (mounted) { // Ensure mounted before using context
            if (await launcher.canLaunchUrl(fallbackUri)) {
              await launcher.launchUrl(fallbackUri, mode: launcher.LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('לא ניתן לפתוח מפות לניווט.')),
              );
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('לא ניתן למצוא קואורדינטות עבור הכתובת הזו.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בניווט: $e')),
        );
      }
    }
  }

  void _showAddEditActivityDialog({Activity? existingActivity}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the sheet to take full height and adjust for keyboard
      builder: (BuildContext context) {
        return AddEditActivityForm(
          trip: _currentTrip,
          existingActivity: existingActivity,
          onSave: (activity) {
            setState(() {
              if (existingActivity == null) {
                final newDayKey = DateUtils.dateOnly(activity.date);
                _groupedActivities[newDayKey] ??= [];
                _groupedActivities[newDayKey]!.add(activity);
              } else {
                final oldDayKey = DateUtils.dateOnly(existingActivity.date);
                _groupedActivities[oldDayKey]?.remove(existingActivity);
                if (_groupedActivities[oldDayKey]?.isEmpty ?? false) {
                  _groupedActivities.remove(oldDayKey);
                }

                final newDayKey = DateUtils.dateOnly(activity.date);
                _groupedActivities[newDayKey] ??= [];
                _groupedActivities[newDayKey]!.add(activity);
              }
            });
            _updateAndSaveTrip();
          },
        );
      },
    );
  }
}