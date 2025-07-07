import 'package:flutter/material.dart';

/// This screen displays a map of the trip location.
class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map'),
      ),
      body: Center(
        child: Text(
          'Map Content Here',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
