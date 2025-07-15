enum MemoryType {
  photo,
  video,
  note,
  link,
  audio,
}

class MemoryItem {
  final String id;
  final MemoryType type;
  String title;
  String? description;
  String content; // File path, URL, or note text
  DateTime timestamp;
  String? thumbnailUrl; // For preview (same as content for images, or generated for video)

  // --- NEW: Location and Weather data ---
  double? latitude;
  double? longitude;
  String? locationName; // A human-readable name for the location
  String? weatherDescription; // e.g., "Clear Sky"
  double? weatherTemp;       // e.g., 25.5

  MemoryItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.content,
    required this.timestamp,
    this.thumbnailUrl,
    // --- NEW fields in constructor ---
    this.latitude,
    this.longitude,
    this.locationName,
    this.weatherDescription,
    this.weatherTemp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
      // --- NEW: Add to JSON conversion ---
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'weatherDescription': weatherDescription,
      'weatherTemp': weatherTemp,
    };
  }

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'] as String,
      type: MemoryType.values.firstWhere((e) => e.toString().split('.').last == json['type']),
      title: json['title'] as String,
      description: json['description'] as String?,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      // --- NEW: Read from JSON ---
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['locationName'] as String?,
      weatherDescription: json['weatherDescription'] as String?,
      weatherTemp: (json['weatherTemp'] as num?)?.toDouble(),
    );
  }
}