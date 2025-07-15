// lib/models/activity_model.dart
import 'package:flutter/material.dart';

class Activity {
  String name;
  String? description;
  DateTime date;
  TimeOfDay startTime;
  bool isDone;

  String? locationName;      // שם המקום (לדוגמה: "מוזיאון הלובר")
  String? address;           // כתובת המקום (לדוגמה: "Rue de Rivoli, Paris")
  String? contactInfo;       // טלפון או מייל ליצירת קשר (לדוגמה: "01-2345678")
  String? notes;             // הערות נוספות (לדוגמה: "להביא מצלמה")
  String? reservationDetails; // פרטי הזמנה (לדוגמה: "הזמנה לשעה 14:00, קוד: XYZ123")
  String? website;           // אתר אינטרנט רלוונטי
  double? cost;              // עלות הפעילות, אם יש

  Activity({
    required this.name,
    this.description,
    required this.date,
    required this.startTime,
    this.isDone = false,
    this.locationName,
    this.address,
    this.contactInfo,
    this.notes,
    this.reservationDetails,
    this.website,
    this.cost,
  });

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
      'locationName': locationName,
      'address': address,
      'contactInfo': contactInfo,
      'notes': notes,
      'reservationDetails': reservationDetails,
      'website': website,
      'cost': cost,
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
      locationName: json['locationName'] as String?,
      address: json['address'] as String?,
      contactInfo: json['contactInfo'] as String?,
      notes: json['notes'] as String?,
      reservationDetails: json['reservationDetails'] as String?,
      website: json['website'] as String?,
      cost: (json['cost'] as num?)?.toDouble(), // Cast num to double, handle null
    );
  }
}