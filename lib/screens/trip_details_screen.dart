import 'package:flutter/material.dart';

/// This screen displays the detailed information about the trip.
class TripDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Details'),
      ),
      body: Center(
        child: Text(
          'Trip Details Content Here',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
