import 'package:flutter/material.dart';

/// This screen summarizes the trip's key details.
class SummaryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Summary'),
      ),
      body: Center(
        child: Text(
          'Summary Content Here',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
