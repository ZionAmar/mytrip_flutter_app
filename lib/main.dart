import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // 1. הוסף את הייבוא הזה
import 'screens/splash_screen.dart';
import 'screens/trips_list_screen.dart';

void main() {
  // 2. החלף את פונקציית ה-main הקיימת בזו
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting('he_IL', null).then((_) {
    runApp(MyTripApp());
  });
}

class MyTripApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyTrip App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(nextRoute: '/trips'),
        '/trips': (context) => TripsListScreen(),
      },
    );
  }
}