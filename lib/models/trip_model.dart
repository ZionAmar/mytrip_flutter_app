// lib/models/trip_model.dart
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

  // copyWith method for convenient updating
  Trip copyWith({
    String? id,
    String? name,
    String? destinationCity,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastModifiedDate,
    List<Activity>? activities,
    List<BudgetCategory>? budgetCategories,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      destinationCity: destinationCity ?? this.destinationCity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastModifiedDate: lastModifiedDate ?? this.lastModifiedDate,
      activities: activities ?? this.activities,
      budgetCategories: budgetCategories ?? this.budgetCategories,
    );
  }

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
      destinationCity: json['destinationCity'] ?? '', // הוספנו לקריאה, עם טיפול ב-null
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      lastModifiedDate: json['lastModifiedDate'] != null
          ? DateTime.parse(json['lastModifiedDate'])
          : DateTime.now(), // Fallback if lastModifiedDate is missing
      activities: (json['activities'] as List<dynamic>?) // Handle potential null activities list
          ?.map((a) => Activity.fromJson(a as Map<String, dynamic>))
          .toList() ?? [], // Provide empty list if null
      budgetCategories: (json['budgetCategories'] as List<dynamic>?) // Handle potential null categories list
          ?.map((b) => BudgetCategory.fromJson(b as Map<String, dynamic>))
          .toList() ?? [], // Provide empty list if null
    );
  }
}