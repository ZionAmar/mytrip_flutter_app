import 'package:uuid/uuid.dart'; // Make sure uuid is in pubspec.yaml

enum MemoryType { photo, video, note, link, audio }

class MemoryItem {
  final String id;
  final MemoryType type;
  final String title;
  final String? description;
  final String content; // Path for media, URL for link, text for note
  final DateTime timestamp;
  final String? thumbnailUrl; // For photo/video/audio preview

  // Location and Weather data for the moment
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? weatherDescription;
  final double? weatherTemp;

  MemoryItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.content,
    required this.timestamp,
    this.thumbnailUrl,
    this.latitude,
    this.longitude,
    this.locationName,
    this.weatherDescription,
    this.weatherTemp,
  });

  // Convert MemoryItem to a JSON map for saving
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString().split('.').last, // Store enum as string
    'title': title,
    'description': description,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'thumbnailUrl': thumbnailUrl,
    'latitude': latitude,
    'longitude': longitude,
    'locationName': locationName,
    'weatherDescription': weatherDescription,
    'weatherTemp': weatherTemp,
  };

  // Create a MemoryItem from a JSON map for loading
  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'] as String,
      type: MemoryType.values.firstWhere((e) => e.toString().split('.').last == json['type']),
      title: json['title'] as String,
      description: json['description'] as String?,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['locationName'] as String?,
      weatherDescription: json['weatherDescription'] as String?,
      weatherTemp: (json['weatherTemp'] as num?)?.toDouble(),
    );
  }
}