import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For encoding/decoding List<String>

class ActivitiesScreen extends StatefulWidget {
  @override
  _ActivitiesScreenState createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  List<String> _activities = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActivities(); // Load from local storage when screen opens
  }

  // Load the activities from SharedPreferences
  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedList = prefs.getString('activities');
    if (storedList != null) {
      setState(() {
        _activities = List<String>.from(jsonDecode(storedList));
      });
    }
  }

  // Save the activities to SharedPreferences
  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('activities', jsonEncode(_activities));
  }

  void _showActivityDialog({String? existingText, int? index}) {
    _controller.text = existingText ?? '';

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              existingText == null ? 'Add Activity' : 'Edit Activity',
            ),
            content: TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: 'Activity name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final text = _controller.text.trim();
                  if (text.isNotEmpty) {
                    setState(() {
                      if (existingText == null) {
                        _activities.add(text);
                      } else {
                        _activities[index!] = text;
                      }
                    });
                    _saveActivities();
                  }
                  Navigator.pop(context);
                  _controller.clear();
                },
                child: Text(existingText == null ? 'Add' : 'Save'),
              ),
            ],
          ),
    );
  }

  void _deleteActivity(int index) {
    setState(() {
      _activities.removeAt(index);
    });
    _saveActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Activities')),
      body:
          _activities.isEmpty
              ? Center(child: Text('No activities yet. Tap + to add one.'))
              : ListView.builder(
                itemCount: _activities.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_activities[index]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed:
                              () => _showActivityDialog(
                                existingText: _activities[index],
                                index: index,
                              ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteActivity(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActivityDialog(),
        child: Icon(Icons.add),
        tooltip: 'Add Activity',
      ),
    );
  }
}
