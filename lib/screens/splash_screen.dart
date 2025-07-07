import 'package:flutter/material.dart';

/// SplashScreen appears briefly when the app launches.
/// It shows a logo or loading message, then navigates to the home screen.
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Delay for 2 seconds, then navigate to Home
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/home');
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
            // Optional logo or icon
            Icon(Icons.flight_takeoff, size: 80, color: Colors.teal),
            SizedBox(height: 20),
            Text(
              'MyTrip',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Preparing your trip...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
