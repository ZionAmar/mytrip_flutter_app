import 'package:flutter/material.dart';

class Activity {
  String name;
  String? description; // שדה אופציונלי
  DateTime date;
  TimeOfDay startTime;
  bool isDone;

  Activity({
    required this.name,
    this.description,
    required this.date,
    required this.startTime,
    this.isDone = false, // ערך ברירת מחדל
  });

  // המרה מאובייקט ל-Map (כדי לשמור כ-JSON)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'date': date.toIso8601String(), // המרת תאריך לטקסט
      'startTime': '${startTime.hour}:${startTime.minute}', // המרת שעה לטקסט
      'isDone': isDone,
    };
  }

  // המרה מ-Map לאובייקט (כדי לקרוא מ-JSON)
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