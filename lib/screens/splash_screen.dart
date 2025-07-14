import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  // הוספנו משתנה שיקבל את הנתיב הבא
  final String nextRoute;
  const SplashScreen({super.key, required this.nextRoute});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      // שימוש בנתיב שהתקבל במקום בנתיב קבוע
      Navigator.pushReplacementNamed(context, widget.nextRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_takeoff, size: 80, color: Colors.teal),
            SizedBox(height: 20),
            Text('MyTrip', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}