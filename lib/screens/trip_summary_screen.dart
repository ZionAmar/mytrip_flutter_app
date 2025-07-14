// lib/screens/trip_summary_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // To format dates
import '../models/trip_model.dart'; // To access trip data
import '../models/activity_model.dart'; // To access activity details, if not already through Trip
import '../models/budget_category_model.dart'; // To access budget categories
import '../models/expense_model.dart'; // To access expense details, if not already through BudgetCategory
import '../models/weather_model.dart'; // <--- החזרנו ייבוא

/// This screen summarizes all aspects of the trip.
class TripSummaryScreen extends StatelessWidget {
  final Trip trip; // Receive the Trip object

  const TripSummaryScreen({
    super.key,
    required this.trip,
  });

  // Helper functions to calculate summary data
  int _getTotalActivities(Trip trip) {
    return trip.activities.length; // Count total activities
  }

  int _getCompletedActivities(Trip trip) {
    // Count activities marked as done
    return trip.activities.where((activity) => activity.isDone).length;
  }

  double _getTotalPlannedBudget(Trip trip) {
    // Sum up planned budget from all categories
    return trip.budgetCategories.fold(0.0, (sum, category) => sum + category.plannedAmount);
  }

  double _getTotalActualSpent(Trip trip) {
    // Sum up actual spending from all categories
    return trip.budgetCategories.fold(0.0, (sum, category) => sum + category.actualAmount);
  }

  String _getWeatherSummary(List<DailyWeather>? forecast) { // <--- החזרנו את הפונקציה
    if (forecast == null || forecast.isEmpty) {
      return 'אין נתוני מזג אוויר שמורים.'; // Message if no saved weather
    }
    // Example weather summary: average temperature and common conditions
    double avgTemp = forecast.fold(0.0, (sum, daily) => sum + daily.temp) / forecast.length;
    String commonDescription = forecast.map((e) => e.description).toSet().join(', '); // Unique conditions

    return 'טמפ. ממוצעת: ${avgTemp.toStringAsFixed(1)}°C\nתנאים נפוצים: $commonDescription';
  }


  @override
  Widget build(BuildContext context) {
    final totalActivities = _getTotalActivities(trip); // Get total activities
    final completedActivities = _getCompletedActivities(trip); // Get completed activities
    final totalPlannedBudget = _getTotalPlannedBudget(trip); // Get total planned budget
    final totalActualSpent = _getTotalActualSpent(trip); // Get total actual spent
    final budgetRemaining = totalPlannedBudget - totalActualSpent; // Calculate remaining budget

    return Scaffold(
      appBar: AppBar(
        title: Text('סיכום טיול: ${trip.name}'), // Display trip name in app bar
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Trip Details Section
            _buildSectionTitle(context, 'פרטי טיול כלליים'),
            _buildInfoRow('יעד:', trip.destinationCity),
            _buildInfoRow('תאריכים:', '${DateFormat('dd/MM/yyyy').format(trip.startDate)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate)}'),
            _buildInfoRow('עודכן לאחרונה:', DateFormat('dd/MM/yyyy HH:mm').format(trip.lastModifiedDate)),
            const SizedBox(height: 20),

            // Activities Summary Section
            _buildSectionTitle(context, 'סיכום פעילויות'),
            _buildInfoRow('סה"כ פעילויות:', '$totalActivities'),
            _buildInfoRow('פעילויות שהושלמו:', '$completedActivities / $totalActivities'),
            const SizedBox(height: 20),

            // Budget Summary Section
            _buildSectionTitle(context, 'סיכום תקציב'),
            _buildInfoRow('תקציב מתוכנן:', '${totalPlannedBudget.toStringAsFixed(2)} ₪'),
            _buildInfoRow('הוצאות בפועל:', '${totalActualSpent.toStringAsFixed(2)} ₪'),
            _buildInfoRow(
              'יתרה:',
              '${budgetRemaining.toStringAsFixed(2)} ₪',
              valueColor: budgetRemaining < 0 ? Colors.red : Colors.green, // Color remaining budget
            ),
            const SizedBox(height: 20),

            // Weather Summary Section (using savedWeatherForecast)
            _buildSectionTitle(context, 'סיכום מזג אוויר'),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(_getWeatherSummary(trip.savedWeatherForecast)), // <--- חזרנו לשימוש בשדה
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build section titles
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  // Helper widget to build info rows
  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}