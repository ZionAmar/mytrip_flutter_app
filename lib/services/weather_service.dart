import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  // שינינו את כתובת ה-API לזו של התחזית החינמית
  static const _baseUrl = 'https://api.openweathermap.org/data/2.5/forecast';
  final String _apiKey;
  String get apiKey => _apiKey; // <--- הוסיפו את השורה הזו כאן! זהו ה'חלון' לקוד הסודי

  WeatherService(this._apiKey);

  // הפונקציה עדיין תחזיר רשימה של תחזיות יומיות
  Future<List<DailyWeather>> fetchDailyForecast(String cityName) async {
    final Uri uri = Uri.parse('$_baseUrl?q=$cityName&appid=$_apiKey&units=metric&lang=he');

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final json = jsonDecode(decodedBody);

      final List<dynamic> list = json['list'];

      // --- עיבוד הנתונים ---
      // ניקח את התחזית של השעה 12:00 בצהריים מכל יום
      final Map<int, dynamic> dailyData = {};
      for (var item in list) {
        final date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
        // נשמור רק את התחזית של 12:00, או את הראשונה שנמצא
        if (date.hour == 12 || !dailyData.containsKey(date.day)) {
          dailyData[date.day] = item;
        }
      }

      return dailyData.values.map((data) => DailyWeather.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load weather forecast');
    }
  }
}