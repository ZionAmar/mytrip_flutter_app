import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/trips_list_screen.dart';

void main() {
  runApp(MyTripApp());
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
      // מגדירים רק את מסכי הבסיס שהאפליקציה יכולה להגיע אליהם ישירות
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(nextRoute: '/trips'),
        '/trips': (context) => TripsListScreen(),
      },
    );
  }
}