// Import Material package to access basic UI widgets
import 'package:flutter/material.dart';

/// HomeScreen is the main dashboard after login/splash.
/// It contains navigation buttons to all major parts of the MyTrip app.
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar shown at the top of the screen
      appBar: AppBar(
        title: Text('MyTrip Home'),
      ),

      // Main content centered vertically and horizontally
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Welcome message
              Text(
                'Welcome to MyTrip!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 20),

              // Navigation buttons
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/tripDetails'),
                child: Text('Trip Details'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/activities'),
                child: Text('Activities'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/budget'),
                child: Text('Budget'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/summary'),
                child: Text('Summary'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/packingList'),
                child: Text('Packing List'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/map'),
                child: Text('Trip Map'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/tripSummary'),
                child: Text('Trip Summary'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/budgetTest'),
                child: Text('Budget Test'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
