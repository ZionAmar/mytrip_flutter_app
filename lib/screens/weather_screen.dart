import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat; // For date formatting
import 'package:lottie/lottie.dart'; // For Lottie animations
import 'package:flutter_animate/flutter_animate.dart'; // For Flutter Animate effects

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
  // Use a secure way to store API keys, e.g., environment variables or a config file
  final _weatherService = WeatherService('8c8d50cc8e3c472c07c13bf9a8498eef');

  List<DailyWeather> _forecast = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchForecast();
  }

  // --- Data Fetching Logic ---
  Future<void> _fetchForecast() async {
    if (!mounted) return; // Ensure widget is still mounted before setState

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _forecast = []; // Clear previous forecast
    });

    try {
      final fullForecast = await _weatherService.fetchDailyForecast(widget.trip.destinationCity);

      // Filter forecast based on trip dates
      final tripForecast = fullForecast.where((dailyWeather) {
        final forecastDate = DateUtils.dateOnly(dailyWeather.date);
        final startDate = DateUtils.dateOnly(widget.trip.startDate);
        final endDate = DateUtils.dateOnly(widget.trip.endDate);

        return !forecastDate.isBefore(startDate) && !forecastDate.isAfter(endDate);
      }).toList();

      if (!mounted) return;
      setState(() {
        _forecast = tripForecast;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // More user-friendly error messages
        _errorMessage = 'לא ניתן לקבל תחזית עבור ${widget.trip.destinationCity}.\nודא שהשם נכון ונסה שוב מאוחר יותר.';
        _isLoading = false;
      });
      print('Error fetching weather: $e'); // For debugging
    }
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'תחזית לטיול: ${widget.trip.name}',
          style: TextStyle(color: colorScheme.onPrimary), // Consistent app bar text color
        ),
        centerTitle: true,
        backgroundColor: colorScheme.primary, // Themed app bar background
        elevation: 0, // Flat app bar
        automaticallyImplyLeading: false, // מונע הופעת כפתור חזור אוטומטי
        leading: IconButton( // כפתור חזור (בחזית, צד ימין ב-RTL)
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          tooltip: 'חזרה למסך הבית',
          onPressed: () {
            Navigator.pop(context); // חוזר למסך הקודם (HomeScreen)
          },
        ),
        actions: [
          IconButton( // כפתור בית (בצד שמאל ב-RTL)
            icon: const Icon(Icons.home_outlined, color: Colors.white),
            tooltip: 'למסך הראשי של הטיולים',
            onPressed: () {
              // מנקה את מחסנית הניווט וחוזר למסך רשימת הטיולים
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          // כפתור הרענון הוסר מכאן, אך פונקציונליות הרענון נשארת עם RefreshIndicator
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl, // Ensure RTL layout for the entire body
        child: RefreshIndicator( // Allow pull-to-refresh
          onRefresh: _fetchForecast, // פונקציית הרענון נשארת דרך משיכה
          color: colorScheme.secondary,
          backgroundColor: colorScheme.surface,
          child: _buildForecastDisplay(colorScheme),
        ),
      ),
    );
  }

  // --- Forecast Display Logic ---
  Widget _buildForecastDisplay(ColorScheme colorScheme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'טוען תחזית עבור ${widget.trip.destinationCity}...',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView( // Allow scrolling for empty state
          physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Animate(
                effects: [
                  FadeEffect(duration: 500.ms),
                ],
                child: Lottie.asset(
                  'assets/lottie_no_data.json',
                  height: 200,
                  repeat: false,
                  animate: true,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'אופס! ${_errorMessage!}', // Use null assertion here as it's checked above
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.error, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'ודאו ששם העיר נכון ושיש חיבור לאינטרנט.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchForecast,
                icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
                label: const Text('נסה שוב', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
            ],
          ),
        ),
      );
    }
    if (_forecast.isEmpty) {
      return Center(
        child: SingleChildScrollView( // Allow scrolling for empty state
          physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Animate(
                effects: [
                  FadeEffect(duration: 500.ms),
                ],
                child: Lottie.asset(
                  'assets/lottie_no_data.json',
                  height: 200,
                  repeat: false,
                  animate: true,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'אין תחזית זמינה לתאריכי הטיול הללו.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'התחזית החינמית מוגבלת ל-5 ימים קדימה, או שאולי תאריכי הטיול מחוץ לטווח.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchForecast,
                icon: Icon(Icons.refresh, color: colorScheme.onPrimary),
                label: const Text('רענן תחזית', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      itemCount: _forecast.length,
      itemBuilder: (context, index) {
        final daily = _forecast[index];
        final bool isToday = DateUtils.dateOnly(daily.date) == DateUtils.dateOnly(DateTime.now());

        return Animate(
          effects: [
            FadeEffect(duration: 300.ms, delay: (index * 80).ms), // Staggered fade-in
            SlideEffect(begin: const Offset(0.1, 0), end: Offset.zero, duration: 300.ms, delay: (index * 80).ms, curve: Curves.easeOut),
          ],
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 6, // Stronger shadow for modern look
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), // More rounded corners
            clipBehavior: Clip.antiAlias, // Ensures content is clipped to rounded corners
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: Container(
                width: 60, // Fixed width for icon container
                height: 60,
                decoration: BoxDecoration(
                  color: isToday ? colorScheme.tertiary.withOpacity(0.2) : colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.network(
                    'https://openweathermap.org/img/wn/${daily.iconCode}@2x.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.cloud_off, color: colorScheme.error), // Fallback icon
                  ),
                ),
              ),
              title: Text(
                isToday ? 'היום' : DateFormat('EEEE, dd/MM', 'he_IL').format(daily.date),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isToday ? colorScheme.tertiary : colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                daily.description,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${daily.temp.toStringAsFixed(0)}°C',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary, // Primary color for main temp
                    ),
                  ),
                  Text(
                    'מקס: ${daily.maxTemp.toStringAsFixed(0)}° / מינ: ${daily.minTemp.toStringAsFixed(0)}°',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              children: [
                Divider(height: 1, thickness: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDetailItem(colorScheme, Icons.thermostat, 'מרגיש כמו', '${daily.feelsLike.toStringAsFixed(0)}°'),
                      _buildDetailItem(colorScheme, Icons.water_drop, 'לחות', '${daily.humidity}%'),
                      _buildDetailItem(colorScheme, Icons.air, 'מהירות רוח', '${daily.windSpeed} מ/ש'),
                      _buildDetailItem(colorScheme, Icons.umbrella, 'לחץ', '${daily.pressure} hPa'), // Added pressure
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper function for building detailed info items
  Widget _buildDetailItem(ColorScheme colorScheme, IconData icon, String label, String value) {
    return Expanded( // Use Expanded to ensure even spacing
      child: Column(
        children: [
          Icon(icon, color: colorScheme.secondary), // Themed icon color
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface)),
        ],
      ),
    );
  }
}