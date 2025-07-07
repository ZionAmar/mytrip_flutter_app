import 'package:flutter/material.dart';

/// This screen displays budget-related details.
class BudgetScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget'),
      ),
      body: Center(
        child: Text(
          'Budget Content Here',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
