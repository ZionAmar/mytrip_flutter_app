// lib/screens/checklist_screen.dart
import 'package:flutter/material.dart';
import '../models/checklist_item_model.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  _ChecklistScreenState createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final List<ChecklistItem> _checklistItems = [];
  final TextEditingController _newItemController = TextEditingController();

  static const String _storageKey = 'my_general_checklist_items';

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  Future<void> _loadChecklist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? checklistJson = prefs.getString(_storageKey);

      if (checklistJson != null) {
        final List<dynamic> decodedList = jsonDecode(checklistJson);
        setState(() {
          _checklistItems.clear();
          _checklistItems.addAll(decodedList.map((itemJson) => ChecklistItem.fromJson(itemJson as Map<String, dynamic>)).toList());
        });
        print('Checklist loaded successfully.');
      } else {
        print('No checklist found in storage. Initializing with defaults or empty.');
      }
    } catch (e) {
      print('Error loading checklist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בטעינת הרשימה.')),
      );
    }
  }

  Future<void> _saveChecklist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList = _checklistItems.map((item) => item.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
      print('Checklist saved successfully.');
    } catch (e) {
      print('Error saving checklist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בשמירת הרשימה.')),
      );
    }
  }

  void _addItem() {
    final newItemDescription = _newItemController.text.trim();
    if (newItemDescription.isNotEmpty) {
      setState(() {
        _checklistItems.add(ChecklistItem(description: newItemDescription));
      });
      _newItemController.clear();
      FocusScope.of(context).unfocus();
      _saveChecklist();
    }
  }

  void _toggleItemDone(int index) {
    setState(() {
      _checklistItems[index].isDone = !_checklistItems[index].isDone;
    });
    _saveChecklist();
  }

  // --- NEW: Function to confirm deletion ---
  Future<void> _confirmAndDeleteItem(int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('מחיקת משימה'),
          content: Text('האם אתה בטוח שברצונך למחוק את המשימה "${_checklistItems[index].description}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // User cancels
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // User confirms
              child: const Text('מחק'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirm == true) { // Only delete if user confirmed
      _deleteItem(index); // Call the actual deletion function
    }
  }

  // Actual deletion function (now private, called only after confirmation)
  void _deleteItem(int index) {
    setState(() {
      _checklistItems.removeAt(index);
    });
    _saveChecklist();
    ScaffoldMessenger.of(context).showSnackBar( // Optional: show confirmation snackbar
      SnackBar(content: Text('המשימה נמחקה בהצלחה.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('רשימת משימות לטיול'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newItemController,
                    decoration: const InputDecoration(
                      labelText: 'הוסף משימה חדשה',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 36, color: Colors.teal),
                  onPressed: _addItem,
                ),
              ],
            ),
          ),
          Expanded(
            child: _checklistItems.isEmpty
                ? Center(
              child: Text(
                'אין עדיין משימות ברשימה.\nהוסף את המשימה הראשונה שלך!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadChecklist,
              color: Colors.teal,
              child: ListView.builder(
                itemCount: _checklistItems.length,
                itemBuilder: (context, index) {
                  final item = _checklistItems[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      title: Text(
                        item.description,
                        style: TextStyle(
                          decoration: item.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                          color: item.isDone ? Colors.grey[600] : Colors.black87,
                        ),
                      ),
                      leading: Checkbox(
                        value: item.isDone,
                        onChanged: (bool? newValue) {
                          _toggleItemDone(index);
                        },
                        activeColor: Colors.teal,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmAndDeleteItem(index), // <--- CHANGE: Call confirmation function
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}