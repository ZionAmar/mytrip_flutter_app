// lib/models/trip_model.dart
import 'activity_model.dart';
import 'budget_category_model.dart';
import 'weather_model.dart';
import 'memory_item_model.dart'; // <--- NEW: Import MemoryItem model

class Trip {
  final String id;
  String name;
  String destinationCity;
  DateTime startDate;
  DateTime endDate;
  DateTime lastModifiedDate;
  List<Activity> activities;
  List<BudgetCategory> budgetCategories;
  List<DailyWeather>? savedWeatherForecast;
  List<MemoryItem>? memories; // <--- NEW: List to hold memories

  Trip({
    required this.id,
    required this.name,
    required this.destinationCity,
    required this.startDate,
    required this.endDate,
    required this.lastModifiedDate,
    this.activities = const [],
    this.budgetCategories = const [],
    this.savedWeatherForecast,
    this.memories = const [], // <--- NEW: Initialize as empty list by default
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
    List<DailyWeather>? savedWeatherForecast,
    List<MemoryItem>? memories, // <--- NEW: Add to copyWith
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
      savedWeatherForecast: savedWeatherForecast ?? this.savedWeatherForecast,
      memories: memories ?? this.memories, // <--- NEW: Assign in copyWith
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
      'savedWeatherForecast': savedWeatherForecast?.map((w) => w.toJson()).toList(),
      'memories': memories?.map((m) => m.toJson()).toList(), // <--- NEW: Add to toJson
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
      savedWeatherForecast: (json['savedWeatherForecast'] as List<dynamic>?)
          ?.map((w) => DailyWeather.fromJson(w as Map<String, dynamic>))
          .toList(),
      memories: (json['memories'] as List<dynamic>?) // <--- NEW: Add to fromJson
          ?.map((m) => MemoryItem.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}