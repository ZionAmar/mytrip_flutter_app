import 'activity_model.dart';
import 'budget_category_model.dart';

class Trip {
  final String id;
  String name;
  String destinationCity; // הוספנו את עיר היעד
  DateTime startDate;
  DateTime endDate;
  DateTime lastModifiedDate;
  List<Activity> activities;
  List<BudgetCategory> budgetCategories;

  Trip({
    required this.id,
    required this.name,
    required this.destinationCity, // הוספנו לקונסטרקטור
    required this.startDate,
    required this.endDate,
    required this.lastModifiedDate,
    this.activities = const [],
    this.budgetCategories = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'destinationCity': destinationCity, // הוספנו לשמירה
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'lastModifiedDate': lastModifiedDate.toIso8601String(),
      'activities': activities.map((a) => a.toJson()).toList(),
      'budgetCategories': budgetCategories.map((b) => b.toJson()).toList(),
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      name: json['name'],
      destinationCity: json['destinationCity'] ?? '', // הוספנו לקריאה
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      lastModifiedDate: json['lastModifiedDate'] != null
          ? DateTime.parse(json['lastModifiedDate'])
          : DateTime.now(),
      activities: (json['activities'] as List)
          .map((a) => Activity.fromJson(a))
          .toList(),
      budgetCategories: (json['budgetCategories'] as List)
          .map((b) => BudgetCategory.fromJson(b))
          .toList(),
    );
  }
}