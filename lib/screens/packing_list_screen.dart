import 'package:flutter/material.dart';

/// This screen shows the packing list items for the trip.
class PackingListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Packing List'),
      ),
      body: Center(
        child: Text(
          'Packing List Content Here',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
