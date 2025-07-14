// lib/models/trip_model.dart
import 'activity_model.dart';
import 'budget_category_model.dart';
import 'weather_model.dart'; // <--- ודא שזה קיים!

class Trip {
  final String id;
  String name;
  String destinationCity;
  DateTime startDate;
  DateTime endDate;
  DateTime lastModifiedDate;
  List<Activity> activities;
  List<BudgetCategory> budgetCategories;
  List<DailyWeather>? savedWeatherForecast; // <--- החזרנו את השדה

  Trip({
    required this.id,
    required this.name,
    required this.destinationCity,
    required this.startDate,
    required this.endDate,
    required this.lastModifiedDate,
    this.activities = const [],
    this.budgetCategories = const [],
    this.savedWeatherForecast, // <--- החזרנו לקונסטרקטור
  });

  Trip copyWith({
    String? id,
    String? name,
    String? destinationCity,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? lastModifiedDate,
    List<Activity>? activities,
    List<BudgetCategory>? budgetCategories,
    List<DailyWeather>? savedWeatherForecast, // <--- החזרנו ל-copyWith
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
      savedWeatherForecast: savedWeatherForecast ?? this.savedWeatherForecast, // <--- החזרנו לכאן
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'destinationCity': destinationCity,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'lastModifiedDate': lastModifiedDate.toIso8601String(),
      'activities': activities.map((a) => a.toJson()).toList(),
      'budgetCategories': budgetCategories.map((b) => b.toJson()).toList(),
      'savedWeatherForecast': savedWeatherForecast?.map((w) => w.toJson()).toList(), // <--- החזרנו לשמירה
    };
  }

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      name: json['name'],
      destinationCity: json['destinationCity'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      lastModifiedDate: json['lastModifiedDate'] != null
          ? DateTime.parse(json['lastModifiedDate'])
          : DateTime.now(),
      activities: (json['activities'] as List<dynamic>?)
          ?.map((a) => Activity.fromJson(a as Map<String, dynamic>))
          .toList() ?? [],
      budgetCategories: (json['budgetCategories'] as List<dynamic>?)
          ?.map((b) => BudgetCategory.fromJson(b as Map<String, dynamic>))
          .toList() ?? [],
      savedWeatherForecast: (json['savedWeatherForecast'] as List<dynamic>?) // <--- החזרנו לטעינה
          ?.map((w) => DailyWeather.fromJson(w as Map<String, dynamic>))
          .toList(),
    );
  }
}