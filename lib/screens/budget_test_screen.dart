import 'package:flutter/material.dart';

/// This is a test version of the budget screen.
class BudgetTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Test'),
      ),
      body: Center(
        child: Text(
          'Budget Test Content Here',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
