// lib/models/weather_model.dart
class DailyWeather {
  final DateTime date;
  final double temp;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String iconCode;

  DailyWeather({
    required this.date,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.iconCode,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    return DailyWeather(
      // Ensure 'dt' is treated as an int, as it's a Unix timestamp in seconds
      date: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      // Use null-aware access and default to 0.0 if value is missing or null
      temp: (json['main']['temp'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (json['main']['feels_like'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['main']['humidity'] as int?) ?? 0,
      windSpeed: (json['wind']['speed'] as num?)?.toDouble() ?? 0.0,
      // Provide fallback empty string if description or icon is missing
      description: (json['weather']?[0]?['description'] as String?) ?? '',
      iconCode: (json['weather']?[0]?['icon'] as String?) ?? '',
    );
  }

  // <--- RE-ADDED: This toJson method is critical for saving DailyWeather objects
  Map<String, dynamic> toJson() {
    return {
      // Convert DateTime back to Unix timestamp in seconds for saving
      'dt': date.millisecondsSinceEpoch ~/ 1000,
      'main': {
        'temp': temp,
        'feels_like': feelsLike,
        'humidity': humidity,
      },
      'wind': {
        'speed': windSpeed,
      },
      'weather': [
        {
          'description': description,
          'icon': iconCode,
        }
      ],
    };
  }
}