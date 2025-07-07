import 'package:flutter/material.dart';

/// This screen summarizes all aspects of the trip.
class TripSummaryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip Summary'),
      ),
      body: Center(
        child: Text(
          'Trip Summary Content Here',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
