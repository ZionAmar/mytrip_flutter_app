// lib/models/checklist_item_model.dart
import 'package:uuid/uuid.dart'; // Make sure to add this dependency to your pubspec.yaml

class ChecklistItem {
  final String id; // <--- NEW: Unique ID for each item
  String description; // תיאור המשימה (לדוגמה: "לארוז בגדים חמים")
  bool isDone;        // האם המשימה בוצעה (true/false)

  ChecklistItem({
    String? id, // <--- NEW: Optional, generate if not provided
    required this.description,
    this.isDone = false, // ברירת מחדל: המשימה לא בוצעה
  }) : id = id ?? const Uuid().v4(); // <--- NEW: Generate unique ID if not provided

  // שיטה להמרת אובייקט ChecklistItem למפה (Map) המתאימה ל-JSON.
  // זה חשוב לשמירת הנתונים.
  @override // Good practice to use @override for inherited methods if applicable
  Map<String, dynamic> toJson() {
    return {
      'id': id, // <--- NEW: Include id in JSON
      'description': description,
      'isDone': isDone,
    };
  }

  // שיטה ליצירת אובייקט ChecklistItem ממפה (Map) שהגיעה מ-JSON.
  // זה חשוב לטעינת הנתונים בחזרה.
  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String, // <--- NEW: Read id from JSON
      description: json['description'] as String,
      isDone: json['isDone'] as bool,
    );
  }
}