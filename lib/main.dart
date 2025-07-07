// Import Flutter's Material package to use widgets and theming
import 'package:flutter/material.dart';

// Importing all the different screens used in the app
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/activities_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/trip_details_screen.dart';
import 'screens/packing_list_screen.dart';
import 'screens/map_screen.dart';
import 'screens/trip_summary_screen.dart';
import 'screens/budget_test_screen.dart';

/// This is the entry point of the app
void main() {
  runApp(MyTripApp()); // Runs the app and uses MyTripApp as the root widget
}

/// The root widget of the application
class MyTripApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hides the debug banner on top right
      title: 'MyTrip App', // Title of the app used by the OS
      theme: ThemeData(
        primarySwatch: Colors.teal, // Sets the theme color
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/', // The first screen to load (SplashScreen)

      // Defining named routes for navigation
      routes: {
        '/': (context) => SplashScreen(), // Splash screen shown first
        '/home': (context) => HomeScreen(),
        '/activities': (context) => ActivitiesScreen(),
        '/budget': (context) => BudgetScreen(),
        '/summary': (context) => SummaryScreen(),
        '/tripDetails': (context) => TripDetailsScreen(),
        '/packingList': (context) => PackingListScreen(),
        '/map': (context) => MapScreen(),
        '/tripSummary': (context) => TripSummaryScreen(),
        '/budgetTest': (context) => BudgetTestScreen(),
      },
    );
  }
}
