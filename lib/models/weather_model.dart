// lib/models/weather_model.dart
class DailyWeather {
  final DateTime date;
  final double temp;
  final double feelsLike;
  final double minTemp; // Added
  final double maxTemp; // Added
  final int humidity;
  final double windSpeed;
  final int pressure; // Added
  final String description;
  final String iconCode;

  DailyWeather({
    required this.date,
    required this.temp,
    required this.feelsLike,
    required this.minTemp, // Added
    required this.maxTemp, // Added
    required this.humidity,
    required this.windSpeed,
    required this.pressure, // Added
    required this.description,
    required this.iconCode,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    return DailyWeather(
      date: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int) * 1000),
      temp: (json['main']['temp'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (json['main']['feels_like'] as num?)?.toDouble() ?? 0.0,
      minTemp: (json['main']['temp_min'] as num?)?.toDouble() ?? 0.0, // Corrected key
      maxTemp: (json['main']['temp_max'] as num?)?.toDouble() ?? 0.0, // Corrected key
      humidity: (json['main']['humidity'] as int?) ?? 0,
      windSpeed: (json['wind']['speed'] as num?)?.toDouble() ?? 0.0,
      pressure: (json['main']['pressure'] as int?) ?? 0, // Corrected key
      description: (json['weather']?[0]?['description'] as String?) ?? '',
      iconCode: (json['weather']?[0]?['icon'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dt': date.millisecondsSinceEpoch ~/ 1000,
      'main': {
        'temp': temp,
        'feels_like': feelsLike,
        'temp_min': minTemp, // Added
        'temp_max': maxTemp, // Added
        'humidity': humidity,
        'pressure': pressure, // Added
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