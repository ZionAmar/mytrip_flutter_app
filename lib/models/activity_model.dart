import 'package:flutter/material.dart';

class Activity {
  String name;
  String? description;
  DateTime date;
  TimeOfDay startTime;
  bool isDone;

  Activity({
    required this.name,
    this.description,
    required this.date,
    required this.startTime,
    this.isDone = false,
  });

  // הוספנו פונקציית עזר למיון קל יותר
  DateTime get fullDateTime {
    return DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': '${startTime.hour}:${startTime.minute}',
      'isDone': isDone,
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    final timeParts = json['startTime'].split(':');
    return Activity(
      name: json['name'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      startTime: TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
      isDone: json['isDone'],
    );
  }
}