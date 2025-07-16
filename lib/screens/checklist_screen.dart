import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // For Lottie animations
import 'package:flutter_animate/flutter_animate.dart'; // For Flutter Animate
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // For swipe actions
import 'package:uuid/uuid.dart'; // Add uuid dependency to pubspec.yaml
import '../models/checklist_item_model.dart'; // Make sure this model is updated as well

class ChecklistScreen extends StatefulWidget {
  final String tripId;

  const ChecklistScreen({
    super.key,
    required this.tripId,
  });

  @override
  _ChecklistScreenState createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final List<ChecklistItem> _checklistItems = [];
  final TextEditingController _newItemController = TextEditingController();
  late String _currentStorageKey; // Storage key specific to the trip

  @override
  void initState() {
    super.initState();
    _currentStorageKey = 'checklist_for_trip_${widget.tripId}';
    _loadChecklist();
  }

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  // --- Data Loading & Saving ---
  Future<void> _loadChecklist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? checklistJson = prefs.getString(_currentStorageKey);

      if (checklistJson != null) {
        final List<dynamic> decodedList = jsonDecode(checklistJson);
        setState(() {
          _checklistItems.clear();
          _checklistItems.addAll(decodedList.map((itemJson) => ChecklistItem.fromJson(itemJson as Map<String, dynamic>)).toList());
        });
      }
    } catch (e) {
      _showSnackBar('שגיאה בטעינת הרשימה. נסה שוב מאוחר יותר.', isError: true);
    }
  }

  Future<void> _saveChecklist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList = _checklistItems.map((item) => item.toJson()).toList();
      await prefs.setString(_currentStorageKey, jsonEncode(jsonList));
    } catch (e) {
      _showSnackBar('שגיאה בשמירת הרשימה. נסה שוב מאוחר יותר.', isError: true);
    }
  }

  // --- Item Management ---
  void _addItem() {
    final newItemDescription = _newItemController.text.trim();
    if (newItemDescription.isNotEmpty) {
      setState(() {
        _checklistItems.insert(0, ChecklistItem(description: newItemDescription)); // Add to top
      });
      _newItemController.clear();
      FocusScope.of(context).unfocus(); // Dismiss keyboard
      _saveChecklist();
      _showSnackBar('משימה "${newItemDescription}" נוספה בהצלחה!');
    } else {
      _showSnackBar('אנא הזן תיאור למשימה.', isError: true);
    }
  }

  void _toggleItemDone(int index) {
    setState(() {
      _checklistItems[index].isDone = !_checklistItems[index].isDone;
      // Optional: Move completed items to the bottom or sort them
      _sortChecklist();
    });
    _saveChecklist();
    _showSnackBar(_checklistItems[index].isDone ? 'משימה הושלמה!' : 'משימה סומנה כלא הושלמה.');
  }

  void _sortChecklist() {
    _checklistItems.sort((a, b) {
      if (a.isDone == b.isDone) {
        return 0; // Maintain original order if status is same
      }
      return a.isDone ? 1 : -1; // Completed items go to the end
    });
  }

  Future<void> _deleteItem(int index) async {
    final deletedItem = _checklistItems[index];
    final bool? confirm = await _showConfirmationDialog(
      title: 'מחיקת משימה',
      content: 'האם אתה בטוח שברצונך למחוק את המשימה "${deletedItem.description}"?',
      confirmButtonText: 'מחק',
      confirmButtonColor: Colors.red,
    );

    if (confirm == true) {
      setState(() {
        _checklistItems.removeAt(index);
      });
      _saveChecklist();
      _showSnackBar('המשימה "${deletedItem.description}" נמחקה בהצלחה.');
    }
  }

  // --- UI Helpers ---
  InputDecoration _inputDecoration(String labelText, IconData icon, ColorScheme colorScheme) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.7)),
      ),
      prefixIcon: Icon(icon, color: colorScheme.primary),
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textDirection: TextDirection.rtl), // Ensure RTL for snackbar text
          backgroundColor: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmButtonText,
    Color? confirmButtonColor,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(content),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('ביטול', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(confirmButtonText, style: TextStyle(color: confirmButtonColor ?? Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Animate(
                effects: [
                  FadeEffect(duration: 1000.ms),
                  SlideEffect(begin: const Offset(0, 0.1)),
                ],
                child: Lottie.asset(
                  'assets/lottie_empty_checklist.json',
                  height: 250,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'אין עדיין משימות ברשימה זו',
                style: (Theme.of(context).textTheme.headlineSmall ??
                    const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold))
                    .copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'הוסף משימות כמו: "לארוז דרכון", "להזמין רכב", "לקנות קרם הגנה" ועוד!',
                style: (Theme.of(context).textTheme.bodyLarge ?? const TextStyle(fontSize: 16.0)).copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- Build Methods ---
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('רשימת משימות'),
        centerTitle: true,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        automaticallyImplyLeading: false, // מונע הופעת כפתור חזור אוטומטי
        leading: IconButton( // כפתור חזור (בחזית, צד ימין ב-RTL)
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), // צבע לבן לאייקון
          tooltip: 'חזרה למסך הבית',
          onPressed: () {
            Navigator.pop(context); // חוזר למסך הקודם (HomeScreen)
          },
        ),
        actions: [
          IconButton( // כפתור בית (בצד שמאל ב-RTL)
            icon: const Icon(Icons.home_outlined, color: Colors.white), // צבע לבן לאייקון
            tooltip: 'למסך הראשי של הטיולים',
            onPressed: () {
              // מנקה את מחסנית הניווט וחוזר למסך רשימת הטיולים
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
        backgroundColor: colorScheme.primary, // צבע הרקע של ה-AppBar
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: _checklistItems.isEmpty
                  ? _buildEmptyState(colorScheme)
                  : RefreshIndicator(
                onRefresh: _loadChecklist,
                color: colorScheme.primary,
                backgroundColor: colorScheme.surface,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // מרווח לשורת הקלט
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _checklistItems.length,
                  itemBuilder: (context, index) {
                    final item = _checklistItems[index];
                    return Animate(
                      effects: [
                        FadeEffect(duration: 300.ms, delay: (index * 50).ms),
                        SlideEffect(begin: const Offset(0.1, 0), end: Offset.zero, duration: 300.ms, delay: (index * 50).ms, curve: Curves.easeOut),
                      ],
                      child: Slidable(
                        key: ValueKey(item.id),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (context) => _deleteItem(index),
                              backgroundColor: colorScheme.error,
                              foregroundColor: colorScheme.onError,
                              icon: Icons.delete_forever,
                              label: 'מחק',
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ],
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: InkWell(
                            onTap: () => _toggleItemDone(index),
                            borderRadius: BorderRadius.circular(12.0),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: item.isDone,
                                    onChanged: (bool? newValue) {
                                      _toggleItemDone(index);
                                    },
                                    activeColor: colorScheme.tertiary,
                                    checkColor: colorScheme.onTertiary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Text(
                                        item.description,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                          decoration: item.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                                          color: item.isDone ? colorScheme.onSurface.withOpacity(0.6) : colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // שורת ההזנה - למטה!
            SafeArea(
              minimum: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newItemController,
                      decoration: _inputDecoration('הוסף משימה חדשה', Icons.playlist_add_check, colorScheme),
                      onSubmitted: (_) => _addItem(),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: _addItem,
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                    elevation: 4,
                    tooltip: 'הוסף משימה',
                    child: const Icon(Icons.add),
                  ).animate().scale(duration: 300.ms, curve: Curves.easeOut),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}