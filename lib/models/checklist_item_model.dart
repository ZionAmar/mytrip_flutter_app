// lib/models/checklist_item_model.dart
class ChecklistItem {
  String description; // תיאור המשימה (לדוגמה: "לארוז בגדים חמים")
  bool isDone;        // האם המשימה בוצעה (true/false)

  ChecklistItem({
    required this.description,
    this.isDone = false, // ברירת מחדל: המשימה לא בוצעה
  });

  // שיטה להמרת אובייקט ChecklistItem למפה (Map) המתאימה ל-JSON.
  // זה חשוב לשמירת הנתונים.
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'isDone': isDone,
    };
  }

  // שיטה ליצירת אובייקט ChecklistItem ממפה (Map) שהגיעה מ-JSON.
  // זה חשוב לטעינת הנתונים בחזרה.
  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      description: json['description'] as String,
      isDone: json['isDone'] as bool,
    );
  }
}