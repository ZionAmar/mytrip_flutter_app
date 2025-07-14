import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/activity_model.dart';

class ActivitiesScreen extends StatefulWidget {
  @override
  _ActivitiesScreenState createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  List<Activity> _activities = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  void _sortActivities() {
    // שינוי: ממיין את הרשימה לפי התאריך המלא
    _activities.sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime));
  }

  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final String? activitiesString = prefs.getString('activities_list');
    if (activitiesString != null) {
      final List<dynamic> jsonList = jsonDecode(activitiesString);
      setState(() {
        _activities = jsonList.map((jsonItem) => Activity.fromJson(jsonItem)).toList();
        _sortActivities();
      });
    }
  }

  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
    _activities.map((activity) => activity.toJson()).toList();
    await prefs.setString('activities_list', jsonEncode(jsonList));
  }

  // שינוי: הוספנו דיאלוג לאישור מחיקה
  Future<void> _showDeleteConfirmationDialog(int index) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('אישור מחיקה'),
          content: Text('האם אתה בטוח שברצונך למחוק את הפעילות "${_activities[index].name}"?'),
          actions: <Widget>[
            TextButton(
              child: Text('ביטול'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('מחק', style: TextStyle(color: Colors.red)),
              onPressed: () {
                setState(() {
                  _activities.removeAt(index);
                });
                _saveActivities();
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
    final _descriptionController =
    TextEditingController(text: existingActivity?.description);

    DateTime? _selectedDate = existingActivity?.date;
    TimeOfDay? _selectedTime = existingActivity?.startTime;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> _pickDate() async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (pickedDate != null && pickedDate != _selectedDate) {
                setDialogState(() => _selectedDate = pickedDate);
              }
            }

            Future<void> _pickTime() async {
              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: _selectedTime ?? TimeOfDay.now(),
              );
              if (pickedTime != null && pickedTime != _selectedTime) {
                setDialogState(() => _selectedTime = pickedTime);
              }
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text(existingActivity == null ? 'הוספת פעילות' : 'עריכת פעילות'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: 'שם הפעילות'),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(labelText: 'תיאור (אופציונלי)'),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            icon: Icon(Icons.calendar_today),
                            label: Text(_selectedDate == null ? 'בחר תאריך' : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                            onPressed: _pickDate,
                          ),
                          TextButton.icon(
                            icon: Icon(Icons.access_time),
                            label: Text(_selectedTime == null ? 'בחר שעה' : _selectedTime!.format(context)),
                            onPressed: _pickTime,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
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
                        );

                        setState(() {
                          if (existingActivity == null) {
                            _activities.add(newOrUpdatedActivity);
                          } else {
                            _activities[index!] = newOrUpdatedActivity;
                          }
                          _sortActivities(); // מיון לאחר הוספה/עריכה
                        });
                        _saveActivities();
                        Navigator.pop(context);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('פעילויות')),
      // שינוי: הוספנו RefreshIndicator
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _loadActivities,
        child: _activities.isEmpty
            ? Center(child: Text('אין פעילויות. לחץ על + להוספה.'))
            : ListView.builder(
          itemCount: _activities.length,
          itemBuilder: (context, index) {
            final activity = _activities[index];
            return CheckboxListTile(
              title: Text(
                activity.name,
                style: TextStyle(decoration: activity.isDone ? TextDecoration.lineThrough : null),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(activity.date)} - ${activity.startTime.format(context)}',
                  ),
                  // הצג את התיאור רק אם הוא לא ריק
                  if (activity.description != null && activity.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        activity.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
              value: activity.isDone,
              onChanged: (bool? value) {
                setState(() {
                  activity.isDone = value ?? false;
                });
                _saveActivities();
              },
              // שינוי: ה-secondary הוא כעת Row עם שני כפתורים
              secondary: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blueGrey),
                    tooltip: 'עריכת פעילות',
                    onPressed: () => _showActivityDialog(existingActivity: activity, index: index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    tooltip: 'מחיקת פעילות',
                    // שינוי: קריאה לדיאלוג האישור
                    onPressed: () => _showDeleteConfirmationDialog(index),
                  ),
                ],
              ),
              controlAffinity: ListTileControlAffinity.leading,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActivityDialog(),
        child: Icon(Icons.add),
        tooltip: 'הוספת פעילות',
      ),
    );
  }
}