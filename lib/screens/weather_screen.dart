import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import '../models/trip_model.dart';

class WeatherScreen extends StatefulWidget {
  final Trip trip;

  const WeatherScreen({super.key, required this.trip});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _weatherService = WeatherService('8c8d50cc8e3c472c07c13bf9a8498eef');

  List<DailyWeather> _forecast = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchForecast();
  }

  Future<void> _fetchForecast() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fullForecast = await _weatherService.fetchDailyForecast(widget.trip.destinationCity);

      // תיקון לוגיקת הסינון
      final tripForecast = fullForecast.where((dailyWeather) {
        // התעלמות מהשעה והשוואה של תאריכים בלבד
        final forecastDate = DateUtils.dateOnly(dailyWeather.date);
        final startDate = DateUtils.dateOnly(widget.trip.startDate);
        final endDate = DateUtils.dateOnly(widget.trip.endDate);

        return !forecastDate.isBefore(startDate) && !forecastDate.isAfter(endDate);
      }).toList();

      setState(() {
        _forecast = tripForecast;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'לא ניתן לקבל תחזית עבור היעד.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('תחזית לטיול: ${widget.trip.name}'),
      ),
      body: _buildForecastDisplay(),
    );
  }

  Widget _buildForecastDisplay() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red, fontSize: 16)));
    }
    if (_forecast.isEmpty) {
      return Center(child: Text('אין תחזית זמינה לתאריכי הטיול.\nהתחזית החינמית מוגבלת ל-5 ימים.'));
    }

    return ListView.builder(
      itemCount: _forecast.length,
      itemBuilder: (context, index) {
        final daily = _forecast[index];
        // שימוש ב-ExpansionTile במקום ListTile
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            leading: Image.network('https://openweathermap.org/img/wn/${daily.iconCode}@2x.png'),
            title: Text(
              DateFormat('EEEE, dd/MM', 'he_IL').format(daily.date),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(daily.description),
            trailing: Text(
              '${daily.temp.toStringAsFixed(0)}°C',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.teal),
            ),
            // הילדים שמוצגים בהרחבה
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDetailItem(Icons.thermostat, 'מרגיש כמו', '${daily.feelsLike.toStringAsFixed(0)}°'),
                    _buildDetailItem(Icons.water_drop, 'לחות', '${daily.humidity}%'),
                    _buildDetailItem(Icons.air, 'מהירות רוח', '${daily.windSpeed} מ/ש'),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // פונקציית עזר לבניית פריט מידע מפורט
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[700])),
        SizedBox(height: 2),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}